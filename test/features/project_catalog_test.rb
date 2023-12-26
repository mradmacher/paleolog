# frozen_string_literal: true

require 'features_helper'

describe 'Project Catalog' do
  let(:repo) { Paleolog::Repo }
  let(:group1) { repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
  let(:group2) { repo.save(Paleolog::Group.new(name: 'Other')) }
  let(:project) { repo.save(Paleolog::Project.new(name: 'Test Project')) }

  before do
    use_javascript_driver
    species1 = repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata', verified: false))
    species2 = repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium costata', verified: true))
    repo.save(Paleolog::Species.new(group: group2, name: 'Cerodinium diabelli', verified: true))
    repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    section = repo.save(Paleolog::Section.new(name: 'Some section', project_id: project.id))
    counting = repo.save(Paleolog::Counting.new(name: 'Some counting', project: project))
    sample = repo.save(Paleolog::Sample.new(name: 'Some sample', section: section))
    repo.save(
      Paleolog::Occurrence.new(
        rank: 1,
        species_id: species1.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ),
    )
    repo.save(
      Paleolog::Occurrence.new(
        rank: 2,
        species_id: species2.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ),
    )

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }
  end

  after do
    repo.for(Paleolog::Species).delete_all
    repo.for(Paleolog::Group).delete_all
    repo.for(Paleolog::Occurrence).delete_all
    repo.for(Paleolog::Sample).delete_all
    repo.for(Paleolog::Section).delete_all
    repo.for(Paleolog::Counting).delete_all
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::User).delete_all
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
