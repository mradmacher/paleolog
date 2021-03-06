$(function() {
	option_tag = function(value, text) {
		return $( "<option></option>" ).attr({ value: value }).append(text);
	};

  checkbox_tag = function(name, value, text) {
    tag = $('<input></input>')
      .attr('type', 'checkbox')
      .attr('name', name)
      .attr('value', value)
      .attr('checked', 'checked');
    label = $('<label></label>')
      .html(tag).append(text);
    return label;
  }

  get_samples = function(section_id, callback) {
    $.get( '/samples.json', { section_id: section_id }, function( samples ) {
      callback(samples);
    });
  }

  get_species = function(counting_id, section_id, filter_params, callback) {
    var params = 'counting_id=' + counting_id + '&section_id=' + section_id + '&' + $.param(filter_params);
		$.get( "/specimens/search.json", params, function( species ) {
      callback(species);
    });
  }

  get_sections = function(project_id, callback) {
		$.get("/sections.json", { project_id: project_id }, function(sections) {
      callback(sections);
    });
  }

  get_countings = function(project_id, callback) {
		$.get( "/countings.json", { project_id: project_id }, function(countings) {
      callback(countings);
    });
  }

  get_project_tag = function() {
    return $("#project_id");
  }

  get_section_tag = function() {
    return $("#section_id");
  }

  get_counting_tag = function() {
    return $("#counting_id");
  }

  get_selected_project = function() {
    return get_project_tag().select("option:selected").val();
  }

  get_selected_section = function() {
    return get_section_tag().select( "option:selected" ).val();
  }

  get_selected_counting = function() {
    return get_counting_tag().select( "option:selected" ).val();
  }

  load_sections = function() {
    get_sections(get_selected_project(), function(sections) {
      populate_section_tag(sections);
      populate_selections('samples');
    });
  }

  load_countings = function() {
    get_countings(get_selected_project(), function(countings) {
      populate_counting_tag(countings);
      populate_selections('species');
    });
  }

	populate_section_tag = function(sections) {
    section_tag = get_section_tag();
    section_tag.empty();
    for(i in sections) {
      section_tag.append(option_tag(sections[i].id, sections[i].name));
    }
	};

	populate_counting_tag = function(countings) {
    counting_tag = get_counting_tag();
    counting_tag.empty();
    for(i in countings) {
      counting_tag.append(option_tag(countings[i].id, countings[i].name));
    }
	};

  get_filter_params = function(vector, index) {
    var vector_tag = $('.vector[data-index=' + index + '][data-vector=' + vector + ']');
    var filter = vector_tag.find('.filter');
    var filter_params = {};
    filter.find('.selection-filter-field').each(function(){
      if($(this).attr('data-is-collection') == 'true') {
        if(filter_params[$(this).attr('data-filter-key')] == undefined) {
          filter_params[$(this).attr('data-filter-key')] = [];
        }
        filter_params[$(this).attr('data-filter-key')].push($(this).val());
      } else {
        filter_params[$(this).attr('data-filter-key')] = $(this).val();
      }
    });
    return filter_params;
  }

  populate_selection_tag = function(vector, index, key, collection) {
    var selection = $('.selection[data-index=' + index + '][data-vector=' + vector + ']');
    collection_ids = selection.find('.ids')
    collection_ids.empty();
    tag_name = vector + 's[' + index + '][' + key + '][]';
    for(i in collection) {
      collection_ids.append(checkbox_tag(tag_name, collection[i].id, collection[i].name));
      collection_ids.append('<br />');
    }
    selection.find('.all').attr('checked', true);
    selection.find('[name*=' + key + ']').change(function() {
      checked = !($('[name*=' + key + ']').not(':checked').size() > 0);
      selection.find('.all').attr('checked', checked);
    });
  }

  populate_tag = function(source, vector, index, section_id, counting_id) {
    switch(source) {
      case 'samples':
        get_samples(section_id, function(samples) {
          populate_selection_tag(vector, index, 'sample_ids', samples);
        }); break;
      case 'species':
        get_species(counting_id, section_id, get_filter_params(vector, index), function(species) {
          populate_selection_tag(vector, index, 'species_ids', species);
        }); break;
    }
  };

  populate_selections = function(source) {
    $('.selection').each(function() {
      var selection = $(this);
      var index = selection.attr('data-index');
      var vector = selection.attr('data-vector');
      var filter = $('.vector[data-index=' + index + '][data-vector=' + vector + ']').find('.filter');
      var ids = selection.find('.ids');

      if( filter.attr('data-source') == source ) {
        populate_tag(source, vector, index, get_selected_section(), get_selected_counting());
        var filter_key = filter.attr("data-filter-key");

        selection.find('.all').change(function() {
          ids.find('[name*=' + filter_key + ']').attr('checked', $(this).is(':checked'));
        });
      }
    });
  };

  if( $( "#new_report" ).size() > 0 ) {
    $('.selection-filter-field').change(function() {
      filter = $(this).closest('.filter');
      index = filter.closest('.vector').attr('data-index');
      vector = filter.closest('.vector').attr('data-vector');
      source = filter.attr('data-source');
      populate_tag(source, vector, index, get_selected_section(), get_selected_counting());
    });

    get_project_tag().change( function() {
      load_sections();
      load_countings();
    });
    get_section_tag().change( function() {
      populate_selections('samples');
      populate_selections('species');
    });
    get_counting_tag().change( function() {
      populate_selections('species');
    });

    load_sections();
    load_countings();
  }
});

