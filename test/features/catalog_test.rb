# frozen_string_literal: true

require 'features_helper'

describe 'Catalog' do
  let(:repo) { Paleolog::Repo }
  let(:group1) { repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
  let(:group2) { repo.save(Paleolog::Group.new(name: 'Other')) }

  before do
    use_javascript_driver
    repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata', verified: true))
    repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium costata', verified: false))
    repo.save(Paleolog::Species.new(group: group2, name: 'Cerodinium diabelli', verified: true))
    repo.save(Paleolog::User.new(login: 'test', password: 'test123'))

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.ui.form') { click_on('Login') }
  end

  after do
    repo.for(Paleolog::Species).delete_all
    repo.for(Paleolog::Group).delete_all
    repo.for(Paleolog::User).delete_all
  end

  it 'at the beginning displays all verified species' do
    visit '/catalog'

    page.must_have_content('Species list (2)')
    within('#species-list') do
      page.must_have_css('.species', count: 2)
      page.must_have_content('Odontochitina costata')
      page.must_have_content('Cerodinium diabelli')
    end
  end

  it 'displays all when searching with empty criteria' do
    visit '/catalog'

    within('#species-search') do
      uncheck('Verified')
      click_on('Search')
    end
    page.must_have_content('Species list (3)')
    page.must_have_content('Odontochitina costata')
    page.must_have_content('Cerodinium costata')
    page.must_have_content('Cerodinium diabelli')
  end

  it 'allows searching species' do
    visit '/catalog'

    within('#species-search') do
      fill_in('Name', with: 'costa')
      select('Dinoflagellate', from: 'Group')
      check('Verified')
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
      check('Verified')
      click_on('Search')
    end
    assert_current_path(/group_id=#{group1.id}/)
    assert_current_path(/name=costa/)
    assert_current_path(/verified=true/)
  end

  it 'allows passing search params in url' do
    visit "/catalog?group_id=#{group1.id}&name=odonto&verified=true"

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
