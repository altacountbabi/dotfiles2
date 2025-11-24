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
        apps.loupe = {
          package = mkOpt types.package pkgs.loupe "The loupe package";
          default = mkOpt types.bool false "Whether to have loupe be the default image viewer";
        };
      };
    };

  flake.nixosModules.loupe =
    {
      config,
      lib,
      ...
    }:
    {
      prefs.apps.loupe.default = true;

      environment.systemPackages = [ config.prefs.apps.loupe.package ];

      xdg.mime.defaultApplications = lib.mkIf config.prefs.apps.loupe.default {
        "image/png" = "org.gnome.Loupe.desktop";
        "image/bmp" = "org.gnome.Loupe.desktop";
        "image/jpeg" = "org.gnome.Loupe.desktop";
      };
    };
}
