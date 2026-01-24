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
        config = lib.mkIf cfg.enable {
          prefs.iso.copyConfig = true;

          disko.devices = lib.mkForce { };

          services.getty = {
            silentAutologin = true;
            autologinUser = "root";
          };

          prefs.autostart-shell = [
            (
              let
                exe = self.packages.${pkgs.stdenv.hostPlatform.system}.installer |> lib.getExe;
                host = lib.optionalString (cfg.host != null) "--host ${cfg.host}";
              in
              "${exe} ${host} ${config.prefs.user.home}/conf"
            )
          ];
        };
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
          jujutsu
          disko
        ];
        text = lib.readFile ./main.nu;
      };
    };
}
