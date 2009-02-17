=begin
  locale/driver/cgi.rb 

  Copyright (C) 2002-2008  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  Original: Ruby-GetText-Package-1.92.0.

  $Id: cgi.rb 27 2008-12-03 15:06:50Z mutoh $
=end

module Locale
  # Locale::Driver module for CGI.
  # Detect the user locales and the charset from CGI parameters.
  # This is a low-level class. Application shouldn't use this directly.
  module Driver
    module CGI
      $stderr.puts self.name + " is loaded." if $DEBUG

      @@default_locale = Locale::Tag::Simple.new("en")
      @@default_charset = "UTF-8"
      
      module_function
      # Gets required locales from CGI parameters. (Based on RFC2616)
      #
      # Returns: An Array of Locale::Tag's subclasses
      #          (QUERY_STRING "lang" > COOKIE "lang" > HTTP_ACCEPT_LANGUAGE > "en")
      # 
      def locales
        return Locale::TagList.new([@@default_locale]) unless cgi
        cgi_ = cgi

        locales = Locale::TagList.new

        # QUERY_STRING "lang"
        if cgi_.has_key?("lang")
          langs = cgi_.params["lang"]
          if langs
            langs.each do |lang|
              locales << Locale::Tag.parse(lang)
            end
          end
        end

        unless locales.size > 0
          # COOKIE "lang"
          langs = cgi_.cookies["lang"]
          if langs
            langs.each do |lang|
              locales << Locale::Tag.parse(lang) if lang.size > 0
            end
          end
        end

        unless locales.size > 0
          # HTTP_ACCEPT_LANGUAGE
          if lang = cgi_.accept_language and lang.size > 0
            locales += lang.gsub(/\s/, "").split(/,/).map{|v| v.split(";q=")}.map{|j| [j[0], j[1] ? j[1].to_f : 1.0]}.sort{|a,b| -(a[1] <=> b[1])}.map{|v| Locale::Tag.parse(v[0])}
          end
        end

        unless locales.size > 0
          locales << @@default_locale
        end
        Locale::TagList.new(locales.uniq)
      end

      # Gets the charset from CGI parameters. (Based on RFC2616)
      #  * Returns: the charset (HTTP_ACCEPT_CHARSET > "UTF-8").
     def charset
       cgi_ = cgi
       charsets = cgi_.accept_charset
       if charsets and charsets.size > 0
         num = charsets.index(',')
         charset = num ? charsets[0, num] : charsets
         charset = @@default_charset if charset == "*"
       else
         charset = @@default_charset
       end
       charset
     end

      # Sets a CGI object.
      # * cgi_: CGI object
      # * Returns: self
      def set_cgi(cgi_)
        Thread.current[:current_cgi]  = cgi_
        self
      end
      
      def cgi  #:nodoc:
        Thread.current[:current_cgi]
      end
    end
  end

  @@locale_driver_module = Driver::CGI
  
  module_function
  # Sets a CGI object. 
  #
  # Call Locale.init(:driver => :cgi) first.
  #
  # * cgi_: CGI object
  # * Returns: self
  def set_cgi(cgi_)
    @@locale_driver_module.set_cgi(cgi_)
    self
  end
  
  # Sets a CGI object.
  #
  # Call Locale.init(:driver => :cgi) first.
  #
  # * cgi_: CGI object
  # * Returns: cgi_ 
  def cgi=(cgi_)
    set_cgi(cgi_)
    cgi_
  end
  
  # Gets the CGI object. If it is nil, returns new CGI object.
  #
  # Call Locale.init(:driver => :cgi) first.
  #
  # * Returns: the CGI object
  def cgi
    @@locale_driver_module.cgi
  end
end
