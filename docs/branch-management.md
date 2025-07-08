# Branch Management Workflow for Jupiter

This document establishes comprehensive branch management procedures for the Jupiter project, ensuring consistent development practices and Claude Code session continuity.

## Current Branch Overview

### Main Branch: `main`
- **Purpose**: Stable production-ready code
- **Status**: Clean working tree, all tests passing (1190 examples)
- **Code Quality**: RuboCop clean, no violations
- **Policy**: All feature branches merge here via PR

### Active Remote Branches

#### `feature/treasury_forms`
- **Owner**: Brett McHargue + Claude Code  
- **Purpose**: Treasury forms system implementation with OAuth improvements
- **Last Activity**: 2025-07-06 (test cleanup, removing failed specs)
- **Status**: Active development, test maintenance phase

#### `feature/feature-flags`  
- **Owner**: Brett McHargue
- **Purpose**: Comprehensive feature flag system for NationBuilder OAuth control
- **Status**: Merged to main (available for reference)
- **Key Features**: Pundit authorization, admin interface, granular user/role assignments

#### `system-oauth-status-realtime-filtering`
- **Owner**: Brett McHargue
- **Purpose**: OAuth status filtering functionality  
- **Status**: Remote branch, unknown activity level

### Local Branches

#### `feature/treasury_reimbursement_forms`
- **Owner**: Brett McHargue
- **Last Update**: 2025-06-19
- **Status**: Stale local branch, may need cleanup or sync

## Branch Creation Workflow

### 1. Pre-Branch Planning
Before creating any new branch:
- [ ] Verify clear feature/fix purpose
- [ ] Check existing branches for overlap
- [ ] Create or reference related PRD
- [ ] Ensure main branch is up-to-date

### 2. Branch Creation Process
```bash
# Update main branch
git checkout main  
git pull origin main

# Create feature branch
git checkout -b feature/[descriptive-name]

# Examples:
git checkout -b feature/user-dashboard
git checkout -b bugfix/login-validation  
git checkout -b hotfix/security-patch
```

### 3. Initial Documentation
Immediately after branch creation:

**Development Journal Update**:
```markdown
- `feature/user-dashboard`: [Developer] - User dashboard implementation - [Created 2025-07-06]
  - **PRD**: tasks/prd-user-dashboard.md
  - **Timeline**: 1 week
  - **Dependencies**: Authentication system
```

**Initial Commit**:
```bash
git commit --allow-empty -m "Start feature/user-dashboard

Initial branch for user dashboard implementation.
Related PRD: tasks/prd-user-dashboard.md
Timeline: 1 week"
```

## Branch Switching Protocol

### Before Switching Away
```bash
# Save current work
git add .
git commit -m "WIP: [current state description]"
# OR
git stash push -m "Work in progress: [description]"

# Update development journal with progress
```

### After Switching To Branch
1. Run Claude Code `/branch-context` command
2. Review recent commits: `git log --oneline -5`
3. Check development journal for branch context
4. Resume work from documented state

## Branch Maintenance

### Regular Synchronization
```bash
# Keep feature branch current
git checkout main
git pull origin main
git checkout [feature-branch]
git merge main  # or git rebase main for cleaner history
```

### Progress Documentation
Update `docs/development_journal.md` when:
- Completing major milestones
- Encountering significant challenges  
- Changing approach or design
- Before ending development sessions

## Claude Code Session Continuity

### Session Start Checklist
1. **Run `/quickstart`** - Get overall project status
2. **Run `/branch-context`** - Understand current branch  
3. **Review journal** - Check recent development entries
4. **Check todo status** - Resume pending work

### During Development
- Use meaningful commit messages with context
- Update journal for significant changes
- Reference PRDs and issues in commits
- Create todo items for complex tasks

### Session End Protocol
- Commit or stash all work
- Update journal with progress and next steps
- Note any blockers or dependencies
- Update branch status if needed

## Branch Naming Conventions

### Feature Branches
- **Pattern**: `feature/[description]`
- **Examples**: `feature/user-authentication`, `feature/payment-integration`
- **Purpose**: New functionality development
- **Timeline**: Days to weeks

### Bug Fix Branches  
- **Pattern**: `bugfix/[issue-description]`
- **Examples**: `bugfix/login-validation`, `bugfix/mobile-layout`
- **Purpose**: Fixing existing functionality
- **Timeline**: Hours to days

### Hotfix Branches
- **Pattern**: `hotfix/[urgent-issue]`  
- **Examples**: `hotfix/security-patch`, `hotfix/production-error`
- **Purpose**: Urgent production fixes
- **Timeline**: Hours

### Experiment Branches
- **Pattern**: `experiment/[exploration]`
- **Examples**: `experiment/new-ui-framework`, `experiment/performance-optimization`
- **Purpose**: Trying new approaches (may not be merged)
- **Timeline**: Varies

## Quality Assurance

### Pre-Merge Checklist
- [ ] All tests passing: `bin/rspec`
- [ ] Code quality clean: `bin/rubocop`
- [ ] Security check: `bin/brakeman`
- [ ] Documentation updated
- [ ] Journal entry completed
- [ ] Feature fully implemented

### Merge Process
1. **Sync with main**: `git merge main` or `git rebase main`
2. **Final testing**: Run full test suite
3. **Create PR**: Include branch context and journal references
4. **Code review**: Address feedback
5. **Merge**: Use squash merge for clean history

## Branch Cleanup

### After Successful Merge
```bash
# Delete local branch
git branch -d feature/[branch-name]

# Delete remote branch (if needed)
git push origin --delete feature/[branch-name]
```

### Stale Branch Management
- Review local branches monthly: `git branch -vv`
- Remove stale branches that are merged or abandoned
- Update journal to reflect branch closures

## Troubleshooting

### Lost Context Recovery
If Claude Code loses branch context:
1. **Run `/branch-context`** command
2. **Check git log**: `git log --oneline -10`
3. **Review journal**: Look for recent entries
4. **Assess current state**: `git status` and `git diff`

### Merge Conflicts
```bash
git status                    # Identify conflicted files
git diff                      # Review conflicts
# Resolve conflicts in editor
git add [resolved-files]
git commit -m "Resolve merge conflicts with [description]"
```

### Branch Divergence
```bash
# Check divergence
git log --oneline --graph --all --max-count=10

# Sync with main
git checkout [your-branch]
git merge main  # or git rebase main
```

## Integration with Jupiter Development

### PRD Workflow Integration
- Feature branches should reference PRDs in `/tasks/` directory
- Use PRD structure for planning and documentation
- Link branch progress to PRD milestones

### Testing Integration
- Leverage continuous testing with Guard-rspec
- Use fail-fast testing during development
- Ensure all tests pass before branch completion

### Component Architecture
- Use ViewComponent for reusable UI elements
- Follow Rails 8 conventions with Hotwire
- Maintain consistent styling with TailwindCSS

## Documentation Maintenance

This branch management workflow should be updated when:
- New branch patterns emerge
- Workflow improvements are identified
- Tool integrations change
- Team practices evolve

Regular reviews ensure the workflow remains effective and aligned with Jupiter development needs.