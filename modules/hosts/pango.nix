{ self, inputs, ... }:

{
  flake.nixosConfigurations = self.mkConfigurations "pango" {
    normal =
      { lib, ... }:
      {
        imports = [
          inputs.disko.nixosModules.default
        ];

        config = {
          prefs = {
            profiles.desktop = true;
            themes.base16-default-dark = true;
            themes.green = false;

            user.name = "user";
          };

          time.timeZone = "America/Toronto";

          programs.niri.settings = {
            workspaces.void = {
              layout.background-color = "#000000";
            };
            binds = {
              "Mod+Grave".focus-workspace = lib.mkForce "void";
              "Mod+Shift+Grave".move-column-to-workspace = lib.mkForce "void";
            };
          };

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
                openOnOverview = false;
                visible = true;
                popupGapsAuto = true;
                popupGapsManual = 4;
              }
            ];
          };

          boot = {
            initrd.availableKernelModules = [
              "nvme"
              "xhci_pci"
              "ahci"
              "thunderbolt"
              "usb_storage"
              "usbhid"
              "sd_mod"
            ];
            kernelModules = [ "kvm-amd" ];
          };

          disko.devices.disk = {
            main = {
              # device = "/dev/disk/by-uuid/79fc98fa-d1bc-4815-8441-68863ea206b3";
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
                };
              };
            };
            # ssd = {
            #   device = "/dev/disk/by-uuid/bc609d31-e346-467c-80d3-5f3ef9ec70bc";
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
          hardware.cpu.amd.updateMicrocode = true;
        };
      };
  };
}
