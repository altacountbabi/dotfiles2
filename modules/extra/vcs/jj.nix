{
  flake.nixosModules.jj =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) optionalAttrs mkOpt types;
    in
    {
      options.prefs = {
        jj.user.name = mkOpt (types.nullOr types.str) null "The username to use when creating jj commits";
        jj.user.email = mkOpt (types.nullOr types.str) null "The email to use when creating jj commits";

        jj.extraConfig =
          mkOpt (types.attrsOf types.anything) { }
            "Extra properties to set in the jj config";
      };

      config = {
        environment.systemPackages = with pkgs; [
          jujutsu
          lazyjj

          difftastic
        ];

        hjem.users.${config.prefs.user.name} = {
          xdg.config.files."jj/config.toml".source = (pkgs.formats.toml { }).generate "config.toml" (
            {
              ui.default-command = [
                "log"
                "-r"
                "all()"
              ];
              ui.diff-formatter = [
                "difft"
                "--color=always"
                "$left"
                "$right"
              ];

              git.push-new-bookmarks = true;
            }
            // (optionalAttrs (config.prefs.jj.user.name != null) { user.name = config.prefs.jj.user.name; })
            // (optionalAttrs (config.prefs.jj.user.email != null) { user.email = config.prefs.jj.user.email; })
            // config.prefs.jj.extraConfig
          );
        };
      };
    };
}
