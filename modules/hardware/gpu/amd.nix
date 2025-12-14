{
  flake.nixosModules.amd = {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.amdgpu.initrd.enable = true;
  };

  # WARNING: AMDVLK driver is depracated in favor of RADV from mesa (the default)
  flake.nixosModules.amdvlk =
    { pkgs, ... }:
    {
      hardware.graphics = with pkgs; {
        extraPackages = [ amdvlk ];
        extraPackages32 = [ driversi686Linux.amdvlk ];
      };
    };
}
