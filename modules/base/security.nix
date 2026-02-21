{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "";

    opts =
      { mkOpt, types, ... }:
      {
        sudo-rs = mkOpt types.bool true "Whether to use sudo-rs instead of sudo";
        uutils = mkOpt types.bool true "Whether to replace GNU coreutils with uutils";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      lib.mkMerge [
        {
          security.polkit.enable = lib.mkDefault true;
          security.rtkit.enable = lib.mkDefault true;

          environment.shellAliases = {
            run0 = "run0 --background=0";
          };
        }

        (lib.mkIf cfg.sudo-rs {
          security.sudo-rs = {
            enable = true;
            execWheelOnly = true;
            extraConfig = # sudo
              ''
                Defaults !lecture
                Defaults pwfeedback
                Defaults env_keep += "DISPLAY EDITOR PATH"
              '';

            extraRules = [
              {
                groups = [ "wheel" ];
                commands =
                  let
                    system = "/run/current-system";
                    store = "/nix/store";
                  in
                  [
                    {
                      command = "${store}/*/bin/switch-to-configuration";
                      options = [
                        "SETENV"
                        "NOPASSWD"
                      ];
                    }
                    {
                      command = "${system}/sw/bin/nix system activate";
                      options = [ "NOPASSWD" ];
                    }
                    {
                      command = "${system}/sw/bin/nix system apply";
                      options = [ "NOPASSWD" ];
                    }
                    {
                      command = "${system}/sw/bin/nix system boot";
                      options = [ "NOPASSWD" ];
                    }
                    {
                      command = "${system}/sw/bin/nix system build";
                      options = [ "NOPASSWD" ];
                    }
                    {
                      command = "${system}/sw/bin/nixos-rebuild";
                      options = [ "NOPASSWD" ];
                    }
                    {
                      command = "${system}/sw/bin/systemctl";
                      options = [ "NOPASSWD" ];
                    }
                  ];
              }
            ];
          };
        })

        (lib.mkIf cfg.uutils (
          let
            uutils = with pkgs; [
              uutils-coreutils-noprefix
              uutils-findutils
              uutils-diffutils
            ];
          in
          {
            environment.shellInit = # bash
              ''
                export PATH="${lib.makeBinPath uutils}$PATH"
              '';

            programs.nushell.extraConfig = # nu
              ''
                $env.PATH = $env.PATH | prepend [ ${uutils |> map (x: "\"${x}/bin\"") |> lib.concatStringsSep " "} ]
              '';
          }
        ))
      ];
  };
}
