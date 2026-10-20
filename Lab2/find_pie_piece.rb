# Позначає клітинки шматка як зайняті (true) або вільні (false)
def mark(used, r, c, h, w, value)
  i = r
  while i < r + h
    j = c
    while j < c + w
      used[i][j] = value
      j += 1
    end
    i += 1
  end
end

# Розрізає решту торта. Повертає масив шматків, або nil, якщо не вийшло
def find_pieces(grid, used, area, rows, cols)
  # 1. Шукаємо першу вільну клітинку (зліва направо, зверху вниз)
  start_r = nil
  start_c = nil
  r = 0
  while r < rows
    c = 0
    while c < cols
      if used[r][c] == false && start_r == nil
        start_r = r
        start_c = c
      end
      c += 1
    end
    r += 1
  end

  # 2. Вільних клітинок немає, значить торт розрізано
  return [] if start_r == nil

  # 3. Пробуємо ширини від найбільшої до найменшої
  w = cols
  while w >= 1
    if area % w == 0
      h = area / w

      # шматок має вміститися в торт
      if start_r + h <= rows && start_c + w <= cols
        raisins = 0
        free = true

        i = start_r
        while i < start_r + h
          j = start_c
          while j < start_c + w
            free = false if used[i][j]
            raisins += 1 if grid[i][j] == "o"
            j += 1
          end
          i += 1
        end

        # підходить: клітинки вільні і рівно одна родзинка
        if free && raisins == 1
          mark(used, start_r, start_c, h, w, true)

          rest = find_pieces(grid, used, area, rows, cols)
          if rest != nil
            # збираємо текст цього шматка
            lines = []
            i = start_r
            while i < start_r + h
              lines << grid[i][start_c, w]
              i += 1
            end
            return [lines.join("\n")] + rest
          end

          # далі тупик, знімаємо позначки і пробуємо іншу ширину
          mark(used, start_r, start_c, h, w, false)
        end
      end
    end
    w -= 1
  end

  return nil
end

def cut(cake)
  grid = cake.split("\n")
  rows = grid.size
  cols = grid[0].size
  n = cake.count("o")

  return [] if n == 0
  return [] if (rows * cols) % n != 0

  area = rows * cols / n

  # таблиця "зайнято / вільно", спочатку все вільне
  used = []
  rows.times { used << Array.new(cols, false) }

  result = find_pieces(grid, used, area, rows, cols)
  return [] if result == nil
  return result
end

# Красиво виводить результат
def show(cake)
  pieces = cut(cake)

  if pieces.empty?
    puts "Розв'язку немає"
    return
  end

  puts "Шматків: #{pieces.size}"
  puts

  k = 1
  pieces.each do |piece|
    puts "Шматок #{k}:"
    puts piece
    puts
    k += 1
  end
end

# Запуски
puts "=== Торт 1 ==="
show(".o......\n......o.\n....o...\n..o.....")

puts "=== Торт 2 ==="
show("........\n..o.....\n...o....\n........")

puts "=== Торт 3 (розв'язку немає) ==="
show("oo..\n....")