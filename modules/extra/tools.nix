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
        microfetch = mkOpt types.bool true "Whether to install microfetch";
      };

    cfg =
      {
        modulesPath,
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        inherit (lib) mkMerge mkIf;
      in
      {
        imports = [
          "${modulesPath}/programs/htop.nix" # programs.htop
        ];

        config = mkMerge [
          {
            environment.defaultPackages = [ ];
          }

          (mkIf cfg.sys {
            environment.shellAliases = {
              cat = "bat";
              df = "duf";
              tree = "tree -lC";
              less = "less -R";
            };

            environment.systemPackages = with pkgs; [
              (lib.hideDesktop {
                inherit pkgs;
                package = btop;
              })
              libnotify
              strace
              file
              tree
              wget
              duf
              bat
            ];

            programs.htop = {
              enable = true;
              package = lib.hideDesktop {
                inherit pkgs;
                package = pkgs.htop;
              };
              settings = {
                hide_kernel_threads = true;
                hide_userland_threads = true;
              };
            };
          })

          (mkIf cfg.nix {
            environment.shellAliases = {
              shell = "nom-shell --run nu";
              search = "nix-search";
            };

            prefs.nushell.extraConfig =
              let
                index = self.packages.${pkgs.stdenv.hostPlatform.system}.index;
              in
              [
                # nushell
                ''
                  def packages [] {
                    open ${index}
                  }

                  def "nix shell" [...packages: string@packages] {
                    let packages = $packages | each {|x| default-to-nixpkgs $x }

                    $env.name = "nix-shell"
                    nom shell ...$packages --command nu
                  }

                  def "nix run" [package: string@packages, ...program_args] {
                    let package = default-to-nixpkgs $package

                    let exe = nom getExe $package
                    ^$exe ...$program_args
                  }

                  alias ns = nix shell
                  alias nsr = nix run
                ''
              ];

            environment.systemPackages = with pkgs; [
              nix-output-monitor
              nix-search-cli
              nix-inspect
              nix-tree
              nixfmt
              nixd
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

          (mkIf cfg.microfetch {
            environment.systemPackages = [
              inputs.microfetch.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];
          })
        ];
      };
  };
}
