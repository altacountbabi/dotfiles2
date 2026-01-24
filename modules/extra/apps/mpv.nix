{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.mpv";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable mpv";
        package = mkOpt types.package pkgs.mpv "Mpv package";
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

          xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.video == "mpv") {
            "video/mp4" = "mpv.desktop";
          };
        };
      };
  };
}
