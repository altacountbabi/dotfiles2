{ self, ... }:

{
  flake.nixosModules = self.mkModule "gtk" {
    path = "gtk";

    opts =
      { mkOpt, types, ... }:
      {
        bookmarks = mkOpt (types.listOf types.str) [ ] "List of boomarks (for gtk3)";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        programs.dconf = {
          enable = true;
          profiles.user.databases = [
            {
              settings = with lib.gvariant; {
                "org/gnome/desktop/interface" = {
                  color-scheme = "prefer-${config.prefs.theme.polarity}";
                };
              };
            }
          ];
        };

        environment.etc =
          let
            gtk-application-prefer-dark-theme = config.prefs.theme.polarity == "dark";
          in
          {
            "xdg/gtk-4.0/settings.ini".source = (pkgs.formats.ini { }).generate "gtk4-settings.ini" {
              Settings = {
                inherit gtk-application-prefer-dark-theme;
              };
            };
            "xdg/gtk-3.0/bookmarks".text =
              (
                cfg.bookmarks
                ++ [
                  "~/Documents"
                  "~/Music"
                  "~/Pictures"
                  "~/Videos"
                  "~/Downloads"
                ]
              )
              |> map (
                path:
                let
                  inherit (builtins) substring stringLength;
                in
                if substring 0 1 path == "~" then
                  "/home/${config.prefs.user.name}" + substring 1 (stringLength path - 1) path
                else
                  path
              )
              |> builtins.concatStringsSep "\n";
            "xdg/gtk-3.0/settings.ini".source = (pkgs.formats.ini { }).generate "gtk3-settings.ini" {
              Settings = {
                inherit gtk-application-prefer-dark-theme;
              };
            };
          };
      };
  };
}
