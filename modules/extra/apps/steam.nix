{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.steam";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.steam "Steam package";
        autostart = mkOpt types.bool false "Whether to automatically start steam at startup";
      };

    cfg =
      {
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          programs.steam = {
            inherit (cfg) package;
          };

          prefs.autostart = lib.mkIf cfg.autostart [ "steam" ];
        };
      };
  };
}
