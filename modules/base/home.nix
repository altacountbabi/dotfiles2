{ inputs, ... }:

{
  flake.nixosModules.base =
    {
      config,
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
