{ self, ... }:

{
  flake.nixosModules = self.mkModule "nvidia" {
    path = "nvidia";

    opts =
      {
        config,
        mkOpt,
        types,
        ...
      }:
      {
        package =
          mkOpt types.package config.boot.kernelPackages.nvidiaPackages.stable
            "Which package to use for Nvidia GPU drivers";
        open = mkOpt types.bool true "Use open source kernel module";
      };

    cfg =
      { cfg, ... }:
      {
        hardware.nvidia = {
          inherit (cfg) package open;
        };
        services.xserver.videoDrivers = [ "nvidia" ];
      };
  };
}
