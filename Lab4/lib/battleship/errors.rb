# frozen_string_literal: true

module Battleship
  # Базовий клас усіх помилок гри.
  class GameError < StandardError; end

  # Некоректні координати (формат або вихід за межі поля).
  class InvalidCoordinateError < GameError
    def initialize(msg = 'Некоректні координати. Приклад правильного вводу: B5 (літери A-J, цифри 1-10).')
      super
    end
  end

  # Повторний постріл у вже відому клітинку.
  class RepeatShotError < GameError
    def initialize(msg = 'Ви вже стріляли в цю клітинку (або вона відома). Оберіть іншу.')
      super
    end
  end

  # Неможливо розмістити корабель.
  class PlacementError < GameError; end
end
