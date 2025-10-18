{ inputs, ... }:

{
  flake.nixosModules.zen =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        environment.systemPackages = [
          inputs.zen-browser.packages.${pkgs.system}.default
        ];

        # TODO: Create profile with hjem
      };
    };
}
