{
  flake.nixosModules.base =
    { lib, ... }:
    {
      boot.loader.timeout = lib.mkDefault 0;

      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
      };

      boot.initrd.systemd.enable = true;
      system.etc.overlay.enable = true;
      system.nixos-init.enable = true;

      virtualisation.vmVariant = {
        # Nixpkgs issue
        system.nixos-init.enable = lib.mkForce false;

        virtualisation = {
          cores = 8;
          memorySize = 8 * 1024;
          qemu = {
            consoles = lib.mkForce [
              "ttyS0,115200n8"
            ];
            options = [
              # TODO: Figure out a way to make this easily toggleable
              # "-device virtio-gpu-gl"
              # "-display gtk,show-menubar=off,zoom-to-fit=off,gl=on"
              # "-vga virtio"
              "-nographic"
            ];
          };
        };
      };

      # Removes the need to import `not-detected.nix` in every host
      hardware.enableRedistributableFirmware = lib.mkDefault true;
    };
}
