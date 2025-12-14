# Completely skips login on getty, puts you right into your shell

{ self, ... }:

{
  flake.nixosModules = self.mkModule "skip-getty" {
    path = "skip-getty";

    opts =
      {
        config,
        mkOpt,
        types,
        ...
      }:
      {
        user = mkOpt (types.nullOr types.str) config.prefs.user.name "The user to log in as";
      };

    cfg =
      {
        lib,
        cfg,
        ...
      }:
      {
        services.getty = lib.mkIf (cfg.user != null) {
          autologinUser = cfg.user;
          autologinOnce = true;
          greetingLine = "";
          helpLine = "";
          extraArgs = [
            "--skip-login"
            "--nonewline"
            "--noissue"
            "--noclear"
            "--nohostname"
          ];
        };
      };
  };
}
