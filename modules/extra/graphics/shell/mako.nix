{ inputs, ... }:

{
  flake.nixosModules.mako =
    {
      config,
      pkgs,
      ...
    }:
    let
      wrapped =
        (inputs.wrappers.wrapperModules.mako.apply {
          inherit pkgs;

          settings = with config.prefs.theme.colors; {
            anchor = "bottom-center";
            default-timeout = 2500;
            layer = "overlay";

            border-radius = 10;
            border-size = 1;

            background-color = base;
            border-color = overlay0;
          };
        }).wrapper;
    in
    {
      environment.systemPackages = [
        wrapped
      ];

      prefs.autostart = [ wrapped ];
    };
}
