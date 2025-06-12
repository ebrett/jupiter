# Catalyst UI Components for Rails

This directory contains ViewComponent implementations of the Catalyst UI Kit, providing a consistent and reusable component system for the Jupiter application.

## Architecture

All Catalyst components inherit from `Catalyst::BaseComponent`, which provides:

- Consistent variant and size mappings
- CSS class management utilities
- Stimulus.js integration helpers
- ARIA attribute helpers for accessibility
- Test selector helpers for easier testing

## Component Structure

Each component follows this structure:
```
app/components/catalyst/
├── base_component.rb          # Base class with shared functionality
├── button_component.rb        # Component Ruby class
├── button_component.html.erb  # Component template
└── ...
```

## Usage Examples

### Button Component
```erb
# Basic button
<%= render Catalyst::ButtonComponent.new(variant: :primary) do %>
  Click me
<% end %>

# Outline button
<%= render Catalyst::ButtonComponent.new(variant: :secondary, outline: true) do %>
  Cancel
<% end %>

# Plain button
<%= render Catalyst::ButtonComponent.new(variant: :danger, plain: true) do %>
  Delete
<% end %>

# Button with loading state
<%= render Catalyst::ButtonComponent.new(loading: true) do %>
  Saving...
<% end %>

# Button as link
<%= render Catalyst::ButtonComponent.new(href: edit_user_path(@user), variant: :secondary) do %>
  Edit User
<% end %>

# Submit button
<%= render Catalyst::ButtonComponent.new(type: "submit", variant: :primary) do %>
  Save Changes
<% end %>
```

### Badge Component
```erb
# Status badges with icons
<%= render Catalyst::BadgeComponent.new(variant: :success, icon: :check) do %>
  Verified
<% end %>

<%= render Catalyst::BadgeComponent.new(variant: :warning, icon: :warning) do %>
  Pending
<% end %>

<%= render Catalyst::BadgeComponent.new(variant: :danger, icon: :x) do %>
  Failed
<% end %>

# Role badges
<%= render Catalyst::BadgeComponent.new(variant: :primary) do %>
  Admin
<% end %>

<%= render Catalyst::BadgeComponent.new(variant: :indigo) do %>
  Treasury Team
<% end %>

# Interactive badges
<%= render Catalyst::BadgeComponent.new(href: users_path, variant: :info) do %>
  View Users
<% end %>

<%= render Catalyst::BadgeComponent.new(dismissible: true, variant: :warning) do %>
  Dismissible Alert
<% end %>

# Different sizes
<%= render Catalyst::BadgeComponent.new(size: :sm, variant: :success) do %>
  Small
<% end %>

<%= render Catalyst::BadgeComponent.new(size: :md, variant: :success) do %>
  Medium
<% end %>
```

### Input Component
```erb
# Basic input with label
<%= render Catalyst::InputComponent.new(
  label: "Email Address",
  type: "email",
  name: "email",
  placeholder: "Enter your email",
  required: true
) %>

# Input with leading icon
<%= render Catalyst::InputComponent.new(
  label: "Password",
  type: "password",
  name: "password",
  placeholder: "Enter password",
  leading_icon: :lock
) %>

# Input with description
<%= render Catalyst::InputComponent.new(
  label: "Username",
  name: "username",
  placeholder: "Choose a username",
  description: "This will be visible to other users"
) %>

# Input with error state
<%= render Catalyst::InputComponent.new(
  label: "Email",
  type: "email",
  name: "email",
  error_message: "Email is required"
) %>

# Input with both icons
<%= render Catalyst::InputComponent.new(
  label: "Search",
  type: "search",
  name: "search",
  leading_icon: :search,
  trailing_icon: :eye
) %>

# Input with Rails form errors
<%= render Catalyst::InputComponent.new(
  label: "Email",
  name: "email",
  form_errors: @user.errors
) %>

# Disabled input
<%= render Catalyst::InputComponent.new(
  label: "Account Type",
  name: "account_type",
  value: "Premium",
  disabled: true
) %>
```

