{ self, ... }:

{
  flake.nixosModules = self.mkModule "caddy" {
    opts =
      { mkOpt, types, ... }:
      {
        caddy = mkOpt (types.attrsOf types.lines) { } "Attrset of `virtualHosts`";
      };

    cfg =
      { cfg, ... }:
      {
        services.caddy = {
          enable = true;
          virtualHosts = cfg.caddy |> builtins.mapAttrs (k: v: { extraConfig = v; });
        };

        networking.firewall.allowedTCPPorts = [
          443
        ];
      };
  };
}
