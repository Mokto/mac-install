"""
Authenticate with Audible UK and save activation bytes to ~/.audible/activation_bytes.

Run once — aax-to-chapters.sh picks up the saved bytes automatically.

Usage:
    uv run python audible/get_activation_bytes.py
"""

import pathlib
import readline  # noqa: F401 — fixes URL paste on macOS
import audible


CONFIG_DIR = pathlib.Path.home() / ".audible"
AUTH_FILE  = CONFIG_DIR / "theo.json"


def _login_url_callback(url: str) -> str:
    print("\n1. Open this URL in your browser:\n")
    print(f"   {url}\n")
    print("2. Log in with your Amazon.co.uk credentials.")
    print("3. You'll land on a 'not found' page — that's expected.")
    print("4. Copy the full URL from the address bar and paste it below.\n")
    return input("Paste redirect URL: ").strip()


def main() -> None:
    CONFIG_DIR.mkdir(exist_ok=True)

    if AUTH_FILE.exists():
        print(f"Loading existing auth → {AUTH_FILE}")
        auth = audible.Authenticator.from_file(AUTH_FILE)
    else:
        print("Authenticating with Audible UK…")
        auth = audible.Authenticator.from_login_external(
            locale="uk",
            login_url_callback=_login_url_callback,
        )
        auth.to_file(AUTH_FILE)
        print(f"\nAuth saved → {AUTH_FILE}")

    print("\nFetching activation bytes…")
    activation_bytes = auth.get_activation_bytes()
    bytes_file = CONFIG_DIR / "activation_bytes"
    bytes_file.write_text(activation_bytes + "\n")
    print(f"Activation bytes: {activation_bytes}")
    print(f"Saved → {bytes_file}")


if __name__ == "__main__":
    main()
