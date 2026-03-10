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

          programs.lazygit.enable = true;

          environment.systemPackages = [
            pkgs.difftastic
          ]
          ++ (lib.optional cfg.githubAuth pkgs.gh);

          programs.git.config =
            let
              optional = x: y: if x != null then y else null;
              inherit (config.prefs.user.vcs) name email;
              inherit (config.prefs.ssh) pubKey;
            in
            {
              init.defaultBranch = "main";
              url = {
                "https://github.com/".insteadOf = [
                  "gh:"
                  "github:"
                ];
              };

              diff.external = "difft";

              user = {
                ${optional name "name"} = name;
                ${optional email "email"} = email;
                ${optional pubKey "signingkey"} = pubKey;
              };

              gpg = {
                format = "ssh";
                ssh.allowedSignersFile = pubKey; # This assumes that only one public key will be used for signing
              };
              commit.gpgsign = true;
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
