# General Guidelines

- When interacting with GitHub, prefer using the GitHub CLI (`gh`). It is always available and already authenticated.
- When searching for patterns in text files, prefer `ripgrep` (`rg`) over GNU `grep`.
- When working with `pkill` or `pgrep`, always include the `--ignore-ancestors` flag.
- When configuring CMake projects, always use the Ninja generator (`-G Ninja`).
- If a required tool or library is not installed, install it using the system package manager rather than looking for alternative workarounds.
- When writing code, **do not add comments**.
- When asked about project implementation details, inspect the source code instead of relying on memory.
- When committing changes, keep commit titles short and concise. Do not include subtitles or commit body text.
- Never modify the default Git author or committer name/email configuration.
