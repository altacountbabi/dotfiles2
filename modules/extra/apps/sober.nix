{
  flake.nixosModules.sober =
    { config, pkgs, ... }:
    {
      config = {
        services.flatpak.enable = true;

        systemd.services.install-sober-flatpak = {
          description = "install sober flatpak";
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
}
