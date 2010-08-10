require 'time'
require 'date'

module Plato
  class Document
    attr_reader :category, :attributes

    def initialize(category, attributes)
      @category = category
      @attributes = attributes
    end

    def previous_document
      category.documents.prev(self)
    end

    def next_document
      category.documents.next(self)
    end

    def format
      attributes["format"] || 'text'
    end

    def path
      category.dest_path(self)
    end

    def date
      @date ||= (attributes["date"] ? Time.parse(attributes["date"]) : nil)
    end

    RAW_TEXT = %w(text txt raw)

    def body(context = nil)
      if RAW_TEXT.include? format
        attributes["body"]
      else
        @template ||= Tilt.new(format) { attributes["body"] }
        @template.render(context)
      end
    end

    def values_at(*keys)
      keys.map {|k| send(k) }
    end

    def respond_to?(attr)
      attributes.has_key? attr.to_s or super
    end

    def method_missing(attr)
      if date and date.respond_to? attr
        date.send(attr)
      else
        attributes[attr.to_s] or super
      end
    end
  end

  class DocumentCollection
    include Enumerable

    attr_accessor :sort_attribute, :sort_order

    def initialize(sort = nil)
      @documents = []
      @sort_attribute, @sort_order = sort.split(' ') if sort
    end

    def <<(doc)
      @to_a = nil
      @documents << doc
    end

    def [](*args); to_a.[](*args) end

    def index(doc, strict = false)
      unless index = to_a.index(doc)
        raise ArgumentError, "document is not a member of this collection" unless strict
      end
      index
    end

    def first
      to_a.first
    end

    def prev(doc)
      idx = index(doc)
      idx.zero? ? nil : to_a[idx - 1]
    end

    def next(doc)
      to_a[index(doc) + 1]
    end

    def to_a
      sort! unless @to_a
      @to_a.dup
    end

    def each(&block)
      to_a.each(&block)
    end

    def sort!
      @to_a =
        if sorted?
          @documents.sort! do |a, b|
          a,b = [a, b].map {|d| d.send(sort_attribute) }
          ascending? ? a <=> b : b <=> a
        end
        else
          @documents
        end
    end

    def sorted?
      !!@sort_attribute
    end

    def descending?
      sorted? && !!(sort_order =~ /^desc/i)
    end

    def ascending?
      sorted? && !descending?
    end
  end
end
