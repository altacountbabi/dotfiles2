{
  flake.nixosModules.rtl8852au =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      rtl8852au =
        let
          kernel = config.boot.kernelPackages.kernel;
          inherit (pkgs) stdenv fetchFromGitHub bc;
        in
        stdenv.mkDerivation {
          pname = "rtl8852au";
          version = "${kernel.version}-unstable-2025-12-11";

          src = fetchFromGitHub {
            owner = "pulponair";
            repo = "rtl8852au";
            rev = "develop";
            hash = "sha256-R8u89DzKsL2qYswvV0SXFLxsonChi3NtFs8aqVXAD68=";
          };

          nativeBuildInputs = kernel.moduleBuildDependencies ++ [ bc ];

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
              ];
            in
            suppressed |> map (x: "-Wno-${x}") |> builtins.concatStringsSep " ";

          makeFlags = [
            "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
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

          installPhase = ''
            install -D 8852au.ko $out/lib/modules/${kernel.modDirVersion}/8852au.ko
          '';

          enableParallelBuilding = true;

          meta = with lib; {
            description = "Driver for Realtek 802.11ac, rtl8852au, provides the 8852au mod";
            homepage = "https://github.com/natimerry/rtl8852au";
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
          "8852au"
        ];

        extraModulePackages = [
          rtl8852au
        ];
      };

      hardware.usb-modeswitch.enable = true;
    };
}
