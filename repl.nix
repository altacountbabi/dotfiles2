let
  pkgs = import <nixpkgs> { };
  iniFormat = pkgs.formats.iniWithGlobalSection { };
in
iniFormat.generate "mako-settings" { globalSection.foo = "baz"; }
