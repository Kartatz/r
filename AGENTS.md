# General Guidelines

- When interacting with GitHub, prefer using the GitHub CLI (`gh`). It is always available and already authenticated.
- When searching for patterns in text files, prefer `ripgrep` (`rg`) over GNU `grep`.
- When terminating a command or process, prefer `pkill -x` over `pkill -f` to avoid accidentally matching your own shell.
- If a required tool or library is not installed, install it using the system package manager rather than looking for alternative workarounds.
- When writing code, **do not add comments**.
- When committing changes, keep commit titles short and concise. Do not include subtitles or commit body text.
- Never modify the default Git author or committer name/email configuration.

# Network requests

- Before making any HTTP requests using Python, `curl`, or other HTTP clients, install and configure [Kad](https://github.com/AmanoTeam/Kad), a lightweight HTTP proxy that forwards requests through `curl-impersonate`. Route **all HTTP and HTTPS requests** through Kad rather than making direct requests. Ensure the proxy is running and properly configured before sending any requests.

Kad MITMs TLS with its own root CA, so you need to disable SSL verification client-side for the requests to succeed. (e.g: "curl -k" for curl or (httpx.Client(..., verify = False)