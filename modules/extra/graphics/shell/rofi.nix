{ self, inputs, ... }:

{
  flake.nixosModules.rofi =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.rofi;
      inherit (lib) mkOpt types;
    in
    {
      options.programs.rofi =
        let
          rasiLiteral =
            types.submodule {
              options = {
                _type = lib.mkOption {
                  type = types.enum [ "literal" ];
                  internal = true;
                };

                value = lib.mkOption {
                  type = types.str;
                  internal = true;
                };
              };
            }
            // {
              description = "Rasi literal string";
            };
          primitive =
            with types;
            (oneOf [
              str
              int
              bool
              rasiLiteral
            ]);
          configType = with types; (either (attrsOf (either primitive (listOf primitive))) str);
          themeType = with types; attrsOf configType;
        in
        with types;
        {
          settings = mkOpt configType {
            location = 0;
            xoffset = 0;
            yoffset = 0;
          } "Configuration settings for rofi.";

          theme = mkOpt (nullOr (oneOf [
            str
            path
            themeType
          ])) null "Theme to use in rofi";

          plugins = mkOpt (listOf package) [ ] "List of rofi plugins to be installed";
        };

      config =
        let
          wrapped =
            (inputs.wrappers.wrapperModules.rofi.apply {
              inherit pkgs;

              inherit (cfg) settings theme plugins;
            }).wrapper;
        in
        {
          programs.rofi = {
            settings = lib.mkDefault {
              display-drun = ">";
              matching = "fuzzy";
            };

            theme =
              with config.prefs.theme.colors;
              let
                lit = lib.rofiLit;

                bg = base;
                bg-alt = surface0;
                fg = text;
                fg-alt = subtext0;
              in
              mkDefault {
                configuration = {
                  font = "${lib.head config.fonts.fontconfig.defaultFonts.monospace} 12";
                  show-icons = true;
                };

                "*" = {
                  border = 0;
                  margin = 0;
                  padding = 0;
                  spacing = 0;

                  width = 750;

                  background-color = lit bg;
                  text-color = lit fg;
                };

                window = {
                  transparency = "real";
                  border-radius = lit "10px";
                  border = lit "1px solid";
                  border-color = lit bg-alt;
                };

                mainbox.children =
                  [
                    "inputbar"
                    "listview"
                    "message"
                  ]
                  |> map lit;

                inputbar = {
                  background-color = lit bg-alt;
                  children =
                    [
                      "prompt"
                      "entry"
                    ]
                    |> map lit;
                };

                message = {
                  background-color = lit bg-alt;
                  padding = lit "8px 8px";
                };
                textbox.background-color = lit bg-alt;

                entry = {
                  background-color = lit "inherit";
                  padding = lit "12px 3px";
                };

                prompt = {
                  background-color = lit "inherit";
                  padding = lit "12px";
                };

                listview.lines = 10;

                element.children =
                  [
                    "element-icon"
                    "element-text"
                  ]
                  |> map lit;

                "element-icon selected, element-text selected" = {
                  background-color = lit surface1;
                };

                element-icon = {
                  padding = lit "10px 10px";
                  size = lit "1em";
                };

                element-text = {
                  padding = lit "10px 0";
                  text-color = lit fg-alt;
                };

                "element-text selected" = {
                  text-color = lit fg;
                };
              };

            plugins = lib.mkDefault [
              pkgs.rofi-calc
            ];
          };

          prefs.desktop-entries =
            let
              powerEntries =
                {
                  "poweroff" = "Shutdown / Power off";
                  "reboot" = "Restart / Reboot";
                  "suspend" = "Sleep / Suspend";
                }
                |> lib.concatMapAttrs (
                  k: v: {
                    "${k}.desktop" = {
                      name = v;
                      exec = "systemctl ${k}";
                      terminal = false;
                    };
                  }
                );
            in
            powerEntries
            // {
              "rofi-fd.desktop" = {
                name = "File Search";
                exec = "rofi-fd";
                icon = "system-search";
                terminal = false;
              };
              "rofimoji.desktop" = {
                name = "Emojis";
                exec = "rofimoji";
                icon = "emoji-people";
                terminal = false;
              };
            };

          environment.systemPackages = with self.packages.${pkgs.stdenv.hostPlatform.system}; [
            wrapped
            rofimoji
            rofi-fd
          ];
        };
    };
}
