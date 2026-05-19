# Emacs Configuration

Personal Emacs config for macOS — Emacs 29+. Covers completion, file management, org-mode/GTD, Python/C++/LaTeX development, email, and terminal.

## Structure

| File | Purpose |
|---|---|
| `init.el` | Main configuration — all `use-package` declarations |
| `early-init.el` | Startup performance tuning (runs before package init) |
| `custom.el` | Auto-managed by Emacs GUI — **not tracked** |
| `personal.el` | Private identifiers (name, email addresses) — **not tracked**; copy `personal.el.example` if cloning |

Packages install automatically from MELPA on first startup. Nothing else needs manual setup beyond Emacs itself.

## Completion Stack

Three layers that work together:

- **Minibuffer**: `vertico` (vertical candidate list, reversed) + `marginalia` (annotations) + `orderless` (space-separated fuzzy filtering)
- **In-buffer**: `corfu` with `corfu-popupinfo` (auto-popup with documentation delay)
- **Context actions**: `embark` (`C-.` to act on thing at point, `C-;` for dwim)

## File Management

`dirvish` overrides `dired` globally via `dirvish-override-dired-mode`. It adds a three-panel layout (parent | listing | preview), subtree expansion, vc-state indicators, and git commit messages inline. `dired-rainbow` colors files by type.

Key bindings: `C-c f` (full Dirvish), `C-c s` (sidebar), `C-c F` (fd search).

## Org-mode and GTD

Org is configured for a full GTD workflow. Highlights:

- Three TODO keyword sequences: project states (`ACTIVE`/`HOLD`), task states (`TODO`/`NEXT`/`WAITING`), and an opportunity pipeline (`LEAD` → `WON`/`LOST`)
- Six capture templates (`C-c c`) landing in dedicated files (inbox, projects, tickler, reference, opportunities, contacts)
- Custom agenda views via `org-super-agenda`: GTD dashboard, by-context, weekly review, and pipeline views
- `org-contacts` integrates with mu4e compose for contact auto-completion
- Babel enabled for Python, Shell, R, and SQL
- `org-modern` for visual polish

## Programming

### Python

`eglot` connects to `pylsp` with `ruff` (linting + formatting) and `mypy` (type checking). Virtual environments managed by `pyvenv` pointing to `~/.virtualenvs/`. Works over TRAMP for remote hosts.

### C++ / CUDA

`eglot` connects to `clangd`. `.cu` files open in `c++-mode`.

### Jupyter

`jupyter` package provides notebook support inside Emacs.

### Processing

`processing-mode` configured for the macOS Processing.app install.

## LaTeX

`auctex` with `reftex`. PDFs open in `pdf-tools` (dark mode enabled). SyncTeX forward/inverse search wired up between the source buffer and the PDF viewer (`C-c C-g` for forward search). Compilation auto-refreshes the PDF buffer.

## Email (mu4e)

`mu4e` loaded from the system mu install (not MELPA). Two contexts matched by maildir prefix (Gmail and Proton Mail via Bridge). Credentials from macOS Keychain. mbsync syncs every 5 minutes. `C-c m` opens mu4e.

## Theme and UI

- Theme: `doom-one-light` from `doom-themes`
- Modeline: `doom-modeline` showing time, battery, git branch, LSP checker status
- Icons: `nerd-icons` + `nerd-icons-dired`
- Tab bar enabled; `vertico-reverse-mode` pins the minibuffer to the bottom

## Terminal

`vterm` for a full terminal emulator. `inheritenv` propagates buffer-local environment variables (e.g. `WORKON_HOME`) into vterm sessions. `exec-path-from-shell` ensures Emacs inherits `$PATH` from the login shell.

## Claude Code

`claude-code-ide` installed via `:vc` from GitHub. `C-c C-'` opens the IDE menu. Uses vterm as the terminal backend.

## macOS Key Modifiers

```
Option  → Meta
Command → Super
```

`windmove` bound to Meta-arrows for window switching. `M-s-arrows` (`M-⌥-arrows`) resize windows.
