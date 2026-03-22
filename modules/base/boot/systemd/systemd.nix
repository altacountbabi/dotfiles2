{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    {
      boot.loader.systemd-boot.enable = lib.mkDefault true;

      systemd.package = pkgs.systemd.overrideAttrs (prev: {
        patches = (prev.patches or [ ]) ++ [ ./import-env-warning.patch ];
      });
    };
}
