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
          default = mkOpt types.bool false "Whether to have mpv be the default video player";
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
      prefs.apps.mpv.default = true;

      environment.systemPackages = [ config.prefs.apps.mpv.package ];

      xdg.mime.defaultApplications = lib.mkIf config.prefs.apps.mpv.default {
        "video/mp4=mpv.desktop" = "mpv.desktop";
      };
    };
}
