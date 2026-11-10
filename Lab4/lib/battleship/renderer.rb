# frozen_string_literal: true

module Battleship
  # Відображення двох полів поруч.
  # ~ невідомо, # ваш корабель, X влучання, o промах
  module Renderer
    LEFT_WIDTH = 23

    def self.render(own_board, enemy_board)
      header = '    ' + Coordinate::LETTERS.join(' ')
      puts
      puts "#{'   ВАШЕ ПОЛЕ'.ljust(LEFT_WIDTH)}     ПОЛЕ ПРОТИВНИКА"
      puts "#{header.ljust(LEFT_WIDTH)}   #{header}"
      Board::SIZE.times do |r|
        left = row_string(own_board, r, true)
        right = row_string(enemy_board, r, false)
        puts format('%<n>2d  %<l>s     %<n>2d  %<r>s', n: r + 1, l: left, r: right)
      end
      puts "Кораблів у вас: #{own_board.ships_remaining} | у противника: #{enemy_board.ships_remaining}"
    end

    def self.row_string(board, row, show_ships)
      Array.new(Board::SIZE) { |c| symbol(board, row, c, show_ships) }.join(' ')
    end

    def self.symbol(board, row, col, show_ships)
      case board.shot_state(row, col)
      when :hit  then 'X'
      when :miss then 'o'
      else
        show_ships && board.ship_at(row, col) ? '#' : '~'
      end
    end
  end
end
