#
# wget build script for Windows environment
# Author: WebFolder
# https://webfolder.io
# March 15, 2021
#
mkdir build-wget
cd build-wget || exit
mkdir install
export INSTALL_PATH=$PWD/install
export WGET_GCC=x86_64-w64-mingw32-gcc
export WGET_MINGW_HOST=x86_64-w64-mingw32
export WGET_ARCH=x86-64
export MINGW_STRIP_TOOL=x86_64-w64-mingw32-strip
export CORE=$(nproc)
while [[ "$(cat /proc/sys/fs/binfmt_misc/status)" == "enabled" ]]
do
  echo "The build script requires a password to work."
  sudo bash -c "echo 0 > /proc/sys/fs/binfmt_misc/status"
done
# -----------------------------------------------------------------------------
# build gmp
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgmp.a ]; then
  wget -nc https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
  tar -xf gmp-6.3.0.tar.xz
  cd gmp-6.3.0 || exit
  ./configure \
   --host=$WGET_MINGW_HOST \
   --disable-shared \
   --prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[gmp] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[gmp] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[gmp] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build nettle
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libnettle.a ]; then
  wget -nc https://ftp.gnu.org/gnu/nettle/nettle-3.9.1.tar.gz
  tar -xf nettle-3.9.1.tar.gz
  cd nettle-3.9.1 || exit
  CFLAGS="-I$INSTALL_PATH/include" \
  LDFLAGS="-L$INSTALL_PATH/lib" \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --disable-documentation \
  --prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[nettle] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[nettle] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[nettle] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build tasn
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libtasn1.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz
  tar -xf libtasn1-4.19.0.tar.gz
  cd libtasn1-4.19.0 || exit
  ./configure \
   --host=$WGET_MINGW_HOST \
   --disable-shared \
   --disable-doc \
   --prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[tasn] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[tasn] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[tasn] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build idn2
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libidn2.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libidn/libidn2-2.3.0.tar.gz
  tar -xf libidn2-2.3.0.tar.gz
  cd libidn2-2.3.0 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --disable-doc \
  --prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[idn2] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[idn2] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[idn2] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build unistring
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libunistring.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libunistring/libunistring-1.2.tar.gz
  tar -xf libunistring-1.2.tar.gz
  cd libunistring-1.2 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[unistring] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[unistring] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[unistring] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build gnutls
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgnutls.a ]; then
  wget -nc https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.3.tar.xz
  tar -xf gnutls-3.8.3.tar.xz
  cd gnutls-3.8.3 || exit
  PKG_CONFIG_PATH="$INSTALL_PATH/lib/pkgconfig" \
  CFLAGS="-I$INSTALL_PATH/include" \
  LDFLAGS="-L$INSTALL_PATH/lib" \
  GMP_LIBS="-L$INSTALL_PATH/lib -lgmp" \
  NETTLE_LIBS="-L$INSTALL_PATH/lib -lnettle -lgmp" \
  HOGWEED_LIBS="-L$INSTALL_PATH/lib -lhogweed -lnettle -lgmp" \
  LIBTASN1_LIBS="-L$INSTALL_PATH/lib -ltasn1" \
  LIBIDN2_LIBS="-L$INSTALL_PATH/lib -lidn2" \
  GMP_CFLAGS=$CFLAGS \
  LIBTASN1_CFLAGS=$CFLAGS \
  NETTLE_CFLAGS=$CFLAGS \
  HOGWEED_CFLAGS=$CFLAGS \
  LIBIDN2_CFLAGS=$CFLAGS \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --prefix="$INSTALL_PATH" \
  --with-included-unistring \
  --disable-openssl-compatibility \
  --without-p11-kit \
  --disable-tests \
  --disable-doc \
  --disable-shared \
  --enable-static
  (($? != 0)) && { printf '%s\n' "[gnutls] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[gnutls] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[gnutls] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build cares
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libcares.a ]; then
  wget -nc https://github.com/c-ares/c-ares/releases/download/cares-1_27_0/c-ares-1.27.0.tar.gz
  tar -xf c-ares-1.27.0.tar.gz
  cd c-ares-1.27.0 || exit
  CPPFLAGS="-DCARES_STATICLIB=1" \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --disable-tests \
  --disable-debug
  (($? != 0)) && { printf '%s\n' "[cares] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[cares] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[cares] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build iconv
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libiconv.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libiconv/libiconv-1.17.tar.gz
  tar -xf libiconv-1.17.tar.gz
  cd libiconv-1.17 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static
  (($? != 0)) && { printf '%s\n' "[iconv] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[iconv] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[iconv] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build psl
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libpsl.a ]; then
  wget -nc https://github.com/rockdaboot/libpsl/releases/download/0.21.1/libpsl-0.21.1.tar.gz
  tar -xf libpsl-0.21.1.tar.gz
  cd libpsl-0.21.1 || exit
  CFLAGS="-I$INSTALL_PATH/include" \
  LIBS="-L$INSTALL_PATH/lib -lunistring -lidn2" \
  LIBIDN2_CFLAGS="-I$INSTALL_PATH/include" \
  LIBIDN2_LIBS="-L$INSTALL_PATH/lib -lunistring -lidn2" \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --disable-gtk-doc \
  --enable-builtin=libidn2 \
  --enable-runtime=libidn2 \
  --with-libiconv-prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[psl] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[psl] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[psl] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build pcre2
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libpcre2-8.a ]; then
  wget -nc https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.43/pcre2-10.43.tar.gz
  tar -xf pcre2-10.43.tar.gz
  cd pcre2-10.43 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static
  (($? != 0)) && { printf '%s\n' "[pcre2] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[pcre2] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[pcre2] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build gpg-error
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgpg-error.a ]; then
  wget -nc https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.48.tar.gz
  tar -xf libgpg-error-1.48.tar.gz
  cd libgpg-error-1.48 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --disable-doc
  (($? != 0)) && { printf '%s\n' "[gpg-error] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[gpg-error] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[gpg-error] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build assuan
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libassuan.a ]; then
  wget -nc https://gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.7.tar.bz2
  tar -xf libassuan-2.5.7.tar.bz2
  cd libassuan-2.5.7 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --disable-doc \
  --with-libgpg-error-prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[assuan] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[assuan] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[assuan] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build gpgme
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgpgme.a ]; then
  wget -nc https://gnupg.org/ftp/gcrypt/gpgme/gpgme-1.23.2.tar.bz2
  tar -xf gpgme-1.23.2.tar.bz2
  cd gpgme-1.23.2 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --with-libgpg-error-prefix="$INSTALL_PATH" \
  --disable-gpg-test \
  --disable-g13-test \
  --disable-gpgsm-test \
  --disable-gpgconf-test \
  --disable-glibtest \
  --with-libassuan-prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[gpgme] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[gpgme] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[gpgme] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build expat
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libexpat.a ]; then
  wget -nc https://github.com/libexpat/libexpat/releases/download/R_2_6_2/expat-2.6.2.tar.gz
  tar -xf expat-2.6.2.tar.gz
  cd expat-2.6.2 || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --without-docbook \
  --without-tests \
  --with-libgpg-error-prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[expat] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[expat] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[expat] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build metalink
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libmetalink.a ]; then
  wget -nc https://github.com/metalink-dev/libmetalink/releases/download/release-0.1.3/libmetalink-0.1.3.tar.gz
  tar -xf libmetalink-0.1.3.tar.gz
  cd libmetalink-0.1.3 || exit
  EXPAT_CFLAGS="-I$INSTALL_PATH/include" \
  EXPAT_LIBS="-L$INSTALL_PATH/lib -lexpat" \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --with-libgpg-error-prefix="$INSTALL_PATH" \
  --with-libexpat
  (($? != 0)) && { printf '%s\n' "[metalink] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[metalink] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[metalink] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build zlib
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libz.a ]; then
  wget -nc https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
  tar -xf zlib-1.3.1.tar.gz
  cd zlib-1.3.1 || exit
  CC=$WGET_GCC ./configure --64 --static --prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[zlib] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[zlib] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[zlib] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# build openssl
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib64/libssl.a ]; then
  wget -nc https://www.openssl.org/source/openssl-3.2.1.tar.gz
  tar -xf openssl-3.2.1.tar.gz
  cd openssl-3.2.1 || exit
  ./Configure \
  --static \
  -static \
  --prefix="$INSTALL_PATH" \
  --cross-compile-prefix=x86_64-w64-mingw32- \
  mingw64 \
  no-shared \
  enable-asm \
  no-tests \
  --with-zlib-include="$INSTALL_PATH" \
  --with-zlib-lib="$INSTALL_PATH"/lib/libz.a
 make
 make install_sw
 cd ..
