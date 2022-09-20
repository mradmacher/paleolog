# frozen_string_literal: true

require 'features_helper'

describe 'Project Catalog' do
  let(:group1) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
  let(:group2) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other')) }
  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Test Project')) }

  before do
    use_javascript_driver
    species1 = Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata', verified: false))
    species2 = Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium costata', verified: true))
    Paleolog::Repo.save(Paleolog::Species.new(group: group2, name: 'Cerodinium diabelli', verified: true))
    Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    section = Paleolog::Repo::Section.create(name: 'Some section', project_id: project.id)
    counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some counting', project: project))
    sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some sample', section: section))
    Paleolog::Repo.save(
      Paleolog::Occurrence.new(
        rank: 1,
        species_id: species1.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ),
    )
    Paleolog::Repo.save(
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
    within('.ui.form') { click_on('Login') }
  end

  after do
    Paleolog::Repo::Species.delete_all
    Paleolog::Repo::Group.delete_all
    Paleolog::Repo::Occurrence.delete_all
    Paleolog::Repo::Sample.delete_all
    Paleolog::Repo::Section.delete_all
    Paleolog::Repo::Counting.delete_all
    Paleolog::Repo::Project.delete_all
    Paleolog::Repo::User.delete_all
  end

  it 'at the beginning displays all project species' do
    visit "/projects/#{project.id}/species"

    page.must_have_content('Species list (2)')
    within('#species-list') do
      page.must_have_css('.species', count: 2)
      page.must_have_content('Odontochitina costata')
      page.must_have_content('Cerodinium costata')
    end
  end

  it 'displays all when searching with empty criteria' do
    visit "/projects/#{project.id}/species"

    within('#species-search') do
      click_on('Search')
    end
    page.must_have_css('.species', count: 2)
    page.must_have_content('Odontochitina costata')
    page.must_have_content('Cerodinium costata')
  end

  it 'allows searching species' do
    visit "/projects/#{project.id}/species"

    within('#species-search') do
      fill_in('Name', with: 'cero')
      select('Dinoflagellate', from: 'Group')
      check('Verified')
      click_on('Search')
    end
    page.must_have_content('Species list (1)')
    within('#species-list') do
      page.must_have_css('.species', count: 1)
    end
    page.must_have_content('Cerodinium costata')
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

    page.must_have_content('Species list (1)')
    within('#species-list') do
      page.must_have_css('.species', count: 1)
    end
    page.must_have_content('Cerodinium costata')
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
