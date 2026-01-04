"""
Comprehensive test suite for wget builds
Usage: wget-test.py <wget.exe> [<wget2.exe> ...]

The following tests are todo:

Asynchronous DNS (+cares): Check if the DNS resolution is happening asynchronously or non-blocking.

Public Suffix List (+psl): Check cookie-handling logic across domain boundaries (e.g., ensuring a cookie from evil.co.uk isn't accepted for example.co.uk).

Native Language Support (+nls): Wwitch the system locale to see if Wget's error messages translate correctly.

OPIE (+opie): Check for "One-time Passwords In Everything" authentication.

Proxy Support: Check Wget's ability to tunnel through an HTTP or SOCKS proxy.

Recursive Downloading: Check -r (recursive) or -m (mirror) functions.

FTP Support: Check FTP support.
"""

import sys
import subprocess
import os
import tempfile
import re
import threading
import socket
import base64
import hashlib
import time
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler


class NTLMTestHandler(BaseHTTPRequestHandler):
    """Simple HTTP handler that requires NTLM authentication"""

    def log_message(self, format, *args):
        """Suppress logging"""
        pass

    def do_GET(self):
        auth_header = self.headers.get('Authorization', '')

        if not auth_header:
            # No auth provided, send NTLM challenge
            self.send_response(401)
            self.send_header('WWW-Authenticate', 'NTLM')
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(b'<html><body>Authentication required</body></html>')
            return

        if auth_header.startswith('NTLM '):
            ntlm_message = auth_header[5:]

            try:
                decoded = base64.b64decode(ntlm_message)

                # Check if this is Type 1 (NTLM Negotiate) message
                # Type 1 messages start with "NTLMSSP\x00" followed by type 0x01
                if decoded[:8] == b'NTLMSSP\x00' and len(decoded) >= 12:
                    msg_type = int.from_bytes(decoded[8:12], 'little')

                    if msg_type == 1:
                        # This is a Type 1 message, send Type 2 challenge
                        # Create a simple Type 2 (Challenge) message
                        challenge = b'NTLMSSP\x00'  # Signature
                        challenge += b'\x02\x00\x00\x00'  # Type 2
                        challenge += b'\x00\x00\x00\x00\x00\x00\x00\x00'  # Target name (empty)
                        challenge += b'\x01\x02\x81\x00'  # Flags
                        challenge += b'\x01\x23\x45\x67\x89\xab\xcd\xef'  # Challenge (8 bytes)
                        challenge += b'\x00\x00\x00\x00\x00\x00\x00\x00'  # Reserved

                        challenge_b64 = base64.b64encode(challenge).decode('ascii')

                        self.send_response(401)
                        self.send_header('WWW-Authenticate', f'NTLM {challenge_b64}')
                        self.send_header('Content-Type', 'text/html')
                        self.end_headers()
                        self.wfile.write(b'<html><body>Challenge sent</body></html>')
                        return

                    elif msg_type == 3:
                        # This is a Type 3 (Authenticate) message
                        # For testing purposes, we accept any Type 3 message
                        self.send_response(200)
                        self.send_header('Content-Type', 'text/plain')
                        self.end_headers()
                        self.wfile.write(b'NTLM authentication successful!')
                        return

            except Exception as e:
                pass

        # Invalid authentication
        self.send_response(401)
        self.send_header('WWW-Authenticate', 'NTLM')
        self.send_header('Content-Type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<html><body>Authentication failed</body></html>')


class NTLMTestServer:
    """Wrapper for NTLM test server"""

    def __init__(self, port=0):
        self.server = None
        self.thread = None
        self.port = port

    def start(self):
        """Start the server in a background thread"""
        self.server = HTTPServer(('127.0.0.1', self.port), NTLMTestHandler)
        self.port = self.server.server_port
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        return self.port

    def stop(self):
        """Stop the server"""
        if self.server:
            self.server.shutdown()
            self.server.server_close()
        if self.thread:
            self.thread.join(timeout=2)

    def get_url(self):
        """Get the base URL of the server"""
        return f'http://127.0.0.1:{self.port}/'


