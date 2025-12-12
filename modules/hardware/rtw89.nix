{
  flake.nixosModules.rtw89 =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      rtw89 =
        let
          kernel = config.boot.kernelPackages.kernel;
          inherit (pkgs) stdenv fetchFromGitHub;
        in
        stdenv.mkDerivation {
          pname = "rtw89";
          version = "${kernel.version}-unstable-2025-12-12";

          src = fetchFromGitHub {
            owner = "morrownr";
            repo = "rtw89";
            rev = "e47a21c53cbd3bb4d29a42c40ca0c0c2aa005d1b";
            hash = "sha256-ofijADUyFAmE0bXCsJmQB41iGFu7AlXIwKGaHy4V/qU=";
          };

          nativeBuildInputs = kernel.moduleBuildDependencies;
          hardeningDisable = [
            "pic"
            "format"
          ];

          env.NIX_CFLAGS_COMPILE =
            let
              suppressed = [
                "incompatible-pointer-types"
                "missing-prototypes"
                "old-style-declaration"
                "enum-conversion"
                "empty-body"
                "missing-declarations"
                "misleading-indentation"
                "compare-distinct-pointer-types"
              ];
            in
            suppressed |> map (x: "-Wno-${x}") |> builtins.concatStringsSep " ";

          makeFlags = [
            "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
            "KVER=${kernel.version}"
            "ARCH=${stdenv.hostPlatform.linuxArch}"
            ("CONFIG_PLATFORM_I386_PC=" + (if stdenv.hostPlatform.isx86 then "y" else "n"))
            (
              "CONFIG_PLATFORM_ARM_RPI="
              + (if (stdenv.hostPlatform.isAarch32 || stdenv.hostPlatform.isAarch64) then "y" else "n")
            )
          ]
          ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
            "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
          ];

          installPhase =
            let
              modDestDir = "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/realtek/rtw89";
            in
            # bash
            ''
              runHook preInstall

              mkdir -p ${modDestDir}
              find . -name '*.ko' -exec cp --parents {} ${modDestDir} \;
              find ${modDestDir} -name '*.ko' -exec xz -f {} \;

              runHook postInstall
            '';

          enableParallelBuilding = true;

          meta = with lib; {
            description = "Driver for Realtek Wi-Fi 6/6E and Wi-Fi 7 adapters, provides the rtw89 modules";
            homepage = "https://github.com/morrownr/rtw89";
            license = licenses.gpl2Only;
            platforms = platforms.linux;
          };
        };
    in
    {
      boot = {
        kernelModules = [
          "cfg80211"
          "mac80211"
          "rtw89_core_git"
          "rtw89_8852au_git"
        ];

        extraModulePackages = [
          rtw89
        ];
      };

      hardware.usb-modeswitch.enable = true;
    };
}
