{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "git" {
    path = "git";

    opts =
      { mkOpt, types, ... }:
      {
        user.name = mkOpt (types.nullOr types.str) null "The username to use when creating git commits";
        user.email = mkOpt (types.nullOr types.str) null "The email to use when creating git commits";

        githubAuth = mkOpt types.bool true "Whether to allow authenticating with the `gh` cli tool";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        imports = [
          "${inputs.nixpkgs.outPath}/nixos/modules/programs/git.nix"
        ];

        environment.shellAliases = {
          clone = "git clone --depth 1";
          lg = "lazygit";
        };

        environment.systemPackages =
          with pkgs;
          [
            lazygit
            difftastic
          ]
          ++ (lib.optional cfg.githubAuth pkgs.gh);

        programs.git = {
          enable = true;
          config = {
            init.defaultBranch = "main";
            url = {
              "https://github.com/" = {
                insteadOf = [
                  "gh:"
                  "github:"
                ];
              };
            };

            diff.external = "difft";

            inherit (cfg) user;
          }
          // (lib.optionalAttrs cfg.githubAuth {
            credential."https://github.com".helper = [
              null
              "!${pkgs.gh}/bin/gh auth git-credential"
            ];
            credential."https://gist.github.com".helper = [
              null
              "!${pkgs.gh}/bin/gh auth git-credential"
            ];
          });
        };
      };
  };
}
