{
  flake.nixosModules.steam =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkOpt types;
    in
    {
      options.prefs = {
        steam.autostart = mkOpt types.bool false "Whether to automatically start steam at startup";
      };

      config = {
        programs.steam = {
          enable = true;
          extraCompatPackages = with pkgs; [ proton-ge-bin ];
        };

        prefs.autostart.helium = mkIf config.prefs.steam.autostart "steam";
      };
    };
}
