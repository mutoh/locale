=begin
  locale/driver/jruby.rb

  Copyright (C) 2007,2008 Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  Original: Ruby-GetText-Package-1.92.0.

  $Id: jruby.rb 27 2008-12-03 15:06:50Z mutoh $
=end

require File.join(File.dirname(__FILE__), 'env')
require 'java'

module Locale
  module Driver
    # Locale::Driver::JRuby module for JRuby
    # Detect the user locales and the charset.
    # This is a low-level class. Application shouldn't use this directly.
    module JRuby
      $stderr.puts self.name + " is loaded." if $DEBUG

      if java.lang.System.getProperties['os.name'].downcase =~ /windows/
        require 'locale/driver/win32_table'
        
        extend ::Locale::Driver::Win32Table
      end
      
      module_function
      def locales  #:nodoc:
        locales = ::Locale::Driver::Env.locales
        unless locales
          locale = java.util.Locale.getDefault
          variant = Locale.getVariant 
          variants = []
          if valiant != nil and variant.size > 0
            valiants = [valiant]
          end
          locales = TagList.new([Locale::Tag::Common.new(locale.getLanguage, nil,
                                                         locale.getCountry, 
                                                         variants)])
        end
        locales
      end

      def charset
        charset = ::Locale::Driver::Env.charset
        unless charset
          charset = java.nio.charset.Charset.defaultCharset.name
        end
        charset
      end
    end
  end
  @@locale_driver_module = Driver::JRuby
end
