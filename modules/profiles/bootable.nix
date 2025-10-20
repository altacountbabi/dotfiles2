{ self, ... }:

{
  flake.nixosModules.bootable = {
    imports = with self.nixosModules; [
      base
      systemd-boot
    ];
  };
}
