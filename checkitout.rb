class None
end

module SkipableAttributes
  def attributes
    {}.tap do |h|
      instance_variables.each do |var|
        value = instance_variable_get(var)
        h[var[1..-1].to_sym] = value unless value == None
      end
    end
  end
end

class Group
  include SkipableAttributes

  attr_reader :id, :name

  def initialize(id: None, name: None)
    @id = id
    @name = name
  end
end

# Group.new(**ds.where(id: id).first)

group = Group.new(name: 'Adam')
p group.attributes
