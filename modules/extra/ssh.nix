{ self, ... }:

{
  flake.nixosModules = self.mkModule "ssh" {
    path = "ssh";

    opts =
      { mkOpt, types, ... }:
      {
        pubKeys = mkOpt (types.listOf types.str) [ ] "List of public ssh keys to authorize";
      };

    cfg =
      { config, cfg, ... }:
      {
        users.users.${config.prefs.user.name}.openssh.authorizedKeys.keys = cfg.pubKeys;

        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = (builtins.length cfg.pubKeys) != 0;
        };
      };
  };
}
