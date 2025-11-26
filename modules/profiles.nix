{ self, ... }:

{
  flake.profiles = rec {
    bootable = with self.nixosModules; [
      base
      systemd-boot
    ];
    minimal =
      with self.nixosModules;
      [
        tools
        nushell
        helix
      ]
      ++ bootable;
    server =
      with self.nixosModules;
      [
        ssh
        git
        jj
      ]
      ++ minimal;
    desktop =
      with self.nixosModules;
      [
        theme

        plymouth

        ssh
        git
        jj

        printing
        bluetooth

        niri
        fonts
        getty

        # Apps
        nautilus
        wezterm
        discord
        helium
        steam
        sober
        loupe
        zen
        mpv
      ]
      ++ minimal;
  };
}
