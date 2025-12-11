{ self, ... }:

{
  flake.nixosModules = self.mkModule "printing" {
    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        printing.drivers = mkOpt (types.listOf types.package) (with pkgs; [
          gutenprint
          hplip
        ]) "List of printer drivers to install";

        scanning = {
          printers = mkOpt (types.listOf types.str) [ ] "List of IPs for network scanners";
          backends = mkOpt (types.listOf types.package) (with pkgs; [
            airscan
          ]) "List of SANE backends to install";
        };
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        services.printing = {
          enable = true;
          package = lib.hideDesktop {
            inherit pkgs;
            package = pkgs.cups;
          };
          inherit (cfg.printing) drivers;
        };

        hardware.sane = {
          enable = lib.mkDefault true;
          netConf = cfg.scanning.printers |> builtins.concatStringsSep "\n";
          extraBackends = cfg.scanning.backends;
        };
      };
  };
}
