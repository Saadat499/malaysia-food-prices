import importlib
import os
from pathlib import Path
import sys

packages = [
    "pandas", "numpy", "pyarrow", "duckdb", "matplotlib",
    "statsmodels.api", "sklearn", "sqlalchemy", "psycopg",
    "dotenv", "jupyterlab", "ipykernel",
]

print(f"Python: {sys.version.split()[0]}")
print(f"Executable: {sys.executable}")

failed = False
for name in packages:
    try:
        importlib.import_module(name)
        print(f"PASS import: {name}")
    except Exception as exc:
        print(f"FAIL import: {name} ({type(exc).__name__})")
        failed = True

if failed:
    sys.exit(1)

from dotenv import load_dotenv
import psycopg

# Read local settings; existing environment variables take precedence.
load_dotenv(Path(__file__).resolve().parent.parent / ".env", override=False)

required = ["PGHOST", "PGPORT", "PGUSER", "PGPASSWORD"]
missing = [name for name in required if not os.getenv(name)]
if missing:
    print("FAIL missing settings: " + ", ".join(missing))
    sys.exit(1)

try:
    with psycopg.connect(
        host=os.environ["PGHOST"],
        port=os.environ["PGPORT"],
        user=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        dbname="food_prices",
        connect_timeout=5,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT current_database(), 1")
            database, result = cur.fetchone()
            if database != "food_prices" or result != 1:
                raise RuntimeError("Unexpected database result")
except Exception as exc:
    print(f"FAIL PostgreSQL: {type(exc).__name__}")
    print("Check server, host, port, database, username, and password.")
    sys.exit(1)

print("PASS PostgreSQL: food_prices; SELECT 1 returned 1")
print("PASS all environment checks")