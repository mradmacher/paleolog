# frozen_string_literal: true

require 'features_helper'

describe 'Samples' do
  before do
    use_javascript_driver
    user = Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    project, = Paleolog::Operation::Project.create(
      { name: 'test', user_id: user.id },
      authorizer: HappyAuthorizer.new,
    )
    Paleolog::Operation::Section.create(
      { name: 'Section for Sample', project_id: project.id },
      authorizer: HappyAuthorizer.new,
    )

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.ui.form') { click_on('Login') }
    assert_link('Logout')
    visit "/projects/#{project.id}"
  end

  after do
    Paleolog::Repo.delete_all(Paleolog::Researcher)
    Paleolog::Repo.delete_all(Paleolog::Project)
    Paleolog::Repo.delete_all(Paleolog::User)
    Paleolog::Repo.delete_all(Paleolog::Section)
    Paleolog::Repo.delete_all(Paleolog::Sample)
  end

  it 'adds sample' do
    click_on('Section for Sample')
    click_button(class: 'add-sample-action')
    within('#sample-form-window') do
      fill_in('Name', with: 'Some Sample')
      fill_in('Weight', with: '1.23')
      click_on('Save')
    end
    within('.section-samples') do
      assert_text('Some Sample')
      assert_text('1.23')
    end
  end

  it 'displays validation errors while creating sample' do
    click_on('Section for Sample')
    click_button(class: 'add-sample-action')
    within('#sample-form-window') do
      fill_in('Name', with: '')
      fill_in('Weight', with: 'xyz')
      click_on('Save')
    end
    assert_text("Name can't be blank")
    assert_text("Weight needs to be a decimal number")
  end

  it 'updates sample' do
    click_on('Section for Sample')
    click_button(class: 'add-sample-action')
    within('#sample-form-window') do
      fill_in('Name', with: 'Some Sample')
      fill_in('Weight', with: '1.23')
      click_on('Save')
    end
    click_button(class: 'edit-sample-action')
    within('#sample-form-window') do
      fill_in('Name', with: 'Other Sample')
      fill_in('Weight', with: '3.21')
      click_on('Save')
    end
    refute_text('Some Sample')
    within('.section-samples') do
      assert_text('Other Sample')
      assert_text('3.21')
    end
  end

  it 'displays validation errors while editing section' do
    click_button(class: 'add-sample-action')
    within('#sample-form-window') do
      fill_in('Name', with: 'Some Sample')
      click_on('Save')
    end
    click_button(class: 'edit-sample-action')
    within('#sample-form-window') do
      fill_in('Name', with: '')
      fill_in('Weight', with: 'xyz')
      click_on('Save')
    end
    assert_text("Name can't be blank")
    assert_text('Weight needs to be a decimal number')
    click_on('Save')
    assert_text('Some Sample')
  end
end
