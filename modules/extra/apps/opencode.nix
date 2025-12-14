{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "opencode" {
    path = "apps.opencode";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      let
      in
      {
        package =
          mkOpt types.package inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
            "The package to use for opencode";

        settings = {
          theme = mkOpt types.str "system" "The theme to use in opencode";
        };
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      let
        configFile =
          {
            "$schema" = "https://opencode.ai/config.json";
            inherit (cfg.settings) theme;
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
          }
          |> (pkgs.formats.json { }).generate "opencode.jsonc";

        wrapped = (
          inputs.wrappers.lib.wrapPackage {
            inherit pkgs;
            inherit (cfg) package;

            env.OPENCODE_CONFIG = configFile;
          }
        );
      in
      {
        environment.systemPackages = [
          wrapped
        ];

        environment.shellAliases = {
          oc = wrapped;
        };
      };
  };
}
