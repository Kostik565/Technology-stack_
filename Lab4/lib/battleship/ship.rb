# frozen_string_literal: true

module Battleship
  # Корабель: розмір, клітинки та влучання.
  class Ship
    NAMES = {
      4 => 'чотирипалубний',
      3 => 'трипалубний',
      2 => 'двопалубний',
      1 => 'однопалубний'
    }.freeze

    attr_reader :size, :cells

    def initialize(size, row, col, horizontal)
      @size = size
      @cells = Array.new(size) { |i| horizontal ? [row, col + i] : [row + i, col] }
      @hits = []
    end

    def name
      NAMES.fetch(size)
    end

    def occupies?(row, col)
      @cells.include?([row, col])
    end

    def hit!(row, col)
      @hits << [row, col] if occupies?(row, col) && !@hits.include?([row, col])
    end

    def sunk?
      @hits.size == @size
    end

    # Усі сусідні клітинки (включно з діагоналлю), що не належать кораблю.
    def surrounding_cells
      result = []
      @cells.each do |r, c|
        (-1..1).each do |dr|
          (-1..1).each do |dc|
            cell = [r + dr, c + dc]
            result << cell unless @cells.include?(cell)
          end
        end
      end
      result.uniq
    end
  end
end
