{
  perSystem =
    { pkgs, ... }:
    {
      packages.docs-rs-mcp = pkgs.buildNpmPackage rec {
        pname = "docs-rs-mcp";
        version = "1.0.1";

        src = pkgs.fetchFromGitHub {
          owner = "nuskey8";
          repo = "docs-rs-mcp";
          rev = "v${version}";
          hash = "sha256-fKtDrTPDDgRk6ssWLk79TkQ1KzaAIVLI0Vo9deleTjc=";
        };

        npmDepsHash = "sha256-IFhz3DfAyWQbnaW8dC7XLClfxeFbY4b9FuT/O+YRXkI=";

        meta = {
          description = "An MCP server that enables searching for Rust crates and their documentation from docs.rs";
          homepage = "https://github.com/nuskey8/docs-rs-mcp";
          license = pkgs.lib.licenses.mit;
          mainProgram = "docs-rs-mcp";
        };
      };
    };
}
