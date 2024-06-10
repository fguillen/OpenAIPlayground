# python3 -m pip install langchain langchain-community langchain-core
# It doesnt work... deprecated libraries

from langchain_community.chat_models import ChatOpenAI
from langchain_community.schema import HumanMessage, SystemMessage, AIMessage
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

chat = ChatOpenAI(temperature = .7, openai_api_key = os.getenv("API_KEY"))

chat(
    [
        SystemMessage(content = "You are a nice AI bot that helps a user figure out where to travel in one short sentence"),
        HumanMessage(content = "I like the beaches where should I go?"),
        AIMessage(content = "You should go to Nice, France"),
        HumanMessage(content = "What else should I do when I'm there?")
    ]
)
