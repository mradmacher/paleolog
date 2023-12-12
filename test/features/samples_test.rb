# frozen_string_literal: true

require 'features_helper'

describe 'Samples' do
  let(:repo) { Paleolog::Repo }

  before do
    use_javascript_driver
    user = repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    project = Paleolog::Operation::Project.new(repo, HappyAuthorizer.new(user)).create(
      name: 'test',
    ).value
    Paleolog::Operation::Section.new(repo, HappyAuthorizer.new(user)).create(
      name: 'Section for Sample', project_id: project.id,
    )

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }
    assert_link('Logout')
    visit "/projects/#{project.id}"
  end

  after do
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::User).delete_all
    repo.for(Paleolog::Section).delete_all
    repo.for(Paleolog::Sample).delete_all
  end

  it 'adds sample' do
    click_on('Section for Sample')
    click_button(class: 'add-sample action')
    within('.form-window') do
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
    click_button(class: 'add-sample action')
    within('.form-window') do
      fill_in('Name', with: '')
      fill_in('Weight', with: 'xyz')
      click_on('Save')
    end
    assert_text("Name can't be blank")
    assert_text('Weight needs to be a decimal number')
  end

  it 'updates sample' do
    click_on('Section for Sample')
    click_button(class: 'add-sample action')
    within('.form-window') do
      fill_in('Name', with: 'Some Sample')
      fill_in('Weight', with: '1.23')
      click_on('Save')
    end
    within('.section-samples') do
      assert_text('Some Sample')
      assert_text('1.23')
    end

    click_button(class: 'edit-sample action')
    within('.form-window') do
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
    click_on('Section for Sample')
    click_button(class: 'add-sample action')
    within('.form-window') do
      fill_in('Name', with: 'Some Sample')
      click_on('Save')
    end
    click_button(class: 'edit-sample action')
    within('.form-window') do
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
