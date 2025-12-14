{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-on-droid-switch = self.lib.nushellScript {
        inherit pkgs;
        name = "switch";
        packages = [
          pkgs.nix-output-monitor
        ];
        text = builtins.readFile ./main.nu;
      };
    };
}
