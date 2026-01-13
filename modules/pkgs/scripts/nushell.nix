{
  flake.lib = rec {
    nushellScript =
      {
        pkgs,

        name,
        text,
        packages ? [ ],
        ...
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
            #!${lib.getExe pkgs.nushell}
            source ${./nushell-lib.nu}
            $env.PATH = $"${path}:($env.PATH | str join ":")"

            ${text}
          '';
      };

    nushellRun =
      {
        pkgs,
        packages ? [ ],
        env ? { },
        ...
      }@args:
      let
        name = args.name + "-builder";
        script = nushellScript (args // { inherit name; });
      in
      pkgs.runCommand name
        {
          buildInputs = packages;
          inherit env;
        }
        ''
          exec ${script}/bin/${name}
        '';
  };
}
