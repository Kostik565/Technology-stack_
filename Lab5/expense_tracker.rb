#!/usr/bin/env ruby
# frozen_string_literal: true

# ExpenseTracker — консольний облік витрат (Ruby 2.7+)
# Запуск:  ruby expense_tracker.rb [шлях_до_файлу.json]

require 'json'
require 'date'

# Щоб кирилиця працювала незалежно від локалі терміналу
Encoding.default_external = Encoding::UTF_8
$stdin.set_encoding(Encoding::UTF_8)
$stdout.set_encoding(Encoding::UTF_8)

CATEGORIES      = %w[food transport study entertainment other].freeze
MAX_DESCRIPTION = 200
DEFAULT_FILE    = 'expenses.json'

class ValidationError < StandardError; end # некоректні дані користувача / запису
class StorageError    < StandardError; end # проблеми з файлом
class InputClosed     < StandardError; end # stdin закрито (Ctrl+D)

# ---------------------------------------------------------------- Гроші
module Money
  # 12550 -> "125.50" (лише цілочисельна арифметика, без float)
  def self.format(kopecks)
    "#{kopecks / 100}.#{(kopecks % 100).to_s.rjust(2, '0')}"
  end
end

# ----------------------------------------------------------- Валідація
module Validator
  DATE_RE = /\A\d{4}-\d{2}-\d{2}\z/.freeze
  FIELDS  = %w[id date amount_in_kopecks category description].freeze

  def self.date(value)
    unless value.is_a?(String) && value.match?(DATE_RE)
      raise ValidationError, 'дата має бути у форматі YYYY-MM-DD'
    end
    y, m, d = value.split('-').map(&:to_i)
    raise ValidationError, "дати #{value} не існує в календарі" unless y >= 1 && Date.valid_date?(y, m, d)

    value
  end

  def self.id(value)
    unless value.is_a?(Integer) && value.positive?
      raise ValidationError, 'id має бути додатним цілим числом'
    end

    value
  end

  def self.amount(value)
    unless value.is_a?(Integer) && value.positive?
      raise ValidationError, 'amount_in_kopecks має бути додатним цілим числом'
    end

    value
  end

  def self.category(value)
    unless value.is_a?(String) && CATEGORIES.include?(value)
      raise ValidationError, "категорія має бути однією з: #{CATEGORIES.join(', ')}"
    end

    value
  end

  def self.description(value)
    raise ValidationError, 'опис має бути рядком' unless value.is_a?(String)

    text = value.strip
    raise ValidationError, 'опис не може бути порожнім' if text.empty?
    raise ValidationError, "опис довший за #{MAX_DESCRIPTION} символів" if text.length > MAX_DESCRIPTION

    text
  end

  # Перевіряє цілий запис (Hash з JSON) і повертає чистий Hash із символьними ключами.
  # require_id: false — для імпорту (id може бути відсутній, тоді його видасть програма)
  def self.record(raw, require_id: true)
    raise ValidationError, 'запис має бути JSON-об’єктом' unless raw.is_a?(Hash)

    extra = raw.keys - FIELDS
    raise ValidationError, "зайві поля: #{extra.join(', ')}" unless extra.empty?

    required = require_id ? FIELDS : FIELDS - ['id']
    missing  = required - raw.keys
    raise ValidationError, "відсутні поля: #{missing.join(', ')}" unless missing.empty?

    {
      id: raw.key?('id') ? id(raw['id']) : nil,
      date: date(raw['date']),
      amount_in_kopecks: amount(raw['amount_in_kopecks']),
      category: category(raw['category']),
      description: description(raw['description'])
    }
  end
end

