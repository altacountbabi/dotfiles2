{
  flake.nixosModules.tools =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkEnableOption;
    in
    {
      options.prefs =
        let
          mkDefaultEnableOption = args: (mkEnableOption args) // { default = true; };
        in
        {
          tools.nix = mkDefaultEnableOption "nix-related tools";
          tools.sys = mkDefaultEnableOption "system-related tools";
        };

      config = {
        environment.systemPackages =
          let
            packages = {
              nix = with pkgs; [
                nix-output-monitor
                nix-search
                nixd
                nixfmt
              ];
              sys = with pkgs; [
                file
                tree
                htop
                helix
                duf
                bat
              ];
            };
          in
          lib.concatLists (
            lib.mapAttrsToList (name: pkgs: lib.optionals (config.prefs.tools.${name} or false) pkgs) packages
          );
      };
    };
}
