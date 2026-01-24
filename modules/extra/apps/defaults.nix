{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    opts =
      {
        lib,
        mkOpt,
        types,
        ...
      }:
      {
        defaultApps =
          {
            browser = [
              "helium"
              "zen"
            ];
            files = [ "nautilus" ];
            image = [ "loupe" ];
            video = [ "mpv" ];
            terminal = [ "wezterm" ];
          }
          |> (lib.mapAttrs (
            class: apps:
            mkOpt (types.nullOr (types.enum apps)) (lib.head apps) "The default app for class \"${class}\""
          ));
      };
  };

}
