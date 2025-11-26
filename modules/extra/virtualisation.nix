{ self, ... }:

{
  flake.nixosModules = self.mkModule "virtualisation" {
    path = "virtualisation";

    cfg =
      { ... }:
      {
        prefs.user.groups = [ "libvirtd" ];

        virtualisation = {
          libvirtd.enable = true;
          spiceUSBRedirection.enable = true;
        };
      };
  };
}
