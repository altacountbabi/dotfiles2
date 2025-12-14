{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.tscp = self.lib.nushellScript {
        inherit pkgs;
        name = "tscp";
        packages = with pkgs; [
          pv
          gnutar
          openssh
        ];
        text = builtins.readFile ./main.nu;
      };
    };
}
