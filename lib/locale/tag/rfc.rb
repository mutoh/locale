=begin
  locale/tag/rfc.rb - Locale::Tag::Rfc

  Copyright (C) 2008  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  $Id: rfc.rb 27 2008-12-03 15:06:50Z mutoh $
=end

module Locale #:nodoc:
  module Tag #:nodoc:

    # Language tag class for RFC4646(BCP47).
    class Rfc < Common
      SINGLETON = '[a-wyz0-9]'
      VARIANT = "(#{ALPHANUM}{5,8}|#{DIGIT}#{ALPHANUM}{3})" 
      EXTENSION = "(#{SINGLETON}(?:-#{ALPHANUM}{2,8})+)"
      PRIVATEUSE = "(x(?:-#{ALPHANUM}{1,8})+)"
      GRANDFATHERED = "#{ALPHA}{1,3}(?:-#{ALPHANUM}{2,8}){1,2}"
      
      TAG_RE = /\A#{LANGUAGE}(?:-#{SCRIPT})?
                  (?:-#{REGION})?((?:-#{VARIANT})*
                  (?:-#{EXTENSION})*(?:-#{PRIVATEUSE})?)\Z/ix

      attr_reader :extensions, :privateuse

      def initialize(language, script = nil, region = nil, variants = [],
                     extensions = [], privateuse = nil)
        @extensions, @privateuse = extensions, privateuse
        super(language, script, region, variants)
      end

      # Parse the language tag and return the new Locale::Tag::Common. 
      def self.parse(tag)
        if tag =~ /\APOSIX\Z/  # This is the special case of POSIX locale but match this regexp.
          nil
        elsif tag =~ TAG_RE
          lang, script, region, subtag = $1, $2, $3, $4
          extensions = []
          variants = []
          if subtag =~ /#{PRIVATEUSE}/
            subtag, privateuse = $`, $1
            # Private use for CLDR.
            if /x-ldml(.*)/ =~ privateuse
              p_subtag = $1 
              extensions = p_subtag.scan(/(^|-)#{EXTENSION}/i).collect{|v| p_subtag.sub!(v[1], ""); v[1]}
              variants = p_subtag.scan(/(^|-)#{VARIANT}(?=(-|$))/i).collect{|v| v[1]}
            end
          end
          extensions += subtag.scan(/(^|-)#{EXTENSION}/i).collect{|v| subtag.sub!(v[1], ""); v[1]}
          variants += subtag.scan(/(^|-)#{VARIANT}(?=(-|$))/i).collect{|v| v[1]}
          
          ret = self.new(lang, script, region, variants, extensions, privateuse)
          ret.tag = tag
          ret
        else
          nil
        end
      end

      # Returns the language tag 
      #   <language>-<Script>-<REGION>-<variants>-<extensions>-<PRIVATEUSE>
      #   (e.g.) "ja-Hira-JP-variant"
      def to_s
        s = super.to_s.gsub(/_/, "-")
        @extensions.each do |v|
          s << "-#{v}"
        end
        s << "-#{@privateuse}" if @privateuse
        s
      end

      # Sets the extensions.
      def extensions=(val)
        clear
        @extensions = val
      end

      # Sets the extensions.
      def privateuse=(val)
        clear
        @privateuse = val
      end

      private
      def convert_to(klass)
        if klass == Rfc
          klass.new(language, script, region, variants, extensions, privateuse)
        elsif klass == Cldr
          exts = {}
          extensions.each do |v|
            if v =~ /^k-(#{ALPHANUM}{2,})-(.*)$/i
              exts[$1] = $2
            end
          end
          klass.new(language, script, region, variants, exts)
        else
          super
        end
      end
      
    end
  end
end
