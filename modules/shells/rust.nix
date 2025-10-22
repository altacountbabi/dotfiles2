{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) mkShell;
    in
    {
      devShells.rust = mkShell {
        packages = with pkgs; [
          rustc
          cargo
          clippy
          rust-analyzer
        ];
      };
    };
}
