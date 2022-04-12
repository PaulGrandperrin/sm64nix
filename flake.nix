{
  description = "Super Mario 64";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = {self, nixpkgs}:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      baserom = {
        us = pkgs.fetchurl {
          url = "https://archive.org/download/Nintendo64FullRegionalUploadByGhostware/Super%20Mario%2064%20%28USA%29.z64";
          hash = "sha256-F84Hc0PGEz+Mny1tbZpKtiyM0qpXxArqH0kLTIuyHZE=";
          name = "super-mario-64-us.z64";
        }; # lftp -c "torrent 'magnet:?xt=urn:btih:ca77720f1a9be2086d9b71616b2299570290a237&dn=super-mario-64-usa&tr=http%3A%2F%2Fbt1.archive.org%3A6969%2Fannounce&tr=http%3A%2F%2Fbt2.archive.org%3A6969%2Fannounce&ws=https%3A%2F%2Farchive.org%2Fdownload%2F&ws=http%3A%2F%2Fia903207.us.archive.org%2F20%2Fitems%2F'"

        eu = pkgs.fetchurl {
          url = "https://archive.org/download/Nintendo64FullRegionalUploadByGhostware/Super%20Mario%2064%20%28Europe%29%20%28En%2CFr%2CDe%29.z64";
          hash = "sha256-x5Ll68ujTI2YwMRM8pdHyO5n57kH/Md4h/n/JSP4BXI=";
          name = "super-mario-64-eu.z64";
        };
        jp = pkgs.fetchurl {
          url = "https://archive.org/download/Nintendo64FullRegionalUploadByGhostware/Super%20Mario%2064%20%28Japan%29.z64";
          hash = "sha256-nPeoDbMhsHqNRh/lNsAsh7dBJDOVOJHN7JGRv60tsxc=";
          name = "super-mario-64-jp.z64";
        };
        sh = pkgs.fetchurl {
          url = "https://archive.org/download/Nintendo64FullRegionalUploadByGhostware/Super%20Mario%2064%20%28Japan%29%20%28Rev%20A%29%20%28Shindou%20Edition%29.z64";
          hash = "sha256-+IB7XijxsaMcXTZ10j7Oc/lJzLVT3LsHlyZmoedq36I=";
          name = "super-mario-64-sh.z64";
        };
      };
      sm64pc = {rom_version ? "us"}: pkgs.stdenv.mkDerivation rec {
          pname = "sm64pc_${rom_version}";
          version = "git";

          buildInputs = with pkgs; [
            audiofile
            SDL2
            libusb1
            glfw3
            libgcc
            xorg.libX11
            xorg.libXrandr
            libpulseaudio
            alsaLib
            glfw
            libGL
            # capstone
          ];

          nativeBuildInputs = with pkgs; [
            copyDesktopItems
            unixtools.hexdump
            pkg-config
            gnumake
            python3
            (writeShellApplication {name = "git"; text = "";}) # HACK: the makefile tries to extract the version using git, but the .git folder is not available
          ];

          src = pkgs.fetchFromGitHub {
            owner = "sm64pc";
            repo = "sm64ex";
            rev = "db9a6345baa5acb41f9d77c480510442cab26025";
            hash = "sha256-q7JWDvNeNrDpcKVtIGqB1k7I0FveYwrfqu7ZZK7T8F8=";
          };

          preBuild = ''
            patchShebangs extract_assets.py
            ln -s ${builtins.getAttr rom_version baserom} ./baserom.${rom_version}.z64
          '';

          makeFlags = [ "VERSION=${rom_version}" ];

          installPhase = ''
            mkdir -p $out/bin
            cp ./build/${rom_version}_pc/sm64.${rom_version}.f3dex2e $out/bin/sm64pc_${rom_version}
            copyDesktopItems
          '';

          desktopItems = [(pkgs.makeDesktopItem {
              name = "sm64pc_${rom_version}";
              exec = "sm64pc_${rom_version}";
              desktopName = "Super Mario 64 (${rom_version})";
              genericName = "Super Mario 64 (${rom_version})";
              comment = meta.description;
              categories = [ "Game" ];
            })];

          meta = with pkgs.stdenv.lib; {
            description = "Super Mario 64 (${rom_version}), decompiled from N64 version and ported to PC";
            homepage = "https://github.com/sm64pc/sm64ex";
          };
        };
    in {
      packages.x86_64-linux.default = sm64pc;
      packages.x86_64-linux.sm64pc_us = sm64pc {rom_version = "us";};
      packages.x86_64-linux.sm64pc_eu = sm64pc {rom_version = "eu";};
      packages.x86_64-linux.sm64pc_jp = sm64pc {rom_version = "jp";};
      packages.x86_64-linux.sm64pc_sh = sm64pc {rom_version = "sh";};
    };
}
