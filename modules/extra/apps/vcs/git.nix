{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.git";

    opts =
      { mkOpt, types, ... }:
      {
        githubAuth = mkOpt types.bool true "Whether to allow authenticating with the `gh` cli tool";
      };

    cfg =
      {
        modulesPath,
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        imports = [
          "${modulesPath}/programs/git.nix"
        ];

        config = lib.mkIf cfg.enable {
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

          programs.git.config = {
            init.defaultBranch = "main";
            url = {
              "https://github.com/".insteadOf = [
                "gh:"
                "github:"
              ];
            };

            diff.external = "difft";

            user = {
              ${if config.prefs.user.vcs.name != null then "name" else null} = config.prefs.user.vcs.name;
              ${if config.prefs.user.vcs.email != null then "email" else null} = config.prefs.user.vcs.email;
            };
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
