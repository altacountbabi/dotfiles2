{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.firefox-pwa";

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
        package = mkOpt types.package pkgs.firefox-bin "Firefox package";

        websites = mkOpt (
          with types;
          attrsOf (submodule {
            options = {
              name = mkOpt str "" "Name of website";
              icon = mkOpt (either str path) "firefox" "Icon of the website";
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
                  user_pref("${k}", ${
                    if lib.isString v then
                      "\"${v}\""
                    else if lib.isBool v then
                      lib.boolToString v
                    else
                      toString v
                  });
                ''
              )
              |> lib.concatStringsSep "\n"
              |> pkgs.writeText "user.js";

            mergedExtensions = pkgs.buildEnv {
              name = "firefox-extensions-${name}";
              paths = extensions;
            };
          in
          pkgs.linkFarm "firefox-profile-${name}" [
            {
              name = "user.js";
              path = userJs;
            }
            {
              name = "extensions";
              path = "${mergedExtensions}/share/mozilla/extensions";
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

              firefoxWrapped = inputs.wrappers.lib.wrapPackage {
                inherit pkgs;
                package = cfg.package;

                env.MOZ_LEGACY_PROFILES = "1";
                flags = {
                  "--kiosk" = v.url;
                };
              };

              runtimeWrapper = pkgs.writeShellScriptBin k ''
                set -eu

                PROFILE_SRC="${profile}"
                PROFILE_DST="$XDG_STATE_HOME/firefox-pwa/${k}"

                if [ ! -d "$PROFILE_DST" ]; then
                  mkdir -p "$PROFILE_DST"
                  cp -rT "$PROFILE_SRC" "$PROFILE_DST"
                  chmod -R u+w "$PROFILE_DST"
                fi

                exec ${lib.getExe firefoxWrapped} \
                  --name "${k}" \
                  --new-instance --no-remote \
                  --profile "$PROFILE_DST" \
                  --kiosk \
                  "$@"
              '';
            in
            runtimeWrapper
          );

      in
      {
        config = lib.mkIf cfg.enable {
          environment.systemPackages = lib.attrValues wrappers;

          prefs.desktop-entries =
            cfg.websites
            |> lib.concatMapAttrs (
              k: v: {
                "firefox-pwa-${k}.desktop" = {
                  inherit (v) name icon;
                  exec = lib.getExe wrappers.${k};
                  terminal = false;
                };
              }
            );
        };
      };
  };
}