### Select Component
```erb
# Basic select with options
<%= render Catalyst::SelectComponent.new(
  label: "Country",
  name: "country",
  options: [
    ["United States", "us"],
    ["Canada", "ca"], 
    ["Mexico", "mx"]
  ],
  value: "ca"
) %>

# Simple string array
<%= render Catalyst::SelectComponent.new(
  label: "Priority",
  name: "priority",
  options: ["High", "Medium", "Low"],
  value: "Medium"
) %>

# With custom blank option
<%= render Catalyst::SelectComponent.new(
  label: "Department",
  name: "department", 
  options: ["Engineering", "Design", "Marketing"],
  include_blank: "Select department..."
) %>

# Multiple selection
<%= render Catalyst::SelectComponent.new(
  label: "Skills",
  name: "skills[]",
  options: ["Ruby", "JavaScript", "Python"],
  multiple: true,
  size: 4,
  value: ["Ruby", "JavaScript"]
) %>

# With description
<%= render Catalyst::SelectComponent.new(
  label: "Size",
  name: "size",
  options: ["Small", "Medium", "Large"],
  description: "Choose the display size"
) %>

# With error state
<%= render Catalyst::SelectComponent.new(
  label: "Category",
  name: "category",
  options: ["A", "B", "C"],
  error_message: "Category is required"
) %>

# Required field
<%= render Catalyst::SelectComponent.new(
  label: "Required Field",
  name: "required",
  options: ["Option 1", "Option 2"],
  required: true
) %>

# Disabled select
<%= render Catalyst::SelectComponent.new(
  label: "Account Type",
  name: "account_type",
  options: ["Premium", "Basic"],
  value: "Premium",
  disabled: true
) %>

# Standalone select (no label)
<%= render Catalyst::SelectComponent.new(
  name: "status",
  options: ["Active", "Inactive"]
) %>

# With Rails form errors
<%= render Catalyst::SelectComponent.new(
  label: "Country",
  name: "country",
  options: [["US", "us"], ["CA", "ca"]],
  form_errors: @user.errors
) %>

# Custom styling
<%= render Catalyst::SelectComponent.new(
  label: "Custom Select",
  name: "custom",
  options: ["A", "B", "C"],
  class: "border-2 border-blue-300",
  id: "my-select"
) %>
```

### Notification Component
```erb
# Basic notifications
<%= render Catalyst::NotificationComponent.new(
  variant: :success,
  message: "Your changes have been saved!"
) %>

<%= render Catalyst::NotificationComponent.new(
  variant: :error,
  message: "There was an error processing your request."
) %>

<%= render Catalyst::NotificationComponent.new(
  variant: :warning,
  message: "Please review your settings before continuing."
) %>

<%= render Catalyst::NotificationComponent.new(
  variant: :info,
  message: "New features are available."
) %>

# With titles
<%= render Catalyst::NotificationComponent.new(
  title: "Success!",
  message: "Your profile has been updated.",
  variant: :success
) %>

# Dismissible notifications
<%= render Catalyst::NotificationComponent.new(
  title: "Welcome Back!",
  message: "You have 3 new messages.",
  variant: :info,
  dismissible: true
) %>

# Custom icons
<%= render Catalyst::NotificationComponent.new(
  message: "Custom star icon",
  variant: :info,
  icon: "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
) %>

# No icon
<%= render Catalyst::NotificationComponent.new(
  message: "This has no icon",
  variant: :warning,
  icon: false
) %>

# With action buttons
<%= render Catalyst::NotificationComponent.new(
  title: "Update Available",
  message: "A new version is available.",
  variant: :info,
  dismissible: true,
  actions: capture do %>
    <div class="flex gap-2">
      <%= render Catalyst::ButtonComponent.new(variant: :primary, size: :sm) do %>
        Update Now
      <% end %>
      <%= render Catalyst::ButtonComponent.new(variant: :secondary, size: :sm) do %>
        Later
      <% end %>
    </div>
  <% end
) %>

# Flash message helper (in ApplicationHelper)
<%= render_flash_messages %>
```

