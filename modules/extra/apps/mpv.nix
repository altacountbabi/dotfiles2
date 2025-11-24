{
  flake.nixosModules.base =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        apps.mpv = {
          package = mkOpt types.package pkgs.mpv "The mpv package";
        };
      };
    };

  flake.nixosModules.mpv =
    {
      config,
      lib,
      ...
    }:
    {
      environment.systemPackages = [ config.prefs.apps.mpv.package ];

      xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.video == "mpv") {
        "video/mp4=mpv.desktop" = "mpv.desktop";
      };
    };
}
