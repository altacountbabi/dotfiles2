{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "desktop-entries";

    opts =
      {
        mkOpt,
        mkOpt',
        types,
        ...
      }:
      mkOpt (types.attrsOf (
        types.submodule {
          options = with types; {
            type = mkOpt str "Application" "Type of desktop entry";
            name = mkOpt' str "Name of desktop entry";
            exec = mkOpt' (either str path) "Command to execute in desktop entry";
            icon = mkOpt (nullOr (either str path)) null "Icon of desktop entry";
            comment = mkOpt (nullOr str) null "Tooltip";
            categories = mkOpt (listOf str) [ ] "Categories desktop entry is in";
            terminal = mkOpt bool false "Whether the command should be executed in a terminal";
            startupNotify = mkOpt bool true "Whether to send a notification when the app starts";
            version = mkOpt str "1.4" "Desktop file version";
          };
        }
      )) { } "Desktop entries";

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        optional = cond: val: if cond then val else null;
        entries =
          cfg
          |> lib.mapAttrsToList (
            id: v:
            (pkgs.formats.ini { }).generate "${id}.desktop" {
              "Desktop Entry" = with v; {
                Type = type;
                Name = name;
                Exec = toString exec;
                ${optional (icon != null) "Icon"} = toString icon;
                ${optional (comment != null) "Comment"} = comment;
                ${optional (categories != [ ]) "Categories"} = categories |> lib.concatStringsSep ";";
                Terminal = terminal;
                StartupNotify = startupNotify;
                Version = version;
              };
            }
          )
          |> map (drv: {
            name = "share/applications/${drv.name}";
            path = drv;
          })
          |> pkgs.linkFarm "desktop-entries";
      in
      {
        environment.systemPackages = [
          entries
        ];
      };
  };
}
