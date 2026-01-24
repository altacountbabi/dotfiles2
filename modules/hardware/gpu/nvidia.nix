{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".hardware.nvidia";

    opts =
      { mkOpt, types, ... }:
      {
        enable = mkOpt types.bool false "Enable nvidia drivers";
      };

    cfg =
      {
        config,
        lib,
        ...
      }:
      {
        config = lib.mkIf config.hardware.nvidia.enable {
          hardware.nvidia = {
            package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
            open = lib.mkDefault true;
          };

          services.xserver.videoDrivers = [ "nvidia" ];
        };
      };
  };
}
