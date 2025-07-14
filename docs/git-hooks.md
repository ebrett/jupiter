# Git Hooks Setup

This project uses git hooks to enforce development workflow standards.

## Main Branch Protection

A pre-commit hook prevents direct commits to the main branch, requiring all changes to go through feature branches and pull requests.

### Setup

After cloning the repository, run:

```bash
bin/setup-git-hooks
```

### What it does

- **Blocks commits to main**: Prevents accidental direct commits to the main branch
- **Provides helpful guidance**: Shows clear error message with instructions
- **Preserves git-secrets**: Maintains existing security scanning functionality

### Example

```bash
# This will be blocked:
git checkout main
git commit -m "some change"
# ❌ Direct commits to main branch are not allowed!

# This works:
git checkout -b feature/my-feature
git commit -m "some change"
# ✅ Commit successful
```

### Bypass (Emergency Only)

If you absolutely must commit directly to main (emergency hotfix):

```bash
git commit --no-verify -m "emergency fix"
```

**Note**: This should only be used in genuine emergencies and requires careful review.

## Other Hooks

- **git-secrets**: Scans for AWS credentials and other secrets before commits
- **prepare-commit-msg**: Adds context to commit messages

## Development Workflow

1. Always create feature branches: `git checkout -b feature/your-feature`
2. Make commits on feature branches
3. Create pull requests for code review
4. Merge to main via PR only

This ensures:
- All changes are reviewed
- Main branch history is clean
- CI/CD runs on all changes
- Rollback is easier if needed