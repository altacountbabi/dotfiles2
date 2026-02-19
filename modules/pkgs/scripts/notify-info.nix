{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.notify-info = self.lib.nushellScript {
        inherit pkgs;
        name = "notify-info";
        packages = with pkgs; [
          libnotify
          self.packages.${pkgs.stdenv.hostPlatform.system}.volume
        ];
        text = # nu
          ''
            let time = (date now | format date `%-I:%M`)
            let date = (date now | format date `%A, %d, %B`)
            let volume = (volume get)

            notify-send -t 5000 -e $"Time:\t($time)" $"Date:\t($date)\nVolume:\t($volume)%"
          '';
      };
    };
}
