require 'test_helper'

class SpecimenTest < ActiveSupport::TestCase
  def test_if_sham_builds_valid_object
    assert Specimen.sham!( :build ).valid?
  end

  def test_if_invalid_when_name_length_less_than_min
    specimen = Specimen.sham!( :build, :name => 'a' * (Specimen::NAME_MIN_LENGTH - 1) )
    refute specimen.valid?
		assert specimen.invalid?( :name )
		assert specimen.errors[:name].include?( I18n.t( 'activerecord.errors.models.specimen.attributes.name.too_short',
      :count => Specimen::NAME_MIN_LENGTH ) )
  end

  def test_if_valid_when_name_length_equals_min
    specimen = Specimen.sham!( :build, :name => 'a' * Specimen::NAME_MIN_LENGTH )
    assert specimen.valid?
	end

  def test_if_invalid_when_name_length_greater_than_max
    specimen = Specimen.sham!( :build, :name => 'a' * (Specimen::NAME_MAX_LENGTH + 1) )
    refute specimen.valid?
		assert specimen.invalid?( :name )
		assert specimen.errors[:name].include?( I18n.t( 'activerecord.errors.models.specimen.attributes.name.too_long',
      :count => Specimen::NAME_MAX_LENGTH ) )
  end

  def test_if_valid_when_name_longth_equals_max
    specimen = Specimen.sham!( :build, :name => 'a' * Specimen::NAME_MAX_LENGTH )
    assert specimen.valid?
	end

  def test_if_invalid_when_description_max_length_exceeded
    specimen = Specimen.sham!( :build, :description => 'a' * (Specimen::DESCRIPTION_MAX_LENGTH + 1) )
    refute specimen.valid?
		assert specimen.invalid?( :description )
		assert specimen.errors[:description].include?( I18n.t( 'activerecord.errors.models.specimen.attributes.description.too_long',
      :count => Specimen::DESCRIPTION_MAX_LENGTH ) )
	end

  def test_if_invalid_when_environmental_preferences_maximum_length_exceeded
    specimen = Specimen.sham!(:build, environmental_preferences: 'a' * (Specimen::ENVIRONMENTAL_PREFERENCES_MAX_LENGTH + 1))
    refute specimen.valid?
		assert specimen.invalid?(:environmental_preferences)
		assert specimen.errors[:environmental_preferences].include?( I18n.t( 'activerecord.errors.models.specimen.attributes.environmental_preferences.too_long',
      :count => Specimen::ENVIRONMENTAL_PREFERENCES_MAX_LENGTH ) )
	end

  def test_name_uniqueness_in_group
    existing = Specimen.sham!
    specimen = Specimen.sham!( :build, :group => existing.group, :name => existing.name )
    refute specimen.valid?
		assert specimen.errors[:name].include?( I18n.t( 'activerecord.errors.models.specimen.attributes.name.taken' ) )
  end

  def test_name_not_have_to_be_unique_in_different_groups
    existing = Specimen.sham!
    specimen = Specimen.sham!( :group => Group.sham!, :name => existing.name )
    assert specimen.valid?
	end

  def test_if_invalid_when_group_not_present
    specimen = Specimen.sham!( :build )
    specimen.group = nil
    refute specimen.valid?
    assert specimen.invalid?( :group_id )
		assert specimen.errors[:group_id].include?( I18n.t( 'activerecord.errors.models.specimen.attributes.group_id.blank' ) )
  end

  should 'destroy dependent features after destroying when has some features' do
    group = Group.sham!
    field = Field.sham!( group: group )
    choice = Choice.sham!( field: field )
    specimen = Specimen.sham!( group: group )
    feature = Feature.sham!( choice: choice, specimen: specimen )

    assert Feature.where( id: feature.id ).exists?
    specimen.destroy
    refute Feature.where( id: feature.id ).exists?
  end

  should 'not allow to change group when has some features' do
    group = Group.sham!
    other_group = Group.sham!
    field = Field.sham!( group: group )
    choice = Choice.sham!( field: field )
    specimen = Specimen.sham!( group: group )
    feature = Feature.sham!( choice: choice, specimen: specimen )

    specimen.group = other_group
    refute specimen.valid?
		assert specimen.errors[:group_id].include?( I18n.t( 'activerecord.errors.models.specimen.attributes.group_id.features' ) )
  end

  context 'search' do
    context 'group' do
      setup do
        @group1 = Group.sham!
        @group2 = Group.sham!
        @species1 = [Specimen.sham!( group: @group1 ), Specimen.sham!( group: @group1 ), Specimen.sham!( group: @group1 )]
        @species2 = [Specimen.sham!( group: @group2 ), Specimen.sham!( group: @group2 ), Specimen.sham!( group: @group2 )]
      end

      should 'return all for nil filter' do
        result = Specimen.search
        assert_equal @species1.size + @species2.size, result.size
        (@species1 + @species2).each do |species|
          assert result.include?( species )
        end
      end

      should 'blank all for blank filter' do
        result = Specimen.search( group_id: '' )
        assert_equal @species1.size + @species2.size, result.size
        (@species1 + @species2).each do |species|
          assert result.include?( species )
        end
      end

      should 'return only for given group' do
        result = Specimen.search( group_id: @group1.id )
        assert_equal @species1.size, result.size
        @species1.each do |species|
          assert result.include?( species )
        end
      end
    end

    context 'counting' do
      setup do
        project = Project.sham!
        @counting1 = Counting.sham!(project: project)
        @counting2 = Counting.sham!(project: project)

        @section1 = Section.sham!(project: project)
        @section2 = Section.sham!(project: project)
        @section3 = Section.sham!(project: project)
        @section4 = Section.sham!(project: project)

        @species1 = Specimen.sham!
        @species2 = Specimen.sham!
        @species3 = Specimen.sham!
        @species4 = Specimen.sham!
        @species5 = Specimen.sham!
        @species6 = Specimen.sham!
        @species7 = Specimen.sham!
        @species8 = Specimen.sham!

        Occurrence.sham!( counting: @counting1, sample: Sample.sham!( section: @section1 ), specimen: @species1 )
        Occurrence.sham!( counting: @counting1, sample: Sample.sham!( section: @section1 ), specimen: @species2 )
        Occurrence.sham!( counting: @counting1, sample: Sample.sham!( section: @section2 ), specimen: @species3 )
        Occurrence.sham!( counting: @counting1, sample: Sample.sham!( section: @section2 ), specimen: @species4 )

        Occurrence.sham!( counting: @counting2, sample: Sample.sham!( section: @section1 ), specimen: @species5 )
        Occurrence.sham!( counting: @counting2, sample: Sample.sham!( section: @section1 ), specimen: @species6 )
        Occurrence.sham!( counting: @counting2, sample: Sample.sham!( section: @section2 ), specimen: @species7 )
        Occurrence.sham!( counting: @counting2, sample: Sample.sham!( section: @section2 ), specimen: @species8 )
      end

      should 'return all for nil filter' do
        result = Specimen.search
        expected = [@species1, @species2, @species3, @species4, @species5, @species6, @species7, @species8]
        assert_equal expected.size, result.size
        expected.each do |species|
          assert result.include?( species )
        end
      end

      should 'return all for blank filter' do
        result = Specimen.search( counting_id: '' )
        expected = [@species1, @species2, @species3, @species4, @species5, @species6, @species7, @species8]
        assert_equal expected.size, result.size
        expected.each do |species|
          assert result.include?( species )
        end
      end

      should 'return only for given counting' do
        result = Specimen.search(counting_id: @counting1.id)
        expected = [@species1, @species2, @species3, @species4]
        assert_equal expected.size, result.size
        expected.each do |species|
          assert result.include?(species)
        end
      end

      should 'return only for given section' do
        result = Specimen.search(section_id: @section1.id)
        expected = [@species1, @species2, @species5, @species6]
        assert_equal expected.size, result.size
        expected.each do |species|
          assert result.include?( species )
        end
      end

      should 'return only for given section and counting' do
        result = Specimen.search(section_id: @section1.id, counting_id: @counting1.id)
        expected = [@species1, @species2]
        assert_equal expected.size, result.size
        expected.each do |species|
          assert result.include?( species )
        end
      end
    end

    context 'choice_id' do
      setup do
        @group = Group.sham!
        @field = Field.sham!( group: @group )
        @choice1 = Choice.sham!( field: @field )
        @choice2 = Choice.sham!( field: @field )

        @other_field = Field.sham!( group: @group )
        @other_choice1 = Choice.sham!( field: @other_field )
        @other_choice2 = Choice.sham!( field: @other_field )

        @species11 = Specimen.sham!( group: @group )
        @species12 = Specimen.sham!( group: @group )
        Feature.sham!( choice: @choice1, specimen: @species11 )
        Feature.sham!( choice: @choice1, specimen: @species12 )
        Feature.sham!( choice: @other_choice1, specimen: @species11 )

        @species21 = Specimen.sham!( group: @group )
        @species22 = Specimen.sham!( group: @group )
        Feature.sham!( choice: @choice2, specimen: @species21 )
        Feature.sham!( choice: @choice2, specimen: @species22 )

        @species1 = [@species11, @species12]
        @species2 = [@species21, @species22]
      end

      should 'return all for nil filter' do
        result = Specimen.search
        assert_equal @species1.size + @species2.size, result.size
        (@species1 + @species2).each do |species|
          assert result.include?( species )
        end
      end

      should 'return all for blank filter' do
        result = Specimen.search( choice_id: '' )
        assert_equal @species1.size + @species2.size, result.size
        (@species1 + @species2).each do |species|
          assert result.include?( species )
        end
      end

      should 'return only for given choice' do
        result = Specimen.search( choice_id: @choice1.id )
        assert_equal @species1.size, result.size
        @species1.each do |species|
          assert result.include?( species )
        end
      end

    end

    context 'choice_ids' do
      setup do
        @group = Group.sham!
        @field = Field.sham!( group: @group )
        @choice1 = Choice.sham!( field: @field )
        @choice2 = Choice.sham!( field: @field )

        @other_field = Field.sham!( group: @group )
        @other_choice1 = Choice.sham!( field: @other_field )
        @other_choice2 = Choice.sham!( field: @other_field )

        @species11 = Specimen.sham!( group: @group )
        @species12 = Specimen.sham!( group: @group )
        Feature.sham!( choice: @choice1, specimen: @species11 )
        Feature.sham!( choice: @choice1, specimen: @species12 )
        Feature.sham!( choice: @other_choice1, specimen: @species11 )

        @species21 = Specimen.sham!( group: @group )
        @species22 = Specimen.sham!( group: @group )
        Feature.sham!( choice: @choice2, specimen: @species21 )
        Feature.sham!( choice: @choice2, specimen: @species22 )

        @species1 = [@species11, @species12]
        @species2 = [@species21, @species22]
      end

      should 'return all for nil filter' do
        result = Specimen.search
        assert_equal @species1.size + @species2.size, result.size
        (@species1 + @species2).each do |species|
          assert result.include?( species )
        end
      end

      should 'return all for blank filter' do
        result = Specimen.search( choice_ids: '' )
        assert_equal @species1.size + @species2.size, result.size
        (@species1 + @species2).each do |species|
          assert result.include?( species )
        end
      end

      should 'return only for given choice' do
        result = Specimen.search( choice_id: @choice1.id )
        assert_equal @species1.size, result.size
        @species1.each do |species|
          assert result.include?( species )
        end
      end

      should 'treat one choice in multiple choices as single choice' do
        multi_result = Specimen.search( choice_ids: [@choice1.id] )
        single_result = Specimen.search( choice_id: @choice1.id )
        assert_equal single_result.size, multi_result.size
        single_result.each do |s|
          assert multi_result.include?( s )
        end
      end

      should 'respect multiple choices' do
        result = Specimen.search( choice_ids: [@choice1.id, @other_choice1.id] )
        assert_equal 1, result.size
        assert result.include?( @species11 )
      end

      should 'ignore blank choices' do
        result = Specimen.search( choice_ids: ['', @choice1.id, '', @other_choice1.id] )
        assert_equal 1, result.size
        assert result.include?( @species11 )
      end
    end

  end

end
