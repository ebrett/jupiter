# Journal Instructions for Claude Code

This rule governs how Claude Code should maintain an ongoing development journal for tracking work progress and providing daily catchup summaries.

## Journal Location and Structure

**File**: `docs/development_journal.md`

**Format**: Chronological entries with structured sections for easy scanning and context building.

## When to Update the Journal

Claude should update the journal after completing significant work sessions, specifically:

1. **Bug fixes** - Any bugs identified and resolved
2. **Feature implementations** - New features or enhancements added
3. **Refactoring** - Code improvements or architectural changes  
4. **Infrastructure changes** - CI/CD, testing, or deployment modifications
5. **Important decisions** - Technical choices, architecture decisions, or approach changes
6. **Problem investigations** - Research into issues, even if not fully resolved

## Journal Entry Structure

Each entry should follow this format:

```markdown
## [Date] - [Brief Summary Title]
**Developer(s)**: [Name/Handle] | **Context**: [How work was initiated]

### What Was Done
- Bullet point list of specific actions taken
- Include file names and line numbers where applicable
- Mention any tools, commands, or scripts used

### Why It Was Done  
- Context for the changes
- Problem being solved
- User request or issue being addressed

### Technical Details
- Key code changes made
- Architectural decisions
- Testing approach used
- Any notable implementation details

### Results
- What works now that didn't before
- Test results (passing/failing counts)
- Performance improvements if applicable
- Any remaining issues or follow-up needed

### Next Steps (if applicable)
- Related work that should be done
- Known issues to address
- Improvements to consider

---
```

## Daily Catchup Format

When the user asks for a "catchup" or "where are we", Claude should:

1. **Read the journal** to understand recent work
2. **Summarize the last 3-5 entries** in a concise format
3. **Highlight current state** of key features/systems
4. **Identify any pending work** or unresolved issues
5. **Suggest logical next steps** based on recent work patterns

## Developer Attribution Guidelines

**For Claude Code entries**:
- Use "Claude Code (with [User])" format 
- Include how work was initiated (user request, bug report, etc.)

**For human developer entries**:
- Use developer's preferred name/handle
- Include context (pair programming, solo work, code review, etc.)

**For collaborative work**:
- List all contributors: "Jane Doe & Claude Code (with Brett)"
- Note the nature of collaboration in context

## Example Journal Entry

```markdown
## 2025-06-20 - Fixed Modal Authentication Bugs from Cursor Bot Report
**Developer(s)**: Claude Code (with Brett) | **Context**: User reported Cursor bot identified bugs in PR #37

### What Was Done
- Fixed undefined FeatureFlagService in `app/components/auth_modal_component.rb:14`
- Replaced setTimeout race condition with Promise-based modal timing in `app/javascript/controllers/auth_controller.js:11-25`
- Eliminated framework conflicts in modal opening method `app/javascript/controllers/auth_controller.js:39-74`
- Ran comprehensive tests to verify fixes

### Why It Was Done
- Cursor bot identified 3 critical bugs in PR #37 that could cause authentication failures
- Race conditions were causing unreliable modal behavior, especially on slower systems
- Mixed event paradigms were creating conflicts with Stimulus framework

### Technical Details
- Changed `FeatureFlagService.enabled?(flag_name, nil)` to pass `current_user` for proper user context
- Replaced 10ms setTimeout with `requestAnimationFrame` and Promise-based approach for reliable timing
- Simplified modal opening to use consistent DOM manipulation instead of mixing custom events
- Added proper escape key handling and modal cleanup methods

### Results
- All authentication modal tests passing (90 examples, 0 failures)
- Modal timing issues resolved - no more race conditions
- Feature flag integration working correctly with user context
- RuboCop showing only acceptable violations (comprehensive test expectations)

### Next Steps
- Monitor for any authentication-related issues in production
- Consider adding JavaScript unit tests for modal interactions
- Review other components for similar race condition patterns

---
```

## Multi-Developer Collaboration Features

### Developer Activity Summary
Maintain a running summary at the top of the journal showing recent contributors:

```markdown
## Recent Contributors (Last 30 Days)
- **Brett McHargue**: Project owner, authentication system, bug fixes
- **Claude Code**: Automated bug fixing, testing, refactoring
- **[Other Developer]**: [Their focus areas]

## Active Branches & Ownership
- `feature/enhanced-testing-strategy`: Brett + Claude Code
- `feature/payment-workflows`: [Developer Name]
- `bugfix/oauth-flow`: [Developer Name]
```

### Conflict Prevention
- **Before starting work**: Check recent journal entries for conflicts
- **Branch coordination**: Note active branches and who's working on what
- **Handoff documentation**: When passing work between developers, include detailed context

### Cross-Reference System
- **Link related entries**: Reference previous entries when building on someone else's work
- **Mention dependencies**: Note if work depends on another developer's changes
- **Tag blocking issues**: Mark entries that block other developers' work

## Important Guidelines

1. **Be Specific**: Include file paths, line numbers, method names, and test results
2. **Provide Context**: Explain why changes were needed, not just what was changed
3. **Track Progress**: Show how issues evolve and get resolved over time
4. **Include Failures**: Document what didn't work and why, for future reference
5. **Link Related Work**: Connect entries that build on each other
6. **Keep It Scannable**: Use clear headings and bullet points for quick reading

## Journal Maintenance

- **Update frequency**: After each significant work session
- **Entry length**: Aim for 100-300 words per entry
- **File size**: If journal exceeds 10,000 lines, create monthly archives in `docs/journal_archive/`
- **Cross-references**: Link to related PRs, issues, or other documentation when relevant

This journal serves as both a development log and a knowledge base for understanding the project's evolution and current state.