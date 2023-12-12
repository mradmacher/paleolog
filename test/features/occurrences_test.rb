# frozen_string_literal: true

require 'features_helper'

describe 'Occurrences' do
  let(:repo) { Paleolog::Repo }
  let(:project) { repo.save(Paleolog::Project.new(name: 'some project')) }
  let(:counting) { repo.save(Paleolog::Counting.new(name: 'some counting', project: project)) }

  def click_to_select_species(name)
    find(:xpath, "//td[text()='#{name}']/following::button[contains(@class, 'select-species-action')]").click
  end

  before do
    use_javascript_driver
    group1 = repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
    group2 = repo.save(Paleolog::Group.new(name: 'Other'))
    species11 = repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata'))
    species21 = repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium costata'))
    species12 = repo.save(Paleolog::Species.new(group: group2, name: 'Cerodinium diabelli'))
    repo.save(Paleolog::Species.new(group: group2, name: 'Diabella diabelli'))
    section = repo.save(Paleolog::Section.new(name: 'some section', project: project))
    sample = repo.save(Paleolog::Sample.new(name: 'some sample', section: section))
    repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species11, rank: 1))
    repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species21, rank: 2))
    repo.save(Paleolog::Occurrence.new(sample: sample, counting: counting, species: species12, rank: 3))
    user = repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    repo.save(Paleolog::Researcher.new(user: user, project: project, manager: true))

    visit '/login'
    fill_in('login-field', with: 'test')
    fill_in('password-field', with: 'test123')
    within('.form') { click_on('Login') }
    assert_link('Logout')
  end

  after do
    repo.for(Paleolog::Occurrence).delete_all
    repo.for(Paleolog::Sample).delete_all
    repo.for(Paleolog::Section).delete_all
    repo.for(Paleolog::Counting).delete_all
    repo.for(Paleolog::Species).delete_all
    repo.for(Paleolog::Group).delete_all
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::User).delete_all
  end

  it 'suggests counted group when adding occurrences' do
    counted_group = repo.save(Paleolog::Group.new(name: 'Counted'))
    repo.save(Paleolog::Species.new(group: counted_group, name: 'Counted Group Species'))
    repo.for(Paleolog::Counting).update(counting.id, group_id: counted_group.id)
    visit "/projects/#{project.id}/occurrences"
    click_action_to('add occurrence')
    within page.find('#species-list') do
      assert_text('Counted Group Species')
    end
    click_to_select_species('Counted Group Species')
    within page.find('#occurrences-collection') do
      assert_text('Counted Group Species')
    end
  end

  it 'adds occurrence' do
    visit "/projects/#{project.id}/occurrences"

    table_rows = page.all('#occurrences-collection .occurrence')
    assert_equal 3, table_rows.size
    assert_match(/Odontochitina costata/, table_rows[0].text)
    assert_match(/Cerodinium costata/, table_rows[1].text)
    assert_match(/Cerodinium diabelli/, table_rows[2].text)

    within page.find(:table_row, ['Odontochitina costata']) do
      click_action_to('increase quantity')
      select('r', from: 'occurrence-status')
    end
    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_action_to('increase quantity')
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
    click_to_select_species('Diabella diabelli')

    table_rows = page.all('#occurrences-collection .occurrence')
    assert_match(/Odontochitina costata/, table_rows[0].text)
    assert_match(/Cerodinium costata/, table_rows[1].text)
    assert_match(/Cerodinium diabelli/, table_rows[2].text)
    assert_match(/Diabella diabelli/, table_rows[3].text)
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
    table_rows = page.all('#occurrences-collection .occurrence')
    assert_match(/Odontochitina costata/, table_rows[0].text)
    assert_match(/Cerodinium costata/, table_rows[1].text)
    assert_match(/Cerodinium diabelli/, table_rows[2].text)
    assert_match(/Diabella diabelli/, table_rows[3].text)
  end

  it 'sets quantity' do
    visit "/projects/#{project.id}/occurrences"

    within page.find(:table_row, ['Odontochitina costata']) do
      click_action_to('set quantity')
    end
    within('.modal.set-quantity') do
      fill_in('occurrence-quantity', with: '100')
      click_on('Save')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('100')

    visit "/projects/#{project.id}/occurrences"
    assert page.find(:table_row, ['Odontochitina costata']).has_content?('100')
  end

  it 'increases quantity' do
    visit "/projects/#{project.id}/occurrences"

    within page.find(:table_row, ['Odontochitina costata']) do
      click_action_to('increase quantity')
      click_action_to('increase quantity')
      click_action_to('increase quantity')
    end
    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_action_to('increase quantity')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('3')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')

    visit "/projects/#{project.id}/occurrences"
    assert page.find(:table_row, ['Odontochitina costata']).has_content?('3')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')
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
      click_action_to('increase quantity')
    end
    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_action_to('increase quantity')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('1')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')
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
      click_action_to('increase quantity')
      select('r', from: 'occurrence-status')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('1')
    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('1')
    end

    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_action_to('increase quantity')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('1')
    assert page.find(:table_row, ['Cerodinium diabelli']).has_content?('1')
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
    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('2')
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
      click_action_to('increase quantity')
      check('occurrence-uncertain')
    end

    assert page.find(:table_row, ['Odontochitina costata']).has_content?('1')
    assert page.find(:table_row, ['Odontochitina costata']).has_checked_field?('occurrence-uncertain')
    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('1')
    end

    visit "/projects/#{project.id}/occurrences"
    assert page.find(:table_row, ['Odontochitina costata']).has_checked_field?('occurrence-uncertain')
    within('#occurrences-countable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('1')
    end
  end

  it 'removes occurrences' do
    visit "/projects/#{project.id}/occurrences"

    within page.find(:table_row, ['Odontochitina costata']) do
      click_action_to('increase quantity')
      select('r', from: 'occurrence-status')
    end

    within page.find(:table_row, ['Cerodinium diabelli']) do
      click_action_to('increase quantity')
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

    within page.find(:table_row, ['Cerodinium diabelli']) do
      accept_confirm do
        click_button(class: 'delete-occurrence')
      end
    end
    assert_no_text('Cerodinium diabelli')

    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('1')
    end

    within page.find(:table_row, ['Odontochitina costata']) do
      dismiss_confirm do
        click_button(class: 'delete-occurrence')
      end
    end
    assert_text('Odontochitina costata')
    within('#occurrences-countable-sum') do
      page.must_have_content('0')
    end
    within('#occurrences-uncountable-sum') do
      page.must_have_content('1')
    end
    within('#occurrences-total-sum') do
      page.must_have_content('1')
    end

    within page.find(:table_row, ['Odontochitina costata']) do
      accept_confirm { click_action_to('delete occurrence') }
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
