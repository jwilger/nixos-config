{ pkgs, lib, ... }:
let
  inherit (lib) getExe getExe';

  bashLs = getExe pkgs.bash-language-server;
  basedPyright = getExe pkgs.basedpyright;
  black = getExe pkgs.black;
  clangd = getExe' pkgs.clang-tools "clangd";
  clangFormat = getExe' pkgs.clang-tools "clang-format";
  cmakeFormat = getExe pkgs.cmake-format;
  dockerComposeLs = getExe pkgs.docker-compose-language-service;
  dockerfileLs = getExe pkgs.dockerfile-language-server;
  elixirLs = getExe pkgs.elixir-ls;
  elp = getExe' pkgs.erlang-language-platform "elp";
  debugpyPython = pkgs.python312.withPackages (ps: [ ps.debugpy ]);
  fourmolu = getExe pkgs.fourmolu;
  gleamCmd = getExe pkgs.gleam;
  gofmt = getExe' pkgs.go "gofmt";
  gopls = getExe pkgs.gopls;
  golangciLs = getExe pkgs.golangci-lint-langserver;
  graphqlLsp = getExe pkgs.graphql-language-service-cli;
  haskellWrapper = getExe' pkgs.haskell-language-server "haskell-language-server-wrapper";
  jqLsp = getExe pkgs.jq-lsp;
  latexindent = getExe pkgs.texlivePackages.latexindent;
  luaLs = getExe pkgs.lua-language-server;
  marksman = getExe pkgs.marksman;
  markdownOxide = getExe pkgs.markdown-oxide;
  nixfmt = getExe pkgs.nixfmt-rfc-style;
  nil = getExe pkgs.nil;
  prettier = getExe pkgs.nodePackages.prettier;
  prismaLs = getExe pkgs.prisma-language-server;
  protols = getExe pkgs.protols;
  rustAnalyzer = getExe pkgs.rust-analyzer;
  rustfmt = getExe pkgs.rustfmt;
  shfmt = getExe pkgs.shfmt;
  sqls = getExe pkgs.sqls;
  stylua = getExe pkgs.stylua;
  taplo = getExe pkgs.taplo;
  terraformFmt = getExe pkgs.terraform;
  terraformLs = getExe pkgs.terraform-ls;
  texlab = getExe pkgs.texlab;
  tsLs = getExe pkgs.typescript-language-server;
  jsDebug = getExe pkgs.vscode-js-debug;
  jsDebugger = {
    name = "js-debug";
    transport = "tcp";
    command = jsDebug;
    "port-arg" = "{port}";
    templates = [
      {
        name = "launch";
        request = "launch";
        args = {
          type = "pwa-node";
          program = "{file}";
          cwd = "{workspace}";
        };
      }
    ];
  };
  vscodeCssLs = getExe' pkgs.vscode-langservers-extracted "vscode-css-language-server";
  vscodeHtmlLs = getExe' pkgs.vscode-langservers-extracted "vscode-html-language-server";
  vscodeJsonLs = getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server";
  yamlLs = getExe pkgs.yaml-language-server;
  yamlfmt = getExe pkgs.yamlfmt;
  zls = getExe pkgs.zls;
