{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      inherit (lib)
        mkIf
        mkDefault
        mkOpt
        types
        ;
    in
    {
      options.prefs = {
        sudo-rs.enable = mkOpt types.bool true "Whether to use sudo-rs instead of sudo";
      };

      config = {
        security.polkit.enable = mkDefault true;
        security.rtkit.enable = mkDefault true;
        security.sudo-rs = mkIf config.prefs.sudo-rs.enable {
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
      };
    };
}
