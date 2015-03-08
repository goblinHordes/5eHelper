require 'rubygems'
require 'sinatra'
require 'json'
require 'hashie'
require 'data_mapper'
#require 'sinatra-partial'

class Character 
  include DataMapper::Resource

  property :name, String
  property :player, String
  property :type, Discriminator 
  property :size, String
  property :race, String
  property :subrace, String
  property :proficency, Integer
  property :background, String
  property :sex, String
  property :alignment, String
  property :experience, Integer
  property :armorclass, Integer
  property :hitpoints, Integer
  property :speed, Integer
  property :languages, String

  has n, :items
end

class Monster < Character

end

class PlayerCharacter < Character

end

class Item 
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :type_properties, String
  property :type, Discriminator
  
  belongs_to :item_archetype

  after :create do
    @type_properties = JSON.parse(@type_properties)
  end

  before :save do
    @type_properties = @type_properties.to_json
  end

  def type_properties=(value)
    @type_properties = value
  end

end

class Weapon < Item
  
end

class ItemArchetype
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :type_properties, String
  property :type, Discriminator

  has n, :items
end

class WeaponArchetype < ItemArchetype
  
end


helpers do

  def class_line(char)
    race = [char["size"], char.subrace, char.race].join(' ')
    levels = char.classlevels.map{|e| e.join(" ")}.join(" / ")
    background = char.background ? "(%s)" % char.background : nil
    levels = [levels, background].compact.join(" ")
    [race, levels, char.alignment].compact.join(", ")
  end

  def action_helper(actions)
    out = []
    actions.each do |attacktype, details| 
      ad = details["attack"]
      dd = details["damage"]

      attack = [
        (ad["modifier"]? sprintf("%+d to hit", ad["modifier"]) : nil), 
        (ad["reach"] ? "reach %d ft." % ad["reach"] : nil ),
        (ad["range"] ? "range %d/%d ft." % [ ad["range"]["short"], ad["range"]["long"] ] : nil ),
      ].compact.join(", ")

      damage = [
        (dd["roll"] ? "%dd%d" % [dd["roll"]["number"], dd["roll"]["type"]] : nil),
        (dd["modifier"] ? "%+d" % dd["modifier"] : nil)
      ].compact.join('')
      attack += "." unless attack[-1] == "."

      out << "<dt>%s:</dt><dd>%s</dd>" % [attacktype, attack]
      if !damage.empty?
        out << "<dt>Hit:</dt><dd>%s %s damage.</dd>" % [ damage, dd["type"] ]
      end
    end
    ["<dl>", out, "</dl>"].flatten.join
  end
end

get '/statblock' do
  json = File.read('test/stabby.json')
  values = JSON.parse(json)
  char = Hashie::Mash.new(values)
  erb :statblock, :locals => { :character => char }
end

