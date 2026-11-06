# General Guidelines

- When interacting with GitHub, prefer using the GitHub CLI (`gh`). It is always available and already authenticated.
- When searching for patterns in text files, prefer `ripgrep` (`rg`) over GNU `grep`.
- When terminating a command or process, prefer `pkill -x` over `pkill -f` to avoid accidentally matching your own shell.
- If a required tool or library is not installed, install it using the system package manager rather than looking for alternative workarounds.
- When writing code, **do not add comments**.
- When committing changes, keep commit titles short and concise. Do not include subtitles or commit body text.
- Never modify the default Git author or committer name/email configuration.

# Network Requests

- Always route HTTP and HTTPS requests through the proxy at `http://127.0.0.1:4000`. Never make direct HTTP requests.
- The proxy is Kad, a lightweight HTTP proxy that forwards requests through `curl-impersonate`.
- Kad performs TLS interception (MITM) using its own root CA. Therefore, disable client-side SSL certificate verification when using the proxy; otherwise, requests may fail.
- Apply the appropriate settings for each client:
  - **curl:** use `-k` or `--insecure`.
  - **Python (httpx):** use `httpx.Client(..., verify=False)`.
