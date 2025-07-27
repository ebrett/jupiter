# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TailwindFormBuilder, type: :form_builder do
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:user) { User.new(email_address: 'test@example.com') }
  let(:builder) { described_class.new(:user, user, template, {}) }

  describe 'constants' do
    it 'defines base input classes' do
      expect(TailwindFormBuilder::BASE_INPUT_CLASSES).to include('appearance-none', 'block', 'w-full')
    end

    it 'defines error input classes' do
      expect(TailwindFormBuilder::ERROR_INPUT_CLASSES).to include('border-red-300', 'text-red-900')
    end

    it 'defines label classes' do
      expect(TailwindFormBuilder::LABEL_CLASSES).to include('block', 'text-sm', 'font-medium')
    end

    it 'defines submit button classes' do
      expect(TailwindFormBuilder::SUBMIT_BUTTON_CLASSES).to include('bg-blue-600', 'hover:bg-blue-700')
    end

    it 'defines checkbox classes' do
      expect(TailwindFormBuilder::CHECKBOX_CLASSES).to include('h-4', 'w-4', 'text-blue-600')
    end
  end

  describe '#email_field' do
    it 'renders email field with base styling' do
      output = builder.email_field(:email_address)

      expect(output).to include('type="email"')
      expect(output).to include('name="user[email_address]"')
      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end

    it 'preserves additional options' do
      output = builder.email_field(:email_address, placeholder: 'Enter email', required: true)

      expect(output).to include('placeholder="Enter email"')
      expect(output).to include('required="required"')
    end

    it 'merges custom classes with base classes' do
      output = builder.email_field(:email_address, class: 'custom-class')

      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
      expect(output).to include('custom-class')
    end
  end

  describe '#text_field' do
    it 'renders text field with base styling' do
      output = builder.text_field(:first_name)

      expect(output).to include('type="text"')
      expect(output).to include('name="user[first_name]"')
      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end
  end

  describe '#password_field' do
    it 'renders password field with base styling' do
      output = builder.password_field(:password)

      expect(output).to include('type="password"')
      expect(output).to include('name="user[password]"')
      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end
  end

  describe '#number_field' do
    it 'renders number field with base styling' do
      output = builder.number_field(:id)

      expect(output).to include('type="number"')
      expect(output).to include('name="user[id]"')
      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end
  end

  describe '#date_field' do
    it 'renders date field with base styling' do
      output = builder.date_field(:created_at)

      expect(output).to include('type="date"')
      expect(output).to include('name="user[created_at]"')
      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end
  end

  describe '#text_area' do
    it 'renders text area with base styling' do
      output = builder.text_area(:first_name)

      expect(output).to include('<textarea')
      expect(output).to include('name="user[first_name]"')
      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end
  end

  describe '#select' do
    let(:choices) { [ [ 'Option 1', '1' ], [ 'Option 2', '2' ] ] }

    it 'renders select field with base styling' do
      output = builder.select(:first_name, choices)

      expect(output).to include('<select')
      expect(output).to include('name="user[first_name]"')
      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end

    it 'preserves select options' do
      output = builder.select(:first_name, choices)

      expect(output).to include('<option value="1">Option 1</option>')
      expect(output).to include('<option value="2">Option 2</option>')
    end
  end

  describe '#check_box' do
    it 'renders checkbox with checkbox styling' do
      output = builder.check_box(:email_verified_at)

      expect(output).to include('type="checkbox"')
      expect(output).to include('name="user[email_verified_at]"')
      expect(output).to include(TailwindFormBuilder::CHECKBOX_CLASSES)
    end

    it 'includes hidden field for unchecked value' do
      output = builder.check_box(:email_verified_at)

      expect(output).to include('type="hidden"')
      expect(output).to include('value="0"')
    end
  end

  describe '#submit' do
    it 'renders submit button with button styling' do
      output = builder.submit('Create Account')

      expect(output).to include('type="submit"')
      expect(output).to include('value="Create Account"')
      expect(output).to include(TailwindFormBuilder::SUBMIT_BUTTON_CLASSES)
    end

    it 'uses default value when none provided' do
      output = builder.submit

      expect(output).to include('value="Create User"')
    end

    it 'merges custom classes with button classes' do
      output = builder.submit('Save', class: 'extra-margin')

      expect(output).to include(TailwindFormBuilder::SUBMIT_BUTTON_CLASSES)
      expect(output).to include('extra-margin')
    end
  end

  describe '#label' do
    it 'renders label with label styling' do
      output = builder.label(:email_address, 'Email Address')

      expect(output).to include('<label')
      expect(output).to include('for="user_email_address"')
      expect(output).to include('Email Address')
      expect(output).to include(TailwindFormBuilder::LABEL_CLASSES)
    end

    it 'merges custom classes with label classes' do
      output = builder.label(:email_address, 'Email', class: 'required')

      expect(output).to include(TailwindFormBuilder::LABEL_CLASSES)
      expect(output).to include('required')
    end
  end

  describe 'error state handling' do
    let(:user_with_errors) do
      user = User.new(email_address: '')
      user.valid? # Trigger validation errors
      user
    end

    let(:builder_with_errors) { described_class.new(:user, user_with_errors, template, {}) }

    it 'applies error classes when field has validation errors' do
      output = builder_with_errors.email_field(:email_address)

      expect(output).to include(TailwindFormBuilder::ERROR_INPUT_CLASSES)
      expect(output).not_to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end

    it 'applies base classes when field has no validation errors' do
      output = builder_with_errors.text_field(:first_name)

      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
      expect(output).not_to include(TailwindFormBuilder::ERROR_INPUT_CLASSES)
    end
  end

  describe 'integration with ApplicationHelper' do
    it 'defines tailwind_form_with helper' do
      expect(ApplicationHelper.instance_methods).to include(:tailwind_form_with)
    end
  end

  describe 'class merging behavior' do
    it 'handles nil class option gracefully' do
      output = builder.text_field(:first_name, class: nil)

      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end

    it 'handles empty string class option' do
      output = builder.text_field(:first_name, class: '')

      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
    end

    it 'preserves existing class order' do
      output = builder.text_field(:first_name, class: 'first-class second-class')

      expect(output).to include(TailwindFormBuilder::BASE_INPUT_CLASSES)
      expect(output).to include('first-class second-class')
    end
  end
end
