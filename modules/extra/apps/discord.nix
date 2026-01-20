{ inputs, ... }:

{
  flake.nixosModules.discord =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.discord;
      inherit (lib) mkOpt types mkDefault;

      json = (pkgs.formats.json { });
    in
    {
      options.programs.discord = {
        package = mkOpt types.package (
          inputs.nixcord.packages.${pkgs.stdenv.hostPlatform.system}.discord.override
          {
            withVencord = true;
            withOpenASAR = true;
            commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
          }
        ) "The package to use for discord";
        autostart = mkOpt types.bool false "Whether to automatically start discord at startup";

        openASARSettings = mkOpt (types.attrsOf json.type) { } "OpenASAR settings";
        vencordSettings = mkOpt (types.attrsOf json.type) { } "Vencord settings";
      };

      config = {
        programs.discord = {
          openASARSettings = {
            DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = mkDefault true;
            trayBalloonShown = mkDefault false;
            BACKGROUND_COLOR = mkDefault "${config.prefs.theme.colors.base}";
            openasar.setup = true;
          };

          vencordSettings = {
            autoUpdate = mkDefault false;
            autoUpdateNotification = mkDefault false;
            notifyAboutUpdates = mkDefault false;

            disableMinSize = mkDefault true;
            enableReactDevtools = mkDefault false;

            useQuickCSS = mkDefault true;

            frameless = mkDefault true;
            transparent = mkDefault false;

            plugins = mkDefault {
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
          };
        };

        environment.systemPackages = [
          cfg.package
        ];

        prefs.autostart = lib.mkIf cfg.autostart [ cfg.package ];

        prefs.merged-configs = with config.prefs.user; {
          openASAR = {
            path = "${home}/.config/discord/settings.json";
            overlay = cfg.openASARSettings;
          };
          vencord = {
            path = "${home}/.config/Vencord/settings/settings.json";
            overlay = cfg.vencordSettings;
            formatting.indent = 4;
          };
        };
      };
    };
}
