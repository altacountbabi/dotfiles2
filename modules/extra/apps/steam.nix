{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.steam";

    opts =
      { mkOpt, types, ... }:
      {
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
          prefs.autostart = lib.mkIf cfg.autostart [ "steam" ];
        };
      };
  };
}
