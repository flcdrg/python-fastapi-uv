from fastapi import FastAPI
from os import getenv
from dotenv import load_dotenv
from mssql_python import connect

app = FastAPI()

load_dotenv()

@app.get("/")
async def root():
    connStr = getenv("SQL_CONNECTION_STRING")
    print(f"Connection String: {connStr}")

    conn = connect(connStr)
    SQL_QUERY = """
    SELECT
    TOP 1 p.LastName
    FROM
    Person.Person AS p;
    """

    cursor = conn.cursor()
    cursor.execute(SQL_QUERY)

    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return {"message": f"Hello, {result[0]}!"}