# frozen_string_literal: true

require 'features_helper'

describe 'Projects' do
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end

  before do
    use_javascript_driver

    user
    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }

    assert_link('Logout')
  end

  it 'adds project' do
    visit '/projects'

    click_button(class: 'add-project action')
    within('.form-window') do
      fill_in('Name', with: 'Some Project')
      click_on('Save')
    end
    page.must_have_content('Projects (1)')
    page.must_have_content('Some Project')
  end

  it 'displays validation errors while creating project' do
    visit '/projects'

    click_button(class: 'add-project action')
    within('.form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end
    page.must_have_content("Name can't be blank")
  end

  it 'renames project' do
    visit '/projects'

    click_button(class: 'add-project action')
    within('.form-window') do
      fill_in('Name', with: 'Some Project')
      click_on('Save')
    end
    click_on('Some Project')
    click_button(class: 'edit-project action')
    within('.form-window') do
      fill_in('Name', with: 'Other Project')
      click_on('Save')
    end
    page.must_have_content('Other Project')
  end

  it 'displays validation errors while renaming project' do
    visit '/projects'

    click_button(class: 'add-project action')
    within('.form-window') do
      fill_in('Name', with: 'Some Project')
      click_on('Save')
    end
    click_on('Some Project')
    click_button(class: 'edit-project action')
    within('.form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end
    page.must_have_content("Name can't be blank")
    click_on('Save')
    page.must_have_content('Some Project')
  end
end
