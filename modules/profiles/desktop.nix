{ self, ... }:

{
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      minimal

      plymouth

      ssh
      git
      jj

      niri
      sddm
      sddm-silent

      wezterm
      zen
    ];
  };
}
