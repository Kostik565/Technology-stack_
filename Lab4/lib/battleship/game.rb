# frozen_string_literal: true

module Battleship
  # Одна партія: гравець проти комп'ютера.
  # Правило: після влучання стрілець стріляє ще раз.
  class Game
    SURRENDER_WORDS = %w[Q QUIT EXIT].freeze

    def initialize(input: $stdin, rng: Random.new)
      @input = input
      @player_board = FleetPlacer.random_board(rng)
      @computer_board = FleetPlacer.random_board(rng)
      @computer = ComputerPlayer.new(rng)
    end

    # Повертає :player, :computer (переможець).
    def play
      turn = :player
      loop do
        Renderer.render(@player_board, @computer_board) if turn == :player
        result = turn == :player ? player_turn : computer_turn
        return :computer if result == :surrender

        return :player if @computer_board.all_sunk?
        return :computer if @player_board.all_sunk?

        turn = other(turn) unless result.hit?
      end
    end

    private

    def other(turn)
      turn == :player ? :computer : :player
    end

    def player_turn
      loop do
        print "\nВаш постріл (напр. B5, 'q' — здатися): "
        line = @input.gets
        return :surrender if line.nil? || SURRENDER_WORDS.include?(line.strip.upcase)

        begin
          row, col = Coordinate.parse(line)
          result = @computer_board.fire_at(row, col)
          announce('Ви стріляєте', row, col, result)
          return result
        rescue GameError => e
          puts "⚠ #{e.message}"
        end
      end
    end

    def computer_turn
      row, col = @computer.choose_shot(@player_board)
      result = @player_board.fire_at(row, col)
      @computer.report([row, col], result)
      announce('Комп\'ютер стріляє', row, col, result)
      result
    end

    def announce(who, row, col, result)
      cell = Coordinate.format(row, col)
      text =
        case result.status
        when :miss then 'Промах.'
        when :hit  then 'Влучання!'
        when :sunk then "Знищено #{result.ship.name} корабель!"
        end
      puts "#{who} в #{cell}: #{text}"
    end
  end
end
