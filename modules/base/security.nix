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
      {
        security.polkit.enable = lib.mkDefault true;
        security.rtkit.enable = lib.mkDefault true;

        security.sudo-rs = lib.mkIf cfg.sudo-rs {
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

        environment.shellAliases = {
          run0 = "run0 --background=0";
        };

        system.replaceDependencies.replacements = lib.mkIf cfg.uutils (
          let
            postfix = version: version |> lib.stringLength |> lib.genList (_: "_") |> lib.concatStringsSep "";

            coreutils-full-name = "coreuutils-full" + postfix pkgs.coreutils-full.version;
            coreutils-name = "coreuutils" + postfix pkgs.coreutils.version;
            findutils-name = "finduutils" + postfix pkgs.findutils.version;
            diffutils-name = "diffuutils" + postfix pkgs.diffutils.version;
          in
          [
            # coreutils
            {
              oldDependency = pkgs.coreutils-full;
              newDependency = pkgs.symlinkJoin {
                name = coreutils-full-name;
                paths = [ pkgs.uutils-coreutils-noprefix ];
              };
            }
            {
              oldDependency = pkgs.coreutils;
              newDependency = pkgs.symlinkJoin {
                name = coreutils-name;
                paths = [ pkgs.uutils-coreutils-noprefix ];
              };
            }
            # findutils
            {
              oldDependency = pkgs.findutils;
              newDependency = pkgs.symlinkJoin {
                name = findutils-name;
                paths = [ pkgs.uutils-findutils ];
              };
            }
            # diffutils
            {
              oldDependency = pkgs.diffutils;
              newDependency = pkgs.symlinkJoin {
                name = diffutils-name;
                paths = [ pkgs.uutils-diffutils ];
              };
            }
          ]
        );
      };
  };
}
