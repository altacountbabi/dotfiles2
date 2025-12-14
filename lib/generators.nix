_:

{
  hideDesktop =
    {
      pkgs,
      package,
    }:
    (pkgs.symlinkJoin {
      name = "${package.pname or package.name}-hidden";
      paths = [ package ];
      postBuild = ''
        rm -rf $out/share/applications/*.desktop
      '';
    });
}
