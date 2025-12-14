{ self, ... }:

{
  flake.nixosModules = self.mkModule "gdm" {
    path = "gdm";

    cfg =
      {
        config,
        lib,
        ...
      }:
      {
        services.displayManager.gdm.enable = true;

        systemd.services = lib.mkIf config.services.displayManager.autoLogin.enable {
          "getty@tty1".enable = false;
          "autovt@tty1".enable = false;
        };
      };
  };
}
