#!/bin/bash
#
# wget build script for Windows environment (Combined x86/x64)
# Author: WebFolder, KnugiHK
# https://github.com/KnugiHK/wget-on-windows
#
# Usage: 
#   ./build.sh       (Builds both x86 and x64)
#   ./build.sh x86   (Builds x86 only)
#   ./build.sh x64   (Builds x64 only)
#   ./build.sh arm64 (Builds ARM64 only)

# -----------------------------------------------------------------------------
# Version & URL Definitions (Centralized Management)
# -----------------------------------------------------------------------------
GMP_VER="6.3.0"
GMP_URL="https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VER}.tar.xz"

NETTLE_VER="3.10.2"
NETTLE_URL="https://ftp.gnu.org/gnu/nettle/nettle-${NETTLE_VER}.tar.gz"

TASN1_VER="4.20.0"
TASN1_URL="https://ftp.gnu.org/gnu/libtasn1/libtasn1-${TASN1_VER}.tar.gz"

IDN2_VER="2.3.8"
IDN2_URL="https://ftp.gnu.org/gnu/libidn/libidn2-${IDN2_VER}.tar.gz"

UNISTRING_VER="1.4.1"
UNISTRING_URL="https://ftp.gnu.org/gnu/libunistring/libunistring-${UNISTRING_VER}.tar.gz"

ZLIB_VER="1.3.1"
ZLIB_URL="https://github.com/madler/zlib/releases/download/v${ZLIB_VER}/zlib-${ZLIB_VER}.tar.gz"

GNUTLS_VER="3.8.11"
GNUTLS_URL="https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-${GNUTLS_VER}.tar.xz"

CARES_VER="1.34.6"
CARES_URL="https://github.com/c-ares/c-ares/releases/download/v${CARES_VER}/c-ares-${CARES_VER}.tar.gz"

ICONV_VER="1.18"
ICONV_URL="https://ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VER}.tar.gz"

PSL_VER="0.21.5"
PSL_URL="https://github.com/rockdaboot/libpsl/releases/download/${PSL_VER}/libpsl-${PSL_VER}.tar.gz"

PCRE2_VER="10.47"
PCRE2_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VER}/pcre2-${PCRE2_VER}.tar.gz"

GPG_ERROR_VER="1.58"
GPG_ERROR_URL="https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${GPG_ERROR_VER}.tar.bz2"

GETTEXT_VER="0.26"
GETTEXT_URL="https://ftp.gnu.org/gnu/gettext/gettext-${GETTEXT_VER}.tar.gz"

OPENSSL_VER="3.5.4"
OPENSSL_URL="https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VER}/openssl-${OPENSSL_VER}.tar.gz"

WGET_VER="1.24.5"
WGET_URL="https://ftp.gnu.org/gnu/wget/wget-${WGET_VER}.tar.gz"

LLVM_MINGW_URL="https://github.com/mstorsjo/llvm-mingw/releases/download/20251216/llvm-mingw-20251216-ucrt-ubuntu-22.04-x86_64.tar.xz"

# -----------------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------------

BUILD_ARCH_TYPE=$1
ROOT_DIR=$PWD

if [ -z "$BUILD_ARCH_TYPE" ]; then
  BUILD_ARCH_TYPE="both"
fi

if [ "$BUILD_ARCH_TYPE" == "both" ]; then
  echo "================================================================="
  echo "ENACTING DUAL-ARCHITECHTURE BUILD"
  echo "================================================================="
  /bin/bash "$0" x64 || exit 1
  /bin/bash "$0" x86 || exit 1
  exit 0
fi

echo "================================================================="
echo "STARTING BUILD FOR: $BUILD_ARCH_TYPE"
echo "================================================================="

# -----------------------------------------------------------------------------
# Set Architecture Specific Variables
# -----------------------------------------------------------------------------
download_arm64_toolchain() {
  if [[ ! -d "$LLVM_MINGW_PATH" || ! -f "$LLVM_MINGW_PATH/bin/aarch64-w64-mingw32-gcc" ]]; then
    echo "llvm-mingw not found. Downloading..."
    mkdir -p "$LLVM_MINGW_PATH"
    wget -qO- "$LLVM_MINGW_URL" | tar -xJ --strip-components=1 -C "$LLVM_MINGW_PATH"
  else
    echo "ARM64 MinGW toolchain already exists. Skipping download."
  fi
}

