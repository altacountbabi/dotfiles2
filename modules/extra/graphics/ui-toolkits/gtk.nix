{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".gtk";

    opts =
      { mkOpt, types, ... }:
      {
        bookmarks = mkOpt (types.listOf types.str) [ ] "List of bookmarks (for gtk3)";
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
        inherit (config.prefs.theme) polarity;
      in
      {
        gtk.bookmarks = [
          "~/Documents"
          "~/Music"
          "~/Pictures"
          "~/Videos"
          "~/Downloads"
        ];

        programs.dconf = {
          enable = true;
          profiles.user.databases = [
            {
              settings = with lib.gvariant; {
                "org/gnome/desktop/interface" = {
                  color-scheme = "prefer-${polarity}";
                };
              };
            }
          ];
        };

        environment.etc =
          let
            settings = (pkgs.formats.ini { }).generate "gtk-settings.ini" {
              Settings = {
                gtk-application-prefer-dark-theme = polarity == "dark";
              };
            };
          in
          {
            "xdg/gtk-4.0/settings.ini".source = settings;
            "xdg/gtk-3.0/settings.ini".source = settings;
            "xdg/gtk-3.0/bookmarks".text =
              cfg.bookmarks
              |> map (
                path:
                if (lib.substring 0 1 path) == "~" then
                  config.prefs.user.home + (lib.substring 1 (lib.stringLength path - 1) path)
                else
                  path
              )
              |> map (x: "file://${x}")
              |> lib.concatStringsSep "\n";
          };
      };
  };
}