# ------------------------------------------------------------ Сховище
class Store
  attr_reader :expenses

  def initialize(path)
    @path = path
    @expenses = []
  end

  # Завантаження. Файлу немає -> порожній список.
  # Порожній/пошкоджений/некоректний -> StorageError (файл НЕ чіпаємо).
  def load!
    return @expenses = [] unless File.exist?(@path)

    content = File.read(@path, encoding: 'UTF-8')
    raise StorageError, 'файл порожній' if content.strip.empty?

    data = JSON.parse(content)
    raise StorageError, 'очікувався JSON-масив записів' unless data.is_a?(Array)

    records = data.each_with_index.map do |raw, i|
      begin
        Validator.record(raw)
      rescue ValidationError => e
        raise StorageError, "запис №#{i + 1}: #{e.message}"
      end
    end

    ids = records.map { |r| r[:id] }
    dup = ids.select { |x| ids.count(x) > 1 }.uniq
    raise StorageError, "дубльовані id: #{dup.join(', ')}" unless dup.empty?

    @expenses = records
  rescue JSON::ParserError => e
    raise StorageError, "файл пошкоджений (некоректний JSON): #{e.message.lines.first&.strip}"
  rescue SystemCallError, IOError, EncodingError => e
    raise StorageError, "не вдалося прочитати файл: #{e.message}"
  end

  def next_id
    (@expenses.map { |e| e[:id] }.max || 0) + 1
  end

  def add(date:, amount:, category:, description:)
    transaction do
      rec = { id: next_id, date: date, amount_in_kopecks: amount,
              category: category, description: description }
      @expenses << rec
      rec
    end
  end

  def find(id)
    @expenses.find { |e| e[:id] == id }
  end

  def delete(id)
    transaction { @expenses.reject! { |e| e[:id] == id } }
  end

  # Імпорт готових (перевірених) записів. Конфліктні/відсутні id замінюються новими.
  # Повертає кількість записів, яким видано новий id.
  def import(records)
    transaction do
      used = @expenses.map { |e| e[:id] }
      counter = (used.max || 0) + 1
      reassigned = 0
      records.each do |r|
        id = r[:id]
        if id.nil? || used.include?(id)
          id = counter
          counter += 1
          reassigned += 1
        end
        used << id
        @expenses << r.merge(id: id)
      end
      reassigned
    end
  end

  private

  # Робить зміну в пам'яті, зберігає на диск. Якщо збереження провалилось —
  # повертає список у попередній стан і прокидає помилку далі.
  def transaction
    backup = @expenses.dup
    result = yield
    save!
    result
  rescue StorageError
    @expenses = backup
    raise
  end

  # Атомарний запис: спочатку у тимчасовий файл, потім rename.
  # Так основний файл не буде напівзаписаним.
  def save!
    tmp = "#{@path}.tmp"
    File.write(tmp, JSON.pretty_generate(@expenses), encoding: 'UTF-8')
    File.rename(tmp, @path)
  rescue SystemCallError, IOError => e
    begin
      File.delete(tmp) if tmp && File.exist?(tmp)
    rescue SystemCallError
      nil
    end
    raise StorageError, "не вдалося зберегти файл: #{e.message}"
  end
end

