{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "network";

    opts =
      { mkOpt, types, ... }:
      {
        hostname = mkOpt types.str "nixos" "The name of the machine";
        domain = mkOpt types.str "nixos" "The system domain name";
        wol = mkOpt (types.nullOr types.str) null "Name of interface to enable wake on lan for";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        prefs.user.groups = [ "networkmanager" ];

        networking.hostName = cfg.hostname;
        networking.domain = cfg.domain;
        networking.networkmanager.enable = true;

        systemd.services.enable-wol = lib.mkIf (cfg.wol != null) {
          description = "Enable Wake-on-LAN";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = [ "${pkgs.ethtool |> lib.getExe} -s ${cfg.wol} wol g" ];
          };
        };
      };
  };
}
