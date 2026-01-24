{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "ssh";

    opts =
      { mkOpt, types, ... }:
      {
        pubKeys = mkOpt (types.listOf types.str) [ ] "List of public ssh keys to authorize";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        users.users.${config.prefs.user.name}.openssh.authorizedKeys.keys = cfg.pubKeys;

        services.openssh = {
          settings.PasswordAuthentication = lib.mkDefault ((lib.length cfg.pubKeys) != 0);
        };
      };
  };
}
