{ self, ... }:

{
  flake.nixosModules.pangoHardware =
    {
      modulesPath,
      config,
      lib,
      ...
    }:
    {
      imports = with self.nixosModules; [
        (modulesPath + "/installer/scan/not-detected.nix")

        amd
      ];

      boot = {
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "thunderbolt"
            "usb_storage"
            "usbhid"
            "sd_mod"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];
      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/79fc98fa-d1bc-4815-8441-68863ea206b3";
          fsType = "ext4";
        };

        "/boot" = {
          device = "/dev/disk/by-uuid/1677-BF10";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };

        "/mnt/sdd" = {
          device = "/dev/disk/by-uuid/bc609d31-e346-467c-80d3-5f3ef9ec70bc";
          fsType = "ext4";
          options = [ "nofail" ];
        };
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
