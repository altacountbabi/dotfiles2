{ inputs, ... }:

{
  flake.nixosModules.sddm-silent =
    {
      # config,
      # pkgs,
      lib,
      ...
    }:
    # let
    #   theme =
    #     if config.prefs.theme.wallpaper != null then
    #       inputs.silentSDDM.packages.${pkgs.stdenv.hostPlatform.system}.default.override (
    #         let
    #           wallpaper = pkgs.runCommand "wallpaper" {
    #             inherit (config.prefs.theme) wallpaper;
    #           } "cp $wallpaper $out";
    #         in
    #         {
    #           extraBackgrounds = [ config.prefs.theme.wallpaper ];
    #           theme-overrides = {
    #             LoginScreen.background = wallpaper.name;
    #             LockScreen.background = wallpaper.name;
    #           };
    #         }
    #       )
    #     else
    #       inputs.silentSDDM.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # in
    {
      imports = [
        inputs.silentSDDM.nixosModules.default
      ];

      programs.silentSDDM = {
        enable = true;
        theme = "rei";
        # settings = { ... }; see example in module
      };
    };
}
