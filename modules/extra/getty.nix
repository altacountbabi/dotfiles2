{
  flake.nixosModules.getty =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
    in
    {
      options.prefs = {
        getty.autologin = mkEnableOption "autologin in getty";
      };

      config = {
        services.getty = mkIf config.prefs.getty.autologin {
          autologinUser = config.prefs.user.name;
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
