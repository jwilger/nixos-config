{ pkgs, lib, ... }:

{
  programs.helix = {
    enable = true;
    settings.theme = "catppuccin_mocha";
    # Keep defaults, but add language entries to wire formatters/LSPs with correct placeholders.
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
      language = [
        {
          name = "markdown";
          scope = "source.md";
          file-types = [ "md" "markdown" "mdx" "mkd" "mkdn" "mdwn" "mdown" "markdn" "mdtxt" "mdtext" ];
          roots = [ ".marksman.toml" ];
          formatter = {
            command = lib.getExe pkgs.nodePackages.prettier;
            args = [
              "--stdin-filepath"
              "%{buffer_name}"
              "--parser"
              "markdown"
              "--prose-wrap"
              "always"
              "--print-width"
              "80"
            ];
          };
        }
        {
          name = "markdown-rustdoc";
          scope = "source.markdown-rustdoc";
          formatter = {
            command = lib.getExe pkgs.nodePackages.prettier;
            args = [
              "--stdin-filepath"
              "%{buffer_name}"
              "--parser"
              "markdown"
              "--prose-wrap"
              "always"
              "--print-width"
              "80"
            ];
          };
        }
      ];
    };
  };

}
