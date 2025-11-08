{ inputs, ... }:

{
  flake.nixosModules.sddm-silent =
    {
      config,
      pkgs,
      ...
    }:
    let
      theme = inputs.silentSDDM.packages.${pkgs.system}.default.override (
        let
          # TODO: Make this use a common option, not a hard-coded wallpaper.
          wallpaper = pkgs.runCommand "wallpaper" {
            inherit (config.prefs.theme) wallpaper;
          } "cp $wallpaper $out";
        in
        {
          extraBackgrounds = [ config.prefs.theme.wallpaper ];
          theme-overrides = {
            LoginScreen.background = wallpaper.name;
            LockScreen.background = wallpaper.name;
          };
        }
      );
    in
    {
      assertions = [
        {
          assertion = config.services.displayManager.sddm.enable;
          message = "sddm display manager must be enabled to use sddm-silent theme";
        }
      ];

      environment.systemPackages = [
        theme
        theme.test
      ];

      services.displayManager.sddm = {
        theme = theme.pname;
        extraPackages = theme.propagatedBuildInputs;
        settings.General = {
          GreeterEnvironment = "QML2_IMPORT_PATH=${theme}/share/sddm/themes/${theme.pname}/components/,QT_IM_MODULE=qtvirtualkeyboard";
          InputMethod = "qtvirtualkeyboard";
        };
      };
    };
}
