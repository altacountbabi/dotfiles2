{ self, ... }:

{
  flake.nixosModules.depozit =
    { lib, ... }:
    {
      imports = lib.mkHost (
        with self.nixosModules;
        {
          profile = self.profiles.server;
          include = [
            depozitHardware
          ];
        }
      );

      networking.hostName = "depozit";

      prefs =
        let
          vcsUser = {
            name = "Whoman";
            email = "altacountbabi@users.noreply.github.com";
          };
        in
        {
          timeZone = "Europe/Bucharest";

          git.user = vcsUser;
          jj.user = vcsUser;

          ssh.pubKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLPZH1a0cm/8M5m+zWrreCRQQ0CgZUJlOMrk4IYguP3 main-pc"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtgDeI2walSNUJUL52gLAUDiHXSByy+La8Knoep8wd9" # phone
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICr+MnG3i1kRYpef8+1jhhaCKZeBKBpE0GFskJbqatqm" # tablet
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6sJxditJlJ004Ag4e1WL92yrNVzl7+SDFhMIercysY home-assistant"
          ];
        };
    };

  flake.nixosConfigurations = self.mkConfigurations "depozit" (
    with self.nixosModules;
    {
      normal.include = [ depozit ];
      iso.include = [
        vm-monitor
        installer
      ];
    }
  );
}
