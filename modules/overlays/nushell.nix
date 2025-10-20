{
  flake.overlays.nushell = final: prev: {
    nushellScript =
      {
        name,
        text,
      }:
      final.writeTextFile {
        inherit name;
        destination = "/bin/${name}";
        executable = true;
        text = ''
          #!${final.nushell |> final.lib.getExe}

          ${text}
        '';
      };

  };
}
