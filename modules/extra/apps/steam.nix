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
        steam.autostart = mkOpt types.bool false "Whether to automatically start steam at startup";
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

        prefs.autostart.steam = mkIf config.prefs.steam.autostart "steam";
      };
    };
}
