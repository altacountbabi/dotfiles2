{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.rofi-fd = self.lib.nushellScript {
        inherit pkgs;
        name = "rofi-fd";
        packages = with pkgs; [
          fd
          xdg-utils
        ];
        text = builtins.readFile ./main.nu;
      };
    };
}