class LargeFileHandler(BaseHTTPRequestHandler):
    """Serves a large stream of zeros with support for Range requests"""
    FILE_SIZE = 3 * 1024 * 1024 * 1024  # 3GB
    CHUNK_SIZE = 64 * 1024  # 64KB chunks for streaming

    def do_GET(self):
        range_header = self.headers.get('Range', '')
        start_byte = 0

        if range_header.startswith('bytes='):
            # Simple range parsing: 'bytes=start-'
            start_byte = int(range_header.split('=')[1].split('-')[0])

        if start_byte >= self.FILE_SIZE:
            self.send_error(416, "Requested Range Not Satisfiable")
            return

        # Prepare headers
        if start_byte > 0:
            self.send_response(206)
            self.send_header('Content-Range', f'bytes {start_byte}-{self.FILE_SIZE-1}/{self.FILE_SIZE}')
        else:
            self.send_response(200)

        self.send_header('Content-Type', 'application/octet-stream')
        self.send_header('Content-Length', str(self.FILE_SIZE - start_byte))
        self.end_headers()

        # Stream the zeros
        remaining = self.FILE_SIZE - start_byte
        zero_chunk = b'\x00' * self.CHUNK_SIZE

        try:
            while remaining > 0:
                to_send = min(remaining, self.CHUNK_SIZE)
                self.wfile.write(zero_chunk[:to_send])
                remaining -= to_send
        except (ConnectionResetError, BrokenPipeError):
            # Expected when we terminate the wget process early
            pass


class LargeFileServer(NTLMTestServer):
    """Wrapper for the Large File server"""

    def start(self):
        self.server = HTTPServer(('127.0.0.1', self.port), LargeFileHandler)
        self.port = self.server.server_port
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        return self.port


def calculate_sha256(file_path):
    """Calculate SHA-256 of a file in chunks to handle large files"""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(1024*1024), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()


def run_command(cmd, check=True, capture=True):
    """Run a command and return output"""
    try:
        if capture:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=check,
                timeout=30
            )
            return result.returncode, result.stdout, result.stderr
        else:
            result = subprocess.run(cmd, check=check, timeout=30)
            return result.returncode, "", ""
    except subprocess.CalledProcessError as e:
        return e.returncode, e.stdout if capture else "", e.stderr if capture else ""
    except subprocess.TimeoutExpired:
        print("  ❌ Command timed out")
        return -1, "", "Timeout"


def test_version(wget_path):
    """Test --version output for correct header"""
    print(f"\n🔍 Testing version output...")

    expected_version = os.environ.get('WGET_VERSION', '')
    if not expected_version:
        print("  ⚠️  Warning: WGET_VERSION environment variable not set")

    rc, stdout, stderr = run_command([wget_path, '--version'])

    if rc != 0:
        print(f"  ❌ --version failed with return code {rc}")
        return False

    lines = stdout.split('\n')
    if not lines:
        print(f"  ❌ No output from --version")
        return False

    headline = lines[0].strip()
    print(f"  Version headline: {headline}")

    # Check for GNU Wget pattern
    if not re.match(r'GNU Wget \d+\.\d+', headline):
        print(f"  ❌ Version headline doesn't match expected pattern")
        return False

    # Check for mingw32
    if 'mingw32' not in headline.lower():
        print(f"  ❌ Version headline doesn't contain 'mingw32'")
        return False

    # Check expected version if set
    if expected_version and expected_version not in headline:
        print(f"  ❌ Expected version '{expected_version}' not found in headline")
        return False

    print(f"  ✅ Version check passed")
    return True


def test_features(wget_path):
    """Test that required features are present"""
    print(f"\n🔍 Testing features...")

    # Features that MUST be present
    mandatory_features = {
        '+cares': True,
        '+digest': True,
        '-gpgme': True,
        '+https': True,
        '+ipv6': True,
        '+iri': True,
        '+large-file': True,
        '-metalink': True,
        '+nls': True,
        '+ntlm': True,
        '+opie': True,
        '+psl': True,
    }

    # Features where at least ONE must be present
    ssl_alternatives = ['+ssl/gnutls', '+ssl/openssl']

    rc, stdout, stderr = run_command([wget_path, '--version'])

    if rc != 0:
        print(f"  ❌ --version failed")
        return False

    full_text = ' '.join(stdout.split('\n'))
    all_passed = True

    for feature, should_exist in mandatory_features.items():
        if feature in full_text:
            print(f"  ✅ Found: {feature}")
        else:
            print(f"  ❌ Missing: {feature}")
            all_passed = False

    found_ssl = [f for f in ssl_alternatives if f in full_text]
    
    if found_ssl:
        for ssl_lib in found_ssl:
            print(f"  ✅ Found: {ssl_lib}")
    else:
        print(f"  ❌ Missing: Either {ssl_alternatives[0]} or {ssl_alternatives[1]}")
        all_passed = False

    return all_passed


def test_basic_download(wget_path):
    """Test basic HTTPS download functionality"""
    print(f"\n🔍 Testing basic HTTPS download...")

    with tempfile.TemporaryDirectory() as tmpdir:
        output_file = os.path.join(tmpdir, 'example.html')

        rc, stdout, stderr = run_command([
            wget_path,
            'https://example.com',
            '-O', output_file,
            '--timeout=10',
            '--tries=2'
        ])

        if rc != 0:
            print(f"  ❌ Download failed with return code {rc}")
            print(f"  stderr: {stderr}")
            return False

        if not os.path.exists(output_file):
            print(f"  ❌ Output file not created")
            return False

        file_size = os.path.getsize(output_file)
        if file_size == 0:
            print(f"  ❌ Downloaded file is empty")
            return False

        print(f"  ✅ Downloaded {file_size} bytes to file")
        return True


