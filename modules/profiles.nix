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
        green-theme
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
        plymouth

        printing
        bluetooth

        niri
        keyd
        fonts

        # Basic apps
        nautilus
        wezterm
        helium
        loupe
        mpv
      ]
      ++ minimal;

    # Extra desktop apps
    desktopApps = with self.nixosModules; [
      discord
      steam
      sober
      loupe
      zen
      mpv
    ];
  };
}
