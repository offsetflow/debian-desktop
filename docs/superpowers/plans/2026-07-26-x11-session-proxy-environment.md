# X11 Session Proxy Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make applications launched by dwm inherit the local mihomo proxy environment without duplicating proxy configuration in Zsh.

**Architecture:** Export the proxy environment once from the repository-managed X11 session entrypoint after mihomo starts. Protect the ownership boundary with a behavioral regression test that runs the entrypoint in a temporary HOME, captures the environment received by a fake dwm, and separately sources Zsh without inherited proxy variables.

**Tech Stack:** POSIX shell, Bash source tests.

## Global Constraints

- HTTP and HTTPS proxy values are `http://127.0.0.1:7890`.
- ALL_PROXY values are `socks5://127.0.0.1:7890`.
- NO_PROXY values are `127.0.0.1,localhost,::1`.
- Preserve unrelated local changes in `shell/zshrc`.
- This configures inherited proxy variables, not TUN transparent proxying.
- Do not commit or push without explicit user instruction.

---

### Task 1: Move proxy ownership to the X11 session

**Files:**
- Create: `tests/xinitrc_proxy_env_test.sh`
- Modify: `x11/xinitrc`
- Modify: `shell/zshrc`

**Interfaces:**
- Consumes: the X11 session launched through `~/.xinitrc`.
- Produces: eight exported proxy variables inherited by dwm child processes.

- [ ] **Step 1: Write the failing behavioral test**

Create an executable Bash test that builds a temporary repository-shaped HOME,
copies the real `x11/xinitrc`, stubs its external commands, and makes a fake
`~/.local/bin/dwm` save its environment. Assert that the captured environment
contains these exact values:

```sh
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
export HTTP_PROXY="http://127.0.0.1:7890"
export HTTPS_PROXY="http://127.0.0.1:7890"
export all_proxy="socks5://127.0.0.1:7890"
export ALL_PROXY="socks5://127.0.0.1:7890"
export no_proxy="127.0.0.1,localhost,::1"
export NO_PROXY="127.0.0.1,localhost,::1"
```

In a clean proxy environment, source the real `shell/zshrc` with Zsh and assert
that none of `http_proxy`, `https_proxy`, `HTTP_PROXY`, `HTTPS_PROXY`,
`all_proxy`, `ALL_PROXY`, `no_proxy`, or `NO_PROXY` becomes set.

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash tests/xinitrc_proxy_env_test.sh
```

Expected: FAIL because the exports are absent from `x11/xinitrc` and still
present in `shell/zshrc`.

- [ ] **Step 3: Implement the minimal move**

Add the eight exact exports to `x11/xinitrc` immediately after the mihomo
startup block. Remove only the proxy marker block and its eight exports from
`shell/zshrc`; preserve the unrelated opencode PATH addition.

- [ ] **Step 4: Run focused verification**

Run:

```bash
sh -n x11/xinitrc
bash tests/xinitrc_proxy_env_test.sh
```

Expected: both commands exit successfully.

- [ ] **Step 5: Run full verification**

Run:

```bash
for test_file in tests/*_test.sh; do bash "$test_file"; done
git diff --check
```

Expected: all commands exit successfully.

- [ ] **Step 6: Leave changes uncommitted**

Run:

```bash
git status --short
```

Expected: the design, plan, test, `x11/xinitrc`, and the pre-existing
unrelated `shell/zshrc` changes remain available for user review.
