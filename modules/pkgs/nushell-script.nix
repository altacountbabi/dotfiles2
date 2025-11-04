{
  flake.lib.nushellScript =
    {
      pkgs,

      name,
      text,
      packages ? [ ],
    }:
    let
      inherit (pkgs) lib;
      path = lib.makeBinPath packages;
    in
    pkgs.writeTextFile {
      inherit name;
      destination = "/bin/${name}";
      executable = true;
      text = # nushell
        ''
          #!${pkgs.nushell |> lib.getExe}
          $env.PATH = "${path}"

          ${text}
        '';
    };
}
