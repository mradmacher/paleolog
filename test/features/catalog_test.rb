# frozen_string_literal: true

require 'features_helper'

describe 'Catalog' do
  before do
    group1 = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
    group2 = Paleolog::Repo.save(Paleolog::Group.new(name: 'Other'))
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

  it 'displays species' do
    visit '/catalog'

    page.must_have_content('Species list (2)')
    within('#species-list') do
      page.must_have_css('.species', count: 2)
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
end
