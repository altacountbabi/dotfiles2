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
      inherit (lib) mkIf mkOpt types;
    in
    {
      options.prefs = {
        zen.package =
          mkOpt types.package inputs.zen-browser.packages.${pkgs.system}.default
            "The package to use for zen browser";
        zen.autostart = mkOpt types.bool false "Whether to automatically start zen browser at startup";
      };

      config = {
        environment.systemPackages = [
          config.prefs.zen.package
        ];

        prefs.autostart.zen = mkIf config.prefs.zen.autostart config.prefs.zen.package;

        # TODO: Create profile with hjem
      };
    };
}