fi
# -----------------------------------------------------------------------------
# build wget (gnuTLS)
# -----------------------------------------------------------------------------
wget -nc https://ftp.gnu.org/gnu/wget/wget-1.21.4.tar.gz
tar -xf wget-1.21.4.tar.gz
cd wget-1.21.4 || exit
CFLAGS="-I$INSTALL_PATH/include -DGNUTLS_INTERNAL_BUILD=1 -DCARES_STATICLIB=1 -DPCRE2_STATIC=1 -DNDEBUG -O2 -march=$WGET_ARCH -mtune=generic" \
 LDFLAGS="-L$INSTALL_PATH/lib -static -static-libgcc" \
 GNUTLS_CFLAGS=$CFLAGS \
 GNUTLS_LIBS="-L$INSTALL_PATH/lib -lgnutls -lbcrypt -lncrypt" \
 LIBPSL_CFLAGS=$CFLAGS \
 LIBPSL_LIBS="-L$INSTALL_PATH/lib -lpsl" \
 CARES_CFLAGS=$CFLAGS \
 CARES_LIBS="-L$INSTALL_PATH/lib -lcares" \
 PCRE2_CFLAGS=$CFLAGS \
 PCRE2_LIBS="-L$INSTALL_PATH/lib -lpcre2-8"  \
 METALINK_CFLAGS="-I$INSTALL_PATH/include" \
 METALINK_LIBS="-L$INSTALL_PATH/lib -lmetalink -lexpat" \
 LIBS="-L$INSTALL_PATH/lib -lhogweed -lnettle -lgmp -ltasn1 -lidn2 -lpsl -liphlpapi -lcares -lunistring -liconv -lpcre2-8 -lmetalink -lexpat -lgpgme -lassuan -lgpg-error -lz -lcrypt32 -lpthread" \
 ./configure \
 --host=$WGET_MINGW_HOST \
 --prefix="$INSTALL_PATH" \
 --disable-debug \
 --disable-valgrind-tests \
 --enable-iri \
 --enable-pcre2 \
 --with-ssl=gnutls \
 --with-included-libunistring \
 --with-libidn \
 --with-cares \
 --with-libpsl \
 --with-metalink \
 --with-gpgme-prefix="$INSTALL_PATH"
