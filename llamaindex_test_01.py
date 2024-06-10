# From here: https://docs.llamaindex.ai/en/latest/understanding/putting_it_all_together/structured_data/

# Logging
import logging
import sys

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
logging.getLogger().addHandler(logging.StreamHandler(stream=sys.stdout))

# Setup
from sqlalchemy import (
    create_engine,
    MetaData,
    Table,
    Column,
    String,
    Integer,
    select,
    column,
)

engine = create_engine("sqlite:///:memory:")
metadata_obj = MetaData()

# create city SQL table
table_name = "city_stats"
city_stats_table = Table(
    table_name,
    metadata_obj,
    Column("city_name", String(16), primary_key=True),
    Column("population", Integer),
    Column("country", String(16), nullable=False),
)
metadata_obj.create_all(engine)

# insert data
from sqlalchemy import insert

rows = [
    {"city_name": "Toronto", "population": 2731571, "country": "Canada"},
    {"city_name": "Tokyo", "population": 13929286, "country": "Japan"},
    {"city_name": "Berlin", "population": 600000, "country": "Germany"},
]
for row in rows:
    stmt = insert(city_stats_table).values(**row)
    with engine.begin() as connection:
        cursor = connection.execute(stmt)


# Finally, we can wrap the SQLAlchemy engine with our SQLDatabase wrapper; this allows the db to be used within LlamaIndex:
from llama_index.core import SQLDatabase

sql_database = SQLDatabase(engine, include_tables=["city_stats"])


# Natural Language queries
from llama_index.core.query_engine import NLSQLTableQueryEngine

from dotenv import load_dotenv
import os
load_dotenv()
os.environ["OPENAI_API_KEY"] = os.getenv("API_KEY")

query_engine = NLSQLTableQueryEngine(
    sql_database=sql_database,
    tables=["city_stats"],
)
query_str = "Which city has the highest population?"
response = query_engine.query(query_str)

print(query_str)
print(response)

# Building table index
from llama_index.core.objects import (
    SQLTableNodeMapping,
    ObjectIndex,
    SQLTableSchema,
)

table_node_mapping = SQLTableNodeMapping(sql_database)
table_schema_objs = [
    (SQLTableSchema(table_name="city_stats"))
]  # one SQLTableSchema for each table

obj_index = ObjectIndex.from_objects(
    table_schema_objs,
    table_node_mapping,
    ObjectIndex,
)

# Using natural language SQL queries
from llama_index.core.indices.struct_store import SQLTableRetrieverQueryEngine

query_engine = SQLTableRetrieverQueryEngine(
    sql_database, obj_index.as_retriever(similarity_top_k=1)
)
response = query_engine.query("Which city has the highest population?")
print(response)
