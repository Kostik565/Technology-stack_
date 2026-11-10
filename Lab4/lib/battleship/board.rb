# frozen_string_literal: true

module Battleship
  # Результат пострілу: :miss, :hit або :sunk.
  ShotResult = Struct.new(:status, :ship) do
    def hit?
      status == :hit || status == :sunk
    end
  end

  # Ігрове поле 10x10.
  class Board
    SIZE = 10

    attr_reader :ships

    def self.in_bounds?(row, col)
      row.between?(0, SIZE - 1) && col.between?(0, SIZE - 1)
    end

    def initialize
      @ships = []
      @shots = {} # [row, col] => :hit / :miss
    end

    def place_ship(ship)
      ship.cells.each do |r, c|
        raise PlacementError, 'Корабель виходить за межі поля.' unless Board.in_bounds?(r, c)
        raise PlacementError, 'Корабель перетинається або торкається іншого.' if touches_ship?(r, c)
      end
      @ships << ship
    end

    def fire_at(row, col)
      raise InvalidCoordinateError unless Board.in_bounds?(row, col)
      raise RepeatShotError if @shots.key?([row, col])

      ship = ship_at(row, col)
      if ship.nil?
        @shots[[row, col]] = :miss
        return ShotResult.new(:miss, nil)
      end

      ship.hit!(row, col)
      @shots[[row, col]] = :hit
      return ShotResult.new(:hit, ship) unless ship.sunk?

      mark_surroundings(ship)
      ShotResult.new(:sunk, ship)
    end

    def ship_at(row, col)
      @ships.find { |s| s.occupies?(row, col) }
    end

    # :hit, :miss або nil (невідомо)
    def shot_state(row, col)
      @shots[[row, col]]
    end

    def available_cells
      cells = []
      SIZE.times { |r| SIZE.times { |c| cells << [r, c] unless @shots.key?([r, c]) } }
      cells
    end

    def all_sunk?
      !@ships.empty? && @ships.all?(&:sunk?)
    end

    def ships_remaining
      @ships.count { |s| !s.sunk? }
    end

    private

    # Чи є корабель у самій клітинці або в будь-якій сусідній (в т.ч. по діагоналі).
    def touches_ship?(row, col)
      (-1..1).any? do |dr|
        (-1..1).any? { |dc| ship_at(row + dr, col + dc) }
      end
    end

    # Після знищення корабля клітинки навколо нього автоматично стають промахами.
    def mark_surroundings(ship)
      ship.surrounding_cells.each do |r, c|
        @shots[[r, c]] ||= :miss if Board.in_bounds?(r, c)
      end
    end
  end
end
