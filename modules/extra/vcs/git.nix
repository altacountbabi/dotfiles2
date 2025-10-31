{
  flake.nixosModules.base =
    { lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        git.user.name = mkOpt (types.nullOr types.str) null "The username to use when creating git commits";
        git.user.email = mkOpt (types.nullOr types.str) null "The email to use when creating git commits";

        git.githubAuth = mkOpt types.bool true "Whether to allow authenticating with the `gh` cli tool";
      };
    };

  flake.nixosModules.git =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.shellAliases = {
        clone = "git clone --depth 1";
        lg = "lazygit";
      };

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
          // (lib.optionalAttrs config.prefs.git.githubAuth {
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
}
