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
          programs.opencode.settings = lib.mkDefault {
            "$schema" = "https://opencode.ai/config.json";
            theme = "system";
            autoupdate = false;
            mcp = {
              nixos = {
                type = "local";
                command = [
                  (inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default |> lib.getExe)
                  "--"
                ];
              };
              docs-rs = {
                type = "local";
                # TODO: Package this properly
                command = [
                  "${pkgs.bun |> lib.getExe}"
                  "--"
                  "x"
                  "@nuskey8/docs-rs-mcp@latest"
                ];
              };
            };
          };

          environment.systemPackages = [
            wrapped
          ];

          environment.shellAliases = {
            oc = wrapped;
          };
        };
      };
  };
}
