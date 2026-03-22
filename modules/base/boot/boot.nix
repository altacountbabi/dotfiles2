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
          useEFIBoot = true;
          qemu = {
            consoles = lib.mkForce [ "tty0" ];
            options = [
              "-no-user-config"
              "-nodefaults"
              # "-device qemu-xhci,p2=15,p3=15,id=usb"
              "-device virtio-serial-pci,id=virtio-serial0"
              "-chardev spicevmc,id=ch1,name=vdagent"
              "-device virtserialport,bus=virtio-serial0.0,nr=1,chardev=ch1,name=com.redhat.spice.0"
              "-device usb-tablet,id=input0"
              "-spice unix,addr=$XDG_RUNTIME_DIR/spice.sock,disable-ticketing=on,image-compression=off,gl=on,seamless-migration=off"
              "-device virtio-vga-gl"
              "-display spice-app,gl=on"
            ];
          };
        };
      };

      # Removes the need to import `not-detected.nix` in every host
      hardware.enableRedistributableFirmware = lib.mkDefault true;
    };
}
