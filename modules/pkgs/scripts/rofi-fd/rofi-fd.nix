{ self, ... }:

{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.rofi-fd = self.lib.nushellScript {
        inherit pkgs;
        name = "rofi-fd";
        packages = with pkgs; [
          fd
          xdg-utils
        ];
        text = lib.readFile ./main.nu;
      };
    };
}
