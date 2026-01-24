{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".services.getty";

    opts =
      { mkOpt, types, ... }:
      {
        silentAutologin = mkOpt types.bool true "Make autologin completely silent";
      };

    cfg =
      {
        lib,
        cfg,
        ...
      }:
      {
        services.getty = lib.mkIf (cfg.silentAutologin && cfg.autologinUser != null) {
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
