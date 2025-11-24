{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      checkDefaults =
        apps:
        let
          selectedApps = apps |> map (name: config.prefs.apps.${name});
          defaultAppsCount = selectedApps |> lib.count (app: app.default);
        in
        defaultAppsCount > 1;
      classes = {
        "browsers" = [
          "zen"
          "helium"
        ];
        "file managers" = [
          "nautilus"
        ];
        "image viewers" = [
          "loupe"
        ];
        "video players" = [
          "mpv"
        ];
      };
    in
    {
      assertions =
        classes
        |> lib.mapAttrsToList (
          class: apps: {
            assertion = !(checkDefaults apps);
            message = "Multiple ${class} are set to be the default";
          }
        );
    };
}
