# Rules

- Do not edit the openai repo.
- I am working on OPENCLAW, it is in `openclaw` repo (it is checked out in the repo root)
- This repo is a light-wrapper around the `openclaw` repo. This repo is used to track scripts and openclaw.json config file.
- Import and follow `openclaw/AGENTS.md` in addition to this wrapper repo's instructions.
- Load claude.md and skills etc from the `openclaw` repo.
- Treat `openclaw/` and `codex/` as important local context even if they are ignored by Git. Examine them when they are relevant to the task; do not assume ignored means unimportant.
- `deploy` is the source of truth for the config and soul.md etc. Do not edit openclaw.json in `state`.
- Do not ever install the macos launch agent.
- Do not install npm versions less than one week old.

## Development flow
- Keep this project as simple as possible. Do not over-complicate. Do not add configurable settings that are not necessary.
- Prefer existing string normalization/coercion utilities over creating new string helper functions.
- Do not update or run tests until prompted.
- Do not remove comments from files unless explicitly asked.
- Do not add excessive comments describing what you are doing.
- When debugging, look at the logs, config files etc and on the internet first.
- When debugging the **codex harness** specifically, the `codex/` directory at the repo root is the cloned Codex source. Read it freely.
- You may restart the local gateway without asking. Do it by sending SIGINT (`kill -INT <pid>`) to the running gateway process (the `openclaw` process, not the `oc` / `pnpm` / `run-node.mjs` wrappers). Find it with `ps aux | grep openclaw`. oc is usually called in a `while` loop, so it should restart automatically.