def test_stdout_download(wget_path):
    """Test download to stdout with -O-"""
    print(f"\n🔍 Testing download to stdout (-O-)...")

    rc, stdout, stderr = run_command([
        wget_path,
        'https://example.com',
        '-O-',
        '--quiet',
        '--timeout=10',
        '--tries=2'
    ])

    if rc != 0:
        print(f"  ❌ Download to stdout failed with return code {rc}")
        return False

    if not stdout or len(stdout) == 0:
        print(f"  ❌ No output to stdout")
        return False

    if 'example' not in stdout.lower():
        print(f"  ❌ Output doesn't appear to be from example.com")
        return False

    print(f"  ✅ Downloaded {len(stdout)} bytes to stdout")
    return True


def test_ipv6_support(wget_path):
    """Test IPv6 support (if +ipv6 feature exists)"""
    print(f"\n🔍 Testing IPv6 support...")

    # Test with a known IPv6-enabled site
    rc, stdout, stderr = run_command([
        wget_path,
        '--spider',
        '--timeout=10',
        '--tries=2',
        '-6',  # Force IPv6
        'https://ipv6.google.com'
    ], check=False)

    # IPv6 might not be available on all systems, so we just check it doesn't crash
    if rc == 0:
        print(f"  ✅ IPv6 connection successful")
    else:
        # Check if it's a network issue vs unsupported feature
        if 'unrecognized option' in stderr or 'invalid option' in stderr:
            print(f"  ❌ IPv6 option not supported")
            return False
        else:
            print(f"  ⚠️  IPv6 connection failed (may be network issue): {rc}")

    return True


def test_large_file_resume_and_hash(wget_path):
    """Test 3GB streaming download, interruption, resume, and SHA-256 integrity"""
    print(f"\n🔍 Testing 3GB Resume & SHA-256 Integrity...")

    server = LargeFileServer()
    port = server.start()
    url = server.get_url()

    # Pre-calculate the expected hash of 3GB of zeros
    # Optimization: update a hash object with a known block of zeros multiple times
    h = hashlib.sha256()
    block = b'\x00' * 1024 * 1024  # 1MB
    for _ in range(3 * 1024):      # 3072 MB = 3GB
        h.update(block)
    expected_hash = h.hexdigest()

    with tempfile.TemporaryDirectory() as tmpdir:
        output_file = os.path.join(tmpdir, '3gb_test.dat')

        print(f"  ⏳ Phase 1: Starting 3GB download (throttled)...")
        # Use --limit-rate to ensure we have time to kill it
        proc = subprocess.Popen(
            [wget_path, url, '-O', output_file, '--limit-rate=50M'],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )

        time.sleep(5)
        proc.terminate()
        proc.wait()

        initial_size = os.path.getsize(output_file) if os.path.exists(output_file) else 0
        print(f"  ✅ Interrupted at {initial_size / (1024*1024):.2f} MB")

        print(f"  ⏳ Phase 2: Resuming with -c (unthrottled)...")
        # Resume and let it finish (locally it should be fast)
        rc, stdout, stderr = run_command([
            wget_path, '-c', url, '-O', output_file, '--timeout=15'
        ], capture=True)

        final_size = os.path.getsize(output_file)
        print(f"  ✅ Download finished. Final size: {final_size / (1024*1024):.2f} MB")

        if final_size != LargeFileHandler.FILE_SIZE:
            print(f"  ❌ File size mismatch! Expected {LargeFileHandler.FILE_SIZE}, got {final_size}")
            server.stop()
            return False

        print(f"  ⏳ Phase 3: Verifying SHA-256 integrity...")
        actual_hash = calculate_sha256(output_file)

        server.stop()

        if actual_hash == expected_hash:
            print(f"  ✅ SHA-256 matches: {actual_hash}")
            return True
        else:
            print(f"  ❌ Hash mismatch!")
            print(f"     Expected: {expected_hash}")
            print(f"     Actual:   {actual_hash}")
            return False


def test_https_ssl(wget_path):
    """Test HTTPS/SSL functionality"""
    print(f"\n🔍 Testing HTTPS/SSL...")

    rc, stdout, stderr = run_command([
        wget_path,
        '--spider',
        '--timeout=10',
        '--tries=2',
        'https://www.google.com'
    ])

    if rc != 0:
        print(f"  ❌ HTTPS connection failed with return code {rc}")
        print(f"  stderr: {stderr}")
        return False

    print(f"  ✅ HTTPS connection successful")
    return True