if [ "$BUILD_ARCH_TYPE" == "x86" ]; then
  WORK_DIR="build-wget-x86"
  mkdir -p "$WORK_DIR/install"
  export INSTALL_PATH=$ROOT_DIR/$WORK_DIR/install
  export WGET_GCC=i686-w64-mingw32-gcc
  export WGET_MINGW_HOST=i686-w64-mingw32
  export WGET_ARCH=i686
  export MINGW_STRIP_TOOL=i686-w64-mingw32-strip
  export PKG_CONFIG_PATH="$INSTALL_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"
  
  # Specific compilation flags for x86
  ZLIB_CONFIG_ENV="CC=$WGET_GCC CFLAGS=-m32 -march=i686"
  ZLIB_CONFIG_ARGS=""
  
  OPENSSL_ARCH="mingw"
  OPENSSL_FLAGS="-m32 enable-asm"
  OPENSSL_LIB_DIR="lib"
  OPENSSL_CROSS="i686-w64-mingw32-"
  
  WGET_CFLAGS="-Derror=rpl_error"
  
  EXE_SUFFIX="-x86.exe"

elif [ "$BUILD_ARCH_TYPE" == "x64" ]; then
  WORK_DIR="build-wget"
  mkdir -p "$WORK_DIR/install"
  export INSTALL_PATH=$ROOT_DIR/$WORK_DIR/install
  export WGET_GCC=x86_64-w64-mingw32-gcc
  export WGET_MINGW_HOST=x86_64-w64-mingw32
  export WGET_ARCH=x86-64
  export MINGW_STRIP_TOOL=x86_64-w64-mingw32-strip
  export PKG_CONFIG_PATH="$INSTALL_PATH/lib64/pkgconfig:$PKG_CONFIG_PATH"
  
  # Specific compilation flags for x64
  ZLIB_CONFIG_ENV="CC=$WGET_GCC"
  ZLIB_CONFIG_ARGS="--64"
  
  OPENSSL_ARCH="mingw64"
  OPENSSL_FLAGS="enable-asm"
  OPENSSL_LIB_DIR="lib64"
  OPENSSL_CROSS="x86_64-w64-mingw32-"
  WGET_CFLAGS="-Derror=rpl_error"
  
  EXE_SUFFIX="-x64.exe"
elif [ "$BUILD_ARCH_TYPE" == "arm64" ]; then
  WORK_DIR="build-wget-arm64"
  mkdir -p "$WORK_DIR/install"
  export INSTALL_PATH=$ROOT_DIR/$WORK_DIR/install
  export WGET_MINGW_HOST=aarch64-w64-mingw32
  export WGET_ARCH=armv8-a
  export LLVM_MINGW_PATH="$ROOT_DIR/llvm_mingw"
  export PATH="$LLVM_MINGW_PATH/bin:$PATH"
  export CC=aarch64-w64-mingw32-gcc
  export CXX=aarch64-w64-mingw32-g++
  export RC=aarch64-w64-mingw32-windres
  export AR=aarch64-w64-mingw32-ar
  export RANLIB=aarch64-w64-mingw32-ranlib
  export NM=aarch64-w64-mingw32-nm
  export LD=aarch64-w64-mingw32-ld
  export MINGW_STRIP_TOOL=aarch64-w64-mingw32-strip
  export PKG_CONFIG_PATH="$INSTALL_PATH/lib64/pkgconfig:$PKG_CONFIG_PATH"
  download_arm64_toolchain

  ZLIB_CONFIG_ENV="CC=$CC"
  ZLIB_CONFIG_ARGS=""
  
  OPENSSL_ARCH="mingw64"
  OPENSSL_FLAGS="no-asm"
  OPENSSL_LIB_DIR="lib64"
  OPENSSL_CROSS=""
  
  WGET_CFLAGS="-D_GNU_SOURCE -Wno-implicit-function-declaration"
  WGET_OVERRIDE="ac_cv_func_error=no ac_cv_func_strchrnul=no"

  # Disable ASM and hardware acceleration because GnuTLS does not 
  # provide AArch64 assembly in the MinGW COFF format (unlike x86_64).
  GNUTLS_FLAGS="--disable-asm --disable-hardware-acceleration"
  
  EXE_SUFFIX="-arm64.exe"
elif [ "$BUILD_ARCH_TYPE" == "disable-binfmt" ]; then
  if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root to disable binfmt_misc."
    exit 1
  fi
  bash -c "echo 0 > /proc/sys/fs/binfmt_misc/status"
  echo "binfmt_misc disabled!"
  exit 0
else
  echo "Unknown architechture"
  exit 1
fi

# Workaround for gnulib's nanosleep check failing under cross-compilation
# Fixed in https://savannah.gnu.org/bugs/?67704
# To be removed when libraries updates gnulib
NANOSLEEP_OVERRIDES=(
  ac_cv_search_nanosleep="none required" 
  gl_cv_func_nanosleep=yes
)

export CORE=$(nproc)

set -e

abort() {
    echo "====================================================="
    echo "BUILD FAILED!"
    echo "Failed at: $1"
    echo "Directory: $(pwd)"
    echo "====================================================="
    exit 1
}

# -----------------------------------------------------------------------------
# Directory & Download Setup
# -----------------------------------------------------------------------------
DOWNLOAD_DIR="$ROOT_DIR/build-wget-dl"
mkdir -p "$DOWNLOAD_DIR"

# Helper to fetch from cache or download
fetch_src() {
    local url=$1
    local filename=$(basename "$url")
    if [ ! -f "$DOWNLOAD_DIR/$filename" ]; then
        echo "downloading $filename..."
        wget -nc -P "$DOWNLOAD_DIR" "$url"
    else
        echo "cache hit: $filename"
    fi
}

cd $WORK_DIR

# -----------------------------------------------------------------------------
# Build gmp (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgmp.a ]; then
  fetch_src "$GMP_URL"
  tar -xf "$DOWNLOAD_DIR/gmp-${GMP_VER}.tar.xz"
  cd gmp-${GMP_VER}
  ./configure \
   --build=$(./config.guess) \
   --host=$WGET_MINGW_HOST \
   --disable-shared \
   --prefix="$INSTALL_PATH" \
   CC_FOR_BUILD=gcc \
  || abort "[gmp] configure failed"
  make -j $CORE || abort "[gmp] make failed"
  make install || abort "[gmp] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build nettle (Requires GMP)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libnettle.a ]; then
  fetch_src "$NETTLE_URL"
  tar -xf "$DOWNLOAD_DIR/nettle-${NETTLE_VER}.tar.gz"
  cd nettle-${NETTLE_VER}
  CFLAGS="-I$INSTALL_PATH/include" \
  LDFLAGS="-L$INSTALL_PATH/lib" \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --disable-documentation \
  --prefix="$INSTALL_PATH" \
  || abort "[nettle] configure failed"
  make -j $CORE || abort "[nettle] make failed"
  make install || abort "[nettle] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build tasn (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libtasn1.a ]; then
  fetch_src "$TASN1_URL"
  tar -xf "$DOWNLOAD_DIR/libtasn1-${TASN1_VER}.tar.gz"
  cd libtasn1-${TASN1_VER}
  ./configure \
   --host=$WGET_MINGW_HOST \
   --disable-shared \
   --disable-doc \
   --prefix="$INSTALL_PATH" \
  || abort "[tasn] configure failed"
  make -j $CORE || abort "[tasn] make failed"
  make install || abort "[tasn] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build idn2 (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libidn2.a ]; then
  fetch_src "$IDN2_URL"
  tar -xf "$DOWNLOAD_DIR/libidn2-${IDN2_VER}.tar.gz"
  cd libidn2-${IDN2_VER}
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --disable-doc \
  --prefix="$INSTALL_PATH" \
  || abort "[idn2] configure failed"
  make -j $CORE || abort "[idn2] make failed"
  make install || abort "[idn2] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build unistring (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libunistring.a ]; then
  fetch_src "$UNISTRING_URL"
  tar -xf "$DOWNLOAD_DIR/libunistring-${UNISTRING_VER}.tar.gz"
  cd libunistring-${UNISTRING_VER}
  env "${NANOSLEEP_OVERRIDES[@]}" \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  || abort "[unistring] configure failed"
  make -j $CORE || abort "[unistring] make failed"
  make install || abort "[unistring] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build zlib (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libz.a ]; then
  fetch_src "$ZLIB_URL"
  tar -xf "$DOWNLOAD_DIR/zlib-${ZLIB_VER}.tar.gz"
  cd zlib-${ZLIB_VER}
  env $ZLIB_CONFIG_ENV  \
  ./configure $ZLIB_CONFIG_ARGS  \
  --static \
  --prefix="$INSTALL_PATH" \
  || abort "[zlib] configure failed"
  make -j $CORE || abort "[zlib] make failed"
  make install || abort "[zlib] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build gnutls (Requires GMP, nettle, tasn1, idn2, zlib (arm64))
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgnutls.a ]; then
  fetch_src "$GNUTLS_URL"
  tar -xf "$DOWNLOAD_DIR/gnutls-${GNUTLS_VER}.tar.xz"
  cd gnutls-${GNUTLS_VER}
  env "${NANOSLEEP_OVERRIDES[@]}" \
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
  $GNUTLS_FLAGS \
  --with-included-unistring \
  --disable-openssl-compatibility \
  --without-p11-kit \
  --disable-tests \
  --disable-doc \
  --disable-shared \
  --enable-static \
  --without-zstd \
  || abort "[gnutls] configure failed"
  make -j $CORE || abort "[gnutls] make failed"
  make install || abort "[gnutls] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build cares (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libcares.a ]; then
  fetch_src "$CARES_URL"
  tar -xf "$DOWNLOAD_DIR/c-ares-${CARES_VER}.tar.gz"
  cd c-ares-${CARES_VER}
  CPPFLAGS="-DCARES_STATICLIB=1" \
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --disable-tests \
  --disable-debug \
  || abort "[cares] configure failed"
  make -j $CORE || abort "[cares] make failed"
  make install || abort "[cares] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build iconv (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libiconv.a ]; then
  fetch_src "$ICONV_URL"
  tar -xf "$DOWNLOAD_DIR/libiconv-${ICONV_VER}.tar.gz"
  cd libiconv-${ICONV_VER}
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  || abort "[iconv] configure failed"
  make -j $CORE || abort "[iconv] make failed"
  make install || abort "[iconv] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build psl (Requires idn2, unistring, iconv)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libpsl.a ]; then
  fetch_src "$PSL_URL"
  tar -xf "$DOWNLOAD_DIR/libpsl-${PSL_VER}.tar.gz"
  cd libpsl-${PSL_VER}
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
  --with-libiconv-prefix="$INSTALL_PATH" \
  || abort "[psl] configure failed"
  make -j $CORE  || abort "[psl] make failed"
  make install || abort "[psl] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build pcre2 (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libpcre2-8.a ]; then
  fetch_src "$PCRE2_URL"
  tar -xf "$DOWNLOAD_DIR/pcre2-${PCRE2_VER}.tar.gz"
  cd pcre2-${PCRE2_VER}
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  || abort "[pcre2] configure failed"
  make -j $CORE || abort "[pcre2] make failed"
  make install || abort "[pcre2] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build gpg-error (No dependencies)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libgpg-error.a ]; then
  fetch_src "$GPG_ERROR_URL"
  tar -xf "$DOWNLOAD_DIR/libgpg-error-${GPG_ERROR_VER}.tar.bz2"
  cd libgpg-error-${GPG_ERROR_VER}
  ./configure \
  --host=$WGET_MINGW_HOST \
  --disable-shared \
  --prefix="$INSTALL_PATH" \
  --enable-static \
  --disable-doc \
  || abort "[gpg-error] configure failed"
  make -j $CORE || abort "[gpg-error] make failed"
  make install || abort "[gpg-error] make install"
  cd ..
