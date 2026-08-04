# Tauri 2 + Miso project template

A Tauri 2, and Miso (haskell-like language + elm-like views) template.

## For developers

With your package manager

1. install dependencies

`bun install` for bun

2. run Tauri in dev mode

`bun run Tauri dev` for bun

### Commit messages

This project uses [Husky](https://typicode.github.io/husky/) with a `commit-msg` hook to enforce the [Conventional Commits](https://www.conventionalcommits.org/) format: `<type>: <description>`.

Allowed types:

| Emoji | Type       | Description                                                        |
| ----- | ---------- | ------------------------------------------------------------------ |
| 🏗️    | `build`    | Changes to the build system or external dependencies               |
| 🧹    | `chore`    | Maintenance tasks that don't affect src or test files              |
| ⚙️    | `ci`       | Changes to CI configuration and scripts                            |
| 📚    | `docs`     | Documentation only changes                                         |
| ✨    | `feat`     | A new feature                                                      |
| 🐛    | `fix`      | A bug fix                                                          |
| ⚡    | `perf`     | A code change that improves performance                            |
| ♻️    | `refactor` | A code change that neither fixes a bug nor adds a feature          |
| ⏪    | `revert`   | Reverts a previous commit                                          |
| 💄    | `style`    | Changes that do not affect the meaning of the code (formatting, …) |
| ✅    | `test`     | Adding or correcting tests                                         |

Example: `feat: add dark mode toggle`
