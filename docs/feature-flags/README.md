# Feature Flags Documentation

This directory contains documentation for all active feature flags in the Jupiter application. Each feature flag has its own documentation file that outlines implementation details and removal procedures.

## Overview

Feature flags allow us to safely deploy and test new functionality in production environments while maintaining control over who has access to these features. They enable gradual rollouts, A/B testing, and quick rollbacks if issues arise.

## Architecture & Design Principles

### Hybrid Authorization Approach

We use a **hybrid approach** combining direct service calls with Pundit policies, chosen for optimal performance and maintainability:

#### 1. Direct Service/Helper Approach
**Used for:**
- Simple global features (like `nationbuilder_signin`)
- View-level feature flag checks
- Features that need to work without user context (OAuth flows)
- High-performance scenarios where minimal overhead is needed

```ruby
# In views
<% if feature_enabled?('feature_name') %>
  <!-- Feature content -->
<% end %>

# In controllers
before_action :require_feature_flag, 'feature_name'

# In services
FeatureFlagService.enabled?('feature_name', current_user)
```

#### 2. Pundit Policy Approach
**Used for:**
- Admin management of feature flags themselves
- Complex features combining permissions with feature flags
- Features requiring sophisticated authorization logic
- Multi-layered access control scenarios

```ruby
# Admin feature flag management
authorize FeatureFlag, :index?
authorize @feature_flag, :toggle?

# Complex feature access
authorize :nationbuilder_oauth, :access?
```

### Why This Hybrid Approach?

| Aspect | Direct Service | Pundit Policies | Chosen For |
|--------|---------------|-----------------|------------|
| **Performance** | ✅ Minimal overhead | ⚠️ Object instantiation cost | Simple checks |
| **User Context** | ✅ Works without users | ❌ Assumes user present | OAuth flows |
| **Testability** | ⚠️ Service-level testing | ✅ Policy-specific testing | Complex logic |
| **Consistency** | ⚠️ Custom patterns | ✅ Standard authorization | Admin operations |
| **Flexibility** | ❌ Limited logic | ✅ Rich authorization rules | Multi-factor access |

## Feature Flag Types

### 1. Global Features
Features available to all users when enabled (no assignments required).

**Examples:** `nationbuilder_signin`, `new_ui_theme`

**Characteristics:**
- No user or role assignments needed
- Simple on/off switch
- Often used for infrastructure or UI changes
- Work for unauthenticated users

```ruby
# Implementation
def global_feature?
  global_features = %w[nationbuilder_signin new_ui_theme]
  global_features.include?(flag_name)
end
```

### 2. User-Assigned Features
Features requiring explicit user assignments.

**Examples:** `beta_dashboard`, `advanced_reporting`

**Characteristics:**
- Require specific user assignments
- Can be assigned to individual users or roles
- Used for gradual rollouts or beta testing
- Require authenticated user context

### 3. Admin-Only Features
Features that combine feature flags with admin permissions.

**Examples:** `debug_mode`, `system_maintenance_tools`

**Characteristics:**
- Use Pundit policies for authorization
- Combine feature enablement with role checking
- Often have complex access rules

## Implementation Guidelines

### Creating a New Feature Flag

1. **Plan the Feature Type**
   ```ruby
   # Global feature - available to all when enabled
   global_features = %w[new_feature_name]
   
   # OR user-assigned feature - requires assignments
   # (default behavior)
   ```

2. **Add Database Entry**
   ```ruby
   # In db/seeds.rb or migration
   FeatureFlag.find_or_create_by!(name: 'feature_name') do |flag|
     flag.description = 'Description of what this controls'
     flag.enabled = false  # Always start disabled
   end
   ```

3. **Implement Checks**
   ```ruby
   # For global features (views/controllers)
   feature_enabled?('feature_name')
   
   # For complex features (use Pundit)
   authorize :feature_name, :access?
   ```

4. **Create Documentation**
   - Create `docs/feature-flags/feature_name.md`
   - Document all code changes
   - Include removal procedures
   - Add testing checklist

### Testing Feature Flags

#### Unit Tests
```ruby
# Test feature flag service
RSpec.describe FeatureFlagService do
  context 'when flag is enabled' do
    before { create_enabled_flag('feature_name') }
    # Test enabled behavior
  end
end
```

#### Integration Tests
```ruby
# Test UI changes
context 'when feature is enabled' do
  before { enable_feature_flag('feature_name') }
  
  it 'shows new functionality' do
    expect(page).to have_content('New Feature')
  end
end
```

#### Component Tests
```ruby
# Test ViewComponents
context 'when feature flag is disabled' do
  it 'does not render feature content' do
    expect(rendered_content).not_to include('feature-content')
  end
end
```

## Admin Management

