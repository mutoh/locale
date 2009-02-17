=begin

 tag.rb - Locale::Tag module

 Copyright (C) 2008  Masao Mutoh
 
 $Id: tag.rb 27 2008-12-03 15:06:50Z mutoh $
=end

require 'locale/tag/simple'
require 'locale/tag/illegular'
require 'locale/tag/common'
require 'locale/tag/rfc'
require 'locale/tag/cldr'
require 'locale/tag/posix'

module Locale

  # Language tag / locale identifiers.
  module Tag
    module_function
    # Parse a language tag/locale name and return Locale::Tag
    # object.
    # * tag: a tag as a String. e.g.) ja-Hira-JP
    # * Returns: a Locale::Tag subclass.
    def parse(tag)
      # Common is not used here.
      [Simple, Common, Rfc, Cldr, Posix].each do |parser|
        ret = parser.parse(tag)
        return ret if ret
      end
      Locale::Tag::Illegular.new(tag)
    end
  end
end

