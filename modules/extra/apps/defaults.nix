{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
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
              "zen"
              "helium"
            ];
            files = [ "nautilus" ];
            image = [ "loupe" ];
            video = [ "mpv" ];
            terminal = [ "wezterm" ];
          }
          |> (lib.mapAttrs (
            class: apps: mkOpt (types.nullOr (types.enum apps)) null "The default app for class \"${class}\""
          ));
      };
  };

}
