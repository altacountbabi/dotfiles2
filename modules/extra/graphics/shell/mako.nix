{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".services.mako";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable mako";
        package = mkOpt types.package pkgs.mako "Mako package";
        settings = mkOpt (types.attrsOf types.anything) pkgs.mako "Mako settings";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        wrapped =
          (inputs.wrappers.wrapperModules.mako.apply {
            inherit pkgs;
            inherit (cfg) package settings;
          }).wrapper;
      in
      {
        config = lib.mkIf cfg.enable {
          services.mako.settings = lib.mkDefault (
            with config.prefs.theme.colors;
            {
              anchor = "bottom-center";
              default-timeout = 2500;
              layer = "overlay";

              border-radius = 10;
              border-size = 1;

              background-color = base;
              border-color = overlay0;
            }
          );

          environment.systemPackages = [
            wrapped
          ];

          prefs.autostart = [ wrapped ];
        };
      };
  };
}
