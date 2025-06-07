# Claude Development Preferences for Peter

## When you wake up
- If you're in a project directory (e.g. there's a .git folder), check for the .claude folder (see below), and review /memory and decisions.md

## Git & Version Control
- Always ask before: git commit, git merge, git push, git rebase, rm operations
- OK to run non-destructive, read-only commands without asking: git status, git add, git log, git diff, git fetch
- Prefer logical commit organization and clean branch management
- Like descriptive commit messages with context
- **REMINDER**: When starting new features/topics, remind me to create a new branch from main (one feature/bug = one branch to avoid PR scope creep)
- **Snapshot Branch Workflow**: For concurrent development while maintaining clean PRs:
    - Branch main → feat1 (do work)
    - Branch feat1 → feat1-review (create PR from this stable snapshot)
    - Continue development on feat1 or branch feat1 → feat2 for dependent work
    - Keeps PRs stable during review while allowing continued development


## Testing Philosophy  
- Suspect tests over code when failures occur - assume code works as expected
- Prefer robust, non-flaky tests that handle random variation
- Value comprehensive test coverage but want fast CI feedback
- Like separation of model-dependent vs model-independent tests

## Code Organization
- Separate concerns properly (testing improvements vs code features in different branches)
- Value clean architecture (unified packages, eliminate duplication)
- Want features committed to appropriate branches by purpose

## Environment Management
- Prefer conda environments for Python management
- Avoid references to old/obsolete directories
- Value containerized development environments

## Project Structure
- Like comprehensive documentation and clear README organization  
- Value automated tooling (test runner scripts, GitHub Actions)
- Prefer minimal but effective CI/CD setups

## Context Management
- ⚠️ WARN BEFORE AUTO-COMPACT: Always give warning when context is getting full and auto-compact is approaching
- Like to review work and commit changes before conversation compacts
- Prefer to save important state before context reset

## Project Structure - .claude Directory
- **Preferred structure for all projects**: Organized .claude folder for knowledge management
- **Ask about git tracking**: .claude folder may or may not be committed to repo
- **Required subdirectories**:
  - `/.claude` - Local, repo specific memory, contains the following
    - `/input` - For sharing files with Claude (user input area)
    - `/memory` - Session-by-session summaries of work done, so claude can re-trace steps if needed (yyyyddmm-descriptive-name.md format)
    - `decisions.md` - A list of key design/implementation decisions record - short summaries.
