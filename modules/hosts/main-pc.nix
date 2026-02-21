{ self, inputs, ... }:

{
  flake.nixosConfigurations = self.mkConfigurations "main-pc" {
    normal = {
      imports = [
        inputs.disko.nixosModules.default
      ];

      config = {
        prefs = {
          profiles.desktop = true;

          user = {
            name = "user";
            vcs = {
              name = "Whoman";
              email = "altacountbabi@users.noreply.github.com";
            };
          };
        };

        boot.plymouth.enable = true;

        time.timeZone = "Europe/Bucharest";

        programs.dms-shell.settings = {
          barConfigs = [
            {
              id = "default";
              name = "Main Bar";
              enabled = true;
              position = 1; # Bottom
              screenPreferences = [
                "all"
              ];
              showOnLastDisplay = true;
              leftWidgets = [
                "launcherButton"
                "workspaceSwitcher"
                "focusedWindow"
              ];
              centerWidgets = [
                "music"
                "clock"
                "weather"
              ];
              rightWidgets = [
                "systemTray"
                "clipboard"
                "notificationButton"
                "controlCenterButton"
              ];
              spacing = 0;
              innerPadding = 4;
              bottomGap = 0;
              transparency = 1;
              widgetTransparency = 1;
              squareCorners = true;
              noBackground = false;
              gothCornersEnabled = false;
              gothCornerRadiusOverride = false;
              gothCornerRadiusValue = 12;
              borderEnabled = false;
              borderColor = "surfaceText";
              borderOpacity = 1;
              borderThickness = 1;
              fontScale = 1;
              autoHide = false;
              autoHideDelay = 250;
              openOnOverview = true;
              visible = false;
              popupGapsAuto = true;
              popupGapsManual = 4;
            }
          ];
        };

        boot = {
          initrd.availableKernelModules = [
            "xhci_pci"
            "ahci"
            "nvme"
            "usbhid"
            "sd_mod"
          ];
          kernelModules = [ "kvm-intel" ];
        };

        disko.devices.disk = {
          main = {
            # device = "/dev/disk/by-uuid/1fd9bffc-72cc-444f-95cd-8a9fccbecd58";
            device = "/dev/sda";
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
                  size = "100%";
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
              };
            };
          };
          # Uncomment after install
          # ssd = {
          #   device = "/dev/disk/by-uuid/6fbcaebc-340c-44fc-a07e-4ff16c9eccb7";
          #   type = "disk";

          #   content = {
          #     type = "filesystem";
          #     format = "f2fs";
          #     mountpoint = "/";
          #     extraArgs = [
          #       "-O"
          #       "extra_attr,inode_checksum,sb_checksum,compression"
          #     ];
          #     mountOptions = [
          #       "compress_algorithm=zstd:6,compress_chksum,atgc,gc_merge,lazytime,nofail"
          #     ];
          #   };
          # };
        };

        hardware.amdgpu.enable = true;
        hardware.cpu.intel.updateMicrocode = true;
      };
    };
  };
}
