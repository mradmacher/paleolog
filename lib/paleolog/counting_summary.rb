module Paleolog
  class CountingSummary
    attr_reader :occurrences

    NORMAL = 0
    OUTSIDE_COUNT = 1
    CARVING = 2
    REWORKING = 3
    DEFAULT_STATUS = NORMAL

    STATUSES = { NORMAL => '', OUTSIDE_COUNT => '+', CARVING => 'c', REWORKING => 'r' }
    UNCERTAIN_SYMBOL = '?'

    #def initialize(occurrences)
    #  @occurrences = occurrences
    #end

    def set_marker(counted_group:, marker_species:, marker_quantity:, sample_weight:)
      @counted_group = counted_group
      @marker_species = marker_species
      @marker_quantity = marker_quantity
      @sample_weight = sample_weight
    end

    def countable_sum(occurrences)
      occurrences.select { |occurrence| occurrence.status == NORMAL }.map { |occ| occ.quantity.to_i }.sum
    end

    def uncountable_sum(occurrences)
      occurrences.select { |occurrence| occurrence.status != NORMAL }.map { |occ| occ.quantity.to_i }.sum
    end

    def total_sum(occurrences)
      occurrences.map { |occ| occ.quantity.to_i }.sum
    end

    def status_symbol(status)
      STATUSES[status]
    end

    def group_per_gram(counting, sample)
      return nil unless can_compute_density?(counting, sample)

      occurrences = occurrence_repo.all_for_sample(counting, sample)

      counted_marker_quantity = occurrences.select { |occ| occ.species_id == counting.species_id }.map(&:quantity).sum
      return nil if counted_marker_quantity.zero?

      counted_group_quantity = occurrences.select { |occ| occ.species.group_id == counting.group_id }.map(&:quantity).sum * 1.0

      (counted_group_quantity / counted_marker_quantity) * (counting.marker_count / sample.weight)
    end

    def available_species_ids(counting, sample, group)
      used_ids = occurrence_repo.all_for_sample(counting, sample).map(&:species_id)
      if used_ids.empty? then used_ids << 0 end
      species_repo.in_group(group).select { |s| !used_ids.include?(s.id) }.sort_by(&:name).map(&:id)
    end

    def occurrence_density_map(counting, section)
      density_map = {}

      sample_repo.for_section(section).each do |sample|
        next unless can_compute_density?(counting, sample)

        occurrences = occurrence_repo.all_for_sample(counting, sample)

        marker_cnt = occurrences.select { |occ| occ.species_id == counting.species_id }.map(&:quantity).compact.sum
        next if marker_cnt == 0

        occurrences.select { |occ| occ.species.group_id == counting.group_id }.each do |occ|
          density_map[occ.id] = ((((occ.quantity || 0)*1.0)/marker_cnt)*(counting.marker_count/sample.weight))
        end
      end
      density_map
    end

    # occurrence: in: [:first, :last]
    def summary(counting, section, occurrence: :first)
      samples_summary = sample_repo.for_section(section).sort_by(&:rank)

      species_summary = specimens_by_occurrence(counting, occurrence == :first ? samples_summary : samples_summary.reverse)

      occurrences_summary = []
      samples_summary.each_with_index do |sample, row|
        occurrences_summary[row] = []
        occrs = {}
        occurrence_repo.all_for_sample(counting, sample).each { |occ| occrs[occ.species_id] = occ }
        species_summary.each_with_index do |sp, column|
          occurrences_summary[row][column] = occrs[sp.id]
        end
      end

      [samples_summary, species_summary, occurrences_summary]
    end

    def specimens_by_occurrence_for_section(counting, section)
      specimens_by_occurrence(counting, sample_repo.for_section(section).sort_by(&:rank))
    end

    def specimens_by_occurrence(counting, samples)
      specimens = []
      samples.each do |sample|
        occurrences = occurrence_repo.all_for_sample(counting, sample)
        occurrences = occurrences.select { |occ| !specimens.map(&:id).include?(occ.species_id) }.sort_by(&:rank)
        specimens += occurrences.map(&:species)
      end
      specimens
    end

    private

    def occurrence_repo
      @occurrence_repo ||= Paleolog::Repository::Occurrence.new
    end

    def sample_repo
      @sample_repo ||= Paleolog::Repository::Sample.new
    end

    def species_repo
      @species_repo ||= Paleolog::Repository::Species.new
    end

    def can_compute_density?(counting, sample)
      counting.group_id && counting.species_id && counting.marker_count && sample.weight && (sample.weight != 0.0)
    end
  end
end
