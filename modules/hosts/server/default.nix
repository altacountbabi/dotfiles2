{ inputs, self, ... }:

{
  flake.nixosConfigurations.server = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.serverHost ];
  };

  flake.nixosModules.serverHost =
    { config, lib, ... }:
    {
      imports = lib.mkHost (
        with self.nixosModules;
        {
          profile = self.profiles.server;
          include = [
            iso
            # ./_hardware.nix TODO: Uncomment this when deploying
          ];
        }
      );

      prefs = {
        boot.timeout = 5;
        network.hostname = "server";

        git.user = {
          name = "Whoman";
          email = "altacountbabi@users.noreply.github.com";
        };

        timeZone = "Europe/Bucharest";
        language.secondary = "ro_RO.UTF-8";

        ssh.pubKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLPZH1a0cm/8M5m+zWrreCRQQ0CgZUJlOMrk4IYguP3 main-pc"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtgDeI2walSNUJUL52gLAUDiHXSByy+La8Knoep8wd9" # phone
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICr+MnG3i1kRYpef8+1jhhaCKZeBKBpE0GFskJbqatqm" # tablet
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6sJxditJlJ004Ag4e1WL92yrNVzl7+SDFhMIercysY home-assistant"
        ];
      };

      system.activationScripts.copy-config.text =
        let
          src = config.prefs.cleanRoot;
          username = config.prefs.user.name;
        in
        ''
          mkdir -p /home/${username}
          cp -r ${src} /home/${username}/conf
          chown -R 1000:100 /home/${username}/conf
          chmod +w -R /home/${username}/conf
        '';

      system.stateVersion = lib.mkForce "25.05";
    };
}
