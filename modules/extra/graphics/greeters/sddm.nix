{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".services.displayManager.sddm";

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          qt.enable = true;

          services.displayManager.sddm = {
            package = lib.mkDefault pkgs.kdePackages.sddm;
            wayland.enable = true;
          };
        };
      };
  };
}
