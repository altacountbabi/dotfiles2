{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "tools" {
    path = "tools";

    opts =
      { mkOpt, types, ... }:
      {
        nix = mkOpt types.bool true "Whether to install nix-related tools";
        sys = mkOpt types.bool true "Whether to install system-related tools";
        ffmpeg = mkOpt types.bool true "Whether to install ffmpeg";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        inherit (lib) mkMerge mkIf;
      in
      {
        config = mkMerge [
          (mkIf cfg.sys (
            let
              noDesktopFilesWrapper =
                pkg:
                inputs.wrappers.lib.wrapPackage {
                  inherit pkgs;
                  package = pkg;
                  filesToExclude = [ "share/applications/*.desktop" ];
                };
            in
            {
              environment.shellAliases = {
                cat = "bat";
                df = "duf";
                tree = "tree -lC";
                less = "less -R";
              };

              environment.systemPackages = with pkgs; [
                (noDesktopFilesWrapper btop)
                libnotify
                file
                tree
                duf
                bat
              ];

              programs.htop = {
                enable = true;
                package = noDesktopFilesWrapper pkgs.htop;
                settings = {
                  hide_kernel_threads = true;
                  hide_userland_threads = true;
                };
              };
            }
          ))

          (mkIf cfg.nix {
            environment.shellAliases = {
              shell = "nom-shell --run nu";
            };

            prefs.nushell.extraConfig = [
              # nushell
              ''
                def nsr [pkg] {
                  nix run $"nixpkgs#($pkg)" --log-format internal-json -v o+e>| nom --json
                }
              ''
            ];

            environment.systemPackages = with pkgs; [
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
          })

          (mkIf cfg.ffmpeg {
            environment.shellAliases = {
              ffmpeg = "ffmpeg -hide_banner";
              ffprobe = "ffprobe -hide_banner";
              ffplay = "ffplay -hide_banner";
            };

            environment.systemPackages = with pkgs; [
              ffmpeg
            ];
          })
        ];
      };
  };
}
