{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    opts =
      { mkOpt, types, ... }:
      {
        caddy = mkOpt (types.attrsOf types.lines) { } "Attrset of `virtualHosts`";
      };

    cfg =
      { lib, cfg, ... }:
      {
        services.caddy = {
          enable = lib.mkIf (cfg.caddy != { }) true;
          virtualHosts = cfg.caddy |> lib.mapAttrs (_: v: { extraConfig = v; });
          globalConfig = "skip_install_trust";
        };

        networking.firewall.allowedTCPPorts = [
          443
        ];
      };
  };
}
