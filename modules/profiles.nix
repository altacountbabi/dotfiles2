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

        services
        caddy
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
        keyd
        fonts
        getty

        # Apps
        opencode
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
    desktop-simple =
      with self.nixosModules;
      [
        theme

        plymouth

        ssh
        git
        jj

        printing
        bluetooth

        gdm
        gnome
        fonts

        # Apps
        nautilus
        wezterm
        helium
        loupe
        mpv

        { prefs.tools.ffmpeg = false; }
      ]
      ++ minimal;
  };
}
