{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "ssh";

    opts =
      { mkOpt, types, ... }:
      {
        pubKeys = mkOpt (types.listOf types.str) [ ] "List of public ssh keys to authorize";
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
        users.users.${config.prefs.user.name}.openssh.authorizedKeys.keys = cfg.pubKeys;

        services.openssh = {
          settings.PasswordAuthentication = lib.mkDefault ((lib.length cfg.pubKeys) != 0);
        };

        systemd.user.services.ssh-agent = {
          description = "SSH key agent";
          wantedBy = ["default.target"];
          serviceConfig = {
            Type = "simple";
            Environment = "SSH_AUTH_SOCK=%t/ssh-agent.sock";
            ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
          };
        };

        environment.shellInit = # bash
          ''
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.sock"
          '';

        programs.nushell.extraConfig = # nu
          ''
            $env.SSH_AUTH_SOCK = $env.XDG_RUNTIME_DIR | path join "ssh-agent.sock"
          '';
      };
  };
}
