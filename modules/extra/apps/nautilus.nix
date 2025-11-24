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
        apps.nautilus = {
          package = mkOpt types.package pkgs.nautilus "The nautilus package";
          default = mkOpt types.bool false "Whether to have nautilus be the default file manager";
        };
      };
    };

  flake.nixosModules.nautilus =
    {
      config,
      lib,
      ...
    }:
    {
      prefs.apps.nautilus.default = true;

      environment.systemPackages = [ config.prefs.apps.nautilus.package ];

      xdg.mime.defaultApplications = lib.mkIf config.prefs.apps.nautilus.default {
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };
}
