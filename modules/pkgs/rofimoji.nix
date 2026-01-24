{ self, inputs, ... }:

{
  perSystem =
    { pkgs, ... }:
    let
      emojis = builtins.fetchurl {
        url = "https://gist.githubusercontent.com/bluelovers/9e6cfa68dc7da23fa75f023b67fe0dd1/raw/ac8dde8a374066bcbcf44a8296fc0522c7392244/emojis.json";
        sha256 = "sha256-7RJ8AeP3U695ztU118hF3Om9EynpBAcQ17njbZQjGFw=";
      };
      processedEmojis = self.lib.nushellRun {
        inherit pkgs;
        name = "rofimoji-twemoji";
        env = {
          inherit emojis;
        };
        text = # nushell
          ''
            let emojis = open $env.emojis
              | get emojis
              | where ($it.name | is-not-empty)
              | where ($it.order | is-not-empty)
              | update order {|x| $x.order | into int }
              | sort-by order

            let text = $emojis | each {|x|
              let shortname = $x.shortname | str trim -c ":" 

              if ($x.name == $shortname) {
                $"($x.emoji) ($x.name)"
              } else {
                $"($x.emoji) ($x.name) ($shortname)"
              }
            }

            $text | save $env.out
          '';
      };
    in
    {
      packages.rofimoji = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;

        package = pkgs.rofimoji;
        flags = {
          "--files" = toString processedEmojis;
          "--skin-tone" = "neutral";
          "--keybinding-copy" = "Alt+c";
          "--action" = "clipboard";
          "--prompt" = ">";
          "--selector-args" = "-matching normal"; # fuzzy matching in rofi isn't that great with thousands of items
        };
      };
    };
}
