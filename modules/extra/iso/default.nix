# Simplified version of `nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix` which uses systemd-boot.
# This generates a EFI-bootable iso, this will not boot on legacy BIOS systems.

{
  flake.nixosModules.base =
    { lib, ... }:
    let
      inherit (lib) mkOption mkOpt types;
    in
    {
      options.prefs = {
        iso.compressImage =
          mkOpt types.bool false
            "Whether the ISO image should be compressed using `zstd`";

        iso.squashfsCompression =
          (mkOpt (types.nullOr types.str) "gzip -Xcompression-level 1" ''
            Compression settings to use for the squashfs nix store.
            `null` disables compression
          '')
          // {
            example = "zstd -Xcompression-level 19";
          };

        iso.contents = mkOpt (types.listOf (
          types.submodule {
            options = {
              source = mkOption {
                type = types.oneOf [
                  types.path
                  types.string
                ];
              };
              target = mkOption {
                type = types.oneOf [
                  types.path
                  types.string
                ];
              };
            };
          }
        )) [ ] "Files to be copied to fixed locations in the generated ISO image";

        iso.storeContents =
          mkOpt (types.listOf types.package) [ ]
            "Additional packages to be included in the nix store in the generated ISO image";
      };
    };

  flake.nixosModules.iso =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      volumeID = "nixos-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.uname.processor}";

      mkBootEntry =
        {
          title ? config.system.nixos.distroName,
          sortKey ? title,
          params ? [ ],
        }:
        ''
          title    ${title}
          sort-key ${sortKey}
          linux    /EFI/nixos/vmlinuz.efi
          initrd   /EFI/nixos/initrd.efi
          options  init=${config.system.build.toplevel}/init root=LABEL=${volumeID} ${
            lib.concatStringsSep " " (params ++ config.boot.kernelParams)
          }
        '';

      efiDir = pkgs.runCommand "efi-dir" { nativeBuildInputs = [ pkgs.systemd ]; } ''
        mkdir -p $out/EFI/BOOT
        mkdir -p $out/EFI/nixos
        mkdir -p $out/loader/entries

        cp ${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi \
          $out/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI

        cp ${config.system.build.kernel}/${config.system.boot.loader.kernelFile} $out/EFI/nixos/vmlinuz.efi
        cp ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} $out/EFI/nixos/initrd.efi

        cat > $out/loader/loader.conf <<EOF
        default nixos
        timeout ${config.boot.loader.timeout or 5 |> toString}
        console-mode keep
        EOF

        cat > $out/loader/entries/nixos.conf <<EOF
        ${mkBootEntry {
          sortKey = "01-nixos";
          params = [
            "quiet"
            "loglevel=3"
            "rd.udev.log_level=3"
            "udev.log_priority=3"
            "rd.systemd.show_status=false"
          ];
        }}
        EOF
      '';

      efiImg =
        pkgs.runCommand "efi-img"
          {
            nativeBuildInputs = [
              pkgs.mtools
              pkgs.dosfstools
            ];
            strictDeps = true;
          }
          ''
            mkdir ./contents
            cp -r ${efiDir}/* ./contents/
            truncate --size=48M "$out"
            mkfs.vfat -n EFIBOOT "$out"
            mmd -i "$out" ::/EFI
            mcopy -psvm -i "$out" ./contents/EFI ::/
            mmd -i "$out" ::/loader
            mcopy -psvm -i "$out" ./contents/loader ::/
            fsck.vfat -vn "$out"
          '';

      efiBootImage = "boot/efi.img";
    in
    {
      boot = {
        loader.systemd-boot.enable = true;

        initrd = {
          availableKernelModules = [
            "squashfs"
            "iso9660"
            "uas"
            "overlay"
          ];
          kernelModules = [
            "loop"
            "overlay"
          ];
          supportedFilesystems = [ "vfat" ];
        };
      };

      fileSystems = {
        "/" = lib.mkImageMediaOverride {
          fsType = "tmpfs";
          options = [ "mode=0755" ];
        };

        "/iso" = lib.mkImageMediaOverride {
          device = "/dev/root";
          neededForBoot = true;
          noCheck = true;
        };

        "/nix/.ro-store" = lib.mkImageMediaOverride {
          fsType = "squashfs";
          device = "/iso/nix-store.squashfs";
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
        {
          source = "${efiDir}/loader";
          target = "/loader";
        }
      ];

      system.build.isoImage = pkgs.callPackage ./_make-iso.nix {
        inherit (config.prefs.iso) compressImage squashfsCompression contents;
        inherit volumeID efiBootImage;
        isoName = "${volumeID}.iso";
        squashfsContents = config.prefs.iso.storeContents;
      };

      boot.postBootCommands = ''
        # After booting, register the contents of the Nix store on the
        # CD in the Nix database in the tmpfs.
        ${config.nix.package.out}/bin/nix-store --load-db < /nix/store/nix-path-registration

        # nixos-rebuild also requires a "system" profile and an
        # /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      '';
    };
}
