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
        services.caddy.virtualHosts = cfg.caddy |> lib.mapAttrs (_: v: { extraConfig = v; });

        networking.firewall.allowedTCPPorts = [
          443
        ];
      };
  };
}
