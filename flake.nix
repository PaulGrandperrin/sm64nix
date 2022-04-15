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
        url = "http://sm64pc.info/downloads/model_pack/hd_mario_v2.zip";
        hash = "sha256-wE3jQkYj2JOE+TMUtLuH/zYmEGddM1WvUsMn8lBg4pQ=";
        name = "hd_mario.zip";
      };
      hd_bowser_model = pkgs.fetchurl {
        url = "http://sm64pc.info/downloads/model_pack/hd_bowser.zip";
        hash = "sha256-4ONQH00AC4QGzFyNnPMEI+HfshnoKswKaMyoPE2sPzo=";
        name = "hd_bowser.zip";
      };
      hd_koopa_model = pkgs.fetchurl {
        url = "http://sm64pc.info/downloads/model_pack/hd_koopa_the_quick.zip";
        hash = "sha256-Lhz3LPX0sSVzAuSZE96i5ojTXmdN0px+ErcNSLK94lg=";
        name = "hd_koopa.zip";
      };
      hd_peach_model = pkgs.fetchurl {
        url = "http://sm64pc.info/downloads/model_pack/hd_peach_v2.zip";
        hash = "sha256-Hp2rPfMkUvenQqElCg/CXEW4iFeaAu7x95NIaL4eC2E=";
        name = "hd_peach.zip";
      };
      hd_peach_textures = pkgs.runCommand "hd_peach_textures" {
        nativeBuildInputs = with pkgs; [unzip];
      } ''
        unzip ${hd_peach_model}
        unzip './~hd_peach_v2.zip'
        mkdir $out
        mv -v gfx $out/
      '';
      
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
            vim # for ex
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

            # HD models
            unzip -o ${hd_mario_model}
            unzip -o ${hd_bowser_model}
            unzip -o ${hd_koopa_model}
            unzip -o ${hd_peach_model}

            # patch in Koopa the quick
            ex actors/group14.h -c 'normal G' -c '?#endif' -c 'normal O#include "koopa/geo_header.h"' +wq
            # patch in Koopa's shell
            ex actors/common0.h -c 'normal G' -c '?#endif' -c 'normal O#include "koopa_shell/geo_header.h"' +wq

            # patch in Peach
            ex actors/group10.h -c 'normal G' -c '?#endif' -c 'normal O#include "peach/geo_header.h"' +wq

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
        in pkgs.symlinkJoin rec {
          name = "${base.pname}-tp_${texture_pack}-git";
          pname = "${base.pname}-tp_${texture_pack}";
          version = "git";
          src = builtins.getAttr texture_pack {
            reloaded = pkgs.fetchFromGitHub {
              owner = "GhostlyDark";
              repo = "SM64-Reloaded";
              rev = "8df2a347ef98ef81aaa86274f4f92308520f5edb";
              hash = "sha256-X0bg9PGd5+rUJ9pAkxqwF8adUhs7rtQrVoxMBvj6BcY=";
            };
            reloaded1080p = pkgs.fetchFromGitHub {
              owner = "GhostlyDark";
              repo = "SM64-Reloaded";
              rev = "3171815c4039a7a893a082593cb2f425fad6bc4a";
              hash = "sha256-WUTmCADuYJq1pDMQdMFHv3aHE2mlXvScLQkdW2Xhxv4=";
            };
          };
          paths = [hd_peach_textures src];
          
          nativeBuildInputs = with pkgs; [
            copyDesktopItems
            makeWrapper
          ];

          postBuild = ''
            mkdir -p $out
            makeWrapper ${base}/bin/${base.pname} $out/bin/${pname} --add-flags "--gamedir ../../$(echo $out|cut -d'/' -f4-)"
          '';
        };
    in {
      packages.x86_64-linux.default = sm64pc {texture_pack = "reloaded1080p"; options = ["HIGH_FPS_PC=1"];};
      defaultPackage.x86_64-linux = sm64pc {};
      packages.x86_64-linux.sm64pc_us = sm64pc {rom_version = "us";};
      packages.x86_64-linux.sm64pc_eu = sm64pc {rom_version = "eu";};
      packages.x86_64-linux.sm64pc_jp = sm64pc {rom_version = "jp";};
      packages.x86_64-linux.sm64pc_sh = sm64pc {rom_version = "sh";};
    };
}
