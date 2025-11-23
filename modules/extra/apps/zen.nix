{ inputs, ... }:

{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        apps.zen = {
          package =
            mkOpt types.package inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
              "The package to use for zen browser";
          autostart = mkOpt types.bool false "Whether to automatically start zen browser at startup";
          default = mkOpt types.bool false "Whether to have zen browser be the default browser";
        };
      };
    };

  flake.nixosModules.zen =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf;
    in
    {
      environment.systemPackages = [
        config.prefs.apps.zen.package
      ];

      prefs.autostart.zen = mkIf config.prefs.apps.zen.autostart config.prefs.apps.zen.package;
    };
}
