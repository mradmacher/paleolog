# frozen_string_literal: true

require 'features_helper'

describe 'Countings' do
  before do
    use_javascript_driver
    user = Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    project, = Paleolog::Operation::Project.create(
      { name: 'test', user_id: user.id },
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
    Paleolog::Repo.delete_all(Paleolog::ResearchParticipation)
    Paleolog::Repo.delete_all(Paleolog::Project)
    Paleolog::Repo.delete_all(Paleolog::User)
    Paleolog::Repo.delete_all(Paleolog::Counting)
  end

  it 'adds counting' do
    click_button(class: 'add-counting-action')
    within('#counting-form-window') do
      fill_in('Name', with: 'Some Counting')
      click_on('Save')
    end
    within('.project-countings') do
      assert_text('Some Counting')
    end
  end

  it 'displays validation errors while creating counting' do
    click_button(class: 'add-counting-action')
    within('#counting-form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end
    assert_text("Name can't be blank")
  end

  it 'renames counting' do
    click_button(class: 'add-counting-action')
    within('#counting-form-window') do
      fill_in('Name', with: 'Some Counting')
      click_on('Save')
    end
    click_on('Some Counting')
    click_button(class: 'edit-counting-action')
    within('#counting-form-window') do
      fill_in('Name', with: 'Other Counting')
      click_on('Save')
    end
    refute_text('Some Section')
    within('.project-countings') do
      assert_text('Other Counting')
    end
  end

  it 'displays validation errors whle renaming counting' do
    click_button(class: 'add-counting-action')
    within('#counting-form-window') do
      fill_in('Name', with: 'Some Counting')
      click_on('Save')
    end
    click_on('Some Section')
    click_button(class: 'edit-counting-action')
    within('#counting-form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end
    assert_text("Name can't be blank")
    click_on('Save')
    assert_text('Some Counting')
  end
end
