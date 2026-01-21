{ self, ... }:

{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.nix-on-droid-switch = self.lib.nushellScript {
        inherit pkgs;
        name = "switch";
        packages = [
          pkgs.nix-output-monitor
        ];
        text = lib.readFile ./main.nu;
      };
    };
}
