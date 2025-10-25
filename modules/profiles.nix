{ self, ... }:

{
  flake.profiles = rec {
    bootable = with self.nixosModules; [
      base
      systemd-boot
      facter
    ];
    minimal =
      with self.nixosModules;
      [
        tools
        nushell
        helix
      ]
      ++ bootable;
    desktop =
      with self.nixosModules;
      [
        theme

        plymouth

        ssh
        git
        jj

        printing

        niri
        fonts
        getty

        wezterm
        discord
        helium
        sober
        steam
        zen
      ]
      ++ minimal;
    server =
      with self.nixosModules;
      [
        ssh
        git
        jj
      ]
      ++ minimal;
  };
}
