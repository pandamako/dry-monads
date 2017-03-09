require 'dry/equalizer'
require 'dry/monads/maybe'

module Dry
  module Monads
    class List
      # Builds a list.
      #
      # @param [Array<Object>] values List elements
      # @return [List]
      def self.[](*values)
        new(values)
      end

      # Coerces a value to a list. `nil` will be coerced to an empty list.
      #
      # @param [Object] value Value
      # @return [List]
      def self.coerce(value)
        if value.nil?
          List.new([])
        elsif value.respond_to?(:to_ary)
          List.new(value.to_ary)
        else
          raise ArgumentError, "Can't coerce #{value.inspect} to List"
        end
      end

      include Dry::Equalizer(:value)

      # Internal array value
      attr_reader :value

      # @api private
      def initialize(value)
        @value = value
      end

      # Lifts a block/proc and runs it against each member of the list.
      # The block must return a value coercible to a list.
      # As in other monads if no block given the first argument will
      # be treated as callable and used instead.
      #
      # @example
      #   Dry::Monads::List[1, 2].bind { |x| [x + 1] } # => List[2, 3]
      #   Dry::Monads::List[1, 2].bind(-> x { [x, x + 1] }) # => List[1, 2, 2, 3]
      #
      # @param [Array<Object>] args arguments will be passed to the block or proc
      # @return [List]
      def bind(*args)
        if block_given?
          List.coerce(value.map { |v| yield(v, *args) }.reduce(:+))
        else
          obj, *rest = args
          List.coerce(value.map { |v| obj.(v, *rest) }.reduce(:+))
        end
      end

      # Maps a block over the list. Acts as `Array#map`.
      # As in other monads if no block given the first argument will
      # be treated as callable and used instead.
      #
      # @example
      #   Dry::Monads::List[1, 2].fmap { |x| x + 1 } # => List[2, 3]
      #
      # @param [Array<Object>] args arguments will be passed to the block or proc
      # @return [List]
      def fmap(*args)
        if block_given?
          List.new(value.map { |v| yield(v, *args) })
        else
          obj, *rest = args
          List.new(value.map { |v| obj.(v, *rest) })
        end
      end

      # Maps a block over the list. Acts as `Array#map`.
      # Requires a block.
      #
      # @return [List]
      def map(&block)
        if block
          fmap(block)
        else
          raise ArgumentError, "Missing block"
        end
      end

      # Concatenates two lists.
      #
      # @example
      #   Dry::Monads::List[1, 2] + Dry::Monads::List[3, 4] # => List[1, 2, 3, 4]
      #
      # @param [List] other Other list
      # @return [List]
      def +(other)
        List.new(to_ary + other.to_ary)
      end

      # Returns a string representation of the list.
      #
      # @example
      #   Dry::Monads::List[1, 2, 3].inspect # => "List[1, 2, 3]"
      #
      # @return [String]
      def inspect
        "List#{ value.inspect }"
      end
      alias_method :to_s, :inspect

      # Coerces to an array
      alias_method :to_ary, :value
      alias_method :to_a, :to_ary

      # Returns first element wrapped with a `Maybe`.
      #
      # @return [Maybe<Object>]
      def first
        Maybe.lift(value.first)
      end

      # Returns last element wrapped with a `Maybe`.
      #
      # @return [Maybe<Object>]
      def last
        Maybe.lift(value.last)
      end

      # Folds the list from the left.
      #
      # @param [Object] initial Initial value
      # @return [Object]
      def fold_left(initial)
        value.reduce(initial) { |acc, v| yield(acc, v) }
      end
      alias_method :foldl, :fold_left
      alias_method :reduce, :fold_left

      # Folds the list from the right.
      #
      # @param [Object] initial Initial value
      # @return [Object]
      def fold_right(initial)
        value.reverse.reduce(initial) { |a, b| yield(b, a) }
      end
      alias_method :foldr, :fold_right

      # Whether the list is empty.
      #
      # @return [TrueClass, FalseClass]
      def empty?
        value.empty?
      end

      # Sorts the list.
      #
      # @return [List]
      def sort
        coerce(value.sort)
      end

      # Filters elements with a block
      #
      # @return [List]
      def filter
        coerce(value.select { |e| yield(e) })
      end
      alias_method :select, :filter

      # List size.
      #
      # @return [Integer]
      def size
        value.size
      end

      # Reverses the list.
      #
      # @return [List]
      def reverse
        coerce(value.reverse)
      end

      private

      def coerce(other)
        self.class.coerce(other)
      end

      # Empty list
      EMPTY = List.new([].freeze).freeze

      module Mixin
        List = List
        L = List

        def List(value)
          List.coerce(value)
        end
      end
    end
  end
end
