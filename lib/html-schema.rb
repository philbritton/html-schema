require 'active_support/core_ext'

$:.unshift File.dirname(File.expand_path(__FILE__)) + "/html-schema"

class HTMLSchema
  class << self
    def root
      @root ||= File.dirname(File.expand_path(__FILE__))
    end
    
    def configure(&block)
      yield configuration
    end
    
    def configuration
      @configuration ||= HTMLSchema::Configuration.new
    end
    
    def [](key)
      api[key]
    end
    
    def instance
      @instance ||= new
    end
    
    def instance=(value)
      @instance = value
    end
    
    def bootstrap!(format)
      format_name = format == :api ? "API" : format.to_s.camelize
      Dir["#{HTMLSchema.root}/html-schema/#{format}/**/*.rb"].inject({}) do |hash, file|
        name = ::File.basename(file, File.extname(file))
        hash[name.to_sym] = "::HTMLSchema::#{format_name}::#{name.camelize}".constantize.new if name !~ /^(base|feed|attribute)$/
        hash
      end
    end
  end
  
  def initialize(types = {})
    self.class.instance = self
    api.types.keys.each { |key| define_api_method(key) }
  end
  
  def api
    @api          ||= HTMLSchema::API
  end
  
  def microdata
    @microdata    ||= HTMLSchema::Microdata
  end
  
  def microformat
    @microformat  ||= HTMLSchema::Microformat
  end
  
  # todo, iterate through tree, so you can visualize it however you want.
  def each(&block)
    
  end
  
  def to_hash(options = {})
    recursively_stringify_keys(api.types.keys.inject({}) do |hash, key|
      hash[key] = api.types[key].to_object
      hash
    end, options)
  end
  
  def to_yaml
    to_hash.to_yaml
  end
  
  protected
  def define_api_method(name)
    self.class.send :define_method, name do
      self.api[name]
    end unless self.respond_to?(name)
  end
  
  def compact_keys
    @compact_keys ||= {
      :itemtype  => "t",
      :itemscope => "s",
      :itemprop  => "p", 
      :class     => "c",
      :rel       => "r",
      :type      => "k"
    }
  end
  
  private
  def recursively_stringify_keys(hash = {}, options = {})
    hash.keys.inject({}) do |result, key|
      value = hash[key]
      result[options[:compact] ? (compact_keys[key] || key.to_s) : key.to_s] = case value
      when ::Hash
        recursively_stringify_keys(value, options)
      when ::Array
        value.map(&:to_s)
      else
        value.to_s
      end
      result
    end
  end
end

require 'railtie'
require 'object'
require 'attribute'
require 'configuration'
require 'dsl'
require 'api/object'
require 'api/attribute'
require 'microdata/object'
require 'microdata/attribute'
require 'microformat/object'
require 'microformat/attribute'
require 'api'
require 'microdata'
require 'microformat'