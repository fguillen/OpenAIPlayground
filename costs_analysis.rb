require "openai"
require "json"
require "dotenv/load"

def client
  return @client if @client

  @client ||=
    OpenAI::Client.new(
      access_token: ENV["API_KEY"],
      log_errors: true # Highly recommended in development, so you can see what errors OpenAI is returning. Not recommended in production.
    )

  # puts ">>> models.list: #{JSON.pretty_generate(@client.models.list)}"

  @client.models.retrieve(id: "gpt-4o")

  @client
end

def extract_info(csv_data)
  prompt = <<~PROMPT
    You are a friendly and acurate data analysis assistant.
    Your job is to extract information from a costs csv file. And
    answer the questions from our user in a friendly mode.

    Here is the questions of our user:
    1. What is the month with higher costs?
    2. How much was the costs in the month with higher costs?
    3. What month has the biggest increase in costs from same month in previous year?

    Here you have the costs csv file:

    #{csv_data}
  PROMPT

  puts ">>> prompt: #{prompt}"

  response =
    client.chat(
      parameters: {
        model: "gpt-4o", # Required.
        messages: [{ role: "user", content: prompt}], # Required.
        temperature: 0,
      })

  puts ">>> response: #{JSON.pretty_generate(response)}"

  response.dig("choices", 0, "message", "content")
end



result = extract_info(File.read("data/costs.csv"))

puts ">>> result: #{result}"
