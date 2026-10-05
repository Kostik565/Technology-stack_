def analyze_text(text)
  words = text.downcase.split
  total_words = words.size


  unique_words = []
  words.each do |word|
    unless unique_words.include?(word)
      unique_words << word
    end
  end
  unique_count = unique_words.size


  longest_word = ""
  words.each do |word|
    if word.length > longest_word.length
      longest_word = word
    end
  end

  # Вывод результатов
  puts "\n=== СТАТИСТИКА ТЕКСТУ ==="
  puts "1. ВСЬОГО СЛІВ: #{total_words}"
  puts "2. УНІКАЛЬНИХ СЛІВ: #{unique_count}"
  puts "3. СПИСОК: #{unique_words}"
  puts "4. НАЙДОВШЕ СЛОВО: \"#{longest_word}\" (БУКВ: #{longest_word.length})"
end

print "Введи свій текст: "
user_input = gets.chomp

analyze_text(user_input)
