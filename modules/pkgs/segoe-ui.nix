{
  perSystem =
    { pkgs, ... }:
    {
      packages.segoe-ui = pkgs.stdenvNoCC.mkDerivation {
        pname = "segoe-ui";
        version = "unstable-2025-01-16";

        src = pkgs.fetchurl {
          url = "https://aka.ms/segoeuifont";
          hash = "sha256-g8ZnGi6JHaijAy0uCv+ZqFktMlegbJQ+VWwzIC8oA3Q=";
          curlOptsList = [
            "-L"
            "-H"
            "Accept:application/octet-stream"
          ];
        };

        unpackPhase = ''
          ${pkgs.unzip}/bin/unzip $src -d .
        '';

        installPhase = ''
          mkdir -p $out/share/fonts/ttf
          mv *.ttf $out/share/fonts/ttf
        '';

        meta = with pkgs.lib; {
          description = "Segoe UI font";
          platforms = platforms.all;
        };
      };
    };
}
