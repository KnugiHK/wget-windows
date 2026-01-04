#!/bin/bash
#
# wget build script for Windows environment
# Author: WebFolder, KnugiHK
# https://github.com/KnugiHK/wget-on-windows
#
mkdir build-wget-x86
cd build-wget-x86 || exit
mkdir install
export INSTALL_PATH=$PWD/install
export WGET_GCC=i686-w64-mingw32-gcc
export WGET_MINGW_HOST=i686-w64-mingw32
export WGET_ARCH=i686
export MINGW_STRIP_TOOL=i686-w64-mingw32-strip
export CORE=$(nproc)
while [[ "$(cat /proc/sys/fs/binfmt_misc/status)" == "enabled" ]]
do
  echo "The build script requires a password to work."
  sudo bash -c "echo 0 > /proc/sys/fs/binfmt_misc/status"
done
# -----------------------------------------------------------------------------
# Build gmp (No dependencies)
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
# Build nettle (Requires GMP)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libnettle.a ]; then
  wget -nc https://ftp.gnu.org/gnu/nettle/nettle-3.10.2.tar.gz
  tar -xf nettle-3.10.2.tar.gz
  cd nettle-3.10.2 || exit
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
# Build tasn (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libtasn1.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.20.0.tar.gz
  tar -xf libtasn1-4.20.0.tar.gz
  cd libtasn1-4.20.0 || exit
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
# Build idn2 (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libidn2.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libidn/libidn2-2.3.8.tar.gz
  tar -xf libidn2-2.3.8.tar.gz
  cd libidn2-2.3.8 || exit
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
# Build unistring (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libunistring.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libunistring/libunistring-1.4.1.tar.gz
  tar -xf libunistring-1.4.1.tar.gz
  cd libunistring-1.4.1 || exit
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
# Build gnutls (Requires GMP, nettle, tasn1, idn2)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgnutls.a ]; then
  wget -nc https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.11.tar.xz
  tar -xf gnutls-3.8.11.tar.xz
  cd gnutls-3.8.11 || exit
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
# Build cares (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libcares.a ]; then
  wget -nc https://github.com/c-ares/c-ares/releases/download/v1.34.6/c-ares-1.34.6.tar.gz
  tar -xf c-ares-1.34.6.tar.gz
  cd c-ares-1.34.6 || exit
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
# Build iconv (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libiconv.a ]; then
  wget -nc https://ftp.gnu.org/gnu/libiconv/libiconv-1.18.tar.gz
  tar -xf libiconv-1.18.tar.gz
  cd libiconv-1.18 || exit
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
# Build psl (Requires idn2, unistring, iconv)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libpsl.a ]; then
  wget -nc https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz
  tar -xf libpsl-0.21.5.tar.gz
  cd libpsl-0.21.5 || exit
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
# Build pcre2 (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libpcre2-8.a ]; then
  wget -nc https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.gz
  tar -xf pcre2-10.47.tar.gz
  cd pcre2-10.47 || exit
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
# Build gpg-error (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgpg-error.a ]; then
  wget -nc https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.58.tar.bz2
  tar -xf libgpg-error-1.58.tar.bz2
  cd libgpg-error-1.58 || exit
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
# Build zlib (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libz.a ]; then
  wget -nc https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
  tar -xf zlib-1.3.1.tar.gz
  cd zlib-1.3.1 || exit
  CC=$WGET_GCC CFLAGS="-m32 -march=i686" ./configure --static --prefix="$INSTALL_PATH"
  (($? != 0)) && { printf '%s\n' "[zlib] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[zlib] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[zlib] make install"; exit 1; }
  cd ..
fi
# -----------------------------------------------------------------------------
# Build gettext (provides libintl for NLS, requires iconv)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libintl.a ]; then
  wget -nc https://ftp.gnu.org/gnu/gettext/gettext-0.26.tar.gz
  tar -xf gettext-0.26.tar.gz
  cd gettext-0.26/gettext-runtime || exit
  ./configure \
  --host=$WGET_MINGW_HOST \
  --prefix="$INSTALL_PATH" \
  --disable-shared \
  --enable-static \
  --disable-java \
  --disable-native-java \
  --disable-libasprintf \
  --disable-csharp \
  --disable-libasprintf \
  --enable-nls \
  --with-libiconv-prefix="$INSTALL_PATH" \
  --enable-relocatable
  (($? != 0)) && { printf '%s\n' "[gettext-runtime] configure failed"; exit 1; }
  make -j $CORE
  (($? != 0)) && { printf '%s\n' "[gettext-runtime] make failed"; exit 1; }
  make install
  (($? != 0)) && { printf '%s\n' "[gettext-runtime] make install"; exit 1; }
  cd ../..