### Modal Component
```erb
# Basic modal
<%= render Catalyst::ModalComponent.new(
  title: "Confirm Action",
  description: "Are you sure you want to continue?",
  size: :md,
  open: false
) do %>
  <p>This is the modal body content.</p>
<% end %>

# Modal with actions
<%= render Catalyst::ModalComponent.new(
  title: "Delete Item",
  description: "This action cannot be undone.",
  size: :md,
  open: false,
  actions: capture do %>
    <div class="flex gap-2">
      <%= render Catalyst::ButtonComponent.new(variant: :danger) do %>
        Delete
      <% end %>
      <%= render Catalyst::ButtonComponent.new(variant: :secondary) do %>
        Cancel
      <% end %>
    </div>
  <% end
) do %>
  <p>Are you sure you want to delete this item?</p>
<% end %>

# Different sizes
<%= render Catalyst::ModalComponent.new(size: :xs, title: "Small Modal") %>
<%= render Catalyst::ModalComponent.new(size: :sm, title: "Small Modal") %>
<%= render Catalyst::ModalComponent.new(size: :md, title: "Medium Modal") %>
<%= render Catalyst::ModalComponent.new(size: :lg, title: "Large Modal") %>
<%= render Catalyst::ModalComponent.new(size: :xl, title: "Extra Large Modal") %>
<%= render Catalyst::ModalComponent.new(size: :"2xl", title: "2XL Modal") %>
<%= render Catalyst::ModalComponent.new(size: :"3xl", title: "3XL Modal") %>
<%= render Catalyst::ModalComponent.new(size: :"4xl", title: "4XL Modal") %>
<%= render Catalyst::ModalComponent.new(size: :"5xl", title: "5XL Modal") %>

# Open modal programmatically
<%= render Catalyst::ModalComponent.new(
  title: "Open Modal",
  open: true,
  id: "my-modal"
) %>

# Modal with custom attributes
<%= render Catalyst::ModalComponent.new(
  title: "Custom Modal",
  id: "custom-modal",
  class: "custom-class",
  data: { custom: "value" }
) %>

# JavaScript control
<button data-action="click->catalyst-modal#open" data-catalyst-modal-target="trigger">
  Open Modal
</button>

<div data-controller="catalyst-modal" data-catalyst-modal-open-value="false">
  <!-- Modal content -->
</div>

# Stimulus controller methods
// Open modal
this.element.querySelector('[data-controller="catalyst-modal"]').stimulusController.open()

// Close modal  
this.element.querySelector('[data-controller="catalyst-modal"]').stimulusController.close()
```

### Avatar Component
```erb
# Basic avatar with initials
<%= render Catalyst::AvatarComponent.new(
  initials: "JD",
  alt: "John Doe",
  class: "bg-indigo-600 text-white"
) %>

# Different sizes
<%= render Catalyst::AvatarComponent.new(size: :xs, initials: "XS") %>
<%= render Catalyst::AvatarComponent.new(size: :sm, initials: "SM") %>
<%= render Catalyst::AvatarComponent.new(size: :md, initials: "MD") %>
<%= render Catalyst::AvatarComponent.new(size: :lg, initials: "LG") %>
<%= render Catalyst::AvatarComponent.new(size: :xl, initials: "XL") %>
<%= render Catalyst::AvatarComponent.new(size: :"2xl", initials: "2X") %>

# Square avatars
<%= render Catalyst::AvatarComponent.new(
  initials: "SQ",
  square: true,
  class: "bg-blue-600 text-white"
) %>

# With image (fallback to initials if image fails)
<%= render Catalyst::AvatarComponent.new(
  src: user.avatar.url,
  initials: "JD",
  alt: "John Doe"
) %>

# Clickable avatar (button)
<%= render Catalyst::AvatarComponent.new(
  initials: "BT",
  clickable: true,
  alt: "Button Avatar",
  class: "bg-indigo-600 text-white"
) %>

# Clickable avatar (link)
<%= render Catalyst::AvatarComponent.new(
  initials: "LK", 
  href: user_path(user),
  alt: "Link Avatar",
  class: "bg-green-600 text-white"
) %>

# Generate initials from name
<%= render Catalyst::AvatarComponent.new(
  initials: Catalyst::AvatarComponent.initials_from_name("John Michael Doe"),
  alt: "John Michael Doe",
  class: "bg-purple-600 text-white"
) %>

# Custom styling
<%= render Catalyst::AvatarComponent.new(
  initials: "CS",
  class: "bg-gradient-to-r from-purple-500 to-pink-500 text-white shadow-lg",
  id: "custom-avatar"
) %>

# Empty avatar (no initials or image)
<%= render Catalyst::AvatarComponent.new(
  alt: "No avatar",
  class: "bg-gray-300"
) %>

# Helper method for generating initials
Catalyst::AvatarComponent.initials_from_name("John Doe")       # => "JD"
Catalyst::AvatarComponent.initials_from_name("Madonna")        # => "MA"
Catalyst::AvatarComponent.initials_from_name("John Mike Doe")  # => "JD"
```

