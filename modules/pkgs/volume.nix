{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.volume = self.lib.nushellScript {
        inherit pkgs;
        name = "volume";
        packages = with pkgs; [
          pamixer
          libnotify
        ];
        text = # nushell
          ''
            let id_path = "/tmp/volume_osd_id"

            def main [] {
              main get
            }

            def "main get" [] {
              if (pamixer --get-mute) == "true" {
                0
              } else {
                (pamixer --get-volume) | into int
              }
            }

            def "main mute" [] {
              pamixer --toggle-mute
              ui
            }

            def "main increase" [amount: int] {
              pamixer --unmute
              pamixer --increase $amount
              ui
            }

            def "main decrease" [amount: int] {
              pamixer --unmute
              pamixer --decrease $amount
              ui
            }

            def volume_bar [volume: int]: nothing -> string {
              let full = "●"
              let half = "◐"
              let empty = "○"

              0..9
              | each {|i|
                let threshold = $i * 10

                match $volume {
                  $volume if $volume >= $threshold + 10 => $full
                  $volume if $volume >= $threshold + 5 => $half
                  _ => $empty
                }
              }
              | str join ""
            }

            def ui [] {
              let volume = main get

              let id = if ($id_path | path exists) {
                open $id_path | into int
              } else {
                -1
              }

              let new_id = if $id != -1 {
                notify-send $"(volume_bar $volume) ($volume)%" -r $id -p
              } else {
                notify-send $"(volume_bar $volume) ($volume)%" -p 
              }

              $new_id | into string | save $id_path --force
            }
          '';
      };
    };
}
