# frozen_string_literal: true

require 'features_helper'

describe 'Catalog' do
  let(:group1) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
  let(:group2) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other')) }

  before do
    use_javascript_driver
    Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata', verified: true))
    Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium costata', verified: false))
    Paleolog::Repo.save(Paleolog::Species.new(group: group2, name: 'Cerodinium diabelli', verified: true))
    Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.ui.form') { click_on('Login') }
  end

  after do
    Paleolog::Repo::Species.delete_all
    Paleolog::Repo::Group.delete_all
    Paleolog::Repo::User.delete_all
  end

  it 'at the beginning displays no species' do
    visit '/catalog'

    page.must_have_content('Species list (0)')
    within('#species-list') do
      page.must_have_css('.species', count: 0)
    end
  end

  it 'displays all when searching with empty criteria' do
    visit '/catalog'

    within('#species-search') do
      click_on('Search')
    end
    page.must_have_content('Species list (2)')
    page.must_have_content('Odontochitina costata')
    page.must_have_content('Cerodinium diabelli')
  end

  it 'allows searching species' do
    visit '/catalog'

    within('#species-search') do
      fill_in('Name', with: 'costa')
      select('Dinoflagellate', from: 'Group')
      click_on('Search')
    end
    page.must_have_content('Species list (1)')
    within('#species-list') do
      page.must_have_css('.species', count: 1)
    end
    page.must_have_content('Odontochitina costata')
  end

  it 'updates path after searching' do
    visit '/catalog'

    within('#species-search') do
      fill_in('Name', with: 'costa')
      select('Dinoflagellate', from: 'Group')
      click_on('Search')
    end
    assert_current_path(/group_id=#{group1.id}/)
    assert_current_path(/name=costa/)
  end

  it 'allows passing search params in url' do
    visit "/catalog?group_id=#{group1.id}&name=odonto"

    page.must_have_content('Species list (1)')
    within('#species-list') do
      page.must_have_css('.species', count: 1)
    end
    page.must_have_content('Odontochitina costata')
  end

  it 'updates path to only include provided attributes' do
    visit '/catalog'

    within('#species-search') do
      fill_in('Name', with: 'costa')
      click_on('Search')
    end
    assert_no_current_path(/group_id=/)
    assert_current_path(/name=costa/)
  end
end