### Accessing Feature Flags
- **URL:** `/admin/feature_flags`
- **Permission:** Requires admin role
- **Policy:** `FeatureFlagPolicy`

### Available Operations
1. **View All Flags:** List status and assignments
2. **Toggle Flags:** Real-time enable/disable
3. **Manage Assignments:** Add/remove user or role assignments
4. **Clear Cache:** Reset feature flag cache

### Admin Authorization
```ruby
# app/policies/feature_flag_policy.rb
class FeatureFlagPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end
  
  def toggle?
    user&.admin?
  end
  
  def destroy?
    user&.admin? && user&.has_role?(:system_administrator)
  end
end
```

## Performance Considerations

### Caching Strategy
- **Cache Duration:** 1 hour default
- **Cache Keys:** `feature_flag_{name}` and `feature_flag_{name}_assignments`
- **Invalidation:** Automatic on flag updates
- **Manual Clear:** Available via admin interface

### Optimization Tips
1. **Minimize Checks:** Don't check the same flag multiple times in a request
2. **Use Helpers:** Leverage view helpers for template checks
3. **Cache Results:** Store results in instance variables for repeated use
4. **Global Features:** Prefer global features over user assignments when possible

## Security Considerations

### Access Control
- All admin operations require authentication and authorization
- Feature flag assignments are audited (created_by/updated_by)
- Fail-safe design: features default to disabled on errors

### Data Protection
- Feature flag names should not expose sensitive information
- Descriptions should be clear but not reveal internal details
- Admin access is logged through standard Rails logging

## Monitoring and Observability

### Logging
- All feature flag checks are logged in development
- Errors are logged with context in all environments
- Admin operations are tracked via audit fields

### Metrics to Monitor
- Feature flag check performance
- Cache hit/miss ratios
- Admin operation frequency
- Feature adoption rates (when assignments are used)

## Best Practices

### Naming Conventions
- Use lowercase with underscores: `new_feature_name`
- Be descriptive: `nationbuilder_signin` not `nb_auth`
- Include scope when relevant: `admin_debug_mode`

### Documentation Requirements
- **Purpose:** Why does this flag exist?
- **Type:** Global vs. user-assigned
- **Dependencies:** What other systems are affected?
- **Removal Plan:** How to clean up when ready

### Lifecycle Management
1. **Development:** Create flag, implement checks
2. **Testing:** Enable in staging, verify functionality
3. **Gradual Rollout:** Enable for subset of users
4. **Full Deployment:** Enable globally
5. **Cleanup:** Remove flag and associated code

## Common Patterns

### Controller Protection
```ruby
class SomeController < ApplicationController
  include FeatureFlaggable
  
  before_action :require_feature_flag, 'feature_name'
  
  # OR for complex authorization
  before_action :authorize_feature_access
  
  private
  
  def authorize_feature_access
    authorize :feature_name, :access?
  end
end
```

### View Conditionals
```erb
<%# Simple feature check %>
<% if feature_enabled?('feature_name') %>
  <div class="new-feature">...</div>
<% end %>

<%# Helper method for cleaner templates %>
<%= if_feature_enabled('feature_name') do %>
  <div class="new-feature">...</div>
<% end %>
```

### Service Integration
```ruby
class SomeService
  def process
    if FeatureFlagService.enabled?('advanced_processing', user)
      advanced_process
    else
      standard_process
    end
  end
end
```

## Active Feature Flags

| Flag Name | Type | Status | Documentation |
|-----------|------|--------|---------------|
| `nationbuilder_signin` | Global | 🟡 Testing | [docs](./nationbuilder_signin.md) |

## Troubleshooting

### Common Issues

**Feature not appearing despite being enabled:**
1. Check if user has required assignments (non-global features)
2. Verify cache is current (try cache clear)
3. Confirm feature flag logic in templates/controllers

**Performance issues:**
1. Review number of feature flag checks per request
2. Check cache hit rates
3. Consider making feature global if appropriate

**Admin access denied:**
1. Verify user has admin role
2. Check Pundit policy permissions
3. Confirm user is authenticated

### Debug Commands
```ruby
# Rails console debugging
FeatureFlag.find_by(name: 'feature_name')
FeatureFlagService.enabled?('feature_name', user)
FeatureFlagService.clear_cache('feature_name')

# Check assignments
user.feature_flag_assignments.includes(:feature_flag)
```

## Migration and Cleanup

When a feature flag is no longer needed (feature is stable and permanent):

1. **Communicate:** Notify team of removal plan
2. **Document:** Update feature flag documentation
3. **Remove Code:** Clean up all feature flag checks
4. **Test:** Verify functionality unchanged
5. **Deploy:** Remove feature flag from database
6. **Archive:** Move documentation to archived folder

See individual feature flag documentation files for specific removal procedures.