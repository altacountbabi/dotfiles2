{ inputs, ... }:

{
  flake.nixosModules.mako =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      wrapped =
        (inputs.wrappers.wrapperModules.mako.apply {
          inherit pkgs;

          settings = {
            anchor = "bottom-center";
            default-timeout = 2500;
            layer = "overlay";

            border-radius = 10;
            border-size = 1;
          }
          // (lib.optionalAttrs config.themesEnabled (
            with config.prefs.theme.colors;
            {
              background-color = base;
              border-color = overlay0;
            }
          ));
        }).wrapper;
    in
    {
      prefs.autostart.mako = wrapped;
    };
}
