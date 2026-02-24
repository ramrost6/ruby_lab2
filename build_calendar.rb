require 'date'

if ARGV.length != 4
  puts "Использование: ruby build_calendar.rb teams.txt 01.08.2026 01.06.2027 calendar.txt"
  exit
end

teams_file, start_date_str, end_date_str, output_file = ARGV

unless File.exist?(teams_file)
  puts "Ошибка: файл с командами не найден."
  exit
end

#корректность дат
begin
  start_date = Date.strptime(start_date_str, "%d.%m.%Y")
  end_date = Date.strptime(end_date_str, "%d.%m.%Y")
rescue
  puts "Ошибка: неверный формат даты. Используйте ДД.ММ.ГГГГ"
  exit
end

#дата начала должна быть раньше даты окончания
if start_date >= end_date
  puts "Ошибка: дата начала должна быть раньше даты окончания."
  exit
end

#чтение команд из файла
teams = []
line_number = 0

File.readlines(teams_file).each do |line|
  line_number += 1
  line.strip!
  next if line.empty?

  #название команды - город
  match = line.match(/^\d+\.\s*(.+?)\s*—\s*(.+)$/)

  unless match
    puts "Ошибка формата в строке #{line_number}: #{line}"
    exit
  end

  name = match[1].strip
  city = match[2].strip

  if name.empty? || city.empty?
    puts "Ошибка: пустое название или город в строке #{line_number}"
    exit
  end

  teams << { name: name, city: city }
end

#должно быть минимум 2 команды
if teams.length < 2
  puts "Ошибка: необходимо минимум 2 команды."
  exit
end

#создание матчей
matches = []

# Каждая команда играет с каждой (2 круга)
teams.combination(2).each do |team1, team2|
  # Первый круг
  matches << { home: team1, away: team2 }
  # Второй круг (обратная встреча)
  matches << { home: team2, away: team1 }
end

#генерация доступных слотов
allowed_days = [5, 6, 0]

# Время начала игр
times = ["12:00", "15:00", "18:00"]

slots = []

current_date = start_date

while current_date <= end_date
  if allowed_days.include?(current_date.wday)
    times.each do |time|
      2.times do
        slots << { date: current_date, time: time }
      end
    end
  end
  current_date += 1
end

#проверяем, хватает ли слотов
if slots.length < matches.length
  puts "Ошибка: недостаточно дат для проведения всех матчей."
  exit
end

#равнометражное распределение матчей по слотам
step = slots.length.to_f / matches.length
scheduled_games = []

matches.each_with_index do |match, index|
  slot_index = (index * step).floor

  scheduled_games << {
    date: slots[slot_index][:date],
    time: slots[slot_index][:time],
    home: match[:home],
    away: match[:away]
  }
end

#сортировка по дате и времени
scheduled_games.sort_by! { |g| [g[:date], g[:time]] }

#запись в файл
File.open(output_file, "w") do |file|
  file.puts "СПОРТИВНЫЙ КАЛЕНДАРЬ"
  file.puts "Период: #{start_date.strftime("%d.%m.%Y")} - #{end_date.strftime("%d.%m.%Y")}"
  file.puts "-" * 70

  current_date = nil

  scheduled_games.each do |game|
    if current_date != game[:date]
      current_date = game[:date]
      file.puts
      file.puts current_date.strftime("%A, %d.%m.%Y")
      file.puts "-" * 70
    end

    file.puts "#{game[:time]} | #{game[:home][:name]} (#{game[:home][:city]}) vs #{game[:away][:name]} (#{game[:away][:city]})"
  end
end

puts "Календарь успешно создан: #{output_file}"