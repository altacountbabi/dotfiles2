{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".hardware.amdgpu";

    opts =
      { mkOpt, types, ... }:
      {
        enable = mkOpt types.bool false "Enable amdgpu driver";
      };

    cfg =
      {
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          hardware.graphics = {
            enable = true;
            enable32Bit = true;
          };

          hardware.amdgpu.initrd.enable = true;
        };
      };
  };
}
