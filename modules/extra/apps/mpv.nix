{ self, ... }:

{
  flake.nixosModules = self.mkModule "mpv" {
    path = "apps.mpv";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.mpv "The mpv package";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        environment.systemPackages = [ cfg.package ];

        xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.video == "mpv") {
          "video/mp4=mpv.desktop" = "mpv.desktop";
        };
      };
  };
}
