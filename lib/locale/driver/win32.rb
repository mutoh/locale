=begin
  locale/win32.rb

  Copyright (C) 2002-2008  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  Original: Ruby-GetText-Package-1.92.0.

  $Id: win32.rb 27 2008-12-03 15:06:50Z mutoh $
=end

require File.join(File.dirname(__FILE__), 'env')
require File.join(File.dirname(__FILE__), 'win32_table')
require 'dl/win32'


module Locale
  # Locale::Driver::Win32 module for win32.
  # Detect the user locales and the charset.
  # This is a low-level class. Application shouldn't use this directly.
  module Driver
    module Win32
      include Win32Table

      $stderr.puts self.name + " is loaded." if $DEBUG
      
      @@win32 = Win32API.new("kernel32.dll", "GetUserDefaultLangID", nil, "i")

      module_function

      # Gets the Win32 charset of the locale. 
      def charset
        charset = ::Locale::Driver::Env.charset
        unless charset
          locale = locales[0]
          loc = LocaleTable.find{|v| v[1] =locale.to_rfc}
          loc = LocaleTable.find{|v| v[1] =~ /^#{locale.language}-/} unless loc
          charset = loc ? loc[2] : nil
        end
        charset
      end

      def locales  #:nodoc:
        locales = ::Locale::Driver::Env.locales
        unless locales
          lang = LocaleTable.assoc(@@win32.call)
          if lang
            ret = Locale::Tag::Common.parse(lang[1])
            locales = Locale::TagList.new([ret])
          else
            locales = nil
          end
        end
        locales
      end
    end
  end
  @@locale_driver_module = Driver::Win32
end

