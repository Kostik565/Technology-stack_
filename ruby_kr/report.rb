require 'csv'
require 'json'
require 'fileutils'

CSV_PATH = File.join(__dir__, 'data', 'students.csv')
OUT_DIR  = File.join(__dir__, 'output')
OUT_PATH = File.join(OUT_DIR, 'report.json')

# Сувора перевірка балу; кидає виняток, якщо значення некоректне
def parse_score(raw)
  score = Integer(raw, 10)
  raise ArgumentError, "бал поза діапазоном: #{score}" unless (0..100).cover?(score)

  score
end

# Повертає [масив коректних балів, масив номерів некоректних рядків]
def read_scores(path)
  scores = []
  invalid_rows = []

  CSV.foreach(path, headers: true).with_index(1) do |row, number|
    begin
      scores << parse_score(row['score'])
    rescue ArgumentError, TypeError
      invalid_rows << number
    end
  end

  [scores, invalid_rows]
end

def build_report(scores, invalid_rows)
  average = scores.empty? ? nil : (scores.sum.to_f / scores.size).round(1)

  {
    total: scores.size + invalid_rows.size,
    valid: scores.size,
    invalid_rows: invalid_rows,
    average: average,
    passed: scores.count { |s| s >= 60 }
  }
end

def main
  scores, invalid_rows = read_scores(CSV_PATH)
  report = build_report(scores, invalid_rows)

  FileUtils.mkdir_p(OUT_DIR)
  File.write(OUT_PATH, JSON.pretty_generate(report))
rescue Errno::ENOENT
  warn "Помилка: файл не знайдено: #{CSV_PATH}"
  exit 1
end

main