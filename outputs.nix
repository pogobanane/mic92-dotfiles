{ self
, nixpkgs
, nixos-hardware
, sops-nix
, nur
, home-manager
, retiolum
, flake-utils
, flake-registry
, bme680-mqtt
, nix-ld
, envfs
, doom-emacs
, emacs-overlay
, nix-darwin
, vmsh
, fenix
, nixos-generators
}:
(flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    nurPkgs = import nur {
      inherit pkgs;
      nurpkgs = pkgs;
    };
  in
  {
    devShell = pkgs.callPackage ./shell.nix {
      inherit (sops-nix.packages.${pkgs.system}) sops-import-keys-hook;
    };
    apps.irc-announce = {
      type = "app";
      path = "${nurPkgs.repos.mic92.irc-announce}/bin/irc-announce";
    };

    apps.hm-build = {
      type = "app";
      program = toString (pkgs.writeScript "hm-build" ''
        #!${pkgs.runtimeShell}
        set -eu -o pipefail
        export PATH=${pkgs.lib.makeBinPath [ pkgs.git pkgs.coreutils pkgs.nixFlakes pkgs.jq ]}
        declare -A profiles=(["turingmachine"]="desktop" ["eddie"]="desktop" ["eve"]="eve" ["bernie"]="bernie", ["grandalf"]="common-aarch64", ["yasmin"]="common-aarch64")
        profile=''${profiles[$HOSTNAME]:-common}
        flake=$(nix flake metadata --json ${self} | jq -r .url)
        set -x
        nix build "$@" --no-link --show-trace --json "${self}#hmConfigurations.''${profile}.activationPackage" "$@" | jq -r '.[] | .outputs | .out'
      '');
    };
    apps.hm-switch = {
      type = "app";
      program = toString (pkgs.writeScript "hm-switch" ''
        #!${pkgs.runtimeShell}
        export PATH=${pkgs.lib.makeBinPath [ pkgs.nix pkgs.coreutils ]}
        set -eu -o pipefail -x
        cd ${./.}
        oldpath=$(realpath /nix/var/nix/profiles/per-user/$USER/home-manager)
        path=$(nix run .#hm-build -- "$@")
        nix store diff-closures "$oldpath" "$path"
        $path/activate
      '');
    };
  })) // {
  nixosConfigurations = import ./nixos/configurations.nix {
    nixosSystem = nixpkgs.lib.nixosSystem;
    inherit
      nur
      nixpkgs
      home-manager
      sops-nix
      retiolum
      nixos-hardware
      flake-registry
      bme680-mqtt
      envfs
      nix-ld
      vmsh;
  };

  # nix build '.#kexec'
  packages.x86_64-linux.kexec = nixos-generators.nixosGenerate {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./nixos/images/kexec.nix ];
    format = "kexec";
  };

  hmConfigurations = import ./nixpkgs-config/homes.nix {
    inherit self nixpkgs home-manager nur doom-emacs emacs-overlay;
  };

  hydraJobs = (nixpkgs.lib.mapAttrs' (name: config: nixpkgs.lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel) self.nixosConfigurations)
              // (nixpkgs.lib.mapAttrs' (name: config: nixpkgs.lib.nameValuePair "home-manager-${name}" config.activation-script) self.hmConfigurations);
}
