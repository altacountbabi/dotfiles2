{
  flake.nixosModules.mako =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [ mako ];

      prefs.autostart.mako = "mako";

      hjem.users.${config.prefs.user.name} = {
        xdg.config.files."mako/config".text =
          ''
            anchor=bottom-center
            default-timeout=2500
            layer=overlay

            border-radius=10
            border-size=1
          ''
          + (lib.optionalString config.themesEnabled (
            with config.prefs.theme.colors;
            ''
              background-color=${background}
              border-color=${outline}
            ''
          ));
      };
    };
}
