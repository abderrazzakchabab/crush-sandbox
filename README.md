# crush-sandbox

Run [Charm Crush](https://github.com/charmbracelet/crush) inside a throwaway
Docker container, with the current directory as the workdir and your local
Crush config mounted in.

## Install

```bash
./install.sh
```

This builds `crush-sandbox:<version>`, writes a launcher to
`~/.local/bin/crush-sandbox`, and adds `alias crush=~/.local/bin/crush-sandbox`
to your shell rc file.

Then:

```bash
cd ~/some/project
crush
```

## What gets mounted

| Host                            | Container                            | Mode |
| ------------------------------- | ------------------------------------ | ---- |
| `$PWD`                          | `/workspace`                         | rw   |
| `~/.config/crush`               | `/home/crush/.config/crush`          | rw   |
| `~/.local/share/crush`          | `/home/crush/.local/share/crush`     | rw   |
| `~/.config/AGENTS.md`           | `/home/crush/.config/AGENTS.md`      | ro   |
| `~/.gitconfig`                  | `/home/crush/.gitconfig`             | ro   |
| `~/.config/git/config`          | `/home/crush/.config/git/config`     | ro   |
| `$SSH_AUTH_SOCK`                | `/ssh-agent`                         | rw   |

Crush reads global config from `CRUSH_GLOBAL_CONFIG` and data (sessions,
provider auth) from `CRUSH_GLOBAL_DATA`, both pointed at the mounts above.

The container runs as your host UID/GID, so files it creates in the workspace
stay yours. It is started with `--rm --init --cap-drop ALL
--security-opt no-new-privileges`.

## Options

```bash
./install.sh --version 0.101.0     # different Crush release
./install.sh --alias csx           # different alias name
./install.sh --shell fish          # bash | zsh | fish | all | none
./install.sh --no-build            # skip the image build
./install.sh --build-only          # image only, no launcher/alias
```

Any extra argument passed to the alias goes straight to `crush`, e.g.
`crush --yolo` or `crush logs --tail 50`.

## Runtime overrides

```bash
CRUSH_SANDBOX_DOCKER="sudo docker" crush   # or podman
CRUSH_SANDBOX_REBUILD=1 crush              # rebuild before running
CRUSH_SANDBOX_IMAGE=other:tag crush        # run a different image
```

API keys are passed through from your environment when set (Anthropic,
OpenAI, OpenRouter, DeepSeek, Gemini, AWS/Bedrock, Azure, Vertex, proxies, …).
Keys already stored in `~/.local/share/crush` are picked up automatically.

## Notes

- Your user must be able to talk to the Docker daemon. If it isn't, either
  `sudo usermod -aG docker $USER` (log out/in) or use
  `CRUSH_SANDBOX_DOCKER="sudo docker"`.
- The image only contains bash, git, curl, ripgrep, openssh-client, less and
  procps. Add whatever your projects need to the `apt-get install` list in the
  `Dockerfile`.
- `crush` reads `.crushrc` / `crush.json` from the project directory, and both
  are trusted code, so only run the sandbox in directories you trust.
