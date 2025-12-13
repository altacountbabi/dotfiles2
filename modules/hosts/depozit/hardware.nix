{ inputs, ... }:

{
  flake.nixosModules.depozitHardware =
    {
      modulesPath,
      config,
      lib,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.disko.nixosModules.default
      ];

      boot = {
        initrd = {
          availableKernelModules = [
            "xhci_pci"
            "ahci"
            "nvme"
            "usb_storage"
            "usbhid"
            "sd_mod"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
      };

      disko.devices.disk.main = {
        device = "/dev/disk/by-uuid/53e22d76-1470-476e-b622-1e1cffd6e6d4";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "-8G";
              content = {
                type = "filesystem";
                format = "f2fs";
                mountpoint = "/";
                extraArgs = [
                  "-O"
                  "extra_attr,inode_checksum,sb_checksum,compression"
                ];
                mountOptions = [
                  "compress_algorithm=zstd:6,compress_chksum,atgc,gc_merge,lazytime"
                ];
              };
            };
            swap = {
              size = "100%";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
          };
        };
      };

      networking.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
