# UI Component Reference

This document provides a comprehensive reference for UI components available in Jupiter, including implemented ViewComponents and external libraries for reference.

## Tailwind UI Components

Located in `scripts/tailwind-ui/` - HTML examples from Tailwind UI for reference and translation to ViewComponents:

### Feedback Components
- **Alerts**: `scripts/tailwind-ui/feedback/alerts/`
  - with_accent_border.html
  - with_action.html
  - with_description.html
  - with_dismiss_button.html
  - with_link_on_right.html
  - with_list.html

### Form Components
- **Input Groups**: `scripts/tailwind-ui/forms/input_groups/`
- **Radio Groups**: `scripts/tailwind-ui/forms/radio_groups/`
- **Select Menus**: `scripts/tailwind-ui/forms/select_menus/`
- **Checkboxes**: `scripts/tailwind-ui/forms/checkboxes/`
- **Toggles**: `scripts/tailwind-ui/forms/toggles/`
- **Sign In/Registration**: `scripts/tailwind-ui/forms/sign_in_and_registration/`

### Navigation Components
- **Navbar**: `scripts/tailwind-ui/navigation/navbars/`
- **Sidebar Navigation**: `scripts/tailwind-ui/navigation/sidebar_navigation/`
- **Tabs**: `scripts/tailwind-ui/navigation/tabs/`
- **Breadcrumbs**: `scripts/tailwind-ui/navigation/breadcrumbs/`
- **Pagination**: `scripts/tailwind-ui/navigation/pagination/`

### List Components
- **Tables**: `scripts/tailwind-ui/lists/tables/`
- **Stacked Lists**: `scripts/tailwind-ui/lists/stacked_lists/`
- **Grid Lists**: `scripts/tailwind-ui/lists/grid_lists/`
- **Feeds**: `scripts/tailwind-ui/lists/feeds/`

### Overlay Components
- **Modal Dialogs**: `scripts/tailwind-ui/overlays/modal_dialogs/`
- **Notifications**: `scripts/tailwind-ui/overlays/notifications/`
- **Drawers**: `scripts/tailwind-ui/overlays/drawers/`

## Catalyst UI Kit Components

Located in `scripts/catalyst-ui-kit/` - React/TypeScript components for translation to Rails ViewComponents with Stimulus/Turbo integration:

### Component Files
- **JavaScript**: `scripts/catalyst-ui-kit/javascript/`
- **TypeScript**: `scripts/catalyst-ui-kit/typescript/`

### Available Components
- alert.jsx/tsx
- avatar.jsx/tsx
- badge.jsx/tsx
- button.jsx/tsx
- checkbox.jsx/tsx
- combobox.jsx/tsx
- dialog.jsx/tsx
- dropdown.jsx/tsx
- input.jsx/tsx
- select.jsx/tsx
- table.jsx/tsx
- text.jsx/tsx
- textarea.jsx/tsx
- navbar.jsx/tsx
- sidebar.jsx/tsx
- pagination.jsx/tsx

### Demo Applications
- **JavaScript Demo**: `scripts/catalyst-ui-kit/demo/javascript/`
- **TypeScript Demo**: `scripts/catalyst-ui-kit/demo/typescript/`

## Usage

To reference these components in Claude Code:

```bash
# Read specific Tailwind UI component
read scripts/tailwind-ui/feedback/alerts/with_action.html

# Read Catalyst component
read scripts/catalyst-ui-kit/typescript/alert.tsx

# List all alert variants
ls scripts/tailwind-ui/feedback/alerts/
```

## Translated Components

The following components have been translated from Tailwind UI/Catalyst to Rails ViewComponents:

### ✅ Implemented ViewComponents

#### Catalyst::AlertComponent
- **Source**: `scripts/catalyst-ui-kit/typescript/alert.tsx`
- **Location**: `app/components/catalyst/alert_component.rb`
- **Features**: 
  - Multiple variants (success, error, warning, info)
  - Action buttons support
  - Dismissible functionality
  - Stimulus controller integration (`app/javascript/controllers/alert_controller.js`)
- **Usage**: Used for OAuth error handling and flash messages

#### Catalyst::NotificationComponent  
- **Source**: Similar to Tailwind UI notifications
- **Location**: `app/components/catalyst/notification_component.rb`
- **Features**: Flash message display with variants
- **Usage**: Main flash message system via `render_flash_messages` helper

### 🔄 Partial Implementations

#### AuthModalComponent
- **Location**: `app/components/auth_modal_component.rb`
- **Features**: Login/registration modal
- **Stimulus**: `app/javascript/controllers/auth_controller.js`

### 📋 Available for Translation

#### High Priority
- **Table Component**: Catalyst table component needs enhancement
- **Modal/Dialog**: Could use Catalyst dialog patterns for consistency
- **Form Components**: Input groups, select menus, checkboxes from Tailwind UI
- **Navigation**: Sidebar and navbar improvements

#### Medium Priority  
- **Badge Component**: Catalyst badge for status indicators
- **Avatar Component**: User profile display
- **Button Component**: Consistent button styling
- **Dropdown Component**: Menu and select improvements

## Notes

- Tailwind UI components are HTML examples with Tailwind CSS classes
- Catalyst UI Kit components are React/TypeScript with Headless UI integration
- All components follow accessibility best practices
- Components can be adapted for Rails ViewComponent architecture
- When translating, maintain Stimulus/Turbo/Hotwire patterns for interactivity
