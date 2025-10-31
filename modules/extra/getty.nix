{
  flake.nixosModules.base =
    { lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        getty.autologin = mkOpt types.bool true "Enable autologin in getty";
      };
    };

  flake.nixosModules.getty =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
    in
    {
      services.getty = mkIf config.prefs.getty.autologin {
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
}
