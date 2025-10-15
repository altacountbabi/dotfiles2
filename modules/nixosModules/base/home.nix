{ inputs, ... }:

{
  flake.nixosModules.base =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.hjem.nixosModules.default ];

      config = {
        environment.systemPackages = [
          inputs.hjem.packages.${pkgs.stdenv.system}.smfh
        ];

        hjem =
          let
            username = config.prefs.user.name;
          in
          {
            linker = inputs.hjem.packages.${pkgs.stdenv.system}.smfh;

            users.${username} = {
              enable = true;
              directory = "/home/${username}";
              user = username;
            };

            clobberByDefault = true;
          };
      };
    };
}
