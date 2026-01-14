#!/usr/bin/env bash
# Claude Code Notification Helper
# - If terminal is focused: regular notification with timeout
# - If terminal is NOT focused: sticky notification with Focus button, auto-dismiss on focus

set -euo pipefail

NOTIF_STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/claude-notifications"
mkdir -p "$NOTIF_STATE_DIR"

# Read JSON input from stdin
INPUT=$(cat)

# Extract fields from the notification payload
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude needs attention"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // ""')

# KITTY_PID is inherited from Claude's environment - uniquely identifies the terminal
TERMINAL_PID="${KITTY_PID:-}"

# Extract project name from the working directory
if [[ -n "$CWD" ]]; then
    PROJECT_NAME=$(basename "$CWD")
else
    PROJECT_NAME="Unknown"
fi

# Create a unique key for this session
SESSION_KEY="${SESSION_ID:-${TERMINAL_PID:-$PROJECT_NAME}}"
SESSION_KEY_SAFE=$(echo "$SESSION_KEY" | tr '/' '_' | tr -cd '[:alnum:]_-')
NOTIF_ID_FILE="$NOTIF_STATE_DIR/$SESSION_KEY_SAFE.notif"
WATCHER_PID_FILE="$NOTIF_STATE_DIR/$SESSION_KEY_SAFE.watcher"

# Build the notification title with project context
TITLE="Claude Code [$PROJECT_NAME]"

# Determine urgency based on notification type
case "$NOTIFICATION_TYPE" in
    permission_prompt)
        URGENCY="critical"
        ;;
    *)
        URGENCY="normal"
        ;;
esac

# Cleanup any existing notification/watcher for this session
cleanup_existing() {
    if [[ -f "$WATCHER_PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$WATCHER_PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid" 2>/dev/null || true
        fi
        rm -f "$WATCHER_PID_FILE"
    fi

    if [[ -f "$NOTIF_ID_FILE" ]]; then
        local old_notif_id
        old_notif_id=$(cat "$NOTIF_ID_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_notif_id" ]]; then
            # Close by replacing with auto-expire notification
            notify-send --replace-id="$old_notif_id" --expire-time=1 --app-name="Claude Code" " " " " 2>/dev/null || true
        fi
        rm -f "$NOTIF_ID_FILE"
    fi
}

cleanup_existing

# Check if our terminal is currently focused
is_terminal_focused() {
    if [[ -z "$TERMINAL_PID" ]]; then
        return 1  # Unknown, assume not focused
    fi

    local focused_pid
    focused_pid=$(niri msg focused-window 2>/dev/null | grep -E "^\s*PID:" | sed 's/.*PID:\s*//' | tr -d ' ')

    [[ "$focused_pid" == "$TERMINAL_PID" ]]
}

# Find the niri window ID for our terminal
find_terminal_window_id() {
    if [[ -z "$TERMINAL_PID" ]]; then
        return 1
    fi

    local windows_data current_id=""
    windows_data=$(niri msg windows 2>/dev/null)

    while IFS= read -r line; do
        if [[ "$line" =~ Window\ ID\ ([0-9]+): ]]; then
            current_id="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ PID:\ ([0-9]+) ]]; then
            if [[ "${BASH_REMATCH[1]}" == "$TERMINAL_PID" ]]; then
                echo "$current_id"
                return 0
            fi
        fi
    done <<< "$windows_data"
    return 1
}

# Focus the terminal window
focus_terminal() {
    local window_id
    window_id=$(find_terminal_window_id)
    if [[ -n "$window_id" ]]; then
        niri msg action focus-window --id "$window_id" 2>/dev/null
    fi
}

if is_terminal_focused; then
    # Terminal is focused - just show a regular notification with timeout
    notify-send \
        --app-name="Claude Code" \
        --urgency="$URGENCY" \
        "$TITLE" \
        "$MESSAGE" 2>/dev/null || true
    exit 0
fi

# Terminal is NOT focused - show sticky notification with Focus button
# Run in background so we don't block the hook
(
    # Use a temp file to pass the notification ID from notify-send
    NOTIF_ID_TEMP=$(mktemp)

    # Start notify-send with action in background, save ID immediately
    {
        notify-send \
            --app-name="Claude Code" \
            --urgency="$URGENCY" \
            --expire-time=0 \
            --print-id \
            -A "focus=Focus Window" \
            "$TITLE" \
            "$MESSAGE" 2>/dev/null
    } > "$NOTIF_ID_TEMP" &
    NOTIFY_PID=$!

    # Wait briefly for the notification ID to be written
    sleep 0.2

    # Read the notification ID (first line)
    NOTIF_ID=$(head -1 "$NOTIF_ID_TEMP" 2>/dev/null || echo "")

    if [[ -n "$NOTIF_ID" && "$NOTIF_ID" =~ ^[0-9]+$ ]]; then
        echo "$NOTIF_ID" > "$NOTIF_ID_FILE"

        # Find window ID for focus watching
        TARGET_WINDOW_ID=$(find_terminal_window_id)

        if [[ -n "$TARGET_WINDOW_ID" ]]; then
            # Start watcher that dismisses notification when terminal is focused
            (
                niri msg event-stream 2>/dev/null | while IFS= read -r event; do
                    # Event format: "Window focus changed: Some(41)"
                    if echo "$event" | grep -qE "Window focus changed: Some\(${TARGET_WINDOW_ID}\)"; then
                        # User focused our terminal - dismiss notification by replacing with auto-expire
                        notify-send --replace-id="$NOTIF_ID" --expire-time=1 --app-name="Claude Code" " " " " 2>/dev/null || true
                        # Kill the notify-send process if still waiting
                        kill "$NOTIFY_PID" 2>/dev/null || true
                        rm -f "$NOTIF_ID_FILE" "$WATCHER_PID_FILE" "$NOTIF_ID_TEMP"
                        exit 0
                    fi
                done
            ) &
            echo $! > "$WATCHER_PID_FILE"
        fi
    fi

    # Wait for notify-send to complete (user clicked action or notification was dismissed)
    wait "$NOTIFY_PID" 2>/dev/null || true

    # Check if user clicked "focus"
    CLICKED_ACTION=$(tail -n +2 "$NOTIF_ID_TEMP" 2>/dev/null | head -1 || echo "")

    if [[ "$CLICKED_ACTION" == "focus" ]]; then
        focus_terminal
    fi

    # Cleanup
    rm -f "$NOTIF_ID_TEMP"

    # Kill watcher if still running
    if [[ -f "$WATCHER_PID_FILE" ]]; then
        watcher_pid=$(cat "$WATCHER_PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$watcher_pid" ]]; then
            kill "$watcher_pid" 2>/dev/null || true
        fi
        rm -f "$WATCHER_PID_FILE"
    fi
    rm -f "$NOTIF_ID_FILE"
) &

exit 0
