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
      programs.nautilus-open-any-terminal = lib.mkIf (config.prefs.defaultApps.terminal != null) {
        enable = true;
        terminal = config.prefs.defaultApps.terminal;
      };

      environment.systemPackages = [ config.prefs.apps.nautilus.package ];

      xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.files == "nautilus") {
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };
}
