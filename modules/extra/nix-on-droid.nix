# Module to bring some NixOS module options to nix-on-droid

{ self, ... }:

{
  flake.nixosModules.base =
    { lib, ... }:
    {
      options.isDroid =
        lib.mkOpt lib.types.bool false
          "Whether or not this is a nix-on-droid configuration";
    };

  flake.nixosModules.nix-on-droid =
    (self.mkModule {
      path = ".";

      opts =
        { mkOption, types, ... }:
        let
          mkOpt = type: default: mkOption { inherit type default; };
          mkOpt' = type: mkOption { inherit type; };
        in
        with types;
        {
          # User module
          users.users = mkOpt (attrsOf anything) { };
          services.userborn.enable = mkOpt bool false;

          # Boot module
          boot.loader.timeout = mkOpt int 5;
          boot.loader.systemd-boot.enable = mkOpt bool false;
          boot.initrd.systemd.enable = mkOpt bool false;
          boot.kernel.sysctl = mkOpt (attrsOf anything) { };
          system.etc.overlay.enable = mkOpt bool false;
          system.nixos-init.enable = mkOpt bool false;

          # Kernel module
          boot.kernelPackages = mkOpt' package;
          boot.kernelParams = mkOpt (listOf str) [ ];
          boot.kernelModules = mkOpt (listOf str) [ ];

          # Locale module
          i18n = {
            defaultLocale = mkOpt str "";
            extraLocaleSettings = mkOpt (attrsOf str) { };
          };

          # Network module
          networking.hostName = mkOpt str "";
          networking.domain = mkOpt str "";
          networking.networkmanager.enable = mkOpt bool false;
          systemd.services = mkOpt (attrsOf anything) { };

          # Nix module
          nix = {
            settings = mkOpt (attrsOf anything) { };
            gc = mkOpt (attrsOf anything) { };
            optimise = mkOpt (attrsOf anything) { };
            channel = mkOpt (attrsOf anything) { };
          };
          system.tools = mkOpt (attrsOf anything) { };
          programs.nh.enable = mkOpt bool false;
          environment.shellAliases = mkOpt (attrsOf str) { };
          documentation = mkOpt (attrsOf anything) { };

          # Security module
          security = {
            polkit.enable = mkOpt bool false;
            rtkit.enable = mkOpt bool false;
            sudo-rs = mkOpt (attrsOf anything) { };
          };
          system.replaceDependencies = mkOpt (attrsOf anything) { };

          # XDG-Compat module
          environment.systemPackages = mkOpt (listOf package) [ ];
          environment.defaultPackages = mkOpt (listOf package) [ ];
          environment.interactiveShellInit = mkOpt (listOf package) [ ];
          system.userActivationScripts = mkOpt (attrsOf anything) { };
          services.dbus.implementation = mkOpt str "";
          services.openssh.enable = mkOpt bool false;
          programs.ssh = mkOpt (attrsOf anything) { };

          # Monitors module
          hardware.display.outputs = mkOpt (attrsOf anything) { };

          # NixOS modules from nixpkgs
          meta = mkOpt (attrsOf anything) { };
        };

      cfg =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          isDroid = true;

          prefs.user.home = "/data/data/com.termux.nix/files/home";

          user.shell = lib.getExe config.users.users.user.shell;

          nix.extraOptions =
            let
              inherit (lib)
                isInt
                isBool
                isFloat
                boolToString
                isDerivation
                isPath
                isString
                strings
                toPretty
                escape
                concatStringsSep
                mapAttrsToList
                ;

              mkValueString =
                v:
                if v == null then
                  ""
                else if isInt v then
                  toString v
                else if isBool v then
                  boolToString v
                else if isFloat v then
                  strings.floatToString v
                else if isDerivation v then
                  toString v
                else if isPath v then
                  toString v
                else if isString v then
                  v
                else if strings.isConvertibleWithToString v then
                  toString v
                else
                  abort "The nix conf value: ${toPretty { } v} can not be encoded";

              mkKeyValue = k: v: "${escape [ "=" ] k} = ${mkValueString v}";

              mkKeyValuePairs = attrs: concatStringsSep "\n" (mapAttrsToList mkKeyValue attrs);
            in
            config.nix.settings |> mkKeyValuePairs;

          environment = {
            packages =
              config.environment.systemPackages ++ (lib.optional config.services.openssh.enable pkgs.openssh);
            etcBackupExtension = ".bak";
            sessionVariables = {
              NIX_PATH = null;
              SHELL = lib.getExe config.users.users.user.shell;
            };
            motd = null;

            etc =
              let
                needsEscaping = s: null != lib.match "[a-zA-Z0-9]+" s;
                escapeIfNecessary = s: if needsEscaping s then s else ''"${lib.escape [ "$" "\"" "\\" "`" ] s}"'';
                attrsToText =
                  attrs:
                  (
                    attrs
                    |> lib.mapAttrsToList (n: v: "${n}=${escapeIfNecessary (toString v)}")
                    |> lib.concatStringsSep "\n"
                  )
                  + "\n";
              in
              {
                "lsb-release".text = attrsToText rec {
                  LSB_VERSION = "24.05";
                  DISTRIB_ID = "nix-on-droid";
                  DISTRIB_RELEASE = LSB_VERSION;
                  DISTRIB_DESCRIPTION = "Nix-On-Droid 24.05";
                };
                "os-release".text = attrsToText rec {
                  NAME = "Nix-On-Droid";
                  PRETTY_NAME = "${NAME} 24.05";
                  ID = "nix-on-droid";
                  LOGO = "nix-snowflake";
                  ANSI_COLOR = "0;38;2;126;186;228";
                };

                hostname.text = config.networking.hostName;
              };
          };

          terminal = {
            colors = with config.prefs.theme.colors; {
              foreground = text;
              background = base;
              cursor = rosewater;

              color0 = surface1;
              color1 = red;
              color2 = green;
              color3 = yellow;
              color4 = blue;
              color5 = rosewater;
              color6 = teal;
              color7 = subtext1;

              color8 = surface2;
              color9 = red;
              color10 = green;
              color11 = yellow;
              color12 = blue;
              color13 = pink;
              color14 = teal;
              color15 = subtext0;
            };
            # TODO: Figure out a better way to declare default fonts to also be able to get the raw ttf file rather than just the name.
            font = "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode/FiraCodeNerdFont-Retina.ttf";
          };

          android-integration = {
            termux-open.enable = true;
            termux-open-url.enable = true;
            xdg-open.enable = true;
            termux-reload-settings.enable = true;
            termux-wake-lock.enable = true;
            termux-wake-unlock.enable = true;
          };
        };
    }).base;
}
