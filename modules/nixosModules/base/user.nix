{
  flake.nixosModules.base =
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
      options.prefs = {
        user.name = mkOption {
          type = types.str;
          default = "user";
        };

        user.displayName = mkOption {
          type = types.str;
          default = "User";
        };

        user.groups = mkOption {
          type = types.listOf types.str;
          default = [
            "wheel"
            "video"
            "input"
          ];
        };

        user.shell = mkOption {
          type = types.package;
          default = pkgs.bash;
        };

        user.initialPassword = mkOption {
          type = types.str;
          default = "123";
        };
      };

      config = {
        users.users.${config.prefs.user.name} = {
          isNormalUser = true;
          description = config.prefs.user.displayName;
          extraGroups = config.prefs.user.groups;

          inherit (config.prefs.user) shell initialPassword;
        };
      };
    };
}
