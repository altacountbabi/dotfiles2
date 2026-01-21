{ self, ... }:

{
  flake.nixosModules = self.mkModule "caddy" {
    opts =
      { mkOpt, types, ... }:
      {
        caddy = mkOpt (types.attrsOf types.lines) { } "Attrset of `virtualHosts`";
      };

    cfg =
      { lib, cfg, ... }:
      {
        services.caddy = {
          enable = true;
          virtualHosts = cfg.caddy |> lib.mapAttrs (k: v: { extraConfig = v; });
        };

        networking.firewall.allowedTCPPorts = [
          443
        ];
      };
  };
}
