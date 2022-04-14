{
  description = "Super Mario 64";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
  };

  outputs = {self, nixpkgs}:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      baseroms = {
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
      hd_mario_model = pkgs.fetchurl {
        url = "http://sm64pc.info/forum/download/file.php?id=19";
        hash = "sha256-lsCFyblsg+hWWqoM9j8fv904D+FZ444Jq9++BizsEnM=";
        name = "hd-mario-model.7z";
      };
      hd_bowser_model = pkgs.fetchurl {
        url = "http://sm64pc.info/forum/download/file.php?id=53";
        hash = "sha256-3pbSbG/dLxqNUIz/MlS8IBvYXdl7yb6N9pID/GtdS4A=";
        name = "hd-bowser-model.zip";
      };
      
      sm64pc = {rom_version ? "us", texture_pack ? null, options ? []}: if texture_pack == null then pkgs.stdenv.mkDerivation rec {
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
            p7zip
            unzip
            which
          ];

          src = pkgs.fetchFromGitHub {
            owner = "AloXado320";
            repo = "sm64ex-alo";
            rev = "cfec4721aeebbfe905b210825418547e12d2d171";
            hash = "sha256-NHiVkNTy0vVtXjOwbqyyh9b0uIpY/d7nbunPVlhPUI0";
          };

          patches = [
            #(src + "/enhancements/60fps_ex.patch")
          ];

          preBuild = ''
            patchShebangs extract_assets.py
            ln -s ${builtins.getAttr rom_version baseroms} ./baserom.${rom_version}.z64

            # HD Mario
            7z x -aoa ${hd_mario_model}
            cp -rv "HD Mario Model"/actors/* actors/

            # HD Bowser
            unzip -d actors -o ${hd_bowser_model}

            # circumvent bug in tools/mkzip.py
            find . -type d,f  -exec touch -m -d '1/1/2000' {} +
          '';

          makeFlags = [
            "VERSION=${rom_version}"
            "EXTERNAL_DATA=1"
            "BASEDIR=../res"
          ] ++ options;

          installPhase = ''
            mkdir -p $out/bin
            cp -v ./build/${rom_version}_pc/sm64.${rom_version}.f3dex2e $out/bin/${pname}
            cp -rv ./build/res $out/ 
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
        } else let 
          base = sm64pc {inherit rom_version options;};
        in pkgs.stdenv.mkDerivation rec {
          pname = "${base.pname}-tp_${texture_pack}";
          version = "git";
          src = builtins.getAttr texture_pack {
            reloaded = pkgs.fetchFromGitHub {
              owner = "GhostlyDark";
              repo = "SM64-Reloaded";
              rev = "8df2a347ef98ef81aaa86274f4f92308520f5edb";
              hash = "sha256-X0bg9PGd5+rUJ9pAkxqwF8adUhs7rtQrVoxMBvj6BcY=";
            };
          };
          
          nativeBuildInputs = with pkgs; [
            copyDesktopItems
            makeWrapper
          ];

          installPhase = ''
            mkdir -p $out
            makeWrapper ${base}/bin/${base.pname} $out/bin/${pname} --add-flags "--gamedir ../../$(echo $src|cut -d'/' -f4-)"
          '';
        };
    in {
      packages.x86_64-linux.default = sm64pc {texture_pack = "reloaded"; options = ["HIGH_FPS_PC=1"];};
      defaultPackage.x86_64-linux = sm64pc {};
      packages.x86_64-linux.sm64pc_us = sm64pc {rom_version = "us";};
      packages.x86_64-linux.sm64pc_eu = sm64pc {rom_version = "eu";};
      packages.x86_64-linux.sm64pc_jp = sm64pc {rom_version = "jp";};
      packages.x86_64-linux.sm64pc_sh = sm64pc {rom_version = "sh";};
    };
}
