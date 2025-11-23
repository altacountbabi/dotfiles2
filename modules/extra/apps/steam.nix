{

  flake.nixosModules.base =
    {
      lib,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        apps.steam.autostart = mkOpt types.bool false "Whether to automatically start steam at startup";
      };
    };

  flake.nixosModules.steam =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf;
    in
    {

      config = {
        programs.steam = {
          enable = true;
          extraCompatPackages = with pkgs; [ proton-ge-bin ];
        };

        prefs.autostart.apps.steam = mkIf config.prefs.apps.steam.autostart "steam";
      };
    };
}
