{ self, inputs, ... }:

{
  flake.nixosConfigurations = self.mkConfigurations "depozit" {
    normal = (
      { config, lib, ... }:
      {
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

          services.frigate = {
            enable = true;
            settings.cameras = {
              # test.ffmpeg.inputs = lib.singleton {
              #   path = "rtsp://localhost";
              #   roles = [ "record" ];
              # };
            };
          };

          time.timeZone = "Europe/Bucharest";

          prefs.ssh.pubKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLPZH1a0cm/8M5m+zWrreCRQQ0CgZUJlOMrk4IYguP3 main-pc"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtgDeI2walSNUJUL52gLAUDiHXSByy+La8Knoep8wd9" # phone
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIby1CF9JBHQqJC7v3dP8RgONtveHO1ndO9nxGUWNgc tablet"
          ];

          programs.git.githubAuth = false;

          networking.wakeOnLan = "enp2s0";

          boot = {
            initrd.availableKernelModules = [
              "xhci_pci"
              "ahci"
              "nvme"
              "usb_storage"
              "usbhid"
              "sd_mod"
            ];
            kernelModules = [ "kvm-intel" ];
          };

          disko.devices.disk.main = {
            device = "/dev/nvme0n1";
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

          hardware.nvidia = {
            enable = true;
            # Why did they even bother adding a GT 210 to this pc
            package = config.boot.kernelPackages.nvidiaPackages.legacy_340;
            open = false;
            nvidiaSettings = false;
          };
          services.xserver.videoDrivers = lib.mkForce [ ];
          hardware.cpu.intel.updateMicrocode = true;
        };
      }
    );
  };
}
