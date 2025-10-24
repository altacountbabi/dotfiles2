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
        hjem =
          let
            username = config.prefs.user.name;
          in
          {
            linker = inputs.hjem.packages.${pkgs.system}.smfh;

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
