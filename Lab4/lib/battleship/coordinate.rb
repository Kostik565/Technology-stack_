# frozen_string_literal: true

module Battleship
  # Перетворення тексту ("B5") у координати [рядок, стовпець] та назад.
  module Coordinate
    LETTERS = %w[A B C D E F G H I J].freeze

    def self.parse(text)
      raise InvalidCoordinateError, 'Порожній ввід.' if text.nil? || text.strip.empty?

      match = text.strip.upcase.match(/\A([A-J])\s*(10|[1-9])\z/)
      raise InvalidCoordinateError unless match

      [match[2].to_i - 1, LETTERS.index(match[1])]
    end

    def self.format(row, col)
      "#{LETTERS[col]}#{row + 1}"
    end
  end
end
