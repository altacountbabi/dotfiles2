{
  flake.nixosModules.wezterm =
    {
      config,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        wezterm
      ];

      prefs.autostart.wezterm-mux-server = "${pkgs.wezterm}/bin/wezterm-mux-server";

      hjem.users.${config.prefs.user.name} = {
        xdg.config.files."wezterm/wezterm.lua".text = # lua
          ''
            local wezterm = require 'wezterm'
            local config = wezterm.config_builder()

            -- Colors
            config.color_scheme = 'Themer'
            config.color_scheme_dirs = { '~/.config/wezterm/colors' }

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

        xdg.config.files."wezterm/colors/themer.toml".text = # toml
          ''
            [colors]
            ansi = [
              "#1d3535",
              "#f38ba8",
              "#a6e3a1",
              "#f9e2af",
              "#89b4fa",
              "#f5c2e7",
              "#94e2d5",
              "#9ebab9",
            ]
            background = "#001110"
            brights = [
              "#314a49",
              "#f38ba8",
              "#a6e3a1",
              "#f9e2af",
              "#89b4fa",
              "#f5c2e7",
              "#94e2d5",
              "#87a2a1",
            ]
            compose_cursor = "#f2cdcd"
            cursor_bg = "#f5e0dc"
            cursor_border = "#f5e0dc"
            cursor_fg = "#000404"
            foreground = "#b6d2d2"
            scrollbar_thumb = "#314a49"
            selection_bg = "#314a49"
            selection_fg = "#b6d2d2"
            split = "#455f5e"
            visual_bell = "#092322"

            [colors.indexed]
            16 = "#fab387"
            17 = "#f5e0dc"

            [colors.tab_bar]
            background = "#000404"
            inactive_tab_edge = "#092322"

            [colors.tab_bar.active_tab]
            bg_color = "#259038"
            fg_color = "#000404"
            intensity = "Normal"
            italic = false
            strikethrough = false
            underline = "None"

            [colors.tab_bar.inactive_tab]
            bg_color = "#010606"
            fg_color = "#b6d2d2"
            intensity = "Normal"
            italic = false
            strikethrough = false
            underline = "None"

            [colors.tab_bar.inactive_tab_hover]
            bg_color = "#001110"
            fg_color = "#b6d2d2"
            intensity = "Normal"
            italic = false
            strikethrough = false
            underline = "None"

            [colors.tab_bar.new_tab]
            bg_color = "#092322"
            fg_color = "#b6d2d2"
            intensity = "Normal"
            italic = false
            strikethrough = false
            underline = "None"

            [colors.tab_bar.new_tab_hover]
            bg_color = "#1d3535"
            fg_color = "#b6d2d2"
            intensity = "Normal"
            italic = false
            strikethrough = false
            underline = "None"

            [metadata]
            aliases = []
            author = "alatcountbabi (https://github.com/alatcountbabi)"
            name = "Themer"
            origin_url = "https://github.com/alatcountbabi/themer"
            wezterm_version = "20220807-113146-c2fee766"
          '';
      };
    };
}
