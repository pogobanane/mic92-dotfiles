{ pkgs, ... }: {
  services.samba = {
    enable = true;
    package = pkgs.samba;
    extraConfig = ''
      workgroup = WORKGROUP
      netbios name = MATCHBOX
      server string = Raspberry Pi
      hosts allow = 192.168.178.0/255.255.255.0 fdf7:2de6:251f:1::/64
      interfaces = eth*
      map to guest = Bad User
      max log size = 50
      dns proxy = no
      security = user

      [global]
        syslog only = yes
    '';
    shares.public = {
      comment = "Netzlaufwerk";
      path = "/mnt/hdd/public";
      public = "yes";
      "only guest" = "yes";
      "create mask" = "0644";
      "directory mask" = "2777";
      writable = "yes";
      browseable = "yes";
      printable = "no";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/spool/samba 1777 root root -"
  ];

  networking.firewall.allowedTCPPorts = [
    139
    445 # smbd
  ];

  networking.firewall.allowedUDPPorts = [
    137
    138 # nmbd
  ];
}
