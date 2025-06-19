# Feature Flag: `nationbuilder_signin`

**Status**: 🟡 Active (Testing)  
**Created**: 2025-06-18  
**Type**: Global Feature (no user assignments required)

## Overview

Controls access to NationBuilder OAuth sign-in functionality across the application. When disabled, users can only sign in with email/password. When enabled, the NationBuilder OAuth option is available to all users.

## Purpose

- **Safe Testing**: Allows testing NationBuilder OAuth integration in production with controlled access
- **Gradual Rollout**: Can be enabled for specific environments or user groups before full deployment
- **Quick Rollback**: Instant disable capability if issues arise with NationBuilder integration

## Code Changes Made

### 1. Database Schema
- **Table**: `feature_flags` - stores flag configuration
- **Table**: `feature_flag_assignments` - stores user/role-specific assignments
- **Seed Data**: Creates `nationbuilder_signin` flag (disabled by default)

### 2. Service Layer
- **File**: `app/services/feature_flag_service.rb`
  - Added global feature detection for `nationbuilder_signin`
  - Enabled for all users when flag is globally enabled (no assignments needed)

### 3. Controller Protection
- **File**: `app/controllers/nationbuilder_auth_controller.rb`
  - Added `check_nationbuilder_feature_flag` before_action
  - Redirects to sign-in page with error if feature disabled

### 4. View Templates
- **File**: `app/views/sessions/new.html.erb`
  - Wrapped NationBuilder OAuth button with `feature_enabled?('nationbuilder_signin')` check
  
- **File**: `app/components/auth_modal_component.html.erb`
  - Wrapped NationBuilder OAuth section with feature flag check
  - Includes OAuth button and "or" divider

### 5. Component Updates
- **File**: `app/components/auth_modal_component.rb`
  - Added `FeatureFlagHelper` include
  - Added `current_user` method for feature flag context

### 6. Test Updates
- **File**: `spec/requests/nationbuilder_auth_controller_spec.rb`
  - Added feature flag setup in test environment
  - Enabled flag for OAuth controller tests

- **File**: `spec/requests/nationbuilder_profile_sync_spec.rb`
  - Added feature flag setup for profile sync tests

- **File**: `spec/components/auth_modal_component_spec.rb`
  - Added separate test contexts for enabled/disabled flag states
  - Tests both presence and absence of OAuth elements

## Current Configuration

```ruby
# Flag Configuration
name: 'nationbuilder_signin'
description: 'Enable NationBuilder OAuth sign-in functionality. When disabled, users can only sign in with email/password.'
enabled: false  # Disabled by default
type: 'global'  # No user assignments required - available to all when enabled
```

## Usage in Code

```ruby
# In views/templates
<% if feature_enabled?('nationbuilder_signin') %>
  <!-- NationBuilder OAuth button -->
<% end %>

# In controllers
before_action :check_nationbuilder_feature_flag

# In services
FeatureFlagService.enabled?('nationbuilder_signin', current_user)
```

## Admin Management

1. **Enable/Disable**: Access via `/admin/feature_flags`
2. **Toggle**: Real-time enable/disable with AJAX interface
3. **Assignments**: Not applicable (global feature)
4. **Cache**: Clear cache button available if needed

## Testing Checklist

- [ ] Verify OAuth button hidden when flag disabled
- [ ] Verify OAuth button appears when flag enabled  
- [ ] Test OAuth flow works when enabled
- [ ] Test OAuth endpoints blocked when disabled
- [ ] Verify admin interface toggle functionality
- [ ] Test in both sign-in page and modal

## Removal Plan (When Ready for Production)

### Phase 1: Preparation
1. **Verify Stability**: Ensure NationBuilder OAuth is fully tested and stable
2. **User Communication**: Notify users that NationBuilder sign-in will be permanently available
3. **Backup Plan**: Ensure ability to quickly disable via admin if needed

### Phase 2: Code Cleanup
When removing this feature flag, revert the following changes:

#### 1. Remove Feature Flag Checks
```bash
# Files to update:
app/views/sessions/new.html.erb
app/components/auth_modal_component.html.erb
```

**Remove:**
```erb
<% if feature_enabled?('nationbuilder_signin') %>
<!-- Keep the OAuth content -->
<% end %>
```

**Keep:** The NationBuilder OAuth button and related HTML (unwrapped)

#### 2. Remove Controller Protection
```bash
# File: app/controllers/nationbuilder_auth_controller.rb
```

**Remove:**
- `include FeatureFlaggable`
- `before_action :check_nationbuilder_feature_flag`
- `check_nationbuilder_feature_flag` method

#### 3. Remove Component Dependencies
```bash
# File: app/components/auth_modal_component.rb
```

**Remove:**
- `include FeatureFlagHelper`
- `current_user` method (if only used for feature flags)

#### 4. Clean Up Service Layer
```bash
# File: app/services/feature_flag_service.rb
```

**Remove:** `'nationbuilder_signin'` from `global_features` array

#### 5. Update Tests
```bash
# Files to update:
spec/requests/nationbuilder_auth_controller_spec.rb
spec/requests/nationbuilder_profile_sync_spec.rb
spec/components/auth_modal_component_spec.rb
```

**Remove:** Feature flag setup and separate test contexts
**Simplify:** Tests to expect OAuth elements are always present

#### 6. Database Cleanup (Optional)
```bash
# Remove feature flag data (optional - can keep for historical record)
rails console
> FeatureFlag.find_by(name: 'nationbuilder_signin')&.destroy
```

### Phase 3: Verification
1. **Run Tests**: Ensure all tests pass after removal
2. **Deploy to Staging**: Verify OAuth functionality unchanged
3. **Monitor Production**: Watch for any issues after deployment

## Migration Strategy

1. **Immediate**: Enable flag in production when ready for testing
2. **Gradual**: No user/role assignments needed (global feature)
3. **Full Rollout**: Leave enabled until removal
4. **Cleanup**: Remove code when feature is stable and permanent

## Notes

- This is a **global feature flag** - when enabled, available to all users
- No user or role assignments are required
- The flag serves as a simple on/off switch for the entire OAuth feature
- Safe to enable/disable without affecting user sessions or data