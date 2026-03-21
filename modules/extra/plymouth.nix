{
  flake.nixosModules.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      boot = lib.mkIf config.boot.plymouth.enable {
        plymouth.package =
          (pkgs.plymouth.override {
            systemd = config.boot.initrd.systemd.package;
          }).overrideAttrs
            {
              src = pkgs.fetchFromGitLab {
                domain = "gitlab.freedesktop.org";
                owner = "plymouth";
                repo = "plymouth";
                rev = "082c606b4306afc7f16fdddd0909ef006e812f98";
                hash = "sha256-8HIWYqzR+ovxlAmch0SvQdFFm9t1aw+h9jam/mSJx9E=";
              };
            };

        consoleLogLevel = 0;
        initrd.verbose = false;
        kernelParams = [
          "loglevel=3"
          "quiet"
          "splash"

          "rd.systemd.show_status=false"
          "rd.udev.log_level=3"
          "udev.log_priority=3"
        ];
      };
    };
}
