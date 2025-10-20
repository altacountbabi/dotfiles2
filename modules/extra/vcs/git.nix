{
  flake.nixosModules.git =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib)
        optionalAttrs
        mkDefaultEnableOption
        mkOption
        types
        ;
    in
    {
      options.prefs = {
        git.user.name = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        git.user.email = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        git.githubAuth = mkDefaultEnableOption "authenticating with `gh` cli tool";
      };

      config = {
        environment.systemPackages = with pkgs; [
          lazygit
          difftastic
        ];

        programs.git = {
          enable = true;
          config =
            {
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

              inherit (config.prefs.git) user;
            }
            // (optionalAttrs config.prefs.git.githubAuth {
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
