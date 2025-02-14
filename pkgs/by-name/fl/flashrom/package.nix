{
  fetchurl,
  stdenv,
  installShellFiles,
  lib,
  libftdi1,
  libjaylink,
  libusb1,
  pciutils,
  openssl,
  sphinx,
  meson,
  ninja,
  pkg-config,
  cmocka,
  jlinkSupport ? false,
}:

stdenv.mkDerivation rec {
  pname = "flashrom";
  version = "1.5.1";

  src = fetchurl {
    url = "https://download.flashrom.org/releases/flashrom-v${version}.tar.xz";
    hash = "sha256-H5NLB27UnqziA2Vewkn8eGGmuOh/5K73MuR7bkhbYpM=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    installShellFiles
    sphinx
  ];

  buildInputs =
    [
      libftdi1
      libusb1
      cmocka
      openssl
    ]
    ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [ pciutils ]
    ++ lib.optional jlinkSupport libjaylink;

  mesonFlags = [
    (lib.mesonOption "programmer" "auto")
    (lib.mesonEnable "man-pages" true)
    (lib.mesonEnable "tests" true)
  ];

  # TODO: after the meson build, the udev rules file is no longer present
  # in the build dir, so we need to write it to /tmp to be able to still access
  # it during the install phase.
  # There might be a better way to do this...
  postPatch = ''
    substitute util/flashrom_udev.rules /tmp/flashrom_udev.rules \
      --replace-fail 'GROUP="plugdev"' 'TAG+="uaccess", TAG+="udev-acl"'
  '';

  # TODO: see above
  postInstall = ''
    mkdir --parents $out/lib/udev/rules.d
    mv /tmp/flashrom_udev.rules $out/lib/udev/rules.d/flashrom.rules
  '';

  doCheck = true;

  NIX_CFLAGS_COMPILE = lib.optionalString (
    stdenv.cc.isClang && !stdenv.hostPlatform.isDarwin
  ) "-Wno-gnu-folding-constant";

  meta = with lib; {
    homepage = "https://www.flashrom.org";
    description = "Utility for reading, writing, erasing and verifying flash ROM chips";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ fpletz ];
    platforms = platforms.all;
    mainProgram = "flashrom";
  };
}
