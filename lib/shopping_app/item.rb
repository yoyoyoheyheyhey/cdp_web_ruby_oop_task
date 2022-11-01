require_relative "ownable"

class Item
  include Ownable
  attr_reader :name, :price

  def initialize(name, price, owner=nil)
    @name = name
    @price = price
    self.owner = owner
  end

  def label
    { name: name, price: price }
  end
  
  def self.all
    Marshal.load(File.read("./db/items.txt")) rescue []
  end

end