fi
# -----------------------------------------------------------------------------
# Build gettext (provides libintl for NLS, requires iconv)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH"/lib/libintl.a ]; then
  fetch_src "$GETTEXT_URL"
  tar -xf "$DOWNLOAD_DIR/gettext-${GETTEXT_VER}.tar.gz"
  cd gettext-${GETTEXT_VER}/gettext-runtime
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
  --enable-relocatable \
  || abort "[gettext-runtime] configure failed"
  make -j $CORE || abort "[gettext-runtime] make failed"
  make install || abort "[gettext-runtime] make install"
  cd ../..
fi
# -----------------------------------------------------------------------------
# Build openssl (Requires zlib)
# -----------------------------------------------------------------------------
if [ ! -f "$INSTALL_PATH/$OPENSSL_LIB_DIR/libssl.a" ]; then
  fetch_src "$OPENSSL_URL"
  tar -xf "$DOWNLOAD_DIR/openssl-${OPENSSL_VER}.tar.gz"
  cd openssl-${OPENSSL_VER}
  CPPFLAGS="-I$INSTALL_PATH/include" \
  LDFLAGS="-L$INSTALL_PATH/lib" \
  ./Configure \
  $OPENSSL_FLAGS \
  --static \
  -static \
  --prefix="$INSTALL_PATH" \
  --cross-compile-prefix=$OPENSSL_CROSS \
  $OPENSSL_ARCH \
  no-shared \
  no-tests \
  zlib \
  || abort "[openssl] configure failed"
 make -j $CORE || abort "[openssl] make failed"
 make install_sw || abort "[openssl] make install_sw"
 cd ..
