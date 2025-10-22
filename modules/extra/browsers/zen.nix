{ inputs, ... }:

{
  flake.nixosModules.zen =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        zen.package =
          mkOpt types.package inputs.zen-browser.packages.${pkgs.system}.default
            "The package to use for zen browser";
      };

      config = {
        environment.systemPackages = [
          config.prefs.zen.package
        ];

        prefs.autostart.zen = config.prefs.zen.package;

        # TODO: Create profile with hjem
      };
    };
}
