from dotenv import load_dotenv
from openai import OpenAI
import pandas as pd
import os

# Load environment variables from .env file
load_dotenv()

client = OpenAI(api_key=os.getenv("API_KEY"))

prompt = (
  """Extract the following information from the text:
  Nvidia's revenue
  What Nvidia did this quarter
  Remarks about AI"""
)

def extract_info(text):
  completions = client.chat.completions.create(
    model="gpt-3.5-turbo-16k",
    messages=[ {"role": "user", "content": prompt+"\n\n"+text} ],
    temperature=0.3
  )
  message = completions#.choices[0].message.content
  return message

f = open("data/nvidia.txt", "r")
txt_data = f.read()

additional_params = extract_info(txt_data)
print(additional_params)
