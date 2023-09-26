# frozen_string_literal: true

require 'features_helper'

describe 'Sections' do
  let(:repo) { Paleolog::Repo }
  before do
    use_javascript_driver
    user = repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    project = Paleolog::Operation::Project.new(repo, HappyAuthorizer.new(user)).create(
      name: 'test', user_id: user.id,
    ).value

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.ui.form') { click_on('Login') }
    assert_link('Logout')
    visit "/projects/#{project.id}"
  end

  after do
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::User).delete_all
    repo.for(Paleolog::Section).delete_all
  end

  it 'adds section' do
    click_button(class: 'add-section action')
    within('.form-window') do
      fill_in('Name', with: 'Some Section')
      click_on('Save')
    end
    within('.project-sections') do
      assert_text('Some Section')
    end
  end

  it 'displays validation errors while creating project' do
    click_button(class: 'add-section action')
    within('.form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end
    assert_text("Name can't be blank")
  end

  it 'renames section' do
    click_button(class: 'add-section action')
    within('.form-window') do
      fill_in('Name', with: 'Some Section')
      click_on('Save')
    end
    click_on('Some Section')
    click_button(class: 'edit-section action')
    within('.form-window') do
      fill_in('Name', with: 'Other Section')
      click_on('Save')
    end
    refute_text('Some Section')
    within('.project-sections') do
      assert_text('Other Section')
    end
  end

  it 'displays validation errors whle renaming section' do
    click_button(class: 'add-section action')
    within('.form-window') do
      fill_in('Name', with: 'Some Section')
      click_on('Save')
    end
    click_on('Some Section')
    click_button(class: 'edit-section action')
    within('.form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end
    assert_text("Name can't be blank")
    click_on('Save')
    assert_text('Some Section')
  end
end
