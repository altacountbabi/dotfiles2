# https://github.com/weegs710/AnomalOS/blob/main/modules/shareables/wrapped-helium.nix

{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.helium";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable helium";
        autostart = mkOpt types.bool false "Whether to start helium at startup";

        extraBwrapArgs =
          mkOpt (types.listOf types.str) [ ]
            "List of args to pass to bwrap (sandboxing utility that this helium package uses)";

        extensions = mkOpt (with types; attrsOf (nullOr str)) { } "List of extensions to install";

        settings = mkOpt (types.attrsOf (pkgs.formats.json { }).type) { } ''
          Helium settings.
          Written to the `Preferences` file of the `Default` profile.
        '';
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
        extensionPolicy = pkgs.writeText "policy.json" (
          builtins.toJSON {
            ExtensionInstallForcelist = cfg.extensions |> lib.attrValues |> lib.filter (x: x != null);
          }
        );

        policiesDir = pkgs.runCommand "helium-policies" { } ''
          mkdir -p $out/etc/opt/chrome/policies/managed
          cp ${extensionPolicy} $out/etc/opt/chrome/policies/managed/extensions.json
        '';

        widevineConfig = pkgs.writeText "latest-component-updated-widevine-cdm" (
          builtins.toJSON {
            Path = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm";
          }
        );

        heliumPkg = pkgs.stdenv.mkDerivation rec {
          pname = "helium";
          version = "0.8.5.1";

          src = pkgs.fetchurl {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/${pname}-${version}-x86_64_linux.tar.xz";
            sha256 = "sha256-/cp201tiw2N+xsj89Ms06efJyYnfgc04uoJnvsjDUog=";
          };

          nativeBuildInputs = with pkgs; [
            makeWrapper
            autoPatchelfHook
          ];

          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            gtk3
            nss
            nspr
            alsa-lib
            cups
            libdrm
            mesa
            expat
            libxkbcommon
            pango
            cairo
            at-spi2-atk
            at-spi2-core
            dbus
            libva
            libGL
          ];

          # Qt shim libraries are optional compatibility layers
          autoPatchelfIgnoreMissingDeps = [
            "libQt5Core.so.5"
            "libQt5Gui.so.5"
            "libQt5Widgets.so.5"
            "libQt6Core.so.6"
            "libQt6Gui.so.6"
            "libQt6Widgets.so.6"
          ];

          sourceRoot = "helium-${version}-x86_64_linux";

          installPhase = ''
            mkdir -p $out/opt/helium $out/bin

            cp -r . $out/opt/helium/
            chmod +x $out/opt/helium/helium

            makeWrapper $out/opt/helium/helium $out/bin/helium
            mkdir -p $out/share/applications
            cp $out/opt/helium/helium.desktop $out/share/applications/
            substituteInPlace $out/share/applications/helium.desktop \
              --replace 'Exec=helium' 'Exec=${pname}'

            for size in 16 32 48 64 128 256; do
              mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
              if [ -f $out/opt/helium/product_logo_''${size}.png ]; then
                cp $out/opt/helium/product_logo_''${size}.png \
                   $out/share/icons/hicolor/''${size}x''${size}/apps/helium.png
              fi
            done
          '';

          meta = {
            description = "Private, fast, and honest web browser";
            homepage = "https://helium.computer/";
            platforms = [ "x86_64-linux" ];
          };
        };

        heliumWrapper = pkgs.writeShellScript "helium-wrapper" ''
          USER_DATA_DIR=""
          for arg in "$@"; do
            if [[ "$arg" == --user-data-dir=* ]]; then
              USER_DATA_DIR="''${arg#*=}"
              break
            fi
          done

          if [ -z "$USER_DATA_DIR" ]; then
            USER_DATA_DIR="$HOME/.config/net.imput.helium"
          fi

          mkdir -p "$USER_DATA_DIR/WidevineCdm"
          cp ${widevineConfig} "$USER_DATA_DIR/WidevineCdm/latest-component-updated-widevine-cdm"
          chmod u+w "$USER_DATA_DIR/WidevineCdm/latest-component-updated-widevine-cdm"

          {
            echo "[$(date)] Wrapper called with args: $@"
            echo "[$(date)] About to exec: ${heliumPkg}/bin/helium"
            echo "[$(date)] heliumPkg path: ${heliumPkg}"
            echo "[$(date)] Contents of makeWrapper script:"
            head -50 ${heliumPkg}/bin/helium 2>&1
            echo "[$(date)] Checking policies mount at /etc/chromium/policies/managed:"
            ls -la /etc/chromium/policies/managed/ 2>&1 || echo "NOT FOUND"
            echo "[$(date)] Checking policies mount at /etc/opt/chrome/policies/managed:"
            ls -la /etc/opt/chrome/policies/managed/ 2>&1 || echo "NOT FOUND"
          } >>/tmp/helium-wrapper.log

          exec ${heliumPkg}/bin/helium "$@" >>/tmp/helium.log 2>&1
        '';

        wrappedHelium = pkgs.buildFHSEnv {
          name = "helium";
          targetPkgs = pkgs: [
            heliumPkg
            pkgs.mesa
            pkgs.libGL
            pkgs.libdrm
            pkgs.libva
          ];
          extraBwrapArgs = [
            "--ro-bind ${policiesDir}/etc/opt/chrome/policies/managed /etc/chromium/policies/managed"
            "--ro-bind-try /etc/xdg/ /etc/xdg/"
          ]
          ++ cfg.extraBwrapArgs;
          runScript = heliumWrapper;
          extraInstallCommands = ''
            mkdir -p $out/share/applications
            cp ${heliumPkg}/share/applications/helium.desktop $out/share/applications/

            for size in 16 32 48 64 128 256; do
              mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
              if [ -f ${heliumPkg}/share/icons/hicolor/''${size}x''${size}/apps/helium.png ]; then
                cp ${heliumPkg}/share/icons/hicolor/''${size}x''${size}/apps/helium.png \
                   $out/share/icons/hicolor/''${size}x''${size}/apps/
              fi
            done
          '';
          meta = {
            mainProgram = "helium";
            description = "Helium browser with DRM, dark UI, and bundled extensions";
          };
        };
      in
      {
        config = lib.mkIf cfg.enable {
          programs.helium = {
            extensions =
              {
                darkReader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
                bitwarden = "nngceckbapebfimnlniiiahkandclblb";
                inlineTranslator = "odibgflepadohfmpcemnjbhkionjkapk";
              }
              |> lib.mapAttrs (_: lib.mkDefault);
            settings = {
              browser.custom_chrome_frame = lib.mkDefault false;
              webkit.webprefs.fonts = with config.fonts.fontconfig.defaultFonts; {
                standard.Zyyy = lib.head serif;
                serif.Zyyy = lib.head serif;
                sansserif.Zyyy = lib.head sansSerif;
                fixed.Zyyy = lib.head monospace;
              };
            };
          };

          environment.systemPackages = [
            wrappedHelium
          ];

          xdg.mime.defaultApplications =
            lib.genAttrs [
              "text/html"
              "application/xhtml+xml"
              "application/x-extension-html"
              "application/x-extension-htm"
              "application/x-extension-shtml"
              "x-scheme-handler/http"
              "x-scheme-handler/https"
              "image/svg+xml"
              "application/pdf"
            ] (_: "helium.desktop")
            |> lib.mkIf (config.prefs.defaultApps.browser == "helium");

          prefs.autostart = lib.mkIf cfg.autostart [
            wrappedHelium
          ];

          prefs.merged-configs.helium = {
            path = "${config.prefs.user.home}/.config/net.imput.helium/Default/Preferences";
            overlay = cfg.settings;
          };
        };
      };
  };
}
