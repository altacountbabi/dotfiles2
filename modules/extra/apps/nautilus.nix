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
          package = mkOpt types.package pkgs.nautilus "The file manager package";
          default = mkOpt types.bool false "Whether to have nautilus be the default file manager";
        };
      };
    };

  flake.nixosModules.files =
    {
      config,
      lib,
      ...
    }:
    {
      environment.systemPackages = [ config.prefs.apps.nautilus.package ];

      xdg.mimeApps.defaultApplications = lib.mkIf config.prefs.apps.nautilus.default {
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };
}