### Table Component
```erb
# Basic table
<%= render Catalyst::TableComponent.new(data: @users) do |table|
  table.with_column(key: :id, label: "ID", width: "80px")
  table.with_column(key: :name, label: "Name", sortable: true)
  table.with_column(key: :email, label: "Email")
  table.with_column(key: :created_at, label: "Created", format: :date)
<% end %>

# Sortable table
<%= render Catalyst::TableComponent.new(
  data: @products,
  sortable: true,
  sort_column: params[:sort],
  sort_direction: params[:direction]&.to_sym || :asc,
  striped: true,
  hover: true
) do |table|
  table.with_column(key: :name, label: "Product", sortable: true)
  table.with_column(key: :price, label: "Price", format: :currency, sortable: true, align: :right)
  table.with_column(key: :category, label: "Category", sortable: true)
<% end %>

# Compact table
<%= render Catalyst::TableComponent.new(
  data: @transactions,
  compact: true,
  striped: true
) do |table|
  table.with_column(key: :date, label: "Date", format: :date)
  table.with_column(key: :description, label: "Description")
  table.with_column(key: :amount, label: "Amount", format: :currency, align: :right)
<% end %>

# Table with custom content
<%= render Catalyst::TableComponent.new(data: @users) do |table|
  table.with_column(key: :name, label: "Name")
  table.with_column(key: :status, label: "Status") do |user|
    case user.status
    when "active"
      "<span class='text-green-600'>Active</span>".html_safe
    when "inactive"
      "<span class='text-red-600'>Inactive</span>".html_safe
    end
  end
  table.with_column(label: "Actions") do |user|
    link_to "Edit", edit_user_path(user), class: "text-blue-600"
  end
<% end %>

# Data formatting options
table.with_column(key: :amount, format: :currency)     # $1,234.56
table.with_column(key: :created_at, format: :date)     # 01/15/2023
table.with_column(key: :updated_at, format: :datetime) # 01/15/2023 02:30 PM
table.with_column(key: :active, format: :boolean)      # Yes/No
table.with_column(key: :description, format: :truncate) # Truncates long text

# Column alignment options
table.with_column(key: :id, align: :center)
table.with_column(key: :amount, align: :right)
table.with_column(key: :name, align: :left)  # default

# Empty table with custom message
<%= render Catalyst::TableComponent.new(data: []) do |table|
  table.with_column(key: :name, label: "Name")
  "No records found"
<% end %>
```

