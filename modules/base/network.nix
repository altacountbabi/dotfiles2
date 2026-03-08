{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".networking";

    opts =
      { mkOpt, types, ... }:
      {
        wakeOnLan = mkOpt (types.nullOr types.str) null "Name of interface to enable wake on lan for";
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

        networking.networkmanager.enable = true;

        networking.domain = lib.mkDefault "localhost";

        systemd.services.enable-wol = lib.mkIf (cfg.wakeOnLan != null) {
          description = "Enable Wake-on-LAN";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = [ "${lib.getExe pkgs.ethtool} -s ${cfg.wakeOnLan} wol g" ];
          };
        };
      };
  };
}
