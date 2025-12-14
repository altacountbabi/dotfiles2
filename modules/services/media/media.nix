{ self, ... }:

{
  flake.nixosModules.media = {
    imports = with self.nixosModules; [
      jellyfin
      sonarr
    ];
  };
}
