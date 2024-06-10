require "sequel"
require "langchain"
require "openai"
require "sqlite3"
require "dotenv/load"


# sqlite_db = SQLite3::Database.new "#{__dir__}/db/test.db"

DB = Sequel.connect("sqlite://db/test.db")

DB.create_table?(:items) do
  primary_key :id
  String :name
  Float :price
end

items = DB[:items] # Create a dataset

# Populate the table
items.insert(name: "abc", price: rand * 100)
items.insert(name: "def", price: rand * 100)
items.insert(name: "ghi", price: rand * 100)

# # Print out the number of records
# puts "Item count: #{items.count}"

# # Print out the average price
# puts "The average price is: #{items.avg(:price)}"



# Longchain
Langchain.logger.level = :debug

llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
thread = Langchain::Thread.new
assistant = Langchain::Assistant.new(
  llm: llm,
  thread: thread,
  instructions: "You are a data analist that is quering a database to answer the user's requests",
  tools: [
    Langchain::Tool::Database.new(connection_string: "sqlite://db/test.db")
  ]
)

assistant.add_message content: "What is the average price of all the items?"
assistant.run auto_tool_execution: true

puts assistant.thread.messages.inspect
