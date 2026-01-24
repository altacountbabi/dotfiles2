{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.web-kiosk";

    opts =
      {
        pkgs,
        lib,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable web kiosk";
        package = mkOpt types.package pkgs.firefox-bin "Firefox package to use";

        websites = mkOpt (
          with types;
          attrsOf (submodule {
            options = {
              name = mkOpt str "Name of website";
              url = mkOpt str "" "Website URL";
              extensions = mkOpt (listOf package) [ ] "List of .xpi extensions to add to profile" // {
                example = lib.literalExpression ''
                  with pkgs.nur.repos.rycee.firefox-addons; [
                    ublock-origin
                  ]
                '';
              };
              settings = mkOpt (attrsOf types.anything) { } "Firefox profile settings";
            };
          })
        ) { } "List of websites to make a firefox kiosk profile of";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        mkFirefoxProfile =
          {
            name,
            settings ? { },
            extensions ? [ ],
          }:
          let
            userJs =
              settings
              |> lib.mapAttrsToList (
                k: v: ''
                  user_pref("${k}", ${if lib.isString v then "\"${v}\"" else lib.boolToString v})
                ''
              )
              |> lib.concatStringsSep "\n"
              |> pkgs.writeText "user.js";

            extensionsDir =
              extensions
              |> lib.imap1 (
                i: ext: {
                  name = "extension${i}.xpi";
                  path = ext;
                }
              )
              |> pkgs.linkFarm "firefox-extensions-${name}";
          in
          pkgs.linkFarm "firefox-profile-${name}" [
            {
              name = "user.js";
              path = userJs;
            }
            {
              name = "extensions";
              path = extensionsDir;
            }
          ];

        wrappers =
          cfg.websites
          |> lib.mapAttrs (
            k: v:
            let
              profile = mkFirefoxProfile {
                name = k;
                inherit (v) settings extensions;
              };
            in
            inputs.wrappers.lib.wrapPackage {
              inherit pkgs;
              package = cfg.package;

              env.MOZ_LEGACY_PROFILES = "1";
              flags = {
                "--profile" = profile;
                "--kiosk" = v.url;
              };
            }
          );
      in
      {
        config = lib.mkIf cfg.enable {
          environment.systemPackages = lib.attrValues wrappers;

          prefs.desktop-entries =
            cfg.websites
            |> lib.mapAttrsToList (
              k: v: {
                "web-kiosk-${k}.desktop" = {
                  name = v.name;
                  exec = lib.getExe wrappers.${k};
                  icon = "firefox";
                  terminal = false;
                };
              }
            )
            |> lib.listToAttrs;
        };
      };
  };
}
