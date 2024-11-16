# frozen_string_literal: true

require 'features_helper'

describe 'Catalog' do
  let(:group1) { happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Dinoflagellate').value }
  let(:group2) { happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Other').value }
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end

  before do
    use_javascript_driver
    happy_operation_for(Paleolog::Repository::Species, user).tap do |operation|
      operation.create(group_id: group1.id, name: 'Odontochitina costata', verified: true).value
      operation.create(group_id: group1.id, name: 'Cerodinium costata', verified: false).value
      operation.create(group_id: group2.id, name: 'Cerodinium diabelli', verified: true).value
    end

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }
  end

  it 'at the beginning displays all verified species' do
    visit '/catalog'

    assert_text('Species list (2)')
    within('.species-collection') do
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
    within('.species-collection') do
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
    within('.species-collection') do
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
