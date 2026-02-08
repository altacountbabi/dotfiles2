{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    cfg = _: {
      imports = [
        inputs.sops.nixosModules.sops
      ];

      config = {
        sops = {
          defaultSopsFile = ../../secrets/secrets.yaml;
          age = {
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };
        };
      };
    };
  };
}
