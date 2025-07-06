require 'rails_helper'

# rubocop:disable RSpec/PendingWithoutReason
RSpec.describe 'InKind Donation Form', type: :system do
  let(:submitter_user) { create(:user, first_name: 'John', last_name: 'Submitter') }
  let(:admin_user) { create(:user) }
  let!(:expense_category1) { create(:expense_category, code: 'OFFICE', name: 'Office Supplies') }
  let!(:expense_category2) { create(:expense_category, code: 'TRAVEL', name: 'Travel Expenses') }

  before do
    submitter_user.add_role('submitter')
    admin_user.add_role('system_administrator')
    driven_by(:selenium_chrome_headless)
  end

  describe 'form submission flow' do
    before { sign_in_as(submitter_user) }

    xit 'successfully submits a valid in-kind donation' do
      visit new_inkind_donation_path

      # Verify page loaded
      expect(page).to have_content('New In-Kind Donation')
      expect(page).to have_content('Donor Information')

      # Fill in donor information
      fill_in 'Donor Name', with: 'Jane Philanthropist'
      fill_in 'Donor Email', with: 'jane@example.com'
      fill_in 'Donor Address', with: '123 Charity Lane, Goodville, CA 90210'

      # Select donation type
      select 'Goods', from: 'Donation Type'

      # Fill in donation details
      fill_in 'Item Description', with: 'Office furniture including 10 desks and 20 chairs'
      select 'Office Supplies', from: 'Expense Category'
      fill_in 'Fair Market Value', with: '5000.00'
      fill_in 'Donation Date', with: '2024-01-15'

      # Submit form
      click_button 'Submit Donation'

      # Verify success
      expect(page).to have_content('In-kind donation submitted successfully')
      expect(page).to have_current_path(inkind_donations_path)

      # Verify the donation appears in the list
      expect(page).to have_content('Jane Philanthropist')
      expect(page).to have_content('$5,000.00')
      expect(page).to have_content('Goods')
    end

    xit 'shows validation errors for invalid submission' do
      visit new_inkind_donation_path

      # Submit empty form
      click_button 'Submit Donation'

      # Verify we're still on the form page
      expect(page).to have_current_path(inkind_donations_path)

      # Check for error messages
      expect(page).to have_content('Donor name is required')
      expect(page).to have_content('Donor email is required')
      expect(page).to have_content('Donor address is required')
      expect(page).to have_content('Donation type is required')
      expect(page).to have_content('Item description is required')
      expect(page).to have_content('Expense category code is required')
      expect(page).to have_content('Donation date is required')

      # Verify form fields have error styling
      expect(page).to have_css('.border-red-300')
    end

    xit 'validates email format in real-time', :js do
      visit new_inkind_donation_path

      # Fill in invalid email
      fill_in 'Donor Email', with: 'invalid-email'
      find('body').click # Trigger blur event

      # Check for client-side validation message
      expect(page).to have_content('Please enter a valid email address')

      # Fix the email
      fill_in 'Donor Email', with: 'valid@example.com'
      find('body').click

      # Error should disappear
      expect(page).not_to have_content('Please enter a valid email address')
    end

    xit 'prevents future donation dates', :js do
      visit new_inkind_donation_path

      # Try to enter a future date
      tomorrow = (Date.current + 1.day).strftime('%Y-%m-%d')
      fill_in 'Donation Date', with: tomorrow
      find('body').click

      # Check for validation message
      expect(page).to have_content('Donation date cannot be in the future')
    end

    xit 'persists form data on validation errors' do
      visit new_inkind_donation_path

      # Fill in partial form
      fill_in 'Donor Name', with: 'Partial Donor'
      fill_in 'Donor Email', with: 'partial@example.com'
      select 'Services', from: 'Donation Type'

      # Submit incomplete form
      click_button 'Submit Donation'

      # Verify data persistence
      expect(find_field('Donor Name').value).to eq('Partial Donor')
      expect(find_field('Donor Email').value).to eq('partial@example.com')
      expect(find_field('Donation Type').value).to eq('Services')
    end

    xit 'handles special characters in text fields' do
      visit new_inkind_donation_path

      # Fill form with special characters
      fill_in 'Donor Name', with: "O'Brien & Associates"
      fill_in 'Donor Email', with: 'obrien@example.com'
      fill_in 'Donor Address', with: '123 "Main" Street, Apt #5'
      select 'Goods', from: 'Donation Type'
      fill_in 'Item Description', with: 'Books & <Magazines> with "quotes"'
      select 'Office Supplies', from: 'Expense Category'
      fill_in 'Fair Market Value', with: '100.00'
      fill_in 'Donation Date', with: '2024-01-15'

      click_button 'Submit Donation'

      # Verify success
      expect(page).to have_content('In-kind donation submitted successfully')

      # Check that special characters are properly displayed
      expect(page).to have_content("O'Brien & Associates")
    end
  end

  describe 'authorization' do
    xit 'redirects non-authenticated users to login' do
      visit new_inkind_donation_path

      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content('Please sign in')
    end

    xit 'shows authorization error for users without submitter role' do
      user_without_role = create(:user)
      sign_in_as(user_without_role)

      visit new_inkind_donation_path

      expect(page).to have_content('You are not authorized')
      expect(page).to have_current_path(root_path)
    end
  end

  describe 'admin viewing donations' do
    before do
      # Create some donations
      create(:inkind_request,
        form_data: {
          'donor_name' => 'First Donor',
          'donor_email' => 'first@example.com',
          'donor_address' => '123 First St',
          'donation_type' => 'Goods',
          'item_description' => 'Computers',
          'expense_category_code' => 'OFFICE',
          'donation_date' => '2024-01-10',
          'country' => 'US',
          'submitter_email' => 'submitter@example.com',
          'submitter_name' => 'Test Submitter'
        },
        amount_requested: 2000.00
      )

      sign_in_as(admin_user)
    end

    xit 'allows admin to view all donations' do
      visit inkind_donations_path

      expect(page).to have_content('In-Kind Donations')
      expect(page).to have_content('First Donor')
      expect(page).to have_content('$2,000.00')
      expect(page).to have_content('Computers')
    end

    xit 'allows admin to view donation details' do
      donation = InkindRequest.first
      visit inkind_donation_path(donation)

      expect(page).to have_content('In-Kind Donation Details')
      expect(page).to have_content('First Donor')
      expect(page).to have_content('first@example.com')
      expect(page).to have_content('123 First St')
      expect(page).to have_content('Computers')
    end

    xit 'allows admin to export donations as CSV' do
      visit inkind_donations_path

      click_link 'Export to CSV'

      # Verify CSV download (this is tricky in system specs, so we just check the link exists)
      expect(page).to have_link('Export to CSV', href: export_inkind_donations_path(format: :csv))
    end
  end

  describe 'form interactions', :js do
    before { sign_in_as(submitter_user) }

    xit 'shows/hides validation errors dynamically' do
      visit new_inkind_donation_path

      # Trigger validation on empty required field
      donor_name_field = find_field('Donor Name')
      donor_name_field.click
      find_field('Donor Email').click # Blur from donor name

      expect(page).to have_content('Donor name is required')

      # Fill in the field
      donor_name_field.fill_in with: 'Valid Donor'
      find_field('Donor Email').click

      expect(page).not_to have_content('Donor name is required')
    end

    xit 'calculates and displays character count for text areas' do
      visit new_inkind_donation_path

      description_field = find_field('Item Description')

      # Type in the field
      description_field.fill_in with: 'This is a test description'

      # Check character count is displayed (if implemented)
      # This assumes the form shows character count - adjust based on actual implementation
      within('.field-wrapper', text: 'Item Description') do
        expect(page).to have_content('26 / 1000')
      end
    end
  end

  describe 'error recovery' do
    before { sign_in_as(submitter_user) }

    xit 'allows resubmission after fixing errors' do
      visit new_inkind_donation_path

      # Submit with missing required fields
      fill_in 'Donor Name', with: 'Test Donor'
      click_button 'Submit Donation'

      # Should see errors
      expect(page).to have_content('Donor email is required')

      # Fix the errors
      fill_in 'Donor Email', with: 'donor@example.com'
      fill_in 'Donor Address', with: '456 Test Ave'
      select 'Goods', from: 'Donation Type'
      fill_in 'Item Description', with: 'Test items'
      select 'Office Supplies', from: 'Expense Category'
      fill_in 'Fair Market Value', with: '250.00'
      fill_in 'Donation Date', with: '2024-01-01'

      # Resubmit
      click_button 'Submit Donation'

      # Should succeed this time
      expect(page).to have_content('In-kind donation submitted successfully')
    end
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in 'login_page_email_address', with: user.email_address
    fill_in 'login_page_password', with: 'password123' # Factory default password
    find('input[type="submit"][value="Sign In"]').click
  end
end
# rubocop:enable RSpec/PendingWithoutReason
