{
  flake.nixosModules.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.hardware.sane;
      inherit (lib) mkOpt types;
    in
    {
      options.hardware.sane = {
        scanners = mkOpt (types.listOf types.str) [ ] "List of IPs of network scanners";
      };

      config = {
        services.printing = {
          package = lib.hideDesktop {
            inherit pkgs;
            package = pkgs.cups;
          };
          drivers = lib.mkDefault (
            with pkgs;
            [
              gutenprint
              hplip
            ]
          );
        };

        hardware.sane = {
          netConf = lib.concatStringsSep "\n" cfg.scanners;
          extraBackends = lib.mkDefault [
            pkgs.airscan
          ];
        };
      };
    };
}
