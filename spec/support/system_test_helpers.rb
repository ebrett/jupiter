module SystemTestHelpers
  def login_as(user, password = 'password123')
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
  end
  
  def logout
    click_link "Sign out" if page.has_link?("Sign out")
  end
  
  def ensure_roles_exist
    Role.initialize_all
  end
  
  def create_user_with_role(role_name, attributes = {})
    user = create(:user, attributes)
    user.add_role(role_name)
    user
  end
  
  def expect_authorized_access
    expect(page).not_to have_content("not authorized")
    expect(current_path).not_to eq(root_path)
  end
  
  def expect_unauthorized_access
    expect(page).to have_content("not authorized")
    expect(current_path).to eq(root_path)
  end
  
  def within_user_row(user, &block)
    within("tr", text: user.email_address, &block)
  end
  
  def select_users_for_bulk_action(*users)
    users.each do |user|
      within_user_row(user) do
        check "user_ids[]"
      end
    end
  end
  
  def perform_bulk_action(action, option = nil)
    select action, from: "bulk_action"
    select option, from: "role_to_#{action.downcase.gsub(' ', '_')}" if option
    click_button "Apply to Selected"
  end
  
  def expect_role_badge(role_name, css_class = nil)
    expect(page).to have_css(".role-badge", text: role_name)
    expect(page).to have_css(".#{css_class}") if css_class
  end
  
  def visit_admin_section_as(user, path)
    login_as(user)
    visit path
  end
  
  def expect_admin_navigation_items(*items)
    within("nav") do
      items.each do |item|
        expect(page).to have_link(item)
      end
    end
  end
  
  def expect_no_admin_navigation_items(*items)
    within("nav") do
      items.each do |item|
        expect(page).not_to have_link(item)
      end
    end
  end
end

RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system
end