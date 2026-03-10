{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.lazygit";

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          programs.lazygit.settings = lib.mkDefault {
            gui = {
              # Hide some UI elements
              showRandomTip = false;
              showBottomLine = false;
              showCommandLog = false;
              showPanelJumps = false;

              # Spinner from helix
              spinner = {
                frames = [
                  "⣾"
                  "⣽"
                  "⣻"
                  "⢿"
                  "⡿"
                  "⣟"
                  "⣯"
                  "⣷"
                ];
                rate = 80;
              };
            };
            git.pagers = [
              { externalDiffCommand = "${lib.getExe pkgs.difftastic} --color=always --display=inline"; }
            ];
            update.method = "never";
            notARepository = "quit";
            promptToReturnFromSubprocess = false;
          };
        };
      };
  };
}
