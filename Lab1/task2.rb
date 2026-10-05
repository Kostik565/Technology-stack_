def play_game
  secret_number = rand(1..100)
  attempts = 0


  puts "Я загадав число від 1 до 100. Спробуй вгадати!"

  while true
    print "Введи твоє припущення: "
    guess = gets.chomp.to_i
    attempts += 1

    if guess < secret_number
      puts "Більше"
    elsif guess > secret_number
      puts "Менше"
    else
      puts "Вгадано! Кількість спроб: #{attempts}"
      break
    end

  end
end

play_game