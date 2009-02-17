=begin
  locale/tag/illegular.rb - Locale::Tag::Illegular

  Copyright (C) 2008  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  $Id: illegular.rb 27 2008-12-03 15:06:50Z mutoh $
=end

require 'locale/tag/simple'

module Locale

  module Tag
    # Broken tag class.
    class Illegular < Simple

      def initialize(tag)
        tag = "en" if tag == nil || tag.empty?
        @language = tag
        @tag = tag
      end

      # Returns an Array of tag-candidates order by priority.
      def candidates
        [Illegular.new(tag)]
      end

      # Conver to the klass(the class of Language::Tag)
      private
      def convert_to(klass)
        klass.new(tag)
      end
    end
  end
end
