{ ... }:
{
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
  };

  services.logind.settings = {
    Login = {
      # don't shutdown when power button is short-pressed
      HandlePowerKey = "ignore";
    };
  };

  services.openssh = {
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

  services.fail2ban.enable = true;
  services.timesyncd.enable = true;
  services.upower.enable = true;
  services.logrotate.enable = true;
  services.qdrant = {
    enable = true;
    settings = {
      service = {
        host = "127.0.0.1";
        http_port = 6333;
        grpc_port = 6334;
      };
    };
  };

  # Neo4j for Memento MCP knowledge graph
  services.neo4j = {
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
      dbms.memory.heap.initial_size=512m
      dbms.memory.heap.max_size=2G
      dbms.memory.pagecache.size=1G
      
      # Enable query logging for debugging
      dbms.logs.query.enabled=INFO
      dbms.logs.query.threshold=0
      
      # Vector index settings
      dbms.index.default_schema_provider=native-btree-1.0
    '';
  };
}
