# Refer from activesupport-2.2.0.
# * Remove the dependecies to activesupport.
# * change the key to hash value of args.
# * Not Thread safe
# * Add the clear method.
module Locale
  module Util
    module Memoizable
      MEMOIZED_IVAR = Proc.new do |symbol|
        "#{symbol.to_s.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang')}".to_sym
      end

      def self.included(base)
        mod = self
        base.class_eval do
          extend mod
        end
      end

      alias :freeze_without_memoizable :freeze  #:nodoc:
      def freeze #:nodoc:
        unless frozen?
          @_memoized_ivars = {}
          freeze_without_memoizable
        end
      end

      # Clear memoized values.
      def clear
        @_memoized_ivars = {}
      end

      # Cache the result of the methods.
      #
      #  include Memoizable
      #  def foo
      #    ......
      #  end
      #  def bar(a, b)
      #    ......
      #  end
      #  memoize :foo, :bar(a, b)
      # 
      # To clear cache, #clear_foo, #clear_bar is also defined.
      #
      # (NOTE) Consider to use this with huge objects to avoid memory leaks.
      def memoize(*symbols)
        symbols.each do |symbol|
          original_method = "_unmemoized_#{symbol}"
          memoized_ivar = MEMOIZED_IVAR.call(symbol)
          class_eval <<-EOS, __FILE__, __LINE__
          raise "Already memoized #{symbol}" if method_defined?(:#{original_method})
          alias #{original_method} #{symbol}

          def #{symbol}(*args)
            @_memoized_ivars ||= {}
            @_memoized_ivars[:#{memoized_ivar}] ||= {}

            key = args.hash

            ret = @_memoized_ivars[:#{memoized_ivar}][key]

            if ret
              ret
            else
              @_memoized_ivars[:#{memoized_ivar}][key] = #{original_method}(*args).freeze
            end
          end
          
          EOS
        end
      
      end
    end
  end
end
