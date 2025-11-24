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
      environment.systemPackages = [ config.prefs.apps.loupe.package ];

      xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.image == "loupe") {
        "image/png" = "org.gnome.Loupe.desktop";
        "image/bmp" = "org.gnome.Loupe.desktop";
        "image/jpeg" = "org.gnome.Loupe.desktop";
      };
    };
}
