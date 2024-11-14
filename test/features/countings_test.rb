# frozen_string_literal: true

require 'features_helper'

describe 'Countings' do
  let(:repo) { Paleolog::Repo }

  before do
    use_javascript_driver
    user = repo.find(
      Paleolog::User,
      repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
    project = happy_operation_for(Paleolog::Operation::Project, user).create(
      name: 'test',
    ).value

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }

    assert_link('Logout')
    visit "/projects/#{project.id}"
  end

  it 'adds counting' do
    click_button(class: 'add-counting action')
    within('.form-window') do
      fill_in('Name', with: 'Some Counting')
      click_on('Save')
    end

    within('.project-countings') do
      assert_text('Some Counting')
    end
  end

  it 'displays validation errors while creating counting' do
    click_button(class: 'add-counting action')
    within('.form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end

    assert_text("Name can't be blank")
  end

  it 'renames counting' do
    click_button(class: 'add-counting action')
    within('.form-window') do
      fill_in('Name', with: 'Some Counting')
      click_on('Save')
    end
    click_on('Some Counting')
    click_button(class: 'edit-counting action')
    within('.form-window') do
      fill_in('Name', with: 'Other Counting')
      click_on('Save')
    end

    refute_text('Some Counting')
    within('.project-countings') do
      assert_text('Other Counting')
    end
  end

  it 'displays validation errors whle renaming counting' do
    click_button(class: 'add-counting action')
    within('.form-window') do
      fill_in('Name', with: 'Some Counting')
      click_on('Save')
    end
    click_on('Some Counting')
    click_button(class: 'edit-counting action')
    within('.form-window') do
      fill_in('Name', with: '')
      click_on('Save')
    end

    assert_text("Name can't be blank")
    click_on('Save')

    assert_text('Some Counting')
  end
end
