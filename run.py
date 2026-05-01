import os
import subprocess
import webbrowser
import time
import sys

def main():
    print("="*50)
    print("  Starting Python Development Server for Projects")
    print("="*50)
    
    port = 8000
    
    print(f"[*] Starting server at http://localhost:{port} ...")
    
    # Start the Python server
    server_process = subprocess.Popen([sys.executable, "-m", "http.server", str(port)])

    # Give the server a moment to spin up
    time.sleep(1.5)

    print("[*] Opening your browser...")
    webbrowser.open(f"http://localhost:{port}/index.html")

    print("\n[+] Server is running! Press Ctrl+C in this terminal to stop.")
    
    try:
        server_process.wait()
    except KeyboardInterrupt:
        print("\n[*] Stopping the server...")
        server_process.terminate()
        print("[+] Server stopped successfully.")

if __name__ == "__main__":
    main()
