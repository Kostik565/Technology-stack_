# frozen_string_literal: true

module Battleship
  # Статистика перемог і поразок (зберігається у stats.json).
  class Statistics
    FILE = File.expand_path('../../stats.json', __dir__)

    attr_reader :wins, :losses

    def initialize(file = FILE)
      @file = file
      @wins = 0
      @losses = 0
      load
    end

    def record_win
      @wins += 1
      save
    end

    def record_loss
      @losses += 1
      save
    end

    def total
      @wins + @losses
    end

    def to_s
      percent = total.zero? ? 0 : (@wins * 100.0 / total).round(1)
      "Перемог: #{@wins} | Поразок: #{@losses} | Усього ігор: #{total} | Відсоток перемог: #{percent}%"
    end

    private

    def load
      return unless File.exist?(@file)

      data = JSON.parse(File.read(@file))
      @wins = Integer(data['wins'])
      @losses = Integer(data['losses'])
    rescue JSON::ParserError, SystemCallError, ArgumentError, TypeError
      @wins = 0
      @losses = 0
    end

    def save
      File.write(@file, JSON.generate({ wins: @wins, losses: @losses }))
    rescue SystemCallError
      warn 'Не вдалося зберегти статистику (гра продовжується).'
    end
  end
end