# ----------------------------------------------------------- Інтерфейс
class App
  def initialize(store)
    @store = store
  end

  def run
    loop do
      puts <<~MENU

        === ExpenseTracker ===
        1. Додати витрату
        2. Усі витрати
        3. Фільтр (категорія / період)
        4. Видалити витрату
        5. Статистика
        6. Імпорт з JSON
        0. Вихід
      MENU
      choice = ask('Оберіть дію: ')
      begin
        case choice
        when '1' then add_expense
        when '2' then show_table(@store.expenses)
        when '3' then filter_expenses
        when '4' then delete_expense
        when '5' then statistics_menu
        when '6' then import_file
        when '0'
          puts 'До побачення!'
          return
        else puts 'Невідома команда. Введіть число від 0 до 6.'
        end
      rescue ValidationError => e
        puts "Помилка введення: #{e.message}"
      rescue StorageError => e
        puts "ПОМИЛКА ЗБЕРЕЖЕННЯ: #{e.message}"
        puts 'Зміни НЕ збережено, стан у пам’яті відновлено до попереднього.'
      end
    end
  rescue InputClosed
    puts "\nВвід закрито. Завершення роботи."
  end

  private

  def ask(prompt)
    print prompt
    line = $stdin.gets
    raise InputClosed if line.nil?

    line.strip
  end

  def parse_date_input(text)
    Validator.date(text)
  end

  def parse_amount_input(text)
    raise ValidationError, 'сума має бути цілим додатним числом копійок (напр. 12550)' unless text.match?(/\A\d+\z/)

    Validator.amount(text.to_i)
  end

  def sorted(list)
    list.sort_by { |e| [e[:date], e[:id]] }
  end

  def show_table(list)
    if list.empty?
      puts 'Витрат не знайдено. Сума: 0.00 грн'
      return
    end
    puts format('%-5s %-10s %12s  %-13s %s', 'ID', 'Дата', 'Сума, грн', 'Категорія', 'Опис')
    puts '-' * 70
    sorted(list).each do |e|
      puts format('%-5d %-10s %12s  %-13s %s', e[:id], e[:date],
                  Money.format(e[:amount_in_kopecks]), e[:category], e[:description])
    end
    puts '-' * 70
    puts "Записів: #{list.size}, сума: #{Money.format(sum(list))} грн"
  end

  def sum(list)
    list.sum { |e| e[:amount_in_kopecks] }
  end

  # ---- 1. додавання
  def add_expense
    date     = parse_date_input(ask('Дата (YYYY-MM-DD): '))
    amount   = parse_amount_input(ask('Сума в копійках (напр. 12550 = 125.50 грн): '))
    category = Validator.category(ask("Категорія (#{CATEGORIES.join('/')}): ").downcase)
    desc     = Validator.description(ask("Опис (до #{MAX_DESCRIPTION} символів): "))
    rec = @store.add(date: date, amount: amount, category: category, description: desc)
    puts "Витрату додано та збережено (id=#{rec[:id]})."
  end

  # ---- 3. фільтр
  def filter_expenses
    cat_text = ask("Категорія (Enter — усі; #{CATEGORIES.join('/')}): ").downcase
    category = cat_text.empty? ? nil : Validator.category(cat_text)

    from_text = ask('Дата від (YYYY-MM-DD, Enter — без обмеження): ')
    to_text   = ask('Дата до   (YYYY-MM-DD, Enter — без обмеження): ')
    from = from_text.empty? ? nil : parse_date_input(from_text)
    to   = to_text.empty? ? nil : parse_date_input(to_text)
    check_period(from, to)

    result = @store.expenses.select do |e|
      (category.nil? || e[:category] == category) &&
        (from.nil? || e[:date] >= from) &&
        (to.nil? || e[:date] <= to)
    end
    show_table(result)
  end

  def check_period(from, to)
    # формат YYYY-MM-DD дозволяє порівнювати дати як рядки
    raise ValidationError, 'початкова дата не може бути пізнішою за кінцеву' if from && to && from > to
  end

  # ---- 4. видалення
  def delete_expense
    text = ask('ID витрати для видалення: ')
    raise ValidationError, 'ID має бути додатним цілим числом' unless text.match?(/\A\d+\z/) && text.to_i.positive?

    exp = @store.find(text.to_i)
    raise ValidationError, "витрати з id=#{text} не існує" unless exp

    puts "Буде видалено: #{exp[:id]} | #{exp[:date]} | #{Money.format(exp[:amount_in_kopecks])} грн | " \
         "#{exp[:category]} | #{exp[:description]}"
    answer = ask('Підтвердити видалення? (y/n): ').downcase
    if %w[y yes т так].include?(answer)
      @store.delete(exp[:id])
      puts 'Витрату видалено та зміни збережено.'
    else
      puts 'Видалення скасовано.'
    end
  end

  # ---- 5. статистика
  def statistics_menu
    loop do
      puts "\n--- Статистика ---\n1. Загальна статистика\n2. Сума за період\n0. Назад"
      case ask('Оберіть дію: ')
      when '1' then general_stats
      when '2' then period_stats
      when '0' then return
      else puts 'Невідома команда. Введіть 0, 1 або 2.'
      end
    rescue ValidationError => e
      puts "Помилка введення: #{e.message}"
    end
  end

  def general_stats
    list = @store.expenses
    puts "Загальна сума: #{Money.format(sum(list))} грн"
    puts 'За категоріями:'
    CATEGORIES.each do |c|
      puts format('  %-14s %12s грн', c, Money.format(sum(list.select { |e| e[:category] == c })))
    end
    if list.empty?
      puts 'Найбільша витрата: немає даних'
    else
      max = list.map { |e| e[:amount_in_kopecks] }.max
      puts "Найбільша витрата (#{Money.format(max)} грн):"
      show_table(list.select { |e| e[:amount_in_kopecks] == max })
    end
  end

  def period_stats
    from = parse_date_input(ask('Дата від (YYYY-MM-DD): '))
    to   = parse_date_input(ask('Дата до   (YYYY-MM-DD): '))
    check_period(from, to)
    list = @store.expenses.select { |e| e[:date] >= from && e[:date] <= to }
    puts "Сума за період #{from} — #{to} (включно): #{Money.format(sum(list))} грн"
    puts 'Витрат за цей період немає.' if list.empty?
  end

  # ---- 6. імпорт
  def import_file
    path = ask('Шлях до JSON-файла: ')
    raise ValidationError, 'шлях не може бути порожнім' if path.empty?
    raise ValidationError, 'файл не знайдено' unless File.file?(path)

    data = begin
      JSON.parse(File.read(path, encoding: 'UTF-8'))
    rescue JSON::ParserError
      raise ValidationError, 'файл не є коректним JSON'
    rescue SystemCallError, IOError, EncodingError => e
      raise ValidationError, "не вдалося прочитати файл: #{e.message}"
    end
    raise ValidationError, 'очікувався JSON-масив записів' unless data.is_a?(Array)

    errors = []
    records = []
    data.each_with_index do |raw, i|
      records << Validator.record(raw, require_id: false)
    rescue ValidationError => e
      errors << "запис №#{i + 1}: #{e.message}"
    end

    unless errors.empty?
      puts "Імпорт скасовано: знайдено помилок — #{errors.size}. Нічого не додано."
      errors.first(10).each { |m| puts "  - #{m}" }
      puts "  ... та ще #{errors.size - 10}" if errors.size > 10
      return
    end

    if records.empty?
      puts 'Файл містить порожній список — імпортувати нічого.'
      return
    end

    reassigned = @store.import(records)
    puts "Імпортовано записів: #{records.size}. Зміни збережено."
    puts "Для #{reassigned} записів видано нові id (відсутні або конфліктні)." if reassigned.positive?
  end
end

# ---------------------------------------------------------------- Старт
if $PROGRAM_NAME == __FILE__
  path  = ARGV[0] || ENV['EXPENSES_FILE'] || DEFAULT_FILE
  store = Store.new(path)
  begin
    store.load!
  rescue StorageError => e
    warn "Не вдалося завантажити дані з «#{path}»: #{e.message}"
    warn 'Файл не змінено. Виправте його або перемістіть і запустіть програму знову.'
    exit 1
  end
  puts "Завантажено витрат: #{store.expenses.size} (файл: #{path})"
  App.new(store).run
end
