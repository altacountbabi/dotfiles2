{
  flake.overlays.desktop-files = final: prev: {
    htop = prev.htop.overrideAttrs {
      postInstall =
        (prev.postInstall or "")
        + ''
          rm -rf $out/share/applications
        '';
    };
    btop = prev.btop.overrideAttrs {
      postInstall =
        (prev.postInstall or "")
        + ''
          rm -rf $out/share/applications
        '';
    };
    helix = prev.helix.overrideAttrs {
      postInstall =
        (prev.postInstall or "")
        + ''
          rm -rf $out/share/applications
        '';
    };
  };
}
