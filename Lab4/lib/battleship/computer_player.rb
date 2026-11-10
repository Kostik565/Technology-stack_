# frozen_string_literal: true

module Battleship
  # Суперник-комп'ютер: полювання (випадково, шахова парність) + добивання
  # поранених кораблів. Ніколи не стріляє в уже відому клітинку.
  class ComputerPlayer
    def initialize(rng = Random.new)
      @rng = rng
      @hits = [] # влучання по поточному (ще не потопленому) кораблю
    end

    # Обирає координати серед ще не обстріляних клітинок поля суперника.
    def choose_shot(enemy_board)
      available = enemy_board.available_cells
      raise GameError, 'Немає доступних клітинок для пострілу.' if available.empty?

      targets = target_cells(available)
      return targets.sample(random: @rng) unless targets.empty?

      parity = available.select { |r, c| (r + c).even? }
      (parity.empty? ? available : parity).sample(random: @rng)
    end

    # Повідомляє комп'ютеру результат пострілу, щоб він міг добивати корабель.
    def report(cell, result)
      case result.status
      when :hit  then @hits << cell
      when :sunk then @hits.clear
      end
    end

    private

    def target_cells(available)
      return [] if @hits.empty?

      candidates =
        if @hits.size >= 2
          line_extensions
        else
          orthogonal(@hits.first)
        end
      candidates = @hits.flat_map { |h| orthogonal(h) } if candidates.none? { |c| available.include?(c) }
      candidates.select { |c| available.include?(c) }.uniq
    end

    def orthogonal(cell)
      r, c = cell
      [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]
    end

    # Продовжуємо лінію влучань з обох кінців.
    def line_extensions
      rows = @hits.map(&:first)
      cols = @hits.map(&:last)
      if rows.uniq.size == 1
        [[rows.first, cols.min - 1], [rows.first, cols.max + 1]]
      else
        [[rows.min - 1, cols.first], [rows.max + 1, cols.first]]
      end
    end
  end
end
