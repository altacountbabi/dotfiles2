{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.nautilus";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable nautilus";
        package = mkOpt types.package pkgs.nautilus "Nautilus package";
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
        config = lib.mkIf cfg.enable {
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
  };
}
