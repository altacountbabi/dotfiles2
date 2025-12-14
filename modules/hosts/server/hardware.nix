{ self, inputs, ... }:

{
  flake.nixosModules.serverHardware =
    {
      modulesPath,
      config,
      lib,
      ...
    }:
    {
      imports = with self.nixosModules; [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.disko.nixosModules.default
      ];

      boot = {
        swraid = {
          enable = true;
          mdadmConf = ''
            MAILADDR root
            ARRAY /dev/md0 metadata=1.2 UUID=961d89b8:ffa1eef2:52851cb9:ed6b5716
          '';
        };
        kernelParams = [ "md-mod.start_dirty_degraded=1" ];
        initrd = {
          availableKernelModules = [
            "vmd"
            "xhci_pci"
            "ahci"
            "nvme"
            "usb_storage"
            "usbhid"
            "sd_mod"
            "i915"
          ];
          kernelModules = [ "i915" ];
        };
        kernelModules = [
          "kvm-intel"
          "i915"
        ];
        extraModulePackages = [ ];
        extraModprobeConfig = "options i915 enable_guc=2";
      };

      disko.devices.disk = {
        main = {
          device = "/dev/disk/by-uuid/6338cb10-99af-4704-a655-af76b30716be";
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
                end = "-8G";
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
        # TODO: Figure out how to do this later without erasing everything
        # hdd0 = {
        #   device = "/dev/md0";
        #   type = "disk";
        #   content = {
        #     type = "gpt";
        #     partitions = { };
        #   };
        # };
      };

      fileSystems."/mnt/hdd0" = {
        device = "/dev/md0";
        fsType = "ext4";
        noCheck = true;
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
