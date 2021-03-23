# frozen_string_literal: true

require 'features_helper'

describe 'visit home' do
  it 'is successful' do
    visit '/'

    page.must_have_content('PaleoLog')
  end
end
