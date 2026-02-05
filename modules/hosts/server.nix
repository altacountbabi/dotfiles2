{ self, inputs, ... }:

{
  flake.nixosConfigurations = self.mkConfigurations "server" {
    normal = {
      imports = [
        inputs.disko.nixosModules.default
      ];

      config = {
        prefs = {
          profiles.server = true;

          user = {
            name = "user";
            vcs = {
              name = "Whoman";
              email = "altacountbabi@users.noreply.github.com";
            };
          };
        };

        time.timeZone = "Europe/Bucharest";

        networking.domain = "av1.space";

        prefs.ssh.pubKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLPZH1a0cm/8M5m+zWrreCRQQ0CgZUJlOMrk4IYguP3 main-pc"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtgDeI2walSNUJUL52gLAUDiHXSByy+La8Knoep8wd9" # phone
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICr+MnG3i1kRYpef8+1jhhaCKZeBKBpE0GFskJbqatqm" # tablet
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6sJxditJlJ004Ag4e1WL92yrNVzl7+SDFhMIercysY home-assistant"
        ];

        services.jellyfin = {
          enable = true;
          settings = {
            encoding = {
              hardwareAccelerationType = "qsv";
              qsvDevice = "/dev/dri/renderD128";

              enableDecodingColorDepth10Hevc = true;
              enableDecodingColorDepth10Vp9 = true;

              enableIntelLowPowerH264HwEncoder = true;

              hardwareDecodingCodecs = [
                "h264"
                "hevc"
                "vc1"
                "vp8"
                "vp9"
                "av1"
              ];

              preferSystemNativeHwDecoder = true;

              enableTonemapping = true;
            };
          };
        };

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

        hardware.cpu.intel.updateMicrocode = true;
      };
    };
  };
}
