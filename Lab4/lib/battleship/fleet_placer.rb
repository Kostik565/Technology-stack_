# frozen_string_literal: true

module Battleship
  # Автоматична випадкова розстановка флоту.
  module FleetPlacer
    FLEET = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1].freeze
    MAX_ATTEMPTS_PER_SHIP = 500

    # Повертає нове поле з розставленими кораблями.
    def self.random_board(rng = Random.new)
      loop do
        board = Board.new
        return board if try_fill(board, rng)
      end
    end

    def self.try_fill(board, rng)
      FLEET.each do |size|
        return false unless place_one(board, size, rng)
      end
      true
    end
    private_class_method :try_fill

    def self.place_one(board, size, rng)
      MAX_ATTEMPTS_PER_SHIP.times do
        ship = Ship.new(size, rng.rand(Board::SIZE), rng.rand(Board::SIZE), rng.rand(2).zero?)
        begin
          board.place_ship(ship)
          return true
        rescue PlacementError
          next # спробуємо іншу позицію
        end
      end
      false
    end
    private_class_method :place_one
  end
end