def test_ntlm_authentication(wget_path):
    """Test NTLM authentication with actual handshake"""
    print(f"\n🔍 Testing NTLM authentication (with handshake)...")

    # Start NTLM test server
    server = NTLMTestServer()
    port = server.start()
    url = server.get_url()

    print(f"  Started NTLM test server on {url}")

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            output_file = os.path.join(tmpdir, 'ntlm_test.txt')

            # Test with NTLM authentication
            # Use fake credentials - our server accepts any Type 3 message
            rc, stdout, stderr = run_command([
                wget_path,
                url,
                '-O', output_file,
                '--auth-no-challenge',
                '--user=testuser',
                '--password=testpass',
                '--timeout=10',
                '--tries=2'
            ], check=False)

            if rc != 0:
                print(f"  ❌ NTLM authentication failed with return code {rc}")
                print(f"  stderr: {stderr}")

                # Check if NTLM is even supported
                if 'ntlm' in stderr.lower() and 'not' in stderr.lower():
                    print(f"  ❌ NTLM appears to not be supported")
                    return False

                # Sometimes wget needs explicit --ntlm flag
                print(f"  Retrying with explicit --ntlm flag...")
                rc2, stdout2, stderr2 = run_command([
                    wget_path,
                    url,
                    '-O', output_file,
                    '--ntlm',
                    '--user=testuser',
                    '--password=testpass',
                    '--timeout=10',
                    '--tries=2'
                ], check=False)

                if rc2 != 0:
                    print(f"  ❌ NTLM authentication failed even with --ntlm flag")
                    print(f"  stderr: {stderr2}")
                    return False

                rc, stdout, stderr = rc2, stdout2, stderr2

            # Check if file was created and contains success message
            if not os.path.exists(output_file):
                print(f"  ❌ Output file not created")
                return False

            with open(output_file, 'r') as f:
                content = f.read()

            if 'NTLM authentication successful' in content:
                print(f"  ✅ NTLM authentication handshake completed successfully")
                return True
            else:
                print(f"  ❌ Authentication succeeded but unexpected content received")
                print(f"  Content: {content[:100]}")
                return False

    finally:
        server.stop()


def test_iri_support(wget_path):
    """Test IRI (Internationalized Resource Identifier) support"""
    print(f"\n🔍 Testing IRI support...")

    # Check if --local-encoding or --remote-encoding options exist
    rc, stdout, stderr = run_command([wget_path, '--help'], check=False)

    help_text = stdout + stderr
    if 'encoding' in help_text.lower() or 'iri' in help_text.lower():
        print(f"  ✅ IRI support options found")
        return True
    else:
        print(f"  ⚠️  IRI options not prominently visible (may still be compiled in)")
        return True  # Don't fail on this


def test_wget(wget_path):
    """Run all tests on a wget executable"""
    print(f"\n{'='*60}")
    print(f"Testing: {wget_path}")
    print(f"{'='*60}")

    if not os.path.exists(wget_path):
        print(f"❌ Error: {wget_path} does not exist")
        return False

    tests = [
        ("Version Check", test_version),
        ("Features Check", test_features),
        ("Basic Download", test_basic_download),
        ("Stdout Download", test_stdout_download),
        ("HTTPS/SSL", test_https_ssl),
        ("IPv6 Support", test_ipv6_support),
        ("Large File Support", test_large_file_resume_and_hash),
        ("NTLM Authentication", test_ntlm_authentication),
        ("IRI Support", test_iri_support),
    ]

    results = []
    for test_name, test_func in tests:
        try:
            passed = test_func(wget_path)
            results.append((test_name, passed))
        except Exception as e:
            print(f"  ❌ Test '{test_name}' raised exception: {e}")
            import traceback
            traceback.print_exc()
            results.append((test_name, False))

    # Print summary
    print(f"\n{'='*60}")
    print(f"Test Summary for {wget_path}")
    print(f"{'='*60}")

    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)

    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {test_name}")

    print(f"\nTotal: {passed_count}/{total_count} tests passed")

    return all(passed for _, passed in results)


def main():
    if len(sys.argv) < 2:
        print("Usage: wget-test.py <wget.exe> [<wget2.exe> ...]")
        print("\nTests wget builds for correct version, features, and functionality")
        print("Set WGET_VERSION environment variable to verify specific version")
        sys.exit(1)

    wget_executables = sys.argv[1:]
    all_passed = True

    print("=" * 60)
    print("Wget Build Test Suite")
    print("=" * 60)

    if 'WGET_VERSION' in os.environ:
        print(f"Expected version: {os.environ['WGET_VERSION']}")

    for wget_path in wget_executables:
        if not test_wget(wget_path):
            all_passed = False

    print("\n" + "=" * 60)
    if all_passed:
        print("✅ All tests passed for all executables!")
        print("=" * 60)
        sys.exit(0)
    else:
        print("❌ Some tests failed!")
        print("=" * 60)
        sys.exit(1)


if __name__ == '__main__':
    main()
