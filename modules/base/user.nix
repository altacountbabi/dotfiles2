{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "user";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        name = mkOpt types.str "user" "The name of the default user";
        displayName = mkOpt types.str "User" "The name displayed on the login screen for the default user";

        initialPassword = mkOpt types.str "123" "The initial password for the default user";

        groups = mkOpt (types.listOf types.str) [ ] "The groups that the default user is in";
        shell = mkOpt types.package pkgs.bash "The shell of the default user";
      };

    cfg =
      { cfg, ... }:
      {
        users.users.${cfg.name} = {
          isNormalUser = true;
          description = cfg.displayName;
          extraGroups = cfg.groups ++ [
            "wheel"
            "video"
            "input"
          ];

          inherit (cfg) shell initialPassword;
        };
      };
  };
}
