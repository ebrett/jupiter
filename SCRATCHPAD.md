# Jupiter Development Scratchpad

This file contains ideas, improvements, and future enhancements for the Jupiter application.

## Feature Flag Management

### Current State
Feature flags are managed via Rails runner commands, which are verbose and hard to remember.

### Improvement Ideas
- **Create Rake tasks for feature flag management** - Make common operations easier
  ```bash
  bin/rake flags:enable[nationbuilder_signin]
  bin/rake flags:disable[nationbuilder_signin] 
  bin/rake flags:status[nationbuilder_signin]
  bin/rake flags:toggle[nationbuilder_signin]
  bin/rake flags:list
  ```

- **Create bash scripts for convenience** - Even simpler one-liners
  ```bash
  bin/enable-oauth          # Enables NationBuilder OAuth
  bin/disable-oauth         # Disables NationBuilder OAuth
  bin/toggle-oauth          # Toggles NationBuilder OAuth
  bin/flag-status <name>    # Shows status of any flag
  ```

- **Admin UI for feature flags** - Web interface for non-technical users
  - Add to admin panel/dashboard
  - Toggle switches for each flag
  - Description and impact warnings
  - Audit log of flag changes

## Authentication & UX

### Mobile Navigation
- ✅ Mobile hamburger menu implemented with plain JavaScript
- 🔄 **TODO: Investigate Stimulus mobile compatibility issue** (GitHub issue #47)
  - Test other Stimulus controllers on mobile
  - Consider mobile-specific Stimulus debugging
  - May need to file upstream bug report

### Authentication Flow
- ✅ Dedicated sign-in/sign-up pages implemented
- ✅ NationBuilder OAuth integration with feature flag system
- ✅ OAuth button styling improved - professional indigo theme with proper spacing and interactions
- **Consider adding social auth providers**
  - Google OAuth
  - GitHub OAuth (for developer-focused features)
  - Apple Sign In (for iOS users)

### Password Management
- **Add password reset functionality**
  - Forgot password flow
  - Email-based reset tokens
  - Password strength indicators
  - Password history (prevent reuse)

## Development Tools

### Testing & Quality
- **Add more comprehensive system tests**
  - End-to-end user journeys
  - Multi-device testing
  - Performance testing

### Developer Experience
- **Enhanced seeding system**
  - More realistic test data
  - Configurable data volumes
  - Performance profiling data

### Monitoring & Observability
- **Add application monitoring**
  - Error tracking (Sentry, Rollbar)
  - Performance monitoring (New Relic, DataDog)
  - User analytics (privacy-focused)

## Architecture & Performance

### Database
- **Add database performance optimizations**
  - Query optimization
  - Index analysis
  - Connection pooling tuning

### Caching
- **Implement smart caching strategy**
  - Fragment caching for expensive views
  - HTTP caching headers
  - Background job result caching

### Background Jobs
- **Enhance Solid Queue setup**
  - Dead letter queue handling
  - Job retry strategies
  - Performance monitoring

## Security Enhancements

### OAuth Security
- **Enhance NationBuilder OAuth security**
  - PKCE implementation
  - State parameter validation
  - Token rotation
  - Scope limiting

### General Security
- **Add security headers**
  - Content Security Policy (CSP)
  - HSTS headers
  - X-Frame-Options
  - Rate limiting

## User Experience

### Accessibility
- **Improve accessibility compliance**
  - ARIA label audit
  - Keyboard navigation testing
  - Screen reader compatibility
  - Color contrast validation

### Internationalization
- **Add i18n support**
  - Multi-language support
  - RTL language support
  - Locale-specific date/time formatting
  - Currency localization

## DevOps & Deployment

### CI/CD Pipeline
- **Enhance GitHub Actions**
  - Parallel testing
  - Deployment automation
  - Security scanning
  - Dependency updates

### Production Readiness
- **Add production monitoring**
  - Health check endpoints
  - Metrics collection
  - Log aggregation
  - Backup strategies

## Future Features

### User Management
- **Enhanced user profiles**
  - Avatar uploads
  - Preference settings
  - Activity history
  - Two-factor authentication

### Notifications
- **Real-time notifications**
  - WebSocket integration
  - Email notifications
  - Push notifications (PWA)
  - Notification preferences

### Reporting & Analytics
- **User analytics dashboard**
  - Usage metrics
  - Performance insights
  - User behavior analysis
  - Export capabilities

---

## Notes
- Items marked with ✅ are completed
- Items marked with 🔄 are in progress
- Items marked with **bold** are planned improvements
- This file should be updated regularly as new ideas emerge

## Recent Development Journal

### 2025-07-03 - OAuth Button Styling Improvements
**Problem**: NationBuilder OAuth buttons had poor visual design with basic gray borders, looking unprofessional compared to the main authentication forms.

**Solution Implemented**:
- Redesigned OAuth buttons with indigo color scheme (complementary to blue primary buttons)
- Added professional styling: `border-2 border-indigo-600 rounded-lg bg-indigo-50 text-indigo-700`
- Enhanced interactivity with hover states and smooth transitions
- Improved spacing and typography for better visual hierarchy
- Fixed divider rendering issues (self-closing div tags) and improved text padding
- Updated both sign-in and sign-up pages consistently

**Technical Details**:
- Files modified: `app/views/sessions/new.html.erb`, `app/views/users/new.html.erb`
- Used Tailwind CSS utility classes for consistent design system
- Added focus states for accessibility compliance
- Improved icon choice and positioning

**Result**: OAuth integration now has professional, trustworthy appearance that matches overall application design quality.

---

## Contributing
When adding ideas to this scratchpad:
1. Include context about the current state
2. Describe the problem being solved
3. Provide concrete implementation suggestions
4. Consider impact and priority level