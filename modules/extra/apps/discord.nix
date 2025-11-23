{ inputs, ... }:

{

  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        apps.discord = {
          package = mkOpt types.package (inputs.nixcord.packages.${pkgs.stdenv.hostPlatform.system}.discord.override {
            withVencord = true;
            withOpenASAR = true;
            commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
          }) "The package to use for discord";
          autostart = mkOpt types.bool false "Whether to automatically start discord at startup";
        };
      };
    };

  flake.nixosModules.discord =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      openASARSettings =
        {
          DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
          trayBalloonShown = false;
          # TODO: Use this when theming
          # BACKGROUND_COLOR = "";
          # TODO: This is a useful feature but it doesn't work with the proot bind mounts
          SKIP_HOST_UPDATE = true;
        }
        |> (pkgs.formats.json { }).generate "openasar-settings.json";

      vencordSettings =
        {
          autoUpdate = false;
          autoUpdateNotification = false;
          notifyAboutUpdates = false;

          disableMinSize = true;
          enableReactDevtools = false;

          useQuickCSS = true;

          frameless = true;
          transparent = false;

          plugins = {
            BetterGifPicker.enabled = true;
            BetterSettings = {
              disableFade = true;
              eagerLoad = true;
              enabled = true;
              organizeMenu = true;
            };
            BetterUploadButton.enabled = true;
            ChatInputButtonAPI.enabled = true;
            CommandsAPI.enabled = true;
            ConsoleJanitor = {
              disableLoggers = true;
              disableNoisyLoggers = false;
              disableSpotifyLogger = true;
              enabled = true;
              whitelistedLoggers = "GatewaySocket; Routing/Utils";
            };
            CrashHandler = {
              attemptToNavigateToHome = false;
              attemptToPreventCrashes = true;
              enabled = true;
            };
            Experiments = {
              enabled = true;
              toolbarDevMenu = false;
            };
            FakeNitro = {
              disableEmbedPermissionCheck = false;
              emojiSize = 48;
              enableEmojiBypass = true;
              enableStickerBypass = true;
              enableStreamQualityBypass = true;
              enabled = true;
              hyperLinkText = "{{NAME}}";
              stickerSize = 160;
              transformCompoundSentence = false;
              transformEmojis = true;
              transformStickers = true;
              useHyperLinks = true;
            };
            FavoriteGifSearch = {
              enabled = true;
              searchOption = "hostandpath";
            };
            ImageZoom = {
              enabled = true;
              invertScroll = true;
              nearestNeighbour = true;
              saveZoomValues = true;
              size = 200;
              square = true;
              zoom = 1;
              zoomSpeed = 0.5;
            };
            LoadingQuotes = {
              additionalQuotes = "";
              additionalQuotesDelimiter = "|";
              enableDiscordPresetQuotes = false;
              enablePluginPresetQuotes = true;
              enabled = true;
              replaceEvents = true;
            };
            MemberListDecoratorsAPI.enabled = true;
            MessageAccessoriesAPI.enabled = true;
            MessageClickActions = {
              enableDeleteOnClick = false;
              enableDoubleClickToEdit = true;
              enableDoubleClickToReply = true;
              enabled = true;
              requireModifier = false;
            };
            MessageDecorationsAPI.enabled = true;
            MessageEventsAPI.enabled = true;
            MessageLatency = {
              detectDiscordKotlin = true;
              enabled = true;
              latency = 2;
              showMillis = false;
            };
            MessageLogger = {
              collapseDeleted = false;
              deleteStyle = "text";
              enabled = true;
              ignoreBots = false;
              ignoreChannels = "";
              ignoreGuilds = "";
              ignoreSelf = false;
              ignoreUsers = "";
              inlineEdits = true;
              logDeletes = true;
              logEdits = true;
            };
            MessagePopoverAPI.enabled = true;
            MessageUpdaterAPI.enabled = true;
            NoTrack = {
              disableAnalytics = true;
              enabled = true;
            };
            NoTypingAnimation.enabled = true;
            NoUnblockToJump.enabled = true;
            OnePingPerDM = {
              allowEveryone = false;
              allowMentions = false;
              channelToAffect = "both_dms";
              enabled = true;
            };
            PermissionFreeWill = {
              enabled = true;
              lockout = true;
              onboarding = true;
            };
            PermissionsViewer = {
              defaultPermissionsDropdownState = false;
              enabled = true;
              permissionsSortOrder = 0;
            };
            ServerListAPI.enabled = true;
            Settings = {
              enabled = true;
              settingsLocation = "aboveNitro";
            };
            ShowHiddenChannels = {
              enabled = true;
              hideUnreads = true;
              showHiddenChannels = true;
              showMode = 0;
            };
            SilentTyping = {
              contextMenu = true;
              enabled = true;
              isEnabled = true;
              showIcon = false;
            };
            SpotifyCrack = {
              enabled = true;
              keepSpotifyActivityOnIdle = false;
              noSpotifyAutoPause = true;
            };
            SupportHelper.enabled = true;
            ThemeAttributes.enabled = true;
            UserSettingsAPI.enabled = true;
            ValidUser.enabled = true;
            ViewRaw = {
              clickMethod = "Left";
              enabled = true;
            };
            WebContextMenus.enabled = true;
            WebScreenShareFixes.enabled = true;
            YoutubeAdblock.enabled = true;
            ExpressionCloner.enabled = true;
            BadgeAPI.enabled = true;
          };
        }
        |> (pkgs.formats.json { }).generate "vencord-settings.json";

      # FIXME: Replace proot with setting xdg home to /etc/xdg here and write configs with `environment.etc`
      package = config.prefs.apps.discord.package;
      wrapped = pkgs.stdenv.mkDerivation {
        pname = "discord-wrapped";
        inherit (package) version;

        buildInputs = [
          pkgs.proot
          package
        ];

        dontUnpack = true;
        dontBuild = true;

        installPhase =
          let
            home = "/home/${config.prefs.user.name}";
          in
          # bash
          ''
            mkdir -p $out/bin
            cat > $out/bin/discord <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.proot}/bin/proot \
              -b ${openASARSettings}:${home}/.config/discord/settings.json \
              -b ${vencordSettings}:${home}/.config/Vencord/settings/settings.json \
              ${pkgs.discord}/bin/discord --no-sandbox "\$@"
            EOF
            chmod +x $out/bin/discord
          '';

        inherit (package) meta;
      };
    in
    {
      environment.systemPackages = [
        wrapped
      ];

      prefs.autostart.apps.discord = lib.mkIf config.prefs.apps.discord.autostart config.prefs.apps.discord.package;
    };
}