in
{
  programs.helix = {
    enable = true;
    settings = {
      editor = {
        indent-guides = {
          render = true;
          character = "┊";
        };
        end-of-line-diagnostics = "hint";
        inline-diagnostics = {
          cursor-line = "warning";
        };
      };
      keys = {
        normal = {
          C-s = ":w";
          g = { a = "code_action"; };
          tab = "move_parent_node_end";
          S-tab = "move_parent_node_start";
        };
        insert = {
          j = { k = "normal_mode"; };
          S-tab = "move_parent_node_start";
        };
        select = {
          tab = "extend_parent_node_end";
          S-tab = "extend_parent_node_start";
        };
      };
    };

    languages = {
      language-server = {
        awk-language-server.command = getExe pkgs.awk-language-server;

        bash-language-server = {
          command = bashLs;
          args = [ "start" ];
        };

        clangd.command = clangd;

        codeql = {
          command = getExe pkgs.codeql;
          args = [ "execute" "language-server" "--stdio" ];
        };

        docker-compose-langserver.command = dockerComposeLs;

        docker-langserver = {
          command = dockerfileLs;
          args = [ "--stdio" ];
        };

        elixir-ls.command = elixirLs;

        elp.command = elp;

        gleam = {
          command = gleamCmd;
          args = [ "lsp" ];
        };

        gopls.command = gopls;

        golangci-lint-langserver.command = golangciLs;

        graphql-lsp = {
          command = graphqlLsp;
          args = [ "server" "-m" "stream" ];
        };

        haskell-language-server = {
          command = haskellWrapper;
          args = [ "--lsp" ];
        };

        jq-lsp.command = jqLsp;

        lua-language-server.command = luaLs;

        marksman.command = marksman;

        markdown-oxide.command = markdownOxide;

        neocmakelsp.command = getExe pkgs.neocmakelsp;

        nil.command = nil;

        prisma-language-server.command = prismaLs;

        protols.command = protols;

        ruby-lsp.command = getExe pkgs.rubyPackages.ruby-lsp;

        rust-analyzer.command = rustAnalyzer;

        sqls.command = sqls;

        taplo.command = taplo;

        terraform-ls.command = terraformLs;

        texlab.command = texlab;

        typescript-language-server = {
          command = tsLs;
          args = [ "--stdio" ];
        };

        vscode-css-language-server = {
          command = vscodeCssLs;
          args = [ "--stdio" ];
        };

        vscode-html-language-server = {
          command = vscodeHtmlLs;
          args = [ "--stdio" ];
        };

        vscode-json-language-server = {
          command = vscodeJsonLs;
          args = [ "--stdio" ];
        };

        yaml-language-server = {
          command = yamlLs;
          args = [ "--stdio" ];
        };

        zls.command = zls;

        basedpyright = {
          command = basedPyright;
          args = [ "--stdio" ];
        };
      };

      language = [
        {
          name = "awk";
          scope = "source.awk";
          language-servers = [ "awk-language-server" ];
        }
        {
          name = "bash";
          scope = "source.bash";
          language-servers = [ "bash-language-server" ];
          formatter = {
            command = shfmt;
            args = [ "-i" "2" "-bn" "-ci" "-sr" ];
          };
        }
        {
          name = "c";
          scope = "source.c";
          language-servers = [ "clangd" ];
          formatter.command = clangFormat;
          debugger = {
            name = "lldb-vscode";
            transport = "stdio";
            command = getExe' pkgs.lldb "lldb-vscode";
            templates = [
              {
                name = "launch";
                request = "launch";
                args = {
                  program = "{program}";
                  cwd = "{workspace}";
                };
              }
            ];
          };
        }
        {
          name = "cmake";
          scope = "source.cmake";
          language-servers = [ "neocmakelsp" ];
          formatter = {
            command = cmakeFormat;
            args = [ "-" ];
          };
        }
        {
          name = "codeql";
          scope = "source.ql";
          language-servers = [ "codeql" ];
        }
        {
          name = "cpp";
          scope = "source.cpp";
          language-servers = [ "clangd" ];
          formatter.command = clangFormat;
          debugger = {
            name = "lldb-vscode";
            transport = "stdio";
            command = getExe' pkgs.lldb "lldb-vscode";
            templates = [
              {
                name = "launch";
                request = "launch";
                args = {
                  program = "{program}";
                  cwd = "{workspace}";
                };
              }
            ];
          };
        }
        {
          name = "css";
          scope = "source.css";
          language-servers = [ "vscode-css-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "csv";
          scope = "source.csv";
        }
        {
          name = "diff";
          scope = "source.diff";
        }
        {
          name = "docker-compose";
          scope = "source.yaml.docker-compose";
          language-servers = [ "docker-compose-langserver" "yaml-language-server" ];
        }
        {
          name = "dockerfile";
          scope = "source.dockerfile";
          language-servers = [ "docker-langserver" ];
        }
        {
          name = "eex";
          scope = "source.eex";
          language-servers = [ "elixir-ls" ];
          formatter = {
            command = getExe' pkgs.elixir "mix";
            args = [ "format" "-" ];
          };
        }
        {
          name = "elixir";
          scope = "source.elixir";
          language-servers = [ "elixir-ls" ];
          formatter = {
            command = getExe' pkgs.elixir "mix";
            args = [ "format" "-" ];
          };
        }
        {
          name = "env";
          scope = "source.env";
        }
        {
          name = "erb";
          scope = "text.html.erb";
        }
        {
          name = "erlang";
          scope = "source.erlang";
          language-servers = [ "elp" ];
        }
        {
          name = "gherkin";
          scope = "source.feature";
        }
        {
          name = "gleam";
          scope = "source.gleam";
          language-servers = [ "gleam" ];
          formatter = {
            command = gleamCmd;
            args = [ "format" "--stdin" ];
          };
        }
        {
          name = "go";
          scope = "source.go";
          language-servers = [ "gopls" "golangci-lint-langserver" ];
          formatter.command = gofmt;
          debugger = {
            name = "dlv";
            transport = "tcp";
            command = getExe pkgs.delve;
            args = [ "dap" "-l" "127.0.0.1:{port}" ];
            templates = [
              {
                name = "launch";
                request = "launch";
                args = {
                  program = "{program}";
                  cwd = "{workspace}";
                };
              }
            ];
          };
        }
        {
          name = "graphql";
          scope = "source.graphql";
          language-servers = [ "graphql-lsp" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "haskell";
          scope = "source.haskell";
          language-servers = [ "haskell-language-server" ];
          formatter.command = fourmolu;
        }
        {
          name = "heex";
          scope = "source.heex";
          language-servers = [ "elixir-ls" ];
          formatter = {
            command = getExe' pkgs.elixir "mix";
            args = [ "format" "-" ];
          };
        }
        {
          name = "html";
          scope = "text.html.basic";
          language-servers = [ "vscode-html-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "iex";
          scope = "source.iex";
        }
        {
          name = "javascript";
          scope = "source.js";
          language-servers = [ "typescript-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
          debugger = jsDebugger;
        }
        {
          name = "jq";
          scope = "source.jq";
          language-servers = [ "jq-lsp" ];
          formatter = {
            command = getExe pkgs.jq;
            args = [ "." ];
          };
        }
        {
          name = "json";
          scope = "source.json";
          language-servers = [ "vscode-json-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "jsonc";
          scope = "source.json";
          language-servers = [ "vscode-json-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "kdl";
          scope = "source.kdl";
        }
        {
          name = "latex";
          scope = "source.tex";
          language-servers = [ "texlab" ];
          formatter = {
            command = latexindent;
            args = [ "-" ];
          };
        }
        {
          name = "lua";
          scope = "source.lua";
          language-servers = [ "lua-language-server" ];
          formatter = {
            command = stylua;
            args = [ "--stdin-filepath" "{buffer_path}" "-" ];
          };
        }
        {
          name = "make";
          scope = "source.make";
        }
        {
          name = "markdown";
          scope = "source.md";
          language-servers = [ "marksman" "markdown-oxide" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "markdown-rustdoc";
          scope = "source.markdown-rustdoc";
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "markdown.inline";
          scope = "source.markdown.inline";
        }
        {
          name = "mermaid";
          scope = "source.mermaid";
        }
        {
          name = "nix";
          scope = "source.nix";
          language-servers = [ "nil" ];
          formatter = {
            command = nixfmt;
            args = [ "-" ];
          };
        }
        {
          name = "prisma";
          scope = "source.prisma";
          language-servers = [ "prisma-language-server" ];
        }
        {
          name = "protobuf";
          scope = "source.proto";
          language-servers = [ "protols" ];
        }
        {
          name = "python";
          scope = "source.python";
          language-servers = [ "basedpyright" ];
          formatter = {
            command = black;
            args = [ "-q" "-" ];
          };
          debugger = {
            name = "debugpy";
            transport = "stdio";
            command = getExe' debugpyPython "python";
            args = [ "-m" "debugpy.adapter" ];
            templates = [
              {
                name = "launch";
                request = "launch";
                args = {
                  program = "{file}";
                  cwd = "{workspace}";
                };
              }
            ];
          };
        }
        {
          name = "ruby";
          scope = "source.ruby";
          language-servers = [ "ruby-lsp" ];
          formatter = {
            command = getExe' pkgs.rubyPackages.syntax_tree "stree";
            args = [ "format" "--stdin" ];
          };
          debugger = {
            name = "rdbg";
            transport = "tcp";
            command = getExe' pkgs.ruby "rdbg";
            args = [ "--open" "--port" "{port}" "--command" "--" "{program}" "{args}" ];
            templates = [
              {
                name = "launch";
                request = "launch";
                args = {
                  program = "{program}";
                  cwd = "{workspace}";
                };
              }
            ];
          };
        }
        {
          name = "rust";
          scope = "source.rust";
          language-servers = [ "rust-analyzer" ];
          formatter.command = rustfmt;
          debugger = {
            name = "lldb-vscode";
            transport = "stdio";
            command = getExe' pkgs.lldb "lldb-vscode";
            templates = [
              {
                name = "launch";
                request = "launch";
                args = {
                  program = "{program}";
                  cwd = "{workspace}";
                };
              }
            ];
          };
        }
        {
          name = "scss";
          scope = "source.scss";
          language-servers = [ "vscode-css-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "sql";
          scope = "source.sql";
          language-servers = [ "sqls" ];
          formatter = {
            command = getExe pkgs.nodePackages.sql-formatter;
            args = [ ];
          };
        }
        {
          name = "terraform";
          scope = "source.terraform";
          file-types = [ "tf" "tfvars" ];
          language-servers = [ "terraform-ls" ];
          formatter = {
            command = terraformFmt;
            args = [ "fmt" "-" ];
          };
        }
        {
          name = "toml";
          scope = "source.toml";
          language-servers = [ "taplo" ];
          formatter = {
            command = taplo;
            args = [ "format" "--stdin-filepath" "{buffer_path}" ];
          };
        }
        {
          name = "tsx";
          scope = "source.tsx";
          language-servers = [ "typescript-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
          debugger = jsDebugger;
        }
        {
          name = "jsx";
          scope = "source.jsx";
          language-servers = [ "typescript-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
          debugger = jsDebugger;
        }
        {
          name = "typescript";
          scope = "source.ts";
          language-servers = [ "typescript-language-server" ];
          formatter = {
            command = prettier;
            args = [ "--stdin-filepath" "{buffer_path}" ];
          };
          debugger = jsDebugger;
        }
        {
          name = "yaml";
          scope = "source.yaml";
          language-servers = [ "yaml-language-server" ];
          formatter = {
            command = yamlfmt;
            args = [ "-" ];
          };
        }
        {
          name = "zig";
          scope = "source.zig";
          language-servers = [ "zls" ];
          formatter = {
            command = getExe pkgs.zig;
            args = [ "fmt" "--stdin" ];
          };
        }
      ];
    };
  };
}
