{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "user";

    opts =
      {
        config,
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        name = mkOpt types.str "user" "The name of the default user";
        displayName =
          mkOpt types.str config.prefs.user.name
            "The name displayed on the login screen for the default user";

        initialPassword = mkOpt types.str "123" "The initial password for the default user and root";
        password = mkOpt (types.nullOr types.str) null "Sops secret to configure as user password";

        groups = mkOpt (types.listOf types.str) [ ] "The groups that the default user is in";
        shell = mkOpt types.package pkgs.bash "The shell of the default user";

        home = mkOpt types.str "/home/${config.prefs.user.name}" "The path to the user's home directory";

        vcs = {
          name =
            mkOpt (types.nullOr types.str) null
              "The name to use when authoring commits in version control systems";
          email =
            mkOpt (types.nullOr types.str) null
              "The email to use when authoring commits in version control systems";
        };
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        sops.secrets = lib.mkIf (cfg.password != null) {
          ${cfg.password}.neededForUsers = true;
        };

        users.users =
          let
            optional = cond: val: if cond then val else null;
          in
          {
            root = {
              ${optional (cfg.password != null) "hashedPasswordFile"} = config.sops.secrets.${cfg.password}.path;
              ${optional (cfg.password == null) "initialPassword"} = cfg.initialPassword;

              inherit (cfg) shell;
            };
            ${cfg.name} = {
              isNormalUser = true;
              description = cfg.displayName;
              extraGroups = cfg.groups ++ [
                "wheel"
                "video"
                "input"
              ];

              ${optional (cfg.password != null) "hashedPasswordFile"} = config.sops.secrets.${cfg.password}.path;
              ${optional (cfg.password == null) "initialPassword"} = cfg.initialPassword;

              inherit (cfg) shell;
            };
          };

        services.userborn.enable = true;
      };
  };
}
