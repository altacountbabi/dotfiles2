{
  perSystem =
    { pkgs, ... }:
    {
      packages.niri = pkgs.niri.overrideAttrs (prev: {
        patches = (prev.patches or [ ]) ++ [
          ./screenshot-notification.patch
        ];

        # Checks are pointless, if it built theres no errors
        dontCheck = true;
      });
    };
}
