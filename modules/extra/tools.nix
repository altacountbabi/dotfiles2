{
  flake.nixosModules.tools =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkOpt types;
    in
    {
      options.prefs = {
        tools.nix = mkOpt types.bool true "Whether to install nix-related tools";
        tools.sys = mkOpt types.bool true "Whether to install system-related tools";
      };

      config = {
        environment.shellAliases =
          (lib.optionalAttrs config.prefs.tools.sys {
            cat = "bat";
            df = "duf";
            tree = "tree -lC";
            less = "less -R";
          })
          // (lib.optionalAttrs config.prefs.tools.nix {
            shell = "nom-shell --run nu";
            ns = "nom-shell -p --run nu";
            search = "nix-search";
          });

        prefs.nushell.extraConfig = mkIf config.prefs.tools.nix [
          ''
            def nsr [pkg] {
              nix run $"nixpkgs#($pkg)" --log-format internal-json -v o+e>| nom --json
            }
          ''
        ];

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
                libnotify
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
