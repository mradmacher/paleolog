# frozen_string_literal: true

require 'features_helper'

describe 'Species' do
  let(:group1) { happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Dinoflagellate').value }
  let(:group2) { happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Other').value }
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end
  let(:species) do
    happy_operation_for(Paleolog::Repository::Species, user)
      .create(name: 'Test Species', group_id: group1.id)
      .value
  end

  before do
    use_javascript_driver

    user

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }

    assert_link('Logout')
    visit "/species/#{species.id}"
  end

  it 'updates name' do
    click_button(class: 'edit-species action')
    within('.form-window') do
      fill_in('Name', with: 'Other Name')
      click_on('Save')
    end

    refute_text('Test Species')
    assert_text('Other Name')
  end

  it 'displays validation errors while renaming' do
    click_button(class: 'edit-species action')
    within('.form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end

    assert_text("Name can't be blank")
    click_on('Cancel')

    assert_text('Test Species')
  end
end
