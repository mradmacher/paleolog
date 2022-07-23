# frozen_string_literal: true

require 'features_helper'

describe 'Occurrences' do
  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'some project')) }

  before do
    use_javascript_driver
    group1 = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
    group2 = Paleolog::Repo.save(Paleolog::Group.new(name: 'Other'))
    species11 = Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata'))
    species21 = Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium costata'))
    species12 = Paleolog::Repo.save(Paleolog::Species.new(group: group2, name: 'Cerodinium diabelli'))
    Paleolog::Repo.save(Paleolog::Species.new(group: group2, name: 'Diabella diabelli'))
    counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'some counting', project: project))
    section = Paleolog::Repo.save(Paleolog::Section.new(name: 'some section', project: project))
    sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'some sample', section: section))
    Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species11, rank: 1))
    Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species21, rank: 2))
    Paleolog::Repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species12, rank: 3))
    user = Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.ui.form') { click_on('Login') }
    assert_link('Logout')
  end

  after do
    Paleolog::Repo.delete_all(Paleolog::Occurrence)
    Paleolog::Repo.delete_all(Paleolog::Sample)
    Paleolog::Repo.delete_all(Paleolog::Section)
    Paleolog::Repo.delete_all(Paleolog::Counting)
    Paleolog::Repo.delete_all(Paleolog::Species)
    Paleolog::Repo.delete_all(Paleolog::Group)
    Paleolog::Repo.delete_all(Paleolog::Project)
    Paleolog::Repo.delete_all(Paleolog::User)
  end

  it 'adds occurrence' do
    visit "/projects/#{project.id}/occurrences"

    table_rows = page.all('.occurrences-collection tr')
    assert_match /Odontochitina costata/, table_rows[1].text
    assert_match /Cerodinium costata/, table_rows[2].text
    assert_match /Cerodinium diabelli/, table_rows[3].text

    within page.find(:table_row, ['Odontochitina costata']) do
      click_button(class: 'increase-quantity')
      select('r', from: 'Status')
    end
    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_button(class: 'increase-quantity')
    end
    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('2')
    end

    click_button(class: 'add-occurrence')
    url_before = current_url
    select('Other', from: 'Group')
    click_on('Search')
    assert_current_path(url_before) # searching should not update query string
    click_on('Diabella diabelli')

    table_rows = page.all('.occurrences-collection tr')
    assert_match /Odontochitina costata/, table_rows[1].text
    assert_match /Cerodinium costata/, table_rows[2].text
    assert_match /Cerodinium diabelli/, table_rows[3].text
    assert_match /Diabella diabelli/, table_rows[4].text
    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('2')
    end

    visit "/projects/#{project.id}/occurrences"
    table_rows = page.all('.occurrences-collection tr')
    assert_match /Odontochitina costata/, table_rows[1].text
    assert_match /Cerodinium costata/, table_rows[2].text
    assert_match /Cerodinium diabelli/, table_rows[3].text
    assert_match /Diabella diabelli/, table_rows[4].text
  end

  it 'counts countable' do
    visit "/projects/#{project.id}/occurrences"

    within('#occurrences-countable-sum') do
      assert_text('0')
    end
    within('#occurrences-uncountable-sum') do
      assert_text('0')
    end
    within('#occurrences-total-sum') do
      assert_text('0')
    end

    within page.find(:table_row, ['Odontochitina costata']) do
      click_button(class: 'increase-quantity')
      click_button(class: 'increase-quantity')
      click_button(class: 'increase-quantity')
      click_button(class: 'decrease-quantity')
    end
    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_button(class: 'increase-quantity')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('2')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')
    within('#occurrences-countable-sum') do
      page.must_have_content('3')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('3')
    end

    visit "/projects/#{project.id}/occurrences"
    assert page.find(:table_row, ['Odontochitina costata']).has_content?('2')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')
    within('#occurrences-countable-sum') do
      page.must_have_content('3')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('3')
    end
  end

  it 'counts uncountable' do
    visit "/projects/#{project.id}/occurrences"

    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('0')
    end

    within page.find(:table_row, ['Odontochitina costata']) do
      click_button(class: 'increase-quantity')
      click_button(class: 'increase-quantity')
      select('r', from: 'Status')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('2')
    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('2')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('2')
    end

    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_button(class: 'increase-quantity')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('2')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')
    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('2')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('3')
    end

    visit "/projects/#{project.id}/occurrences"
    assert page.find(:table_row, ['Odontochitina costata']).has_content?('2')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')
    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('2')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('3')
    end
  end

  it 'sets uncertain' do
    visit "/projects/#{project.id}/occurrences"

    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('0')
    end

    within page.find(:table_row, ['Odontochitina costata']) do
      click_button(class: 'increase-quantity')
      click_button(class: 'increase-quantity')
      check('Uncertain')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('2')
    assert page.find(:table_row, ['Odontochitina costata']).has_checked_field?('Uncertain')
    within('#occurrences-countable-sum') do
      page.must_have_content('2')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('2')
    end

    visit "/projects/#{project.id}/occurrences"
    assert page.find(:table_row, ['Odontochitina costata']).has_content?('2')
    assert page.find(:table_row, ['Odontochitina costata']).has_checked_field?('Uncertain')
    within('#occurrences-countable-sum') do
      page.must_have_content('2')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('2')
    end
  end

  it 'removes occurrences' do
    visit "/projects/#{project.id}/occurrences"

    within page.find(:table_row, ['Odontochitina costata']) do
      click_button(class: 'increase-quantity')
      click_button(class: 'increase-quantity')
      select('r', from: 'Status')
    end

    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_button(class: 'increase-quantity')
    end

    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('2')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('3')
    end

    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_button(class: 'delete-occurrence')
    end
    assert_no_text('Cerodinium diabelli')

    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('2')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('2')
    end

    within page.find(:table_row, ['Odontochitina costata']) do
      click_button(class: 'delete-occurrence')
    end
    assert_no_text('Odontochitina costata')

    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('0')
    end

    visit "/projects/#{project.id}/occurrences"
    assert_no_text('Cerodinium diabelli')
    assert_no_text('Odontochitina costata')

    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('0')
    end
  end
end
