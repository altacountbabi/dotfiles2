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
      fonts
      getty

      wezterm
      helium
    ];
  };
}