(($? != 0)) && { printf '%s\n' "[wget gnutls] configure failed"; exit 1; }
make clean
make
(($? != 0)) && { printf '%s\n' "[wget gnutls] make failed"; exit 1; }
make install
(($? != 0)) && { printf '%s\n' "[wget gnutls] make install"; exit 1; }
mkdir "$INSTALL_PATH"/wget-gnutls
cp "$INSTALL_PATH"/bin/wget.exe "$INSTALL_PATH"/wget-gnutls/wget-gnutls-x64.exe
$MINGW_STRIP_TOOL "$INSTALL_PATH"/wget-gnutls/wget-gnutls-x64.exe
# -----------------------------------------------------------------------------
# build wget (openssl)
# -----------------------------------------------------------------------------
make clean
cp ../../windows-openssl.diff .
patch src/openssl.c < windows-openssl.diff
CFLAGS="-I$INSTALL_PATH/include -DCARES_STATICLIB=1 -DPCRE2_STATIC=1 -DNDEBUG -O2 -march=$WGET_ARCH -mtune=generic" \
 LDFLAGS="-L$INSTALL_PATH/lib -static -static-libgcc" \
 OPENSSL_CFLAGS=$CFLAGS \
 OPENSSL_LIBS="-L$INSTALL_PATH/lib64 -lcrypto -lssl -lbcrypt" \
 LIBPSL_CFLAGS=$CFLAGS \
 LIBPSL_LIBS="-L$INSTALL_PATH/lib -lpsl" \
 CARES_CFLAGS=$CFLAGS \
 CARES_LIBS="-L$INSTALL_PATH/lib -lcares" \
 PCRE2_CFLAGS=$CFLAGS \
 PCRE2_LIBS="-L$INSTALL_PATH/lib -lpcre2-8"  \
 METALINK_CFLAGS="-I$INSTALL_PATH/include" \
 METALINK_LIBS="-L$INSTALL_PATH/lib -lmetalink -lexpat" \
 LIBS="-L$INSTALL_PATH/lib -L$INSTALL_PATH/lib64 -lidn2 -lpsl -liphlpapi -lcares -lunistring -liconv -lpcre2-8 -lmetalink -lexpat -lgpgme -lassuan -lgpg-error -lcrypto -lssl -lz -lcrypt32" \
 ./configure \
 --host=$WGET_MINGW_HOST \
 --prefix="$INSTALL_PATH" \
 --disable-debug \
 --disable-valgrind-tests \
 --enable-iri \
 --enable-pcre2 \
 --with-ssl=openssl \
 --with-included-libunistring \
 --with-libidn \
 --with-cares \
 --with-libpsl \
 --with-metalink \
 --with-openssl \
 --with-gpgme-prefix="$INSTALL_PATH"
(($? != 0)) && { printf '%s\n' "[wget openssl] configure failed"; exit 1; }
make
(($? != 0)) && { printf '%s\n' "[wget openssl] make failed"; exit 1; }
make install
(($? != 0)) && { printf '%s\n' "[wget openssl] make install"; exit 1; }
mkdir "$INSTALL_PATH"/wget-openssl
cp "$INSTALL_PATH"/bin/wget.exe "$INSTALL_PATH"/wget-openssl/wget-openssl-x64.exe
$MINGW_STRIP_TOOL "$INSTALL_PATH"/wget-openssl/wget-openssl-x64.exe
