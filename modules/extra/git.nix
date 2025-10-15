{
  flake.nixosModules.git =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      environment.systemPackages = with pkgs; [
        lazygit
      ];

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

          user = {
            name = "altacountbabi";
            email = "altacountbabi@users.noreply.github.com";
          };

          credential."https://github.com".helper = [
            null
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
          credential."https://gist.github.com".helper = [
            null
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
      };

      hjem.users.${config.prefs.user.name} = {
        files.".gitconfig".text = ''
          [credential "https://github.com"]
            helper =
            helper = !/nix/store/x4gwqxx6w677dvk2g7cprsq7i35yp0si-gh-2.81.0/bin/gh auth git-credential
          [credential "https://gist.github.com"]
            helper =
            helper = !/nix/store/x4gwqxx6w677dvk2g7cprsq7i35yp0si-gh-2.81.0/bin/gh auth git-credential

          [user]
            name = altacountbabi
            email = altacountbabi@users.noreply.github.com
        '';
      };
    };
}
