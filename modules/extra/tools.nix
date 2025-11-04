{
  flake.nixosModules.base =
    {
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
        tools.ffmpeg = mkOpt types.bool true "Whether to install ffmpeg";
      };
    };

  flake.nixosModules.tools =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf;
    in
    {
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
          })
          // (lib.optionalAttrs config.prefs.tools.ffmpeg {
            ffmpeg = "ffmpeg -hide_banner";
            ffprobe = "ffprobe -hide_banner";
            ffplay = "ffplay -hide_banner";
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
                nix-tree
                nixfmt
                nixd

                (writeShellApplication {
                  name = "ns";
                  runtimeInputs = with pkgs; [
                    fzf
                    nix-search-tv
                  ];
                  text = ''exec "${pkgs.nix-search-tv.src}/nixpkgs.sh" "$@"'';
                })
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
              ffmpeg = with pkgs; [
                ffmpeg-full
              ];
            };
          in
          packages
          |> lib.mapAttrsToList (name: pkgs: lib.optionals (config.prefs.tools.${name} or false) pkgs)
          |> lib.concatLists;
      };
    };
}
