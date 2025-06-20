# Journal Entry Template

Copy this template when manually adding entries to `docs/development_journal.md`:

```markdown
## [YYYY-MM-DD] - [Brief Summary Title]
**Developer(s)**: [Your Name] | **Context**: [How this work was initiated - user request, bug report, planned feature, etc.]

### What Was Done
- [Specific action taken]
- [Include file paths: `app/controllers/example_controller.rb:25`]
- [Commands run: `bin/rspec`, `bin/rubocop --autocorrect`]
- [Tools used: Cursor, VS Code, manual testing]

### Why It Was Done  
- [Problem being solved]
- [User request or business need]
- [Technical debt being addressed]
- [Bug report or issue being fixed]

### Technical Details
- [Key code changes made]
- [Architecture decisions]
- [Libraries or frameworks used]
- [Database changes if applicable]
- [Testing approach]

### Results
- [What works now that didn't before]
- [Test results: X examples, Y failures]
- [Performance improvements if applicable]
- [Screenshots or demos if relevant]

### Next Steps (if applicable)
- [Related work that should be done]
- [Known issues to address]
- [Improvements to consider]
- [Dependencies for other developers]

---
```

## Quick Examples for Common Scenarios

**Bug Fix:**
```markdown
**Developer(s)**: Jane Doe | **Context**: User reported login failure in Issue #42
```

**Feature Development:**
```markdown
**Developer(s)**: John Smith | **Context**: Implementing payment workflow from PRD-payment-system.md
```

**Pair Programming:**
```markdown
**Developer(s)**: Alice & Bob | **Context**: Pair programming session on OAuth integration
```

**Code Review Follow-up:**
```markdown
**Developer(s)**: Charlie | **Context**: Addressing PR #35 review comments from Brett
```

**Collaborative AI Work:**
```markdown
**Developer(s)**: Dana & Claude Code | **Context**: Investigating performance issues with AI assistance
```

## Tips for Good Journal Entries

1. **Be specific about files changed** - include paths and line numbers when relevant
2. **Include test results** - show the impact of your changes
3. **Explain the "why"** - context helps other developers understand decisions
4. **Link to related work** - mention PRs, issues, or previous journal entries
5. **Note blocking issues** - help other developers avoid conflicts
6. **Update the contributor summary** - keep the top section current