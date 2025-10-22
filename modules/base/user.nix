{
  flake.nixosModules.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        user.name = mkOpt types.str "user" "The name of the default user";
        user.displayName =
          mkOpt types.str "User"
            "The name displayed on the login screen for the default user";

        user.initialPassword = mkOpt types.str "123" "The initial password for the default user";

        user.groups = mkOpt (types.listOf types.str) [ ] "The groups that the default user is in";
        user.shell = mkOpt types.package pkgs.bash "The shell of the default user";
      };

      config = {
        users.users.${config.prefs.user.name} = {
          isNormalUser = true;
          description = config.prefs.user.displayName;
          extraGroups = config.prefs.user.groups ++ [
            "wheel"
            "video"
            "input"
          ];

          inherit (config.prefs.user) shell initialPassword;
        };
      };
    };
}
