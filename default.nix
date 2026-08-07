{ pkgs ? import <nixpkgs> {} }:

let

  mountingScriptsVersion = "snapshot";
  mountingScriptsBuildPackages = with pkgs; [ gnumake gnutar shellcheck ];

  mountingScripts = pkgs.stdenv.mkDerivation {
    pname = "pixel-backup-gang";
    version = mountingScriptsVersion;

    src = ./.;

    buildInputs = mountingScriptsBuildPackages;

    buildPhase = ''
      make PBG_VERSION=${mountingScriptsVersion}
    '';

    installPhase = ''
      mkdir -p $out/share
      cp pixel-backup-gang-${mountingScriptsVersion}.tar.gz $out/share/pixel-backup-gang.tar.gz
    '';
  };

  # supported marlin OS builds, keyed by build id (ro.build.id). add an entry
  # here for another device/OS version - mkMarlinBuild below generates
  # everything else (kernel, factory extraction, repacked boot images) from it
  marlinBuildRegistry = {
    "QP1A.191005.007.A3" = {
      # git-describe hash from this build's own version string ("3.18.137-g72a7a64494e")
      kernelSrcRev = "72a7a64494e033f2213c9701dbf137d277bf2026";
      kernelSrcSha256 = "sha256-CdM0PkUGkm1SVAT/J2QywX15cN/J5nWMqrrI9E6CxnM=";
      factoryImageUrl = "https://dl.google.com/dl/android/aosp/marlin-qp1a.191005.007.a3-factory-bef66533.zip";
      factoryImageSha256 = "bef6653301371b66bd7fca968cf52013c0bf6862f0c7a70a275b0f0d45ab3888";
    };

    # same underlying build as A3 (10.0.0, Oct 2019), different carrier/region
    # ramdisk but byte-identical kernel (confirmed via cmp)
    "QP1A.191005.007.A1" = {
      kernelSrcRev = "72a7a64494e033f2213c9701dbf137d277bf2026";
      kernelSrcSha256 = "sha256-CdM0PkUGkm1SVAT/J2QywX15cN/J5nWMqrrI9E6CxnM=";
      factoryImageUrl = "https://dl.google.com/dl/android/aosp/marlin-qp1a.191005.007.a1-factory-c27241e0.zip";
      factoryImageSha256 = "c27241e0aaf46f4ff60d8279efd9ac6f6ac8e80b1bd08c43d75f851313efaa12";
    };

    # 10.0.0, Sep 2019 - earlier build, distinct kernel commit (different
    # linux_banner git-describe hash)
    "QP1A.190711.020" = {
      kernelSrcRev = "382d7256ce446a4896ceaa244c1eacd7606bef67";
      kernelSrcSha256 = "sha256-/Th9FaDosF6PDlyBkXW7MRL/SEi+UkDSvkCOY5Vm3yY=";
      factoryImageUrl = "https://dl.google.com/dl/android/aosp/marlin-qp1a.190711.020-factory-2db5273a.zip";
      factoryImageSha256 = "2db5273a273a491fee3e175f3018830fc58015bdbacfedb589d67acf123156f8";
    };
  };

  ##############################################################################
  # mk* builder functions
  ##############################################################################

  # patches a prebuilt AOSP toolchain's glibc/interpreter paths for the Nix sandbox
  mkPatchedToolchain = { pname, rev, url }:
    pkgs.stdenv.mkDerivation {
      inherit pname;
      version = builtins.substring 0 7 rev;

      src = pkgs.fetchgit {
        inherit url rev;
        sha256 =
          if rev == "d7d824eaa0690179c4b504209dbb017dfc730cf3"
          then "sha256-BKgt8b3XorBDYigzob9+kLZloh9bTBSJL5K2PtxgqX4="
          else "sha256-9/3dQvATMshK3snKRbWgJBt3t8H2uJXYQf1vVU6yA8Y=";
      };

      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = [ pkgs.glibc pkgs.zlib ];

      installPhase = ''
        mkdir -p $out
        cp -r . $out/
      '';
    };

  # builds a device kernel (Image.lz4-dtb) from the shared kernel source + toolchains
  mkPixelKernel = { deviceCodename, kernelSrc, defconfigFile, extraConfig ? [] }:
    pkgs.stdenv.mkDerivation {
      pname = "${deviceCodename}-kernel";
      version = "3.18.137";

      src = kernelSrc;

      nativeBuildInputs = with pkgs; [ bc bison flex perl which lz4 ];

      postPatch = ''
        # /bin/pwd doesn't exist in the Nix sandbox - use pwd via PATH instead
        # (needed for O= out-of-tree builds)
        sed -i 's|/bin/pwd|pwd|' Makefile
      '';

      configurePhase = ''
        export ARCH=arm64
        export OUT_DIR=$PWD/out
        mkdir -p "$OUT_DIR"

        # the *-gcc wrappers in these AOSP prebuilts are python2 scripts
        # (#!/usr/bin/python), which doesn't exist on NixOS. mirror each
        # toolchain's bin/ into a writable dir, but point gcc at the real ELF
        # binary (*-gcc-4.9.x) instead. these dirs go on PATH with a bare
        # CROSS_COMPILE prefix, matching AOSP's own envsetup.sh
        mkdir -p toolchain-wrappers/aarch64 toolchain-wrappers/arm32

        for f in ${aarch64Toolchain}/bin/*; do
          ln -s "$f" toolchain-wrappers/aarch64/"$(basename "$f")"
        done
        rm -f toolchain-wrappers/aarch64/aarch64-linux-android-gcc
        ln -s ${aarch64Toolchain}/bin/aarch64-linux-android-gcc-4.9.x \
          toolchain-wrappers/aarch64/aarch64-linux-android-gcc

        for f in ${arm32Toolchain}/bin/*; do
          ln -s "$f" toolchain-wrappers/arm32/"$(basename "$f")"
        done
        rm -f toolchain-wrappers/arm32/arm-linux-androideabi-gcc
        ln -s ${arm32Toolchain}/bin/arm-linux-androideabi-gcc-4.9.x \
          toolchain-wrappers/arm32/arm-linux-androideabi-gcc

        # arch/arm64/boot/Makefile shells out to the legacy "lz4c" name, which
        # nixpkgs' lz4 only provides as lz4/lz4cat/unlz4. `${pkgs.lz4}` alone
        # resolves to the "dev" output - .out is needed to reach bin/
        mkdir -p toolchain-wrappers/lz4
        ln -s ${pkgs.lz4.out}/bin/lz4 toolchain-wrappers/lz4/lz4c

        export PATH=$PWD/toolchain-wrappers/aarch64:$PWD/toolchain-wrappers/arm32:$PWD/toolchain-wrappers/lz4:$PATH
        export CROSS_COMPILE=aarch64-linux-android-
        export CROSS_COMPILE_ARM32=arm-linux-androideabi-

        # host tools in this old kernel tree (dtc, kconfig, etc.) rely on
        # pre-C23 tentative-definition semantics that modern gcc's -fno-common
        # default breaks (e.g. "multiple definition of yylloc" in scripts/dtc)
        export HOSTCFLAGS=-fcommon

        cp ${defconfigFile} "$OUT_DIR"/.config
        chmod u+w "$OUT_DIR"/.config
        ${pkgs.lib.optionalString (extraConfig != []) ''
          # scripts/config has a #!/bin/bash shebang, absent in the sandbox -
          # invoke it via bash explicitly
          bash scripts/config --file "$OUT_DIR"/.config ${pkgs.lib.concatStringsSep " " extraConfig}
        ''}
        make O="$OUT_DIR" olddefconfig
      '';

      buildPhase = ''
        # O= builds re-invoke make via a sub-make that only passes through
        # explicit command-line variables, not exported shell env vars - so
        # HOSTCFLAGS has to be repeated here despite being exported above.
        #
        # KCFLAGS=-Idrivers/thermal: drivers/thermal/thermal_core.c does
        # #include <../base/base.h>, which no Makefile in this tree resolves
        # automatically (checked Makefile/Makefile.build/Makefile.lib and
        # AOSP's build.sh/envsetup.sh - neither sets this either).
        #
        # Image.lz4-dtb, not Image.gz-dtb: the real device's kernel partition
        # is lz4-compressed (confirmed via magic bytes against the factory
        # image: 0422 4d18, the lz4 frame magic, not gzip's 1f8b 0800)
        make O="$OUT_DIR" -j$NIX_BUILD_CORES HOSTCFLAGS=-fcommon KCFLAGS=-Idrivers/thermal Image.lz4-dtb
      '';

      installPhase = ''
        mkdir -p $out
        cp "$OUT_DIR"/arch/arm64/boot/Image.lz4-dtb $out/
      '';
    };

  # extracts the stock boot.img out of a factory image zip
  mkPixelFactoryBootImg = { factoryImage }:
    pkgs.stdenv.mkDerivation {
      pname = "factory-bootimg";
      version = "extracted";

      dontUnpack = true;
      nativeBuildInputs = [ pkgs.unzip ];

      buildPhase = ''
        # device images are nested one directory deep in a second zip inside
        # the factory zip (e.g. marlin-qp1a.../image-marlin-qp1a....zip)
        unzip -j ${factoryImage} '*/image-*.zip' -d .
        inner_zip=$(find . -maxdepth 1 -name 'image-*.zip')

        unzip -j "$inner_zip" boot.img -d .
      '';

      installPhase = ''
        mkdir -p $out
        cp boot.img $out/
      '';
    };

  # repacks an existing boot.img (stock or Magisk-patched) with a built kernel
  mkPixelRepackBootImg = { kernelPkg, bootImg }:
    pkgs.stdenv.mkDerivation {
      pname = "${kernelPkg.pname}-bootimg";
      version = kernelPkg.version;

      dontUnpack = true;
      nativeBuildInputs = [ pkgs.android-tools ];

      buildPhase = ''
        work_dir=$(mktemp -d)
        trap 'rm -rf "$work_dir"' EXIT

        unpack_bootimg --boot_img ${bootImg} --out "$work_dir" > "$work_dir/header.txt"
        cat "$work_dir/header.txt"

        kernel_offset=$(sed -n 's/^kernel load address: //p' "$work_dir/header.txt")
        ramdisk_offset=$(sed -n 's/^ramdisk load address: //p' "$work_dir/header.txt")
        second_offset=$(sed -n 's/^second bootloader load address: //p' "$work_dir/header.txt")
        tags_offset=$(sed -n 's/^kernel tags load address: //p' "$work_dir/header.txt")
        page_size=$(sed -n 's/^page size: //p' "$work_dir/header.txt")
        os_version=$(sed -n 's/^os version: //p' "$work_dir/header.txt")
        os_patch_level=$(sed -n 's/^os patch level: //p' "$work_dir/header.txt")
        cmdline=$(sed -n 's/^command line args: //p' "$work_dir/header.txt")

        # base 0 + offset = load address, so the parsed addresses above work
        # directly as offsets without needing the original image's base address
        mkbootimg \
          --kernel ${kernelPkg}/Image.lz4-dtb \
          --ramdisk "$work_dir/ramdisk" \
          --base 0x0 \
          --kernel_offset "$kernel_offset" \
          --ramdisk_offset "$ramdisk_offset" \
          --second_offset "$second_offset" \
          --tags_offset "$tags_offset" \
          --pagesize "$page_size" \
          --os_version "$os_version" \
          --os_patch_level "$os_patch_level" \
          --cmdline "$cmdline" \
          -o boot.img
      '';

      installPhase = ''
        mkdir -p $out
        cp boot.img $out/
      '';
    };

  # pulls the kernel (Image.lz4-dtb) straight out of an existing boot.img -
  # used for the factory variant, where there's no source to build from,
  # just the vendor's original prebuilt kernel already sitting in the image
  mkPixelExtractedKernel = { bootImg, pname, version ? "extracted" }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;

      dontUnpack = true;
      nativeBuildInputs = [ pkgs.android-tools ];

      buildPhase = ''
        unpack_bootimg --boot_img ${bootImg} --out out
      '';

      installPhase = ''
        mkdir -p $out
        cp out/kernel $out/Image.lz4-dtb
      '';
    };

  # official prebuilt Magisk releases, pinned by version + sha256, keyed by
  # version string - use directly with mkMagiskPatchedBootImg for a version
  # other than the latest (magiskLatestVersion below). only the arm64-v8a
  # lib/ binaries and assets/ scripts inside are used, not the Manager app
  magiskRegistry = {
    "30.7" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.7/Magisk-v30.7.apk";
      sha256 = "e0d32d2123532860f97123d927b1bb86c4e08e6fd8a48bfc6b5bee0afae9ebd5";
    };

    "30.6" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.6/Magisk-v30.6.apk";
      sha256 = "f1ffc3c9a5614c251ba6bada308163acc3c3d844cf01d33f55a8bc151adc34ce";
    };

    "30.5" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.5/Magisk-v30.5.apk";
      sha256 = "812f1bf05ba74da4f991c6ca730ec9cf5a4cf433f8774960fd9a61981262492d";
    };

    "30.4" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.4/Magisk-v30.4.apk";
      sha256 = "c6ced29185fce89a909b912df8d7d2a9b370bf791b3a3b88d515e0804f020491";
    };

    "30.3" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.3/Magisk-v30.3.apk";
      sha256 = "bd080c811d8cc228f33017d2cd9d713d5aaa5bdd67000180d71264999cdd8caa";
    };

    "30.2" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.2/Magisk-v30.2.apk";
      sha256 = "123093f51eeb1aa459ac188a22ac3e775e8243293d48df2ceda9ca9dad22d2d6";
    };

    "30.1" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.1/Magisk-v30.1.apk";
      sha256 = "248735479ba807c879aea69494896b5ba581a006735142b09d353961d66d7d2a";
    };

    "30.0" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v30.0/Magisk-v30.0.apk";
      sha256 = "ecb00788c7371e3381a84bef3f88dcc35c61cdf40de01d94a4eab0e22a729bac";
    };

    "29.0" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v29.0/Magisk-v29.0.apk";
      sha256 = "99d40df1a68a05a5e78452a9cd4f2d753434d7622baeeb44ea14ae8238c1a9ca";
    };

    "28.1" = pkgs.fetchurl {
      url = "https://github.com/topjohnwu/Magisk/releases/download/v28.1/Magisk-v28.1.apk";
      sha256 = "8bfd3346b3da5814f82eff6f1b1b5fedd0ad585f39a25709b23eb54aac45691d";
    };
  };

  # the version marlin.*.magiskBootImages is pinned to - bump this (and
  # add a new magiskRegistry entry) to move everyone forward at once
  #
  # NOT 30.7: known bug produces an oversized boot.img ("size too large" from
  # fastboot) - use magiskRegistry."30.7" directly if it's ever fixed upstream
  magiskLatestVersion = "30.6";

  # roots an existing boot.img via Magisk's own boot_patch.sh + prebuilt arm64
  # magiskboot binary, run under qemu-user emulation (it's statically linked,
  # so no bionic/Android sysroot needed, just arm64 instruction emulation)
  mkMagiskPatchedBootImg = { bootImg, magiskApk, magiskVersion, name ? "magisk-patched-bootimg", preinitDevice, legacySAR ? false }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      version = magiskVersion;

      dontUnpack = true;
      nativeBuildInputs = [ pkgs.unzip pkgs.qemu pkgs.bash ];

      buildPhase = ''
        mkdir -p magisk
        unzip -j ${magiskApk} \
          assets/boot_patch.sh assets/util_functions.sh assets/stub.apk \
          lib/arm64-v8a/libmagiskinit.so lib/arm64-v8a/libmagisk.so \
          lib/arm64-v8a/libmagiskboot.so lib/arm64-v8a/libinit-ld.so \
          -d magisk

        cd magisk
        mv libmagiskinit.so magiskinit
        mv libmagisk.so magisk
        mv libinit-ld.so init-ld
        mv libmagiskboot.so magiskboot-arm64
        chmod +x boot_patch.sh util_functions.sh magiskinit magisk init-ld magiskboot-arm64

        # magiskboot is a static arm64 binary - wrap it to run under qemu-user
        # emulation, so boot_patch.sh's own "./magiskboot ..." calls just work
        printf '#!/bin/sh\nexec qemu-aarch64 "$(dirname "$0")/magiskboot-arm64" "$@"\n' > magiskboot
        chmod +x magiskboot

        # boot_patch.sh normally auto-detects ARCH/API level via getprop
        # against a running device - SOURCEDMODE skips that so we can supply
        # the values directly (always arm64 here). BOOTMODE=false is the
        # "offline" install path; OUTFD needs a valid fd since ui_print writes
        # to it outside BOOTMODE
        export SOURCEDMODE=1
        export BOOTMODE=false
        export ARCH=arm64
        export ABI32=armeabi-v7a
        export IS64BIT=true
        exec 3>&1
        export OUTFD=3

        # BOOTMODE=false also skips boot_patch.sh's own PREINITDEVICE
        # detection (`magisk --preinit-device` against a live system) -
        # magiskinit's on-device mount_preinit_dir() does no detection of its
        # own either, it just silently no-ops if unset, breaking magiskd's
        # persistent storage with no obvious error. Must be supplied
        # per-device (see find_preinit_device() in Magisk's native/src/core/mount.rs)
        export PREINITDEVICE=${preinitDevice}

        # marlin predates two-stage init - its bootloader can skip loading the
        # ramdisk entirely (skip_initramfs), mounting /system directly as
        # root. If skipped, magiskinit (which lives only in the ramdisk) never
        # runs - no daemon, no su. LEGACYSAR hexpatches the kernel's
        # "skip_initramfs" string to "want_initramfs" to force the ramdisk on
        export LEGACYSAR=${if legacySAR then "true" else "false"}

        # source (not exec) boot_patch.sh so it can see util_functions.sh's
        # ui_print/abort/etc functions - a separate "bash boot_patch.sh"
        # process wouldn't inherit shell functions. util_functions.sh
        # unconditionally sets TMPDIR=/dev/tmp (an Android path assumption),
        # which would otherwise leak into Nix's later build phases
        nix_tmpdir="$TMPDIR"
        . ./util_functions.sh
        set -- ${bootImg}
        . ./boot_patch.sh
        export TMPDIR="$nix_tmpdir"
      '';

      installPhase = ''
        mkdir -p $out
        cp new-boot.img $out/boot.img
      '';
    };

  ##############################################################################
  # concrete packages built from the mk* functions above
  ##############################################################################

  # exact toolchain revisions pinned by the android10 kernel manifest for marlin,
  # not just the branch HEAD at the time this was researched (same GCC 4.9.x either
  # way, but these are the precise commits actually used to build this kernel)
  aarch64Toolchain = mkPatchedToolchain {
    pname = "aarch64-linux-android-4.9";
    url = "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9";
    rev = "d7d824eaa0690179c4b504209dbb017dfc730cf3";
  };

  arm32Toolchain = mkPatchedToolchain {
    pname = "arm-linux-androideabi-4.9";
    url = "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9";
    rev = "0f5ac4a0fb21cff9cdd55c858380f426f8e5fd1b";
  };

  # builds every output (kernel, factory image extraction, repacked boot images)
  # for one marlinBuildRegistry entry
  mkMarlinBuild = buildId: { kernelSrcRev, kernelSrcSha256, factoryImageUrl, factoryImageSha256 }:
    let
      kernelSrc = pkgs.fetchgit {
        url = "https://android.googlesource.com/kernel/msm";
        rev = kernelSrcRev;
        sha256 = kernelSrcSha256;
      };

      factoryImage = pkgs.fetchurl {
        url = factoryImageUrl;
        sha256 = factoryImageSha256;
      };

      factoryBootImg = mkPixelFactoryBootImg { inherit factoryImage; };

      stockKernel = mkPixelKernel {
        deviceCodename = "marlin-${buildId}";
        inherit kernelSrc;
        defconfigFile = ./kernel/marlin_72a7a64494e_defconfig;
      };

      # same source/config as stockKernel, but with NFS client support enabled
      specialNfsKernel = mkPixelKernel {
        deviceCodename = "marlin-${buildId}-special-nfs";
        inherit kernelSrc;
        defconfigFile = ./kernel/marlin_72a7a64494e_defconfig;
        extraConfig = [
          # NFS_FS is gated behind NETWORK_FILESYSTEMS, which our base config
          # disables - enable it first or olddefconfig silently drops NFS_FS again
          "--enable" "NETWORK_FILESYSTEMS"
          "--enable" "NFS_FS"
          "--enable" "NFS_V3"
          "--enable" "NFS_V4"
        ];
      };
      stockBootImg = mkPixelRepackBootImg {
        kernelPkg = stockKernel;
        bootImg = "${factoryBootImg}/boot.img";
      };

      specialNfsBootImg = mkPixelRepackBootImg {
        kernelPkg = specialNfsKernel;
        bootImg = "${factoryBootImg}/boot.img";
      };

      # no source to build the factory kernel from - just pull it back out of
      # the factory boot.img itself
      factoryKernel = mkPixelExtractedKernel {
        bootImg = "${factoryBootImg}/boot.img";
        pname = "marlin-${buildId}-factory-kernel";
      };

      # repacking factoryBootImg's own extracted kernel back into a boot.img
      # should reproduce factoryBootImg exactly - see the
      # factoryKernelRoundtrip check below, which asserts this
      factoryBootImgRoundtrip = mkPixelRepackBootImg {
        kernelPkg = factoryKernel;
        bootImg = "${factoryBootImg}/boot.img";
      };
    in
    {
      inherit kernelSrc factoryImage;

      # kernel builds, keyed the same way as bootImages/magiskBootImages below
      kernels = {
        factory = factoryKernel;
        stock = stockKernel;
        specialNfs = specialNfsKernel;
      };

      # sanity checks, not build outputs - build one to verify, e.g.
      # `nix-build -A marlin."<id>".checks.factoryKernelRoundtrip`
      checks = {
        # extract + repack the factory kernel and diff it against the
        # original, proving mkPixelExtractedKernel/mkPixelRepackBootImg
        # round-trip cleanly. two dead/inert byte ranges are excluded:
        # - bytes 28-31 (second-bootloader address): mkbootimg always zeroes
        #   this when there's no --second file, regardless of --second_offset
        #   (see mkbootimg.py). the original's non-zero value is just a quirk
        #   of whatever tool built it, never read at boot since second_size
        #   is 0 - copied from the original into our copy before comparing
        # - everything past our repacked image's length: the original has a
        #   trailing Google-signed boot signature (private-key signed
        #   ASN.1/PKCS#7 blob) we have no way to reproduce
        factoryKernelRoundtrip = pkgs.runCommand "marlin-${buildId}-factory-kernel-roundtrip-test" {} ''
          our_size=$(stat -c%s ${factoryBootImgRoundtrip}/boot.img)

          cp ${factoryBootImgRoundtrip}/boot.img ours.img
          chmod +w ours.img
          dd if=${factoryBootImg}/boot.img of=ours.img bs=1 skip=28 seek=28 count=4 conv=notrunc status=none

          cmp -n "$our_size" ${factoryBootImg}/boot.img ours.img
          touch $out
        '';
      };

      # every boot.img variant, keyed by kernel choice only (untouched factory /
      # rebuilt stock / rebuilt with NFS)
      bootImages = {
        factory = factoryBootImg;
        stock = stockBootImg;
        specialNfs = specialNfsBootImg;
      };

      # the same three variants, Magisk-rooted - a separate top-level attrset
      # (not nested in bootImages) since rooting is orthogonal to kernel
      # choice. pinned to magiskLatestVersion - use magiskRegistry +
      # mkMagiskPatchedBootImg directly for a different Magisk version
      magiskBootImages = {
        factory = mkMagiskPatchedBootImg {
          name = "marlin-${buildId}-factory-magisk${magiskLatestVersion}-bootimg";
          bootImg = "${factoryBootImg}/boot.img";
          magiskApk = magiskRegistry.${magiskLatestVersion};
          magiskVersion = magiskLatestVersion;
          # confirmed via /proc/self/mountinfo + ro.crypto.* on the real
          # device: no metadata/cache partition, /persist exists (ext4, rw) -
          # matches what magisk's find_preinit_device() would pick
          preinitDevice = "persist";
          legacySAR = true;
        };

        stock = mkMagiskPatchedBootImg {
          name = "marlin-${buildId}-stock-magisk${magiskLatestVersion}-bootimg";
          bootImg = "${stockBootImg}/boot.img";
          magiskApk = magiskRegistry.${magiskLatestVersion};
          magiskVersion = magiskLatestVersion;
          preinitDevice = "persist";
          legacySAR = true;
        };

        specialNfs = mkMagiskPatchedBootImg {
          name = "marlin-${buildId}-special-nfs-magisk${magiskLatestVersion}-bootimg";
          bootImg = "${specialNfsBootImg}/boot.img";
          magiskApk = magiskRegistry.${magiskLatestVersion};
          magiskVersion = magiskLatestVersion;
          preinitDevice = "persist";
          legacySAR = true;
        };
      };
    };

  marlin = pkgs.lib.mapAttrs mkMarlinBuild marlinBuildRegistry;

in

{
  inherit mountingScripts marlin magiskRegistry;
  inherit mkPixelKernel mkPixelFactoryBootImg mkPixelRepackBootImg mkMarlinBuild mkMagiskPatchedBootImg;
}
