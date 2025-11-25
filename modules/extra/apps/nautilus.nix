{ self, ... }:

{
  flake.nixosModules = self.mkModule "nautilus" {
    path = "apps.nautilus";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.nautilus "The nautilus package";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      let
        defaultApps = config.prefs.defaultApps;
      in
      {
        programs.nautilus-open-any-terminal = lib.mkIf (defaultApps.terminal != null) {
          enable = true;
          terminal = defaultApps.terminal;
        };

        environment.systemPackages = [ cfg.package ];

        xdg.mime.defaultApplications = lib.mkIf (defaultApps.files == "nautilus") {
          "inode/directory" = "org.gnome.Nautilus.desktop";
        };
      };
  };
}