### Card Component
```erb
# Basic card
<%= render Catalyst::CardComponent.new do %>
  <h3>Card Title</h3>
  <p>Card content goes here.</p>
<% end %>

# Card with header and footer
<%= render Catalyst::CardComponent.new do |card|
  card.with_header do %>
    <h3>Header Content</h3>
    <p class="text-sm text-gray-500">Subtitle or description</p>
  <% end %>
  card.with_footer do %>
    <div class="flex justify-between">
      <%= button_to "Action", class: "btn btn-primary" %>
      <%= link_to "Cancel", "#", class: "btn btn-secondary" %>
    </div>
  <% end %>
  <p>Main card content with detailed information.</p>
<% end %>

# Card variants
<%= render Catalyst::CardComponent.new(variant: :outlined) do %>
  <p>Outlined card with border</p>
<% end %>

<%= render Catalyst::CardComponent.new(variant: :elevated) do %>
  <p>Elevated card without border</p>
<% end %>

<%= render Catalyst::CardComponent.new(variant: :ghost) do %>
  <p>Ghost card with transparent background</p>
<% end %>

# Interactive cards
<%= render Catalyst::CardComponent.new(hover: true) do %>
  <p>Card with hover shadow effect</p>
<% end %>

<%= render Catalyst::CardComponent.new(clickable: true) do %>
  <p>Clickable card with cursor pointer</p>
<% end %>

<%= render Catalyst::CardComponent.new(href: user_path(@user)) do %>
  <p>Card that acts as a link</p>
<% end %>

# Padding and shadow options
<%= render Catalyst::CardComponent.new(
  padding: :lg,        # :none, :sm, :default, :lg, :xl
  shadow: :xl          # :none, :sm, :default, :lg, :xl
) do %>
  <p>Large padding with extra large shadow</p>
<% end %>

# Complex card example
<%= render Catalyst::CardComponent.new(
  variant: :elevated,
  hover: true,
  padding: :lg
) do |card|
  card.with_header do %>
    <div class="flex items-center justify-between">
      <h3>User Profile</h3>
      <%= avatar_for(@user) %>
    </div>
  <% end %>
  card.with_footer do %>
    <div class="flex gap-2">
      <%= link_to "Edit", edit_user_path(@user), class: "btn btn-primary" %>
      <%= link_to "Delete", user_path(@user), method: :delete, class: "btn btn-danger" %>
    </div>
  <% end %>
  
  <div class="space-y-4">
    <p><strong>Email:</strong> <%= @user.email %></p>
    <p><strong>Role:</strong> <%= @user.role %></p>
    <p><strong>Created:</strong> <%= @user.created_at.strftime("%B %d, %Y") %></p>
  </div>
<% end %>
```

### Breadcrumb Component
```erb
# Basic breadcrumb
<%= render Catalyst::BreadcrumbComponent.new do |breadcrumb|
  breadcrumb.with_item(label: "Home", href: "/")
  breadcrumb.with_item(label: "Users", href: "/users")
  breadcrumb.with_item(label: "John Doe", current: true)
<% end %>

# Breadcrumb with icons
<%= render Catalyst::BreadcrumbComponent.new do |breadcrumb|
  breadcrumb.with_item(label: "Home", href: "/", icon: :home)
  breadcrumb.with_item(label: "Documents", href: "/documents", icon: :folder)
  breadcrumb.with_item(label: "report.pdf", current: true, icon: :document)
<% end %>

# Different separators
<%= render Catalyst::BreadcrumbComponent.new(separator: :chevron) %> # Default
<%= render Catalyst::BreadcrumbComponent.new(separator: :slash) %>
<%= render Catalyst::BreadcrumbComponent.new(separator: :arrow) %>
<%= render Catalyst::BreadcrumbComponent.new(separator: :dot) %>
<%= render Catalyst::BreadcrumbComponent.new(separator: :pipe) %>
<%= render Catalyst::BreadcrumbComponent.new(separator: ">") %> # Custom

# Different sizes
<%= render Catalyst::BreadcrumbComponent.new(size: :sm) %>      # Small
<%= render Catalyst::BreadcrumbComponent.new(size: :default) %> # Default  
<%= render Catalyst::BreadcrumbComponent.new(size: :lg) %>      # Large

# Complex navigation example
<%= render Catalyst::BreadcrumbComponent.new(separator: :slash) do |breadcrumb|
  breadcrumb.with_item(label: "Store", href: "/", icon: :home)
  breadcrumb.with_item(label: "Electronics", href: "/categories/electronics")
  breadcrumb.with_item(label: "Computers", href: "/categories/electronics/computers")
  breadcrumb.with_item(label: "Laptops", href: "/categories/electronics/computers/laptops")
  breadcrumb.with_item(label: "MacBook Pro 14\"", current: true)
<% end %>

# Rails helper integration
<%= render Catalyst::BreadcrumbComponent.new do |breadcrumb|
  breadcrumb.with_item(label: "Users", href: users_path)
  breadcrumb.with_item(label: @user.name, href: user_path(@user))
  breadcrumb.with_item(label: "Edit", current: true)
<% end %>

# Text-only items (no links)
<%= render Catalyst::BreadcrumbComponent.new do |breadcrumb|
  breadcrumb.with_item(label: "Home", href: "/")
  breadcrumb.with_item(label: "Category Name") # No href = text only
  breadcrumb.with_item(label: "Current", current: true)
<% end %>

# Single item breadcrumb
<%= render Catalyst::BreadcrumbComponent.new do |breadcrumb|
  breadcrumb.with_item(label: "Current Page", current: true)
<% end %>
```

