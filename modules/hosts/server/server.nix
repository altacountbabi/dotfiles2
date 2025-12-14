{ self, ... }:

{
  flake.nixosModules.server =
    { lib, ... }:
    {
      imports = lib.mkHost (
        with self.nixosModules;
        {
          profile = self.profiles.server;
          include = [
            serverHardware
            media

            plymouth
            sddm
            niri
            fonts
            helium
            wezterm
          ];
        }
      );

      prefs =
        let
          vcsUser = {
            name = "Whoman";
            email = "altacountbabi@users.noreply.github.com";
          };
        in
        {
          network = {
            hostname = "server";
            domain = "av1.space";
          };

          timeZone = "Europe/Bucharest";

          git.user = vcsUser;
          jj.user = vcsUser;

          ssh.pubKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLPZH1a0cm/8M5m+zWrreCRQQ0CgZUJlOMrk4IYguP3 main-pc"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtgDeI2walSNUJUL52gLAUDiHXSByy+La8Knoep8wd9" # phone
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICr+MnG3i1kRYpef8+1jhhaCKZeBKBpE0GFskJbqatqm" # tablet
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6sJxditJlJ004Ag4e1WL92yrNVzl7+SDFhMIercysY home-assistant"
          ];

          jellyfin = {
            encoding = {
              hardwareAccelerationType = "qsv";
              qsvDevice = "/dev/dri/renderD128";

              enableDecodingColorDepth10Hevc = true;
              enableDecodingColorDepth10Vp9 = true;

              enableIntelLowPowerH264HwEncoder = true;

              hardwareDecodingCodecs = [
                "h264"
                "hevc"
                "vc1"
                "vp8"
                "vp9"
                "av1"
              ];

              preferSystemNativeHwDecoder = true;

              enableTonemapping = true;
            };
          };
        };
    };

  flake.nixosConfigurations = self.mkConfigurations "server" (
    with self.nixosModules;
    {
      normal.include = [
        server
        iso
      ];
      iso.include = [
        vm-monitor
        installer
      ];
    }
  );
}
