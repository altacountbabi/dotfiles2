{
  flake.nixosModules.base =
    {
      config,
      lib,
      ...
    }:
    let
      enable =
        [
          config.services.displayManager.gdm.enable
          config.services.displayManager.autoLogin.enable
        ]
        |> lib.all (x: x);
    in
    {
      systemd.services = lib.mkIf enable {
        "getty@tty1".enable = false;
        "autovt@tty1".enable = false;
      };
    };
}
