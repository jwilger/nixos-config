{ lib, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services = {
    blueman.enable = true;
    gvfs.enable = true;
    dbus.enable = true;
    fstrim.enable = true;

    # Explicitly disable gnome-keyring to prevent SSH agent interference
    # Use mkForce to override niri-flake defaults
    gnome.gnome-keyring.enable = lib.mkForce false;

    logind.settings = {
      Login = {
        # don't shutdown when power button is short-pressed
        HandlePowerKey = "ignore";
      };
    };

    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        AllowAgentForwarding = true;
        X11Forwarding = false;
        # Required for WezTerm nightly SSH agent forwarding to workspaces
        StreamLocalBindUnlink = true;
      };
      extraConfig = ''
        # Accept environment variables from clients (needed for WezTerm and other modern terminals)
        # WezTerm-specific variables (based on GitHub issues #1015, #5378)
        AcceptEnv WEZTERM_PANE WEZTERM_REMOTE_PANE TERM_PROGRAM TERM_PROGRAM_VERSION
        # Standard locale and terminal variables
        AcceptEnv LANG LC_* TERM COLORTERM
        # Additional terminal capability variables
        AcceptEnv TERMINFO TERMCAP
        # Color output control
        AcceptEnv NO_COLOR FORCE_COLOR CLICOLOR CLICOLOR_FORCE
      '';
    };

    fail2ban.enable = true;
    timesyncd.enable = true;
    upower.enable = true;
    logrotate.enable = true;

    # Neo4j for Memento MCP knowledge graph
    neo4j = {
      enable = true;
      # Use bolt protocol on default port
      bolt.enable = true;
      bolt.listenAddress = "127.0.0.1:7687";
      bolt.tlsLevel = "DISABLED"; # For local development

      # HTTP interface for browser access
      http.enable = true;
      http.listenAddress = "127.0.0.1:7474";

      # HTTPS disabled for local use
      https.enable = false;

      # Configure directories - use /home for larger storage array
      directories = {
        home = "/home/neo4j";
      };

      # Extra configuration for vector search support
      extraServerConfig = ''
        # Disable authentication for local development
        dbms.security.auth_enabled=false

        # Enable procedures for vector search and graph algorithms
        dbms.security.procedures.unrestricted=apoc.*,gds.*
        dbms.security.procedures.allowlist=apoc.*,gds.*,db.*

        # Memory configuration for better performance
        server.memory.heap.initial_size=512m
        server.memory.heap.max_size=2G
        server.memory.pagecache.size=1G

        # Enable query logging for debugging
        db.logs.query.enabled=INFO
        db.logs.query.threshold=0
      '';
    };
  };

  systemd.services.neo4j.preStart = lib.mkBefore ''
    # Neo4j can leave behind a stale PID file; remove it if it does not point
    # to an active Neo4j process.
    pid_file=/home/neo4j/run/neo4j.pid
    mkdir -p /home/neo4j/run
    chown neo4j:neo4j /home/neo4j/run

    if [ -f "$pid_file" ]; then
      pid="$(cat "$pid_file" 2>/dev/null || true)"
      cmdline=""

      if [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ]; then
        cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
      fi

      if ! echo "$cmdline" | grep -qiE '(^|[[:space:]/])neo4j([[:space:]]|$)'; then
        rm -f "$pid_file"
      fi
    fi
  '';
}
