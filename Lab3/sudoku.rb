# Консольна гра "Судоку" 9x9 (блоки 3x3)
# Запуск: ruby sudoku.rb

SIZE = 9   # розмір поля
BLOCK = 3  # розмір одного блоку

# Початкове поле. 0 означає порожню клітинку.
START = [
  [8, 0, 0, 0, 1, 0, 0, 0, 0],
  [6, 0, 2, 0, 0, 0, 0, 9, 8],
  [0, 3, 7, 0, 8, 4, 2, 0, 0],
  [0, 8, 0, 0, 2, 3, 0, 0, 7],
  [0, 0, 0, 0, 7, 0, 1, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 8, 3],
  [9, 0, 0, 1, 0, 0, 0, 0, 0],
  [0, 0, 3, 0, 0, 0, 0, 0, 9],
  [0, 0, 0, 2, 0, 0, 7, 0, 0]
]

# Малює поле в консолі
def show_board(board)
  line_sep = "  +-------+-------+-------+"

  puts
  puts "    1 2 3   4 5 6   7 8 9"
  puts line_sep
  r = 0
  while r < SIZE
    line = "#{r + 1} | "
    c = 0
    while c < SIZE
      if board[r][c] == 0
        line += ". "
      else
        line += "#{board[r][c]} "
      end
      line += "| " if (c + 1) % BLOCK == 0
      c += 1
    end
    puts line
    puts line_sep if (r + 1) % BLOCK == 0
    r += 1
  end
  puts
end

# Чи можна поставити число n у клітинку (r, c)?
# Повертає текст помилки або nil, якщо хід правильний.
def check_move(board, r, c, n)
  # рядок
  j = 0
  while j < SIZE
    if j != c && board[r][j] == n
      return "Число #{n} вже є в цьому рядку."
    end
    j += 1
  end

  # стовпець
  i = 0
  while i < SIZE
    if i != r && board[i][c] == n
      return "Число #{n} вже є в цьому стовпці."
    end
    i += 1
  end

  # блок 3x3: знаходимо його лівий верхній кут
  block_r = (r / BLOCK) * BLOCK
  block_c = (c / BLOCK) * BLOCK
  i = block_r
  while i < block_r + BLOCK
    j = block_c
    while j < block_c + BLOCK
      if (i != r || j != c) && board[i][j] == n
        return "Число #{n} вже є в цьому блоці 3x3."
      end
      j += 1
    end
    i += 1
  end

  return nil
end

# Чи заповнене все поле? (немає нулів)
def board_full?(board)
  r = 0
  while r < SIZE
    c = 0
    while c < SIZE
      return false if board[r][c] == 0
      c += 1
    end
    r += 1
  end
  return true
end

# Перемога: поле повне, і кожне число стоїть за правилами
def won?(board)
  return false unless board_full?(board)

  r = 0
  while r < SIZE
    c = 0
    while c < SIZE
      return false if check_move(board, r, c, board[r][c]) != nil
      c += 1
    end
    r += 1
  end
  return true
end

# Копія поля, щоб не змінювати START
def copy_board(board)
  copy = []
  board.each { |row| copy << row.dup }
  return copy
end

# Таблиця: які клітинки початкові (їх змінювати заборонено)
def make_fixed(board)
  fixed = []
  r = 0
  while r < SIZE
    row = []
    c = 0
    while c < SIZE
      row << (board[r][c] != 0)
      c += 1
    end
    fixed << row
    r += 1
  end
  return fixed
end

# Розбирає введення "рядок стовпець число".
# Повертає [r, c, n] (r і c вже з нуля) або текст помилки.
def parse_input(text)
  parts = text.split

  if parts.size != 3
    return "Потрібно ввести три числа через пробіл, наприклад: 1 2 3"
  end

  parts.each do |p|
    if p.size != 1 || !"0123456789".include?(p)
      return "'#{p}' не підходить. Вводьте лише цифри від 0 до 9."
    end
  end

  r = parts[0].to_i
  c = parts[1].to_i
  n = parts[2].to_i

  return "Рядок має бути від 1 до 9." if r < 1
  return "Стовпець має бути від 1 до 9." if c < 1

  return [r - 1, c - 1, n]
end

# ---------- Головна програма ----------

board = copy_board(START)
fixed = make_fixed(START)
moves = 0
errors = 0

puts "=== СУДОКУ 9x9 ==="
puts "Заповніть поле числами від 1 до 9."
puts "У кожному рядку, стовпці та блоці 3x3 числа не повторюються."
puts "Введіть: рядок стовпець число   (наприклад: 1 3 4)"
puts "Число 0 очищає вашу клітинку. Введіть q, щоб вийти."

while true
  show_board(board)
  print "Ваш хід: "
  input = gets

  # кінець введення (наприклад, Ctrl+D)
  break if input.nil?

  input = input.strip.downcase

  if input == "q"
    puts "Гру завершено достроково."
    break
  end

  result = parse_input(input)

  # якщо повернувся текст, це помилка введення
  if result.is_a?(String)
    puts "Помилка: #{result}"
    errors += 1
    next
  end

  r = result[0]
  c = result[1]
  n = result[2]

  if fixed[r][c]
    puts "Помилка: це початкове число, його змінювати не можна."
    errors += 1
    next
  end

  # очищення клітинки
  if n == 0
    board[r][c] = 0
    moves += 1
    next
  end

  # перевірка ходу за правилами
  message = check_move(board, r, c, n)
  if message != nil
    puts "Неправильний хід: #{message}"
    errors += 1
    next
  end

  board[r][c] = n
  moves += 1

  if won?(board)
    show_board(board)
    puts "Вітаю! Ви розв'язали судоку!"
    break
  end
end

puts
puts "Ходів: #{moves}, помилок: #{errors}"