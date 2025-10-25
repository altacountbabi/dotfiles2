{
  flake.nixosModules.rofi =
    {
      config,
      pkgs,
      ...
    }:
    {
      config = {
        environment.systemPackages = with pkgs; [ rofi ];

        hjem.users.${config.prefs.user.name} = {
          xdg.data.files."rofi/themes/custom.rasi".text =
            with config.prefs.theme.colors; # css
            ''
              configuration {
                font: "${config.fonts.fontconfig.defaultFonts.monospace |> builtins.head} 12";

                show-icons: true;

                drun {
                  display-name: "Run";
                }

                timeout {
                  action: "kb-cancel";
                  delay: 0;
                }
              }

              * {
                border: 0;
                margin: 0;
                padding: 0;
                spacing: 0;

                width: 750;

                bg: ${background};
                bg-alt: ${surface_container_high};
                fg: ${on_background};
                fg-alt: ${on_surface_variant};

                background-color: @bg;
                text-color: @fg;
              }

              window {
                transparency: "real";
                border-radius: 10px;
              }

              mainbox {
                children: [inputbar, listview];
              }

              inputbar {
                background-color: @bg-alt;
                children: [prompt, entry];
              }

              entry {
                background-color: inherit;
                padding: 12px 3px;
              }

              prompt {
                background-color: inherit;
                padding: 12px;
              }

              listview {
                lines: 8;
              }

              element {
                children: [element-icon, element-text];
              }

              element-icon selected, element-text selected {
                background-color: ${surface_container};
              }

              element-icon {
                padding: 10px 10px;
                size: 1em;
              }

              element-text {
                padding: 10px 0;
                text-color: @fg-alt;
              }

              element-text selected {
                text-color: @fg;
              }
            '';

          xdg.config.files."rofi/config.rasi".text = ''
            configuration {
              location: 0;
              xoffset: 0;
              yoffset: 0;
            }

            @theme "custom"
          '';
        };
      };
    };
}
