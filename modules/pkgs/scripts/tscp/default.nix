{ self, ... }:

{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.tscp = self.lib.nushellScript {
        inherit pkgs;
        name = "tscp";
        packages = with pkgs; [
          pv
          gnutar
          openssh
        ];
        text = lib.readFile ./main.nu;
      };
    };
}
