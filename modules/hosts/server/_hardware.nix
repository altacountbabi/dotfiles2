{
  modulesPath,
  config,
  lib,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6338cb10-99af-4704-a655-af76b30716be";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/35C4-C819";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/mnt/hdd0" = {
      device = "/dev/md0";
      fsType = "ext4";
      noCheck = true;
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/627d7e5b-b975-4bee-8e00-458aefc408b4"; }
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
