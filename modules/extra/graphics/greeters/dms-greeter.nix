{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".services.displayManager.dms-greeter";

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          services.displayManager.dms-greeter = {
            compositor = {
              name = "niri";
              customConfig =
                let
                  conf =
                    (inputs.wrappers.wrapperModules.niri.apply {
                      inherit pkgs;
                      settings = {
                        inherit (config.programs.niri.settings)
                          outputs
                          input
                          cursor
                          hotkey-overlay
                          ;

                        layout.background-color = "#000000";
                      };
                    })."config.kdl".path;
                in
                # kdl
                ''
                  include "${conf}"
                '';
            };

            configHome = config.prefs.user.home;

            quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
          };
        };
      };
  };
}
