{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.cycle-sinks = self.lib.nushellScript {
        inherit pkgs;
        name = "cycle-sinks";
        packages = with pkgs; [
          pulseaudio
          libnotify
        ];
        text = # nushell
          ''
            let sinks = pactl -f json list sinks | from json
            let default_sink = pactl get-default-sink
            let next_sink = $sinks | where name != $default_sink | first

            let next_sink_name = $next_sink | get name

            pactl set-sink $next_sink_name
            notify-send "Audio" $"Switched to output \"($next_sink | get description)\""
          '';
      };
    };
}