### Checkbox Component
```erb
# Basic checkbox with label
<%= render Catalyst::CheckboxComponent.new(
  label: "I agree to the terms and conditions",
  name: "agree_terms",
  required: true
) %>

# Checkbox with description
<%= render Catalyst::CheckboxComponent.new(
  label: "Subscribe to newsletter",
  name: "newsletter",
  description: "Get updates about new features and releases"
) %>

# Checked checkbox
<%= render Catalyst::CheckboxComponent.new(
  label: "Remember my preferences",
  name: "remember",
  checked: true
) %>

# Disabled checkbox
<%= render Catalyst::CheckboxComponent.new(
  label: "This option is disabled",
  name: "disabled_option",
  disabled: true
) %>

# Checkbox with custom color
<%= render Catalyst::CheckboxComponent.new(
  label: "Enable notifications",
  name: "notifications",
  checked: true,
  color: :green
) %>

# Checkbox with error state
<%= render Catalyst::CheckboxComponent.new(
  label: "Accept privacy policy",
  name: "privacy",
  error_message: "You must accept the privacy policy",
  required: true
) %>

# Standalone checkbox (no label)
<%= render Catalyst::CheckboxComponent.new(name: "standalone") %>

# Checkbox with Rails form errors
<%= render Catalyst::CheckboxComponent.new(
  label: "Terms",
  name: "terms",
  form_errors: @user.errors
) %>
```

## Common Patterns

### Variants
Most components support these variants:
- `primary` - Primary brand color
- `secondary` - Secondary/muted styling
- `danger` - Error/destructive actions
- `ghost` - Minimal styling
- `success` - Success states
- `warning` - Warning states
- `info` - Informational states

### Sizes
Components typically support:
- `xs` - Extra small
- `sm` - Small
- `md` - Medium (default)
- `lg` - Large
- `xl` - Extra large

### Accessibility
All components include proper ARIA attributes and semantic HTML. Use the provided helpers:
```ruby
aria_attributes(label: "Button label", expanded: false)
```

### Stimulus Integration
Interactive components use Stimulus controllers:
```ruby
stimulus_attributes("modal", open: "show", close: "hide")
```

## Testing

Component specs are located in `spec/components/catalyst/`. Use the provided test helpers:

```ruby
doc = render_component(component)
element = doc.find("[data-test='component-name']")
assert_css_classes(element, "expected-class")
assert_aria_attributes(element, label: "Expected label")
```

## Development Guidelines

1. Always inherit from `Catalyst::BaseComponent`
2. Use the provided helper methods for consistency
3. Include proper ARIA attributes for accessibility
4. Add test selectors for easier testing
5. Write comprehensive specs for each component
6. Follow the established patterns for variants and sizes