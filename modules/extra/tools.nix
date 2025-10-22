{
  flake.nixosModules.tools =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        tools.nix = mkOpt types.bool true "Whether to install nix-related tools";
        tools.sys = mkOpt types.bool true "Whether to install system-related tools";
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
                btop
                duf
                bat
              ];
            };
          in
          packages
          |> lib.mapAttrsToList (name: pkgs: lib.optionals (config.prefs.tools.${name} or false) pkgs)
          |> lib.concatLists;
      };
    };
}
