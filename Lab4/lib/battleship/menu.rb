# frozen_string_literal: true

module Battleship
  # Головне меню програми.
  class Menu
    RULES = <<~TEXT

      ===== ПРАВИЛА =====
      * Поле 10x10: стовпці A-J, рядки 1-10.
      * У кожного по 10 кораблів: 1x4, 2x3, 3x2 та 4x1 клітинок.
      * Кораблі не перетинаються і не торкаються, навіть по діагоналі.
      * Введіть координати пострілу, наприклад B5 або j10.
      * Після влучання або знищення корабля стрілець ходить ще раз.
      * Клітинки навколо знищеного корабля позначаються як промахи.
      * Виграє той, хто першим знищить усі кораблі суперника.
      * 'q' під час гри — здатися (рахується як поразка).
      Умовні позначення: ~ невідомо, # ваш корабель, X влучання, o промах.
    TEXT

    def initialize(input: $stdin)
      @input = input
      @stats = Statistics.new
    end

    def run
      puts '=== МОРСЬКИЙ БІЙ ==='
      loop do
        show_menu
        case read_choice
        when '1' then new_game
        when '2' then puts RULES
        when '3' then puts "\n#{@stats}"
        when '4', nil
          puts 'До побачення!'
          break
        else
          puts '⚠ Невідомий пункт меню. Введіть число від 1 до 4.'
        end
      end
    rescue Interrupt
      puts "\nПрограму перервано. До побачення!"
    end

    private

    def show_menu
      puts <<~MENU

        1. Нова гра
        2. Правила
        3. Статистика
        4. Вихід
      MENU
      print 'Ваш вибір: '
    end

    def read_choice
      line = @input.gets
      line&.strip
    end

    def new_game
      winner = Game.new(input: @input).play
      if winner == :player
        puts "\n🎉 Вітаємо, ви перемогли!"
        @stats.record_win
      else
        puts "\nКомп'ютер переміг. Спробуйте ще раз!"
        @stats.record_loss
      end
      puts @stats
    rescue GameError => e
      puts "Помилка гри: #{e.message}"
    end
  end
end
