{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "wezterm" {
    path = "apps.wezterm";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.wezterm "The wezterm package";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        wrapped =
          (self.wrapperModules.wezterm.apply {
            inherit pkgs;
            package = lib.mkForce cfg.package;

            "wezterm.lua".content =
              let
                theme = (pkgs.formats.toml { }).generate "wezterm-theme" (
                  with config.prefs.theme.colors;
                  let
                    isDark = config.prefs.theme.polarity == "dark";
                  in
                  {
                    colors = {
                      foreground = text;
                      background = base;

                      cursor_fg = if isDark then crust else base;
                      cursor_bg = rosewater;
                      cursor_border = rosewater;

                      selection_fg = text;
                      selection_bg = surface2;

                      scrollbar_thumb = surface2;

                      split = overlay0;

                      ansi = [
                        (if isDark then surface1 else subtext1)
                        red
                        green
                        yellow
                        blue
                        pink
                        teal
                        (if isDark then subtext1 else surface2)
                      ];

                      brights = [
                        (if isDark then surface2 else subtext0)
                        red
                        green
                        yellow
                        blue
                        pink
                        teal
                        (if isDark then subtext0 else surface1)
                      ];

                      indexed = {
                        "16" = peach;
                        "17" = rosewater;
                      };

                      compose_cursor = flamingo;

                      tab_bar = {
                        background = crust;
                        active_tab = {
                          bg_color = accent;
                          fg_color = crust;
                        };
                        inactive_tab = {
                          bg_color = mantle;
                          fg_color = text;
                        };
                        inactive_tab_hover = {
                          bg_color = base;
                          fg_color = text;
                        };
                        new_tab = {
                          bg_color = surface0;
                          fg_color = text;
                        };
                        new_tab_hover = {
                          bg_color = surface1;
                          fg_color = text;
                        };
                        inactive_tab_edge = surface0;
                      };

                      visual_bell = surface0;
                    };

                    metadata = {
                      aliases = [ ];
                      author = "alatcountbabi (https://github.com/alatcountbabi)";
                      name = "Themer";
                      origin_url = "https://github.com/alatcountbabi/dotfiles2";
                      wezterm_version = "20220807-113146-c2fee766";
                    };
                  }
                );
                themeDir = pkgs.runCommand "wezterm-theme-dir" { inherit theme; } ''
                  mkdir -p $out
                  cp "$theme" "$out/themer.toml"
                '';
              in
              # lua
              ''
                local wezterm = require 'wezterm'
                local config = wezterm.config_builder()

                -- Colors
                config.color_scheme = 'Themer'
                config.color_scheme_dirs = { '${themeDir}' }

                -- Keybinds
                local act = wezterm.action
                config.keys = {
                  {
                    key = 'W',
                    mods = 'ALT',
                    action = act.SpawnTab 'DefaultDomain'
                  },
                  {
                    key = 'q',
                    mods = 'ALT',
                    action = act.CloseCurrentTab { confirm = false }
                  },
                }

                -- Font
                config.cell_width = 0.9
                config.line_height = 1.2
                config.font_size = 13
                config.font = wezterm.font_with_fallback {
                  { family = '${
                    config.fonts.fontconfig.defaultFonts.monospace |> builtins.head
                  }', weight = 'Medium' },
                  'Noto Color Emoji',
                  'Symbols Nerd Font Mono',
                }

                -- Tab bar
                config.tab_bar_at_bottom = true
                config.hide_tab_bar_if_only_one_tab = true
                config.show_new_tab_button_in_tab_bar = false
                config.use_fancy_tab_bar = false

                -- Cursor
                config.default_cursor_style = 'SteadyBar'

                -- Window
                config.window_padding = {
                  left = 12,
                  right = 12,
                  top = 12,
                  bottom = 12,
                }
                config.window_close_confirmation = 'NeverPrompt'
                config.window_decorations = 'NONE'
                config.initial_cols = 189
                config.initial_rows = 40

                -- Rendering
                config.front_end = "OpenGL"
                config.enable_wayland = true

                return config
              '';
          }).wrapper;
      in
      {
        environment.systemPackages = [ wrapped ];

        xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.terminal == "wezterm") {
          "x-scheme-handler/terminal" = "wezterm.desktop";
        };

        prefs.autostart = [ "${wrapped}/bin/wezterm-mux-server" ];
      };
  };

  flake.wrapperModules.wezterm = inputs.wrappers.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      _class = "wrapper";
      options = {
        "wezterm.lua" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.content = "";
        };
      };

      config = {
        flagSeparator = "=";
        flags."--config-file" = toString config."wezterm.lua".path;

        package = config.pkgs.wezterm;
      };
    }
  );
}
