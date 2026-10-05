def play_rps
  user_wins = 0
  computer_wins = 0
  ties = 0
  total_rounds = 0

  puts "=== ГРА: КАМІНЬ, НОЖИЦІ, ПАПІР ==="
  puts "Для виходу з гри введи: вихід"

  while true
    print "\nТвій вибір (камінь, ножиці, папір): "
    user_choice = gets.chomp

    # 1. ПЕРША ПЕРЕВІРКА — СТРОГО НА ВИХІД
    if user_choice == "exit"
      puts "Гра закінчена!"
      break
    end

    # 2. ДРУГА ПЕРЕВІРКА — НА КОРЕКТНІСТЬ СЛОВА
    if user_choice != "stone" && user_choice != "scissors" && user_choice != "paper"
      puts "Помилка! Напиши чітко: камінь, ножиці або папір"
      next
    end

    # Вибір комп'ютера (1 = камінь, 2 = ножиці, 3 = папір)
    random_num = rand(1..3)
    if random_num == 1
      computer_choice = "stone"
    elsif random_num == 2
      computer_choice = "scissors"
    else
      computer_choice = "paper"
    end

    puts "Вибір комп'ютера: #{computer_choice}"
    total_rounds += 1

    # Перевірка результатів гри
    if user_choice == computer_choice
      puts "Нічия!"
      ties += 1
    elsif user_choice == "stone" && computer_choice == "scissors"
      puts "Ви перемогли!"
      user_wins += 1
    elsif user_choice == "scissors" && computer_choice == "paper"
      puts "Ви перемогли!"
      user_wins += 1
    elsif user_choice == "paper" && computer_choice == "stone"
      puts "Ви перемогли!"
      user_wins += 1
    else
      puts "Комп'ютер переміг!"
      computer_wins += 1
    end

    puts "--- ПОТОЧНА СТАТИСТИКА ---"
    puts "Загальна кількість раундів: #{total_rounds}"
    puts "Перемоги(а) користувача: #{user_wins}"
    puts "Перемоги(а) комп’ютера: #{computer_wins}"
    puts "Нічиїх: #{ties}"
  end
end

play_rps
