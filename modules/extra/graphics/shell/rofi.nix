{ self, inputs, ... }:

{
  # TODO: Add emoji plugin and file search plugin

  flake.nixosModules.rofi =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.rofi;
      inherit (lib)
        mkDefault
        mkForce
        mkOpt
        types
        ;
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

          powerDesktopEntries =
            let
              mkEntry =
                id: name:
                (pkgs.formats.ini { }).generate "${id}.desktop" {
                  "Desktop Entry" = {
                    Exec = "systemctl ${id}";
                    Name = name;
                    Terminal = false;
                    Type = "Application";
                    Version = "1.4";
                  };
                };
              poweroff = mkEntry "poweroff" "Shutdown / Power off";
              reboot = mkEntry "reboot" "Restart / Reboot";
              suspend = mkEntry "suspend" "Sleep / Suspend";
            in
            pkgs.runCommand "write-desktop-entry" { inherit poweroff reboot suspend; } ''
              mkdir -p $out/share/applications
              cp "$poweroff" "$out/share/applications/poweroff.desktop"
              cp "$reboot" "$out/share/applications/reboot.desktop"
              cp "$suspend" "$out/share/applications/suspend.desktop"
            '';
        in
        {
          programs.rofi = {
            settings = mkDefault {
              display-drun = "Run";
            };
            theme =
              let
                lit = lib.rofiLit;
              in
              with config.prefs.theme.colors;
              mkDefault {
                configuration = {
                  font = "${config.fonts.fontconfig.defaultFonts.monospace |> builtins.head} 12";
                  show-icons = true;
                };

                "*" = {
                  border = 0;
                  margin = 0;
                  padding = 0;
                  spacing = 0;

                  width = 750;

                  bg = lit base;
                  bg-alt = lit surface0;
                  fg = lit text;
                  fg-alt = lit subtext0;

                  background-color = lit "@bg";
                  text-color = lit "@fg";
                };

                window = {
                  transparency = "real";
                  border-radius = lit "10px";
                };

                mainbox.children =
                  [
                    "inputbar"
                    "listview"
                  ]
                  |> map lit;

                inputbar = {
                  background-color = lit "@bg-alt";
                  children =
                    [
                      "prompt"
                      "entry"
                    ]
                    |> map lit;
                };

                entry = {
                  background-color = lit "inherit";
                  padding = lit "12px 3px";
                };

                prompt = {
                  background-color = lit "inherit";
                  padding = lit "12px";
                };

                listview.lines = 8;

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
                  text-color = lit "@fg-alt";
                };

                "element-text selected" = {
                  text-color = lit "@fg";
                };
              };

            plugins = mkDefault [
              pkgs.rofi-calc
            ];
          };

          environment.systemPackages = [
            wrapped
            powerDesktopEntries
            self.packages.${pkgs.stdenv.hostPlatform.system}.rofimoji
          ];
        };
    };
}
