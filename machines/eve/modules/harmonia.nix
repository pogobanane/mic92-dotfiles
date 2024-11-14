{ config, inputs, ... }:
{
  imports = [ inputs.harmonia.nixosModules.harmonia ];
  services.harmonia-dev.enable = true;
  services.harmonia-dev.signKeyPaths = [ config.sops.secrets.harmonia-key.path ];

  nix.settings.allowed-users = [ "harmonia" ];

  services.nginx.virtualHosts."cache.thalheim.io" = {
    useACMEHost = "thalheim.io";
    forceSSL = true;

    # when using http2 we actually see worse throughput,
    # because it only uses a single tcp connection,
    # which pins nginx to a single core.
    http2 = false;

    locations."/".extraConfig = ''
      proxy_pass http://127.0.0.1:5000;
      proxy_set_header Host $host;
      proxy_redirect http:// https://;
      proxy_http_version 1.1;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;

      zstd on;
      zstd_types application/x-nix-archive;
    '';
  };

  # use more cores for compression
  services.nginx.appendConfig = ''
    worker_processes auto;
  '';
}
