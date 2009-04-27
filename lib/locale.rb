=begin
  locale.rb - Locale module

  Copyright (C) 2002-2008  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  Original: Ruby-GetText-Package-1.92.0.

  $Id: locale.rb 27 2008-12-03 15:06:50Z mutoh $
=end

require 'locale/util/memoizable'
require 'locale/tag'
require 'locale/taglist'
require 'locale/version'

# Locale module manages the locale informations of the application.
module Locale
  @@default_tag = nil
  @@locale_driver_module = nil

  include Locale::Util::Memoizable

  module_function
  # Initialize Locale library. 
  # Usually, you don't need to call this directly, because
  # this is called when Locale's methods are called.
  # If you need to specify the option, call this once first.
  # (But Almost of all case, you don't need this, because the 
  # framework/library such as gettext calls this.)
  #
  # If you use this library with CGI(and not use frameworks/gettext), 
  # You need to call Locale.init(:driver => :cgi).
  #
  # * opts: Options as a Hash.
  #   * :driver - The driver. :cgi if you use Locale module with CGI,
  #     nil if you use system locale.
  #       (ex) Locale.init(:driver => :cgi)
  #
  def init(opts = {})
    if opts[:driver]
      require "locale/driver/#{opts[:driver]}"
    else
      if /cygwin|mingw|win32/ =~ RUBY_PLATFORM
        require 'locale/driver/win32'
      elsif /java/ =~ RUBY_PLATFORM
        require 'locale/driver/jruby'
      else
        require 'locale/driver/posix'
      end
    end
  end

  # Gets the driver module.
  #
  # Usually you don't need to call this method.
  #
  # * Returns: the driver module.
  def driver_module
    unless @@locale_driver_module
      Locale.init
    end
    @@locale_driver_module
  end

  # Sets the default locale as the language tag 
  # (Locale::Tag's class or String(such as "ja_JP")).
  # 
  # * tag: the default language_tag
  # * Returns: self.
  def set_default(tag)
    default_tag = nil
    Thread.list.each do |thread|
      thread[:current_languages] = nil
      thread[:candidates_caches] = nil
    end

    if tag
      if tag.kind_of? Locale::Tag::Simple
        default_tag = tag
      else
        default_tag = Locale::Tag.parse(tag)
      end
    end
    @@default_tag = default_tag
    self
  end

  # Same as Locale.set_default.
  #
  # * locale: the default locale (Locale::Tag's class) or a String such as "ja-JP".
  # * Returns: locale.
  def default=(tag)
    set_default(tag)
    @@default_tag
  end

  # Gets the default locale(language tag).
  #
  # If the default language tag is not set, this returns nil.
  #
  # * Returns: the default locale (Locale::Tag's class).
  def default
    @@default_tag
  end

  # Sets the locales of the current thread order by the priority. 
  # Each thread has a current locales.
  # The default locale/system locale is used if the thread doesn't have current locales.
  #
  # * tag: Locale::Language::Tag's class or the language tag as a String. nil if you need to
  # clear current locales.
  # * charset: the charset (override the charset even if the locale name has charset) or nil.
  # * Returns: self
  #
  #    Locale.set_current("ja_JP.eucJP")
  #    Locale.set_current("ja-JP")
  #    Locale.set_current("en_AU", "en_US", ...)
  #    Locale.set_current(Locale::Tag::Simple.new("ja", "JP"), ...)
  def set_current(*tags)
    languages = nil
    if tags[0]
      languages = Locale::TagList.new
      tags.each do |tag|
        if tag.kind_of? Locale::Tag::Simple
          languages << tag
        else
          languages << Locale::Tag.parse(tag)
        end
      end
    end
    Thread.current[:current_languages] = languages
    Thread.current[:candidates_caches] = nil
    self
  end

  # Sets a current locale. This is a single argument version of Locale.set_current.
  #
  # * tag: the language tag such as "ja-JP"
  # * Returns: an Array of the current locale (Locale::Tag's class).
  #
  #    Locale.current = "ja-JP"
  #    Locale.current = "ja_JP.eucJP"
  def current=(tag)
    set_current(tag)
    Thread.current[:current_languages]
  end

  # Gets the current locales (Locale::Tag's class).
  #
  # If the current locale is not set, this returns default/system locale.
  # * Returns: an Array of the current locales (Locale::Tag's class).
  def current
    Thread.current[:current_languages] ||= (default ? Locale::TagList.new([default]) : driver_module.locales)
    Thread.current[:current_languages]
  end

  # Deprecated.
  def get #:nodoc: 
    current
  end

  # Deprecated.
  def set(tag)  #:nodoc:
    set_current(tag)
  end

  # Returns the language tags which are variations of the current locales order by priority.
  # For example, if the current locales are ["fr", "ja_JP", "en_US", "en-Latn-GB-VARIANT"], 
  # then returns ["fr", "ja_JP", "en_US", "en-Latn-GB-VARIANT", "en_Latn_GB", "en_GB", "ja", "en"].
  # "en" is the default locale. It's added at the end of the list even if it isn't exist.
  # Usually, this method is used to find the locale data as the path(or a kind of IDs).
  # * options: options as a Hash or nil.
  #   * :supported_language_tags: an Array of the language tags order by the priority. This option 
  #      restricts the locales which are supported by the library/application.
  #      Default is nil if you don't need to restrict the locales.
  #       * (e.g.1) ["fr_FR", "en_GB", "en_US", ...]
  #   * :type: the type of language tag. :common, :rfc, :cldr, :posix and 
  #      :simple are available. Default value is :common
  #   * :default_language_tags: the default languages as an Array. Default value is ["en"]. 
  def candidates(options = {})
    opts = {:supported_language_tags => nil, :type => :common, 
      :default_language_tags => ["en"]}.merge(options)

    if Thread.current[:candidates_caches]
     cache = Thread.current[:candidates_caches][opts.hash]
      return cache if cache
    else
      Thread.current[:candidates_caches] = {} 
    end
    Thread.current[:candidates_caches][opts.hash] =
      collect_candidates(opts[:type], current, 
                         opts[:default_language_tags], 
                         opts[:supported_language_tags])
  end

  # collect tag candidates and memoize it. 
  # The result is shared from all threads.
  def collect_candidates(type, tags, default_tags, supported_tags) # :nodoc:
    default_language_tags = default_tags.collect{|v| 
      Locale::Tag.parse(v).send("to_#{type}")}.flatten.uniq

    candidate_tags = tags.collect{|v| v.send("to_#{type}").candidates}

    tags = []
    (0...candidate_tags[0].size).each {|i|
      tags += candidate_tags.collect{|v| v[i]}
    }
    tags += default_language_tags
    tags.uniq!

    all_tags = nil
    if @@app_language_tags
      if supported_tags
        all_tags = @@app_language_tags & supported_tags
      else
        all_tags = @@app_language_tags
      end
    elsif supported_tags
      all_tags = supported_tags
    end

    if all_tags
      tags &= all_tags.collect{|v| 
        Locale::Tag.parse(v).send("to_#{type}")}.flatten
      tags = default_language_tags if tags.size == 0
    end
    Locale::TagList.new(tags)
  end
  memoize :collect_candidates

  # Gets the current charset.
  #
  # This returns the current user/system charset. This value is
  # read only, so you can't set it by yourself.
  #
  # * Returns: the current charset.
  def charset
    driver_module.charset
  end
  memoize :charset

  # Clear current locale.
  # * Returns: self
  def clear
    Thread.current[:current_languages] = nil
    Thread.current[:candidates_caches] = nil
    self
  end

  # Clear all locales and charsets of all threads. 
  # This doesn't clear the default locale.
  # Use Locale.default = nil to unset the default locale.
  # * Returns: self
  def clear_all
    Thread.list.each do |thread|
      thread[:current_languages] = nil
      thread[:candidates_caches] = nil
    end
    memoize_clear
    self
  end

  @@app_language_tags = nil
  # Set the language tags which is supported by the Application.
  # This value is same with supported_language_tags in Locale.candidates
  # to restrict the result but is the global setting.
  # Set nil if clear the value.
  #
  # Note that the libraries/plugins shouldn't set this value.
  #
  #  (e.g.1) ["fr_FR", "en_GB", "en_US", ...]
  def set_app_language_tags(*tags)
    @@app_language_tags = tags[0] ? tags : nil
    clear_all
    self
  end

  # Returns the app_language_tags. Default is nil.
  def app_language_tags
    @@app_language_tags
  end
end
