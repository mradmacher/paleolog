# frozen_string_literal: true

require 'features_helper'

describe 'Project Catalog' do
  let(:repo) { Paleolog::Repo }
  let(:group1) { happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Dinoflagellate').value }
  let(:group2) { happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Other').value }
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end
  let(:project) do
    happy_operation_for(Paleolog::Repository::Project, user)
      .create(name: 'Test Project')
      .value
  end

  before do
    use_javascript_driver

    operation = happy_operation_for(Paleolog::Repository::Species, user)
    species1 = operation.create(group_id: group1.id, name: 'Odontochitina costata', verified: false).value
    species2 = operation.create(group_id: group1.id, name: 'Cerodinium costata', verified: true).value
    operation.create(group_id: group2.id, name: 'Cerodinium diabelli', verified: true).value

    counting = happy_operation_for(Paleolog::Repository::Counting, user)
               .create(name: 'Some counting', project_id: project.id)
               .value
    section = happy_operation_for(Paleolog::Repository::Section, user)
              .create(name: 'Some section', project_id: project.id)
              .value
    sample = happy_operation_for(Paleolog::Repository::Sample, user)
             .create(name: 'Some sample', section_id: section.id)
             .value

    happy_operation_for(Paleolog::Repository::Occurrence, user).tap do |op|
      op.create(
        species_id: species1.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ).value
      op.create(
        species_id: species2.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ).value
    end

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }
  end

  it 'at the beginning displays all project species' do
    visit "/projects/#{project.id}/species"

    assert_text('Species list (2)')
    within('.species-collection') do
      assert_css('.species', count: 2)
      assert_text('Odontochitina costata')
      assert_text('Cerodinium costata')
    end
  end

  it 'displays all when searching with empty criteria' do
    visit "/projects/#{project.id}/species"

    within('#species-search') do
      click_on('Search')
    end

    assert_css('.species', count: 2)
    assert_text('Odontochitina costata')
    assert_text('Cerodinium costata')
  end

  it 'allows searching species' do
    visit "/projects/#{project.id}/species"

    within('#species-search') do
      fill_in('Name', with: 'cero')
      select('Dinoflagellate', from: 'Group')
      check('Verified')
      click_on('Search')
    end

    assert_text('Species list (1)')
    within('.species-collection') do
      assert_css('.species', count: 1)
    end
    assert_text('Cerodinium costata')
  end

  it 'updates path after searching' do
    visit "/projects/#{project.id}/species"

    within('#species-search') do
      fill_in('Name', with: 'costa')
      select('Dinoflagellate', from: 'Group')
      check('Verified')
      click_on('Search')
    end

    assert_current_path(/group_id=#{group1.id}/)
    assert_current_path(/name=costa/)
    assert_current_path(/verified=true/)
  end

  it 'allows passing search params in url' do
    visit "/catalog?group_id=#{group1.id}&name=cero&verified=true"

    assert_text('Species list (1)')
    within('.species-collection') do
      assert_css('.species', count: 1)
    end
    assert_text('Cerodinium costata')
  end

  it 'updates path to only include provided attributes' do
    visit "/projects/#{project.id}/species"

    within('#species-search') do
      fill_in('Name', with: 'costa')
      click_on('Search')
    end

    assert_no_current_path(/group_id=/)
    assert_current_path(/name=costa/)
  end
end
