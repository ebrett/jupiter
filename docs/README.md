# Jupiter Documentation

This directory contains all project documentation, planning materials, and technical guides for the Jupiter application.

## Directory Structure

### `/feature-flags/`
Documentation for the feature flag system implementation:
- **README.md** - Comprehensive guide to feature flag usage, hybrid authorization approach with Pundit
- **nationbuilder_signin.md** - Specific documentation for the NationBuilder OAuth feature flag and removal procedures

### `/plans/`
Planning documents and feature specifications:
- **feature_flags.md** - Original feature flag system plan (converted from PHP/Laravel to Rails)
- **investigate-cloudflare-challenge-error.md** - Investigation plan for Cloudflare-related issues

### Root Documentation Files
- **no_service_objects.md** - Architecture decision against traditional service objects pattern
- **oauth_implementation.md** - NationBuilder OAuth integration technical documentation

## Documentation Standards

### Creating New Documentation
- Use clear, descriptive filenames with underscores
- Include table of contents for documents longer than 3 sections
- Add code examples with proper syntax highlighting
- Link to related files when referencing other parts of the system

### Updating Existing Documentation
- Keep documentation current with code changes
- Update this README when adding new directories or major documents
- Use consistent formatting and terminology throughout

## Related Files
- **CLAUDE.md** (project root) - Development guidance for Claude Code interactions
- **README.md** (project root) - General project information and setup instructions
- **tasks/** directory - Contains PRDs (Product Requirements Documents) for active development work

## Quick Navigation

| Topic | Location | Purpose |
|-------|----------|---------|
| Feature Flags | `feature-flags/README.md` | Implementation guide and best practices |
| OAuth Setup | `oauth_implementation.md` | NationBuilder integration details |
| Architecture Decisions | `no_service_objects.md` | Reasoning behind service architecture |
| Development Plans | `plans/` | Feature specifications and investigation plans |
| Task Management | `../tasks/` | Active PRDs and development tasks |