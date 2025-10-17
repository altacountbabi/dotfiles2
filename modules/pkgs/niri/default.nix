{
  perSystem =
    { pkgs, ... }:
    {
      packages.niri = pkgs.niri.overrideAttrs (prev: {
        patches = (prev.patches or [ ]) ++ [
          ./screenshot-notification.patch
        ];
      });
    };
}