fi
# -----------------------------------------------------------------------------
# Build wget (gnuTLS)
# -----------------------------------------------------------------------------
fetch_src "$WGET_URL"
rm -rf "wget-${WGET_VER}"
tar -xf "$DOWNLOAD_DIR/wget-${WGET_VER}.tar.gz"
cd "wget-${WGET_VER}"
# Force fcntl to 'no' because MinGW headers lack POSIX constants like F_SETFD,
# causing Gnulib's replacement wrapper (rpl_fcntl) to fail during compilation.
CFLAGS="-I$INSTALL_PATH/include -DGNUTLS_INTERNAL_BUILD=1 -DCARES_STATICLIB=1 -DPCRE2_STATIC=1 -DNDEBUG -O2 -march=$WGET_ARCH -mtune=generic $WGET_CFLAGS" \
 LDFLAGS="-L$INSTALL_PATH/lib -static -static-libgcc" \
 GNUTLS_CFLAGS=$CFLAGS \
 GNUTLS_LIBS="-L$INSTALL_PATH/lib -lgnutls -lbcrypt -lncrypt" \
 LIBPSL_CFLAGS=$CFLAGS \
 LIBPSL_LIBS="-L$INSTALL_PATH/lib -lpsl" \
 CARES_CFLAGS=$CFLAGS \
 CARES_LIBS="-L$INSTALL_PATH/lib -lcares" \
 PCRE2_CFLAGS=$CFLAGS \
 PCRE2_LIBS="-L$INSTALL_PATH/lib -lpcre2-8"  \
 LIBS="-L$INSTALL_PATH/lib -lpsl -lhogweed -lnettle -lgnutls -lgmp -ltasn1 -lidn2 -lcares -lunistring -lpcre2-8 -lgpg-error -liconv -lintl -lz -lws2_32 -lbcrypt -lcrypt32 -liphlpapi -lpthread" \
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
  ac_cv_func_fcntl=no \
 $WGET_OVERRIDE \
|| abort "[wget gnutls] configure failed"
make -j $CORE || abort "[wget gnutls] make failed"
make install || abort "[wget gnutls] make install"
mkdir -p "$INSTALL_PATH"/wget-gnutls
cp "$INSTALL_PATH"/bin/wget.exe "$INSTALL_PATH"/wget-gnutls/wget-gnutls$EXE_SUFFIX
$MINGW_STRIP_TOOL "$INSTALL_PATH"/wget-gnutls/wget-gnutls$EXE_SUFFIX
# -----------------------------------------------------------------------------
# Build wget (openssl)
# -----------------------------------------------------------------------------
cd ..
rm -rf "wget-${WGET_VER}"
tar -xf "$DOWNLOAD_DIR/wget-${WGET_VER}.tar.gz"
cd "wget-${WGET_VER}"
cp ../../windows-openssl.diff .
patch src/openssl.c < windows-openssl.diff
# Force fcntl to 'no' because MinGW headers lack POSIX constants like F_SETFD,
# causing Gnulib's replacement wrapper (rpl_fcntl) to fail during compilation.
env "${NANOSLEEP_OVERRIDES[@]}" \
CFLAGS="-I$INSTALL_PATH/include -DCARES_STATICLIB=1 -DPCRE2_STATIC=1 -DNDEBUG -O2 -march=$WGET_ARCH -mtune=generic $WGET_CFLAGS" \
 LDFLAGS="-L$INSTALL_PATH/lib -static -static-libgcc" \
 OPENSSL_CFLAGS=$CFLAGS \
 OPENSSL_LIBS="-L$INSTALL_PATH/$OPENSSL_LIB_DIR -lcrypto -lssl -lbcrypt" \
 LIBPSL_CFLAGS=$CFLAGS \
 LIBPSL_LIBS="-L$INSTALL_PATH/lib -lpsl" \
 CARES_CFLAGS=$CFLAGS \
 CARES_LIBS="-L$INSTALL_PATH/lib -lcares" \
 PCRE2_CFLAGS=$CFLAGS \
 PCRE2_LIBS="-L$INSTALL_PATH/lib -lpcre2-8"  \
 LIBS="-L$INSTALL_PATH/lib -L$INSTALL_PATH/$OPENSSL_LIB_DIR -lssl -lcrypto -lpsl -lidn2 -lunistring -liconv -lpcre2-8 -lgpg-error -lintl -lcares -lz -lws2_32 -lbcrypt -lcrypt32 -liphlpapi" \
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
  ac_cv_func_fcntl=no \
  $WGET_OVERRIDE \
|| abort "[wget openssl] configure failed"
make -j $CORE || abort "[wget openssl] make failed"
make install || abort "[wget openssl] make install"
mkdir -p "$INSTALL_PATH"/wget-openssl
cp "$INSTALL_PATH"/bin/wget.exe "$INSTALL_PATH"/wget-openssl/wget-openssl$EXE_SUFFIX
$MINGW_STRIP_TOOL "$INSTALL_PATH"/wget-openssl/wget-openssl$EXE_SUFFIX
cd "$ROOT_DIR" && exit 0
