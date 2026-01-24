{ self, ... }:

{
  flake.nixosModules = self.mkModule "steam" {
    path = "apps.steam";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.steam "The package to use for steam browser";
        autostart = mkOpt types.bool false "Whether to automatically start steam at startup";
      };

    cfg =
      {
        lib,
        cfg,
        ...
      }:
      {
        programs.steam = {
          enable = true;
          inherit (cfg) package;
        };

        prefs.autostart = lib.mkIf cfg.autostart [ "steam" ];
      };
  };
}
