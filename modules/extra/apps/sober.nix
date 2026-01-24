{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.sober";

    opts =
      {
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable sober browser";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          services.flatpak.enable = true;

          # TODO: Use a proper declarative flatpak manager flake here to allow for uninstalling it too
          systemd.services.install-sober-flatpak = {
            description = "Install sober flatpak";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "basic.target" ];
            path = [ pkgs.flatpak ];
            serviceConfig = {
              Type = "simple";
              User = config.prefs.user.name;
              Group = "users";
              ExecStart = "${pkgs.bash}/bin/bash -c 'flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo && flatpak install -y --noninteractive --user flathub org.vinegarhq.Sober'";
            };
          };
        };
      };
  };
}
