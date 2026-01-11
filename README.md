# Windows Binaries of GNU Wget 1.25.0

This is a command-line tool that can be used to retrieve files via the HTTP, HTTPS, and FTP protocols.

GNU Wget is a free software package that allows users to retrieve files through the most commonly used Internet protocols, including HTTP, HTTPS, FTP, and FTPS. As a non-interactive command-line tool, it can be easily integrated into scripts, cron jobs, and terminals.

> [!TIP]
> Binaries for Windows on ARM(64) are now available!

## How to use wget

To learn how to use Wget, please refer to the official GNU Wget manual by clicking the link below.

[https://www.gnu.org/software/wget/manual/wget.html](https://www.gnu.org/software/wget/manual/wget.html)

### Build Environment

- **Native Windows Trust Store Support**: Wget has been built using GitHub Actions and cross-compiled with mingw64 on Ubuntu. It is completely safe to use and free from viruses.

- **Statically Linked**: All the necessary libraries have been **statically linked**, so there is no need to use any third-party DLL.

- **Native Windows Trust Store Support**: Unlike standard OpenSSL builds that require a manual `cert.pem` file, this build includes a custom patch to automatically trust the Windows Certificate Store.

### Wget features

The Windows version of Wget includes all features of Wget except for NLS (the multi-language version) and Metalink.

> [!IMPORTANT]
> 
> Since version 1.24.5, Metalink support has been fully disabled and removed. Consequently, the following dependencies are no longer required and have been removed: **expat**, **gpgme**, and **assuan**.
> 
> If you require Metalink support for your workflow, please refer to commits [4e3c8f9](https://github.com/KnugiHK/wget-windows/commit/4e3c8f993337ac23032b59e75a64cc61e4b75034) and [e93476e](https://github.com/KnugiHK/wget-windows/commit/e93476e0f9296463a4848cc6e1675531075340d1) to review the specific changes and code removals.

GnuTLS version:

`+cares +digest -gpgme +https +ipv6 +iri +large-file -metalink +nls +ntlm +opie +psl +ssl/gnutls`

OpenSSL version:

`+cares +digest -gpgme +https +ipv6 +iri +large-file -metalink +nls +ntlm +opie +psl +ssl/openssl`

### Local Build

To build Wget for Windows on WSL 1 or 2 (Debian/Ubuntu), please follow these steps.

```bash
sudo apt-get install -y mingw-w64 mingw-w64-tools mingw-w64-i686-dev gcc make m4 pkg-config automake gettext
git clone https://github.com/KnugiHK/wget-on-windows && cd wget-on-windows
./build.sh # Builds both x86 and x64 (no arm64 by default)
./build.sh x64 # Builds x64 only
./build.sh x86 # Builds x86 only
./build.sh arm64 # Builds arm64 only
```

> [!TIP]
> If you are seeing constant Windows popups while building for ARM64 on WSL, it's because Windows doesn't recognize the conftests files the build script is running.
>
> You can stop these interruptions by running: `sudo ./build.sh disable-binfmt`
>
> It tells WSL to stop asking Windows for help when it encounters a file it can't run. This "silences" the popups so the build can finish automatically without you having to click "OK" hundreds of times.

## Verifying Build Integrity

To ensure that the binaries provided in the releases were built directly from this source code via GitHub Actions and have not been tampered with, GitHub Artifact Attestations is used. You can verify the authenticity of any `.exe` using the GitHub CLI.

### Using PowerShell (Windows)

```powershell
gci "wget*.exe" | % { gh attestation verify $_.FullName -R KnugiHK/wget-on-windows }
```

### Using Bash (Linux/WSL/macOS)

```bash
for file in wget*.exe; do ; gh attestation verify "$file" -R KnugiHK/wget-on-windows; done
```
## Legacy & Credits

This project is the active continuation of the wget-windows port, originally founded by @webfolderio. As a former contributor to the original repository, I stepped in to keep the project alive for the Windows community after the original source became unavailable.

While this repository initially served as a backup for preservation, it has evolved into an independent distribution focused on security hardening, modern dependencies, and automated, verified builds.
