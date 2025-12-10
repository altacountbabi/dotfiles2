{
  flake.nixosModules.systemd-boot = {
    boot.loader.systemd-boot.enable = true;
  };
}
