{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.jujutsu";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable jujutsu";
        package = mkOpt types.package pkgs.jujutsu "Jujutsu package";
        settings = mkOpt (types.attrsOf types.anything) { } "Jujutsu settings";
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
          (inputs.wrappers.wrapperModules.jujutsu.apply {
            inherit pkgs;
            package = lib.mkForce cfg.package;

            inherit (cfg) settings;
          }).wrapper;
      in
      {
        config = lib.mkIf cfg.enable {
          programs.jujutsu.settings = {
            ui.default-command = [
              "log"
              "-r"
              "all()"
            ];
            ui.diff-formatter = [
              "${pkgs.difftastic |> lib.getExe}"
              "--color=always"
              "$left"
              "$right"
            ];

            user = {
              ${if config.prefs.user.vcs.name != null then "name" else null} = config.prefs.user.vcs.name;
              ${if config.prefs.user.vcs.email != null then "email" else null} = config.prefs.user.vcs.email;
            };
          };

          environment.systemPackages = with pkgs; [
            wrapped
          ];

          environment.shellAliases = {
            jjs = "jj status";
            jjd = "jj describe";
            jjdf = "jj diff";
            jjb = "jj bookmark move --from @- --to @";
            jjp = "jj git push";
          };

          programs.nushell.excludedAliases = [ "jjn" ];
          programs.nushell.extraConfig = # nu
            ''
              def jjn --wrapped [...args] {
                jj new ...$args; jj bookmark move --from @- --to @ ...$args
              }
            '';
        };
      };
  };
}
