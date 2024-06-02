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

  puts ">>> models.list: #{JSON.pretty_generate(@client.models.list)}"

  @client.models.retrieve(id: "gpt-4o")

  @client
end

def extract_info(text)
  prompt = <<~PROMPT
    Extract the following information from the text:
    Nvidia's revenue
    What Nvidia did this quarter
    Remarks about AI
    Divide your report in three parts with a title for each part
    Make your report as short as possible
  PROMPT

  full_content = prompt + "\n\n" + text

  puts ">>> prompt: #{prompt}"

  response =
    client.chat(
      parameters: {
        model: "gpt-3.5-turbo-16k", # Required.
        messages: [{ role: "user", content: full_content}], # Required.
        temperature: 0.7,
      })

  puts ">>> response: #{JSON.pretty_generate(response)}"

  response.dig("choices", 0, "message", "content")
end

result = extract_info(File.read("data/nvidia.txt"))

puts ">>> result: #{result}"
