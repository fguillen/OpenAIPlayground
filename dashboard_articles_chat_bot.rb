require "sqlite3"
require "csv"

# Building the DB
db_file_path = "#{__dir__}/db/dashboard_articles.db"
database_exists = File.exists?(db_file_path)
db = SQLite3::Database.open(db_file_path)

if database_exists
  puts "Database file '#{db_file_path}' already exists."
else
  sql = <<~SQL
    CREATE TABLE articles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sku TEXT,
      article TEXT,
      supplier TEXT,
      category TEXT,
      purchases REAL,
      units INTEGER,
      purchases_year_before REAL,
      units_year_before INTEGER
    );
  SQL
  db.execute(sql)

  CSV.foreach("data/articles_data.csv", headers: true) do |row|
    puts "Inserting row: #{row}"
    sql = <<~SQL
      INSERT INTO articles (
        sku,
        article,
        supplier,
        category,
        purchases,
        units,
        purchases_year_before,
        units_year_before
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    SQL

    db.execute(
      sql,
      [
        row["ID"],
        row["Article"],
        row["Supplier"],
        row["Category"],
        row["Purchases €"],
        row["Units"],
        row["Purchases Year Before €"],
        row["Purchases Year Before €"]
      ]
    )
  end

  puts "Database file '#{db_file_path}' created."
end

# Testing data
## Num or articles
num_of_articles = db.query("select count(*) from articles").first
puts ">>>> Test num_of_articles: #{num_of_articles}"

total_purchases_year = db.query("select sum(purchases) from articles").first
puts ">>>> Test total_purchases_year: #{total_purchases_year}"

total_purchases_year_before = db.query("select sum(purchases_year_before) from articles").first
puts ">>>> Test total_purchases_year_before: #{total_purchases_year_before}"

supplier_with_more_purchases = db.query("select supplier, sum(purchases) from articles group by supplier order by sum(purchases) desc limit 1").first
puts ">>>> Test supplier_with_more_purchases: #{supplier_with_more_purchases}"


# Building the assistant
require "langchain"
require "openai"
require "dotenv"
require "sequel"

Dotenv.load
Langchain.logger.level = :debug

def execute_request(request, assistant)
  puts ">>>> request: #{request}"
  assistant.add_message content: request
  assistant.run auto_tool_execution: true
  puts assistant.thread.messages.map(&:to_hash)
end

llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
thread = Langchain::Thread.new
assistant = Langchain::Assistant.new(
  llm: llm,
  thread: thread,
  instructions: "You are a data analist that is quering a database to answer the user's requests",
  tools: [
    Langchain::Tool::Database.new(connection_string: "sqlite://#{db_file_path}")
  ]
)

execute_request("How may articles are in the list?", assistant)
execute_request("When I say articles I mean the table articles. How many items are in the table articles?", assistant)
execute_request("What is the total of purchases this year?", assistant)
execute_request("What is the total of purchases the previous year?", assistant)
execute_request("What is the supplier with more purchases this year?", assistant)
