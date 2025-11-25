{ self, ... }:

{
  flake.nixosModules = self.mkModule "getty" {
    path = "getty";

    opts =
      { mkOpt, types, ... }:
      {
        autologin = mkOpt types.bool true "Enable autologin in getty";
      };

    cfg =
      {
        config,
        cfg,
        lib,
        ...
      }:
      {
        services.getty = lib.mkIf cfg.autologin {
          autologinUser = config.prefs.user.name;
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