fi
# -----------------------------------------------------------------------------
# Build openssl (Requires zlib)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libssl.a ]; then
  wget -nc https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz
  tar -xf openssl-3.5.4.tar.gz
  cd openssl-3.5.4 || exit
  ./Configure \
  -m32 \
  --static \
  -static \
  --prefix="$INSTALL_PATH" \
  --cross-compile-prefix=i686-w64-mingw32- \
  mingw \
  no-shared \
  enable-asm \
  no-tests \
  --with-zlib-include="$INSTALL_PATH" \
  --with-zlib-lib="$INSTALL_PATH"/lib/libz.a
  make -j $CORE
  make install_sw
cd ..
fi
# -----------------------------------------------------------------------------
# Build wget (gnuTLS)
# -----------------------------------------------------------------------------
wget -nc https://ftp.gnu.org/gnu/wget/wget-1.24.5.tar.gz
tar -xf wget-1.24.5.tar.gz
cd wget-1.24.5 || exit
make clean
CFLAGS="-I$INSTALL_PATH/include -D_WIN32_WINNT=0x601 -DGNUTLS_INTERNAL_BUILD=1 -DCARES_STATICLIB=1 -DPCRE2_STATIC=1 -DNDEBUG -O2 -march=$WGET_ARCH -mtune=generic -Derror=rpl_error" \
 LDFLAGS="-L$INSTALL_PATH/lib -static -static-libgcc" \
 GNUTLS_CFLAGS=$CFLAGS \
 GNUTLS_LIBS="-L$INSTALL_PATH/lib -lgnutls -lbcrypt -lncrypt" \
 LIBPSL_CFLAGS=$CFLAGS \
 LIBPSL_LIBS="-L$INSTALL_PATH/lib -lpsl" \
 CARES_CFLAGS=$CFLAGS \
 CARES_LIBS="-L$INSTALL_PATH/lib -lcares" \
 PCRE2_CFLAGS=$CFLAGS \
 PCRE2_LIBS="-L$INSTALL_PATH/lib -lpcre2-8"  \
 LIBS="-L$INSTALL_PATH/lib -lbcrypt -lhogweed -lnettle -lgmp -ltasn1 -lidn2 -lpsl -liphlpapi -lcares -lunistring -liconv -lpcre2-8 -lgpg-error -lz -lcrypt32 -lpthread -lintl" \
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
  ac_cv_func_fcntl=no
(($? != 0)) && { printf '%s\n' "[wget gnutls] configure failed"; exit 1; }
make -j $CORE
(($? != 0)) && { printf '%s\n' "[wget gnutls] make failed"; exit 1; }
make install
(($? != 0)) && { printf '%s\n' "[wget gnutls] make install"; exit 1; }
mkdir "$INSTALL_PATH"/wget-gnutls
cp "$INSTALL_PATH"/bin/wget.exe "$INSTALL_PATH"/wget-gnutls/wget-gnutls-x86.exe
$MINGW_STRIP_TOOL "$INSTALL_PATH"/wget-gnutls/wget-gnutls-x86.exe
# -----------------------------------------------------------------------------
# Build wget (openssl)
# -----------------------------------------------------------------------------
make clean
cp ../../windows-openssl.diff .
patch src/openssl.c < windows-openssl.diff
CFLAGS="-I$INSTALL_PATH/include -D_WIN32_WINNT=0x601 -DCARES_STATICLIB=1 -DPCRE2_STATIC=1 -DNDEBUG -O2 -march=$WGET_ARCH -mtune=generic -Derror=rpl_error" \
 LDFLAGS="-L$INSTALL_PATH/lib -static -static-libgcc" \
 OPENSSL_CFLAGS=$CFLAGS \
 OPENSSL_LIBS="-L$INSTALL_PATH/lib -lcrypto -lssl -lbcrypt" \
 LIBPSL_CFLAGS=$CFLAGS \
 LIBPSL_LIBS="-L$INSTALL_PATH/lib -lpsl" \
 CARES_CFLAGS=$CFLAGS \
 CARES_LIBS="-L$INSTALL_PATH/lib -lcares" \
 PCRE2_CFLAGS=$CFLAGS \
 PCRE2_LIBS="-L$INSTALL_PATH/lib -lpcre2-8"  \
 LIBS="-L$INSTALL_PATH/lib -lbcrypt -lws2_32 -lidn2 -lpsl -liphlpapi -lcares -lunistring -liconv -lpcre2-8 -lgpg-error -lcrypto -lssl -lz -lcrypt32 -lintl" \
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
 --with-openssl \
  ac_cv_func_fcntl=no
(($? != 0)) && { printf '%s\n' "[wget openssl] configure failed"; exit 1; }
make -j $CORE
(($? != 0)) && { printf '%s\n' "[wget openssl] make failed"; exit 1; }
make install
(($? != 0)) && { printf '%s\n' "[wget openssl] make install"; exit 1; }
mkdir "$INSTALL_PATH"/wget-openssl
cp "$INSTALL_PATH"/bin/wget.exe "$INSTALL_PATH"/wget-openssl/wget-openssl-x86.exe
$MINGW_STRIP_TOOL "$INSTALL_PATH"/wget-openssl/wget-openssl-x86.exe
