{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.opencode";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable opencode";
        package =
          mkOpt types.package inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
            "Opencode package";

        settings = mkOpt (types.attrsOf types.anything) { } "Opencode settings";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        configFile = cfg.settings |> (pkgs.formats.json { }).generate "opencode.jsonc";

        wrapped = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          inherit (cfg) package;

          env.OPENCODE_CONFIG = configFile;
        };
      in
      {
        config = lib.mkIf cfg.enable {
          programs.opencode.settings = lib.mkDefaultRec {
            "$schema" = "https://opencode.ai/config.json";
            theme = "system";
            autoupdate = false;
            mcp = {
              nixos = {
                type = "local";
                command = [
                  (lib.getExe inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default)
                  "--"
                ];
              };
              docs-rs = {
                type = "local";
                command = [
                  (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.docs-rs-mcp)
                ];
              };
            };
          };

          environment.systemPackages = [
            wrapped
          ];

          environment.shellAliases = {
            oc = lib.getExe wrapped;
          };
        };
      };
  };
}
