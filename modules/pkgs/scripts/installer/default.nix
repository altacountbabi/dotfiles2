{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "installer" {
    path = "installer";

    opts =
      {
        config,
        mkOpt,
        types,
        ...
      }:
      {
        host =
          mkOpt (types.nullOr types.str) config.networking.hostName
            "The host to automatically pick in the installer";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        imports = with self.nixosModules; [
          copy-config
          skip-getty
        ];

        prefs.skip-getty.user = "root";

        disko.devices = lib.mkForce { };

        prefs.autostart-shell = [
          (
            let
              exe = self.packages.${pkgs.stdenv.hostPlatform.system}.installer |> lib.getExe;
              host = lib.optionalString (cfg.host != null) "--host ${cfg.host}";
            in
            "${exe} ${host} ${config.prefs.user.home}/conf"
          )
        ];
      };
  };

  perSystem =
    { pkgs, lib, ... }:
    {
      packages.installer = self.lib.nushellScript {
        inherit pkgs;
        name = "installer";
        packages = [
          pkgs.nushell
          pkgs.jujutsu
          self.packages.${pkgs.stdenv.hostPlatform.system}.disko
        ];
        text = lib.readFile ./main.nu;
      };

      # Perlless disko
      packages.disko = inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (
        prev:
        let
          inherit (pkgs)
            stdenv
            path
            nix
            coreutils
            xcp
            ;
          versionInfo = import "${inputs.disko.outPath}/version.nix";
          diskoVersion = versionInfo.version + (lib.optionalString (!versionInfo.released) "-dirty");
        in
        {
          installPhase = ''
            mkdir -p $out/bin $out/share/disko
            cp -r install-cli.nix cli.nix default.nix disk-deactivate lib $out/share/disko

            scripts=(disko)
            ${lib.optionalString (!stdenv.isDarwin) ''
              scripts+=(disko-install)
            ''}

            for i in "''${scripts[@]}"; do
              sed -e "s|libexec_dir=\".*\"|libexec_dir=\"$out/share/disko\"|" "$i" > "$out/bin/$i"
              chmod 755 "$out/bin/$i"
              wrapProgram "$out/bin/$i" \
                --set DISKO_VERSION "${diskoVersion}" \
                --prefix NIX_PATH : "nixpkgs=${path}" \
                --prefix PATH : ${
                  lib.makeBinPath [
                    nix
                    coreutils
                    xcp
                  ]
                }
            done
          '';
        }
      );
    };
}
