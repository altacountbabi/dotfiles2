{
  flake.nixosModules.base =
    { lib, ... }:
    {
      prefs.user.groups = [ "networkmanager" ];

      networking.networkmanager.enable = true;

      networking.domain = lib.mkDefault "localhost";
    };
}
