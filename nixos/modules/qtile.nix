{ pkgs
, lib
, ...
}:
let
  pyEnv = pkgs.python3.withPackages (_p: [
    pkgs.python3.pkgs.qtile
    pkgs.python3.pkgs.iwlib
  ]);
in
{
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;
  fonts.enableDefaultPackages = true;

  security.polkit.enable = true;
  security.pam.services.swaylock = { };

  programs.dconf.enable = lib.mkDefault true;
  programs.xwayland.enable = lib.mkDefault true;

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "qtile";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # used in ping widget
  security.wrappers.fping = {
    source = "${pkgs.fping}/bin/fping";
    capabilities = "cap_net_raw+p";
    owner = "root";
    group = "root";
  };

  programs.wshowkeys.enable = true;

  environment.systemPackages = with pkgs; [
    qtile
    swaylock-effects # lockscreen
    pavucontrol
    swayidle
    rofi-wayland
    rofi-rbw
    gnome.eog
    libnotify
    mako # notifications
    kanshi # auto-configure display outputs
    wdisplays # buggy with qtile?
    wlr-randr
    wl-clipboard
    wev
    blueberry
    grim # screenshots
    wtype

    pavucontrol
    evince
    libnotify
    pamixer
    gnome.file-roller
    firefox-wayland
    chromium
    xdg-utils
    # polkit agent
    polkit_gnome

    # gtk3 themes
    gsettings-desktop-schemas

    # screen brightness
    brightnessctl

    # Here we but a shell script into path, which lets us start qtile.service (after importing the environment of the login shell).
    (pkgs.writeTextFile {
      name = "startqtile";
      destination = "/bin/startqtile";
      executable = true;
      text =
        let
          schema = pkgs.gsettings-desktop-schemas;
          datadir = "${schema}/share/gsettings-schemas/${schema.name}";
        in
        ''
          #! ${pkgs.bash}/bin/bash

          ${pkgs.rbw}/bin/rbw unlock
          if ssh-add -l | grep -q 'The agent has no identities.'; then
            ${pkgs.openssh}/bin/ssh-add
          fi
          export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
          # first import environment variables from the login manager
          systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY
          systemctl --user import-environment
          # then start the service
          exec systemctl --user start qtile.service
        '';
    })
  ];

  # for polkit
  environment.pathsToLink = [ "/libexec" ];

  qt.platformTheme = "qt5ct";

  # brightnessctl
  users.users.joerg.extraGroups = [ "video" ];

  systemd.user.targets.qtile-session = {
    description = "Qtile compositor session";
    documentation = [ "man:systemd.special(7)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  systemd.user.services.qtile = {
    description = "Qtile - Wayland window manager";
    documentation = [ "man:qtile(5)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    # We explicitly unset PATH here, as we want it to be set by
    # systemctl --user import-environment in startqtile
    environment.PATH = lib.mkForce null;
    environment.PYTHONPATH = lib.mkForce null;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pyEnv}/bin/qtile start -b wayland";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
