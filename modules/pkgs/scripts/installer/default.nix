{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.installer";

    opts =
      {
        config,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable installer";
        autostart = mkOpt types.bool false "Autostart the installer on tty1";
        host =
          mkOpt (types.nullOr types.str) config.networking.hostName
            "The host to automatically pick in the installer";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable (
          let
            wrapper = inputs.wrappers.lib.wrapPackage {
              inherit pkgs;
              package = self.packages.${pkgs.stdenv.hostPlatform.system}.installer;
              args =
                (lib.optionals (cfg.host != null) [
                  "--host"
                  cfg.host
                ])
                ++ [
                  "${config.prefs.user.home}/conf"
                ];
            };
          in
          {
            prefs.iso.copyConfig = true;

            disko.devices = lib.mkForce { };

            programs.jujutsu.enable = true;
            programs.git.enable = true;

            environment.systemPackages = [
              wrapper
            ];

            prefs.desktop-entries.installer = {
              name = "Installer";
              exec = wrapper;
              terminal = true;
            };

            services.getty = lib.mkIf cfg.autostart {
              silentAutologin = true;
              autologinUser = "root";
            };

            prefs.autostart-shell = lib.mkIf cfg.autostart [
              (lib.getExe wrapper)
            ];
          }
        );
      };
  };

  perSystem =
    { pkgs, lib, ... }:
    {
      packages.installer = self.lib.nushellScript {
        inherit pkgs;
        name = "installer";
        packages = with pkgs; [
          nushell
          disko
        ];
        text = lib.readFile ./main.nu;
      };
    };
}
