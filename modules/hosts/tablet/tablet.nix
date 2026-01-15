{ self, inputs, ... }:

{
  flake.nixOnDroidConfigurations.tablet = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    pkgs =
      (import inputs.nixpkgs {
        system = "aarch64-linux";
      })
      // {
        lib = inputs.nixpkgs.lib.extend (import ../../../lib);
      };

    modules =
      self.profiles.minimal
      ++ (with self.nixosModules; [
        nix-on-droid
        ssh
        git
        jj

        (
          { pkgs, lib, ... }:
          {
            networking.hostName = "tablet";

            prefs =
              let
                vcsUser = {
                  name = "Whoman";
                  email = "altacountbabi@users.noreply.github.com";
                };
              in
              {
                tools.ffmpeg = false;
                xdg.patchSSH = false;

                git.user = vcsUser;
                jj.user = vcsUser;
              };

            environment.sessionVariables = {
              XDG_CURRENT_DESKTOP = "Termux";
              XDG_SESSION_TYPE = "TTY";
            };

            environment.systemPackages = with pkgs; [
              gnutar
              zstd
            ];

            system.stateVersion = lib.mkForce "24.05";
          }
        )
      ]);
  };
}
