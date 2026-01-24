{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.loupe";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable loupe";
        package = mkOpt types.package pkgs.loupe "Loupe package";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          environment.systemPackages = [ cfg.package ];

          xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.image == "loupe") {
            "image/png" = "org.gnome.Loupe.desktop";
            "image/bmp" = "org.gnome.Loupe.desktop";
            "image/jpeg" = "org.gnome.Loupe.desktop";
          };
        };
      };
  };
}
