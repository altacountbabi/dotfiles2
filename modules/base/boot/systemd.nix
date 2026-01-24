{
  flake.nixosModules.base =
    { lib, ... }:
    {
      boot.loader.systemd-boot.enable = lib.mkDefault true;
    };
}
