# Simplified version of `nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix` which uses systemd-boot.
# This generates a EFI-bootable iso, this will not boot on legacy BIOS systems.

{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "iso";

    opts =
      {
        lib,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable ISO module";

        compressImage = mkOpt types.bool false "Whether the ISO image should be compressed using `zstd`";

        squashfsCompression =
          (mkOpt (types.nullOr types.str) "gzip -Xcompression-level 1" ''
            Compression settings to use for the squashfs nix store.
            `null` disables compression
          '')
          // {
            example = "zstd -Xcompression-level 19";
          };

        contents = mkOpt (types.listOf (
          types.submodule {
            options = {
              source = lib.mkOption {
                type = types.oneOf [
                  types.path
                  types.string
                ];
              };
              target = lib.mkOption {
                type = types.oneOf [
                  types.path
                  types.string
                ];
              };
            };
          }
        )) [ ] "Files to be copied to fixed locations in the generated ISO image";

        storeContents =
          mkOpt (types.listOf types.package) [ ]
            "Additional packages to be included in the nix store in the generated ISO image";

        copyConfig = mkOpt types.bool false "Copy config to home directory";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        volumeID = "nixos-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.uname.processor}";
        targetArch = pkgs.stdenv.hostPlatform.efiArch;

        grubPkgs = if config.boot.loader.grub.forcei686 then pkgs.pkgsi686Linux else pkgs;

        # Minimal GRUB configuration for Option B
        grubCfg = pkgs.writeText "grub.cfg" ''
          search --set=root --file /EFI/nixos-installer-image

          set default=0
          set timeout=${toString (config.boot.loader.timeout or 5)}

          insmod gfxterm
          insmod png
          set gfxpayload=keep
          ${
            let
              monitors = config.prefs.monitors |> lib.attrValues;
              m = if ((lib.length monitors) != 0) then lib.head monitors else null;
            in
            lib.optionalString (m != null) "set gfxmode=${toString m.width}x${toString m.height}"
          }

          loadfont (\$root)/EFI/BOOT/unicode.pf2

          terminal_output gfxterm
          terminal_input console

          menuentry "NixOS" {
            linux /EFI/nixos/vmlinuz.efi init=${config.system.build.toplevel}/init root=LABEL=${volumeID} ${lib.concatStringsSep " " config.boot.kernelParams}
            initrd /EFI/nixos/initrd.efi
          }
        '';

        efiDir =
          pkgs.runCommand "efi-directory"
            {
              nativeBuildInputs = [ pkgs.grub2 ];
              strictDeps = true;
            }
            ''
              mkdir -p $out/EFI/BOOT
              mkdir -p $out/EFI/nixos

              # Add a marker so GRUB can find the filesystem.
              touch $out/EFI/nixos-installer-image

              # Kernel + initrd
              cp ${config.system.build.kernel}/${config.system.boot.loader.kernelFile} $out/EFI/nixos/vmlinuz.efi
              cp ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} $out/EFI/nixos/initrd.efi

              # Minimal set of GRUB modules
              MODULES=(
                # Basic modules for filesystems and partition schemes
                "fat"
                "iso9660"
                "part_gpt"
                "part_msdos"

                # Basic stuff
                "normal"
                "boot"
                "linux"
                "configfile"
                "loopback"
                "chain"
                "halt"

                # Allows rebooting into firmware setup interface
                "efifwsetup"

                # EFI Graphics Output Protocol
                "efi_gop"

                # User commands
                "ls"

                # System commands
                "search"
                "search_label"
                "search_fs_uuid"
                "search_fs_file"
                "echo"

                # We're not using it anymore, but we'll leave it in so it can be used
                # by user, with the console using "C"
                "serial"

                # Graphical mode stuff
                "gfxmenu"
                "gfxterm"
                "gfxterm_background"
                "gfxterm_menu"
                "test"
                "loadenv"
                "all_video"
                "videoinfo"

                # File types for graphical mode
                "png"
              )

              # Build EFI binary
              grub-mkimage \
                --directory=${grubPkgs.grub2_efi}/lib/grub/${grubPkgs.grub2_efi.grubTarget} \
                -o $out/EFI/BOOT/BOOT${lib.toUpper targetArch}.EFI \
                -p /EFI/BOOT \
                -O ${grubPkgs.grub2_efi.grubTarget} \
                ''${MODULES[@]}

              # Copy default font for text output
              cp ${pkgs.grub2}/share/grub/unicode.pf2 $out/EFI/BOOT/

              # Write grub.cfg
              cp ${grubCfg} $out/EFI/BOOT/grub.cfg
            '';

        # Create FAT image containing GRUB EFI binary
        efiImg =
          pkgs.runCommand "efi-img"
            {
              nativeBuildInputs = [
                pkgs.mtools
                pkgs.dosfstools
              ];
            }
            ''
              mkdir contents
              cp -r ${efiDir}/* contents/

              truncate --size=100M "$out"
              mkfs.vfat -n EFIBOOT "$out"

              mmd -i "$out" ::/EFI
              mcopy -psvm -i "$out" ./contents/EFI ::/

              fsck.vfat -vn "$out"
            '';

        efiBootImage = "boot/efi.img";
      in
      {
        config = lib.mkIf cfg.enable {
          boot = {
            loader = {
              systemd-boot.enable = lib.mkForce false;
              grub = {
                enable = false;
                efiSupport = true;
                copyKernels = false;
                devices = [ "nodev" ];
              };
            };

            initrd.availableKernelModules = [
              "squashfs"
              "iso9660"
              "uas"
              "overlay"
            ];

            initrd.kernelModules = [
              "loop"
              "overlay"
            ];

            initrd.supportedFilesystems = [ "vfat" ];
          };

          fileSystems = lib.mkForce {
            "/" = lib.mkImageMediaOverride {
              fsType = "tmpfs";
              options = [ "mode=0755" ];
            };

            "/iso" = lib.mkImageMediaOverride {
              device = "LABEL=${volumeID}";
              neededForBoot = true;
              noCheck = true;
            };

            "/nix/.ro-store" = lib.mkImageMediaOverride {
              fsType = "squashfs";
              device = "/sysroot/iso/nix-store.squashfs";
              options = [ "loop" ];
              neededForBoot = true;
            };

            "/nix/.rw-store" = lib.mkImageMediaOverride {
              fsType = "tmpfs";
              options = [ "mode=0755" ];
              neededForBoot = true;
            };

            "/nix/store" = lib.mkImageMediaOverride {
              overlay = {
                lowerdir = [ "/nix/.ro-store" ];
                upperdir = "/nix/.rw-store/store";
                workdir = "/nix/.rw-store/work";
              };
            };
          };

          prefs.iso.storeContents = [ config.system.build.toplevel ];

          prefs.iso.contents = [
            {
              source = efiImg;
              target = "/boot/efi.img";
            }
            {
              source = "${efiDir}/EFI";
              target = "/EFI";
            }
          ];

          system.build.isoImage = pkgs.callPackage ./_make-iso.nix {
            inherit (cfg)
              compressImage
              squashfsCompression
              contents
              ;
            inherit volumeID efiBootImage;
            inherit (config.system.build) toplevel;
            isoName = "${volumeID}.iso";
            squashfsContents = cfg.storeContents;
          };

          systemd.services.nix-post-boot = {
            description = "Nix post-boot commands";
            after = [ "local-fs.target" ];
            wantedBy = [ "local-fs.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart =
                let
                  nix = config.nix.package.out;
                in
                ''
                  ${lib.getExe pkgs.bash} -c "${nix}/bin/nix-store --load-db < /nix/store/nix-path-registration; touch /etc/NIXOS; ${nix}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system"
                '';
            };
          };

          systemd.services.copy-config = lib.mkIf cfg.copyConfig {
            description = "Nix post-boot commands";
            after = [ "local-fs.target" ];
            wantedBy = [ "local-fs.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart =
                let
                  inherit (config.prefs.user) home;
                  copyConfig = pkgs.writeText "copy-config.sh" ''
                    mkdir -p ${home}
                    cp -r ${config.root} ${home}/conf
                    chown -R 1000:100 ${home}/conf
                    chmod +w -R ${home}/conf
                  '';
                in
                ''
                  ${lib.getExe pkgs.bash} ${copyConfig}
                '';
            };
          };
        };
      };
  };
}
