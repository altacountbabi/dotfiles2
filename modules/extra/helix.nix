{ inputs, ... }:

{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        helix.languages =
          let
            languages = [
              "nix"
              "nu"
            ];
          in
          mkOpt (types.listOf (types.enum languages)) languages "List of languages to configure in helix";

        helix.preferredEditor =
          mkOpt types.bool true
            "Whether to set the `EDITOR` environment variable to helix";

        helix.package =
          mkOpt types.package inputs.helix.packages.${pkgs.system}.default
            "The package to use for helix";
      };
    };

  flake.nixosModules.helix =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib)
        getExe
        mkIf
        ;

      wrapped =
        (inputs.wrappers.wrapperModules.helix.apply {
          inherit pkgs;
          inherit (config.prefs.helix) package;

          settings = {
            ${if config.themesEnabled then "theme" else null} = "themer";

            editor = {
              bufferline = "multiple";
              continue-comments = false;
              cursorline = true;
              true-color = true;

              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "underline";
              };

              indent-guides = {
                character = "▏";
                render = true;
                skip-levels = 1;
              };

              inline-diagnostics = {
                cursor-line = "hint";
                max-diagnostics = 5;
                other-lines = "error";
                prefix-len = 2;
              };

              lsp = {
                display-inlay-hints = true;
                display-messages = true;
              };
            };

            keys = {
              insert = {
                A-space = "completion";
                C-q = ":q";
                C-s = ":w!";
                C-v = [ ":clipboard-paste-before" ];
                C-w = ":buffer-close!";
              };

              normal = {
                A-S-l = ":pipe awk '{ print length, $0 }' | sort -n | cut -d' ' -f2-";
                A-l = ":pipe awk '{ print length, $0 }' | sort -n -r | cut -d' ' -f2-";
                A-space = "completion";
                A-tab = "goto_previous_buffer";
                C-q = ":q";
                C-s = ":w!";
                C-v = ":clipboard-paste-before";
                C-w = ":buffer-close!";
                P = "paste_after";
                X = "extend_line_above";
                a = "insert_mode";
                esc = [
                  "collapse_selection"
                  "keep_primary_selection"
                ];
                i = "append_mode";
                p = "paste_before";
                ret = "goto_word";
                tab = "goto_next_buffer";
                y = [
                  ":clipboard-yank"
                  "yank"
                ];

                space.E = "file_explorer";
                space.F = "file_picker";
                space.e = "file_explorer_in_current_directory";
                space.f = "file_picker_in_current_directory";
                space.space = "file_picker_in_current_directory";
              };

              select = {
                A-S-l = ":pipe awk '{ print length, $0 }' | sort -n | cut -d' ' -f2-";
                A-l = ":pipe awk '{ print length, $0 }' | sort -n -r | cut -d' ' -f2-";
                A-tab = "goto_previous_buffer";
                X = "extend_line_above";
                tab = "goto_next_buffer";
                y = [
                  ":clipboard-yank"
                  "yank"
                ];
              };
            };
          };

          languages = (
            let
              hasLanguage = language: builtins.any (x: x == language) config.prefs.helix.languages;

              languages = {
                nix = {
                  languages = [
                    {
                      name = "nix";
                      language-servers = [ "nixd" ];
                      formatter.command = pkgs.nixfmt |> getExe;
                      auto-format = true;
                    }
                  ];
                  lsps.nixd = {
                    command = "${pkgs.nixd |> getExe}";
                    args = [ "--inlay-hints=true" ];

                    config.nixd.diagnostic.suppress = [ "sema-extra-with" ];
                    config.nixd.nixpkgs.expr = "import (builtins.getFlake \"/home/${config.prefs.user.name}/conf\")inputs.nixpkgs { }";
                  };
                };
                nu = {
                  languages = [
                    {
                      name = "nu";
                      language-servers = [ "nu" ];
                      formatter.command = "${pkgs.nufmt |> getExe} --stdin";
                      auto-format = true;
                    }
                  ];
                  lsps.nu = {
                    command = "${pkgs.nushell |> getExe} --lsp";
                  };
                };
              };

              enabledLanguages = languages |> lib.filterAttrs (name: _: hasLanguage name);
            in
            {
              language =
                enabledLanguages
                |> builtins.mapAttrs (_name: value: value.languages)
                |> builtins.attrValues
                |> builtins.concatLists;
              language-servers =
                enabledLanguages
                |> builtins.attrValues
                |> builtins.foldl' (acc: value: acc // (value."lsps" or { })) { };
            }
          );

          themes.themer = {
            palette = {
              inherit (config.prefs.theme.colors)
                rosewater
                flamingo
                pink
                mauve
                red
                maroon
                peach
                yellow
                green
                teal
                sky
                sapphire
                blue
                lavender
                text
                subtext1
                subtext0
                overlay2
                overlay1
                overlay0
                surface2
                surface1
                surface0
                base
                mantle
                crust
                ;

              cursorline = "#031716";
              secondary_cursor = "#4a4f4d";
              secondary_cursor_select = "#364557";
              secondary_cursor_normal = "#4a4f4d";
              secondary_cursor_insert = "#32503b";
            };

            "attribute" = "yellow";

            "type" = "yellow";
            "type.enum.variant" = "teal";

            "constructor" = "sapphire";

            "constant" = "peach";
            "constant.character" = "teal";
            "constant.character.escape" = "pink";

            "string" = "green";
            "string.regexp" = "pink";
            "string.special" = "blue";
            "string.special.symbol" = "red";

            "comment" = {
              fg = "overlay2";
              modifiers = [ "italic" ];
            };

            "variable" = "text";
            "variable.parameter" = {
              fg = "maroon";
              modifiers = [ "italic" ];
            };
            "variable.builtin" = "red";
            "variable.other.member" = "blue";

            "label" = "sapphire";

            "punctuation" = "overlay2";
            "punctuation.special" = "sky";

            "keyword" = "mauve";
            "keyword.control.conditional" = {
              fg = "mauve";
              modifiers = [ "italic" ];
            };

            "operator" = "sky";

            "function" = "blue";
            "function.macro" = "mauve";

            "tag" = "blue";

            "namespace" = {
              fg = "yellow";
              modifiers = [ "italic" ];
            };

            "special" = "blue";

            "markup.heading.1" = "red";
            "markup.heading.2" = "peach";
            "markup.heading.3" = "yellow";
            "markup.heading.4" = "green";
            "markup.heading.5" = "sapphire";
            "markup.heading.6" = "lavender";
            "markup.list" = "teal";
            "markup.list.unchecked" = "overlay2";
            "markup.list.checked" = "green";
            "markup.bold" = {
              fg = "red";
              modifiers = [ "bold" ];
            };
            "markup.italic" = {
              fg = "red";
              modifiers = [ "italic" ];
            };
            "markup.link.url" = {
              fg = "blue";
              modifiers = [
                "italic"
                "underlined"
              ];
            };
            "markup.link.text" = "lavender";
            "markup.link.label" = "sapphire";
            "markup.raw" = "green";
            "markup.quote" = "pink";

            "diff.plus" = "green";
            "diff.minus" = "red";
            "diff.delta" = "blue";

            "ui.background" = {
              fg = "text";
              bg = "base";
            };

            "ui.linenr" = {
              fg = "surface1";
            };
            "ui.linenr.selected" = {
              fg = "lavender";
            };

            "ui.statusline" = {
              fg = "subtext1";
              bg = "mantle";
            };
            "ui.statusline.inactive" = {
              fg = "surface2";
              bg = "mantle";
            };
            "ui.statusline.normal" = {
              fg = "base";
              bg = "rosewater";
              modifiers = [ "bold" ];
            };
            "ui.statusline.insert" = {
              fg = "base";
              bg = "green";
              modifiers = [ "bold" ];
            };
            "ui.statusline.select" = {
              fg = "base";
              bg = "lavender";
              modifiers = [ "bold" ];
            };

            "ui.popup" = {
              fg = "text";
              bg = "surface0";
            };
            "ui.window" = {
              fg = "crust";
            };
            "ui.help" = {
              fg = "overlay2";
              bg = "surface0";
            };

            "ui.bufferline" = {
              fg = "subtext0";
              bg = "mantle";
            };
            "ui.bufferline.active" = {
              fg = "mauve";
              bg = "base";
              underline = {
                color = "mauve";
                style = "line";
              };
            };
            "ui.bufferline.background" = {
              bg = "crust";
            };

            "ui.text" = "tex;t";
            "ui.text.focus" = {
              fg = "text";
              bg = "surface0";
              modifiers = [ "bold" ];
            };
            "ui.text.inactive" = {
              fg = "overlay1";
            };
            "ui.text.directory" = {
              fg = "blue";
            };

            "ui.virtual" = "overlay;0";
            "ui.virtual.ruler" = {
              bg = "surface0";
            };
            "ui.virtual.indent-guide" = "surface;0";
            "ui.virtual.inlay-hint" = {
              fg = "surface1";
              bg = "mantle";
            };
            "ui.virtual.jump-label" = {
              fg = "rosewater";
              modifiers = [ "bold" ];
            };

            "ui.selection" = {
              bg = "surface1";
            };

            "ui.cursor" = {
              fg = "base";
              bg = "secondary_cursor";
            };
            "ui.cursor.primary" = {
              fg = "base";
              bg = "rosewater";
            };
            "ui.cursor.match" = {
              fg = "peach";
              modifiers = [ "bold" ];
            };

            "ui.cursor.primary.normal" = {
              fg = "base";
              bg = "rosewater";
            };
            "ui.cursor.primary.insert" = {
              fg = "base";
              bg = "green";
            };
            "ui.cursor.primary.select" = {
              fg = "base";
              bg = "lavender";
            };

            "ui.cursor.normal" = {
              fg = "base";
              bg = "secondary_cursor_normal";
            };
            "ui.cursor.insert" = {
              fg = "base";
              bg = "secondary_cursor_insert";
            };
            "ui.cursor.select" = {
              fg = "base";
              bg = "secondary_cursor_select";
            };

            "ui.cursorline.primary" = {
              bg = "cursorline";
            };

            "ui.highlight" = {
              bg = "surface1";
              modifiers = [ "bold" ];
            };

            "ui.menu" = {
              fg = "overlay2";
              bg = "surface0";
            };
            "ui.menu.selected" = {
              fg = "text";
              bg = "surface1";
              modifiers = [ "bold" ];
            };

            "diagnostic.error" = {
              underline = {
                color = "red";
                style = "curl";
              };
            };
            "diagnostic.warning" = {
              underline = {
                color = "yellow";
                style = "curl";
              };
            };
            "diagnostic.info" = {
              underline = {
                color = "sky";
                style = "curl";
              };
            };
            "diagnostic.hint" = {
              underline = {
                color = "teal";
                style = "curl";
              };
            };
            "diagnostic.unnecessary" = {
              modifiers = [ "dim" ];
            };

            error = "red";
            warning = "yellow";
            info = "sky";
            hint = "teal";
          };
        }).wrapper;
    in
    {
      environment.systemPackages = [
        wrapped
      ];

      environment.sessionVariables = {
        EDITOR = mkIf config.prefs.helix.preferredEditor "hx";
      };

      environment.shellAliases.v = "hx";

      prefs.nushell.excludedAliases = [ "v" ];
      prefs.nushell.extraConfig = [
        # nushell
        ''
          def v --wrapped [...args] {
            if ($args | is-empty) {
              hx .
            } else {
              hx ...$args
            }
          }
        ''
      ];
    };
}
