import sqlite3
import os

DB_FILE = 'database.db'

# Define the expected schema for each table
SCHEMA = {
    'web_scraping': '''
        CREATE TABLE web_scraping (
            scraping_id INTEGER PRIMARY KEY,
            external_url TEXT,
            scraping_date INTEGER,  -- Unix timestamp
            content_title TEXT,
            content_text TEXT,
            content_note TEXT
        );
    ''',
    'brands': '''
        CREATE TABLE brands (
            brand_id INTEGER PRIMARY KEY,
            brand_name TEXT
        );
    ''',
    'drink_types': '''
        CREATE TABLE drink_types (
            type_id INTEGER PRIMARY KEY,
            type_name TEXT
        );
    ''',
    'promotions': '''
        CREATE TABLE promotions (
            id INTEGER PRIMARY KEY,
            scraping_id INTEGER,
            brand_id INTEGER,
            promotion_type TEXT,
            start_date INTEGER,  -- Unix timestamp
            end_date INTEGER,    -- Unix timestamp
            FOREIGN KEY (scraping_id) REFERENCES web_scraping(scraping_id),
            FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
        );
    ''',
    'drinks': '''
        CREATE TABLE drinks (
            drink_id INTEGER PRIMARY KEY,
            brand_id INTEGER,
            type_id INTEGER,
            drink_name TEXT,
            FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
            FOREIGN KEY (type_id) REFERENCES drink_types(type_id)
        );
    ''',
    'promotion_drinks': '''
        CREATE TABLE promotion_drinks (
            id INTEGER,
            drink_id INTEGER,
            PRIMARY KEY (id, drink_id),
            FOREIGN KEY (id) REFERENCES promotions(id),
            FOREIGN KEY (drink_id) REFERENCES drinks(drink_id)
        );
    '''
}

def check_db_structure(cursor):
    """Check if the existing database structure matches the expected schema."""
    for table, expected_schema in SCHEMA.items():
        cursor.execute(f"PRAGMA table_info({table});")
        columns = cursor.fetchall()
        column_names = {col[1] for col in columns}
        expected_columns = set(line.split()[0] for line in expected_schema.split('\n') if line.strip().startswith('CREATE TABLE'))
        
        if column_names != expected_columns:
            print(f"Table '{table}' structure does not match the expected schema.")
            print(f"Expected columns: {expected_columns}")
            print(f"Actual columns: {column_names}")
        else:
            print(f"Table '{table}' structure matches the expected schema.")

def main():
    if os.path.exists(DB_FILE):
        print("Database file exists. Checking structure...")
        
        # Connect to the existing database
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        
        check_db_structure(cursor)
        
        # Close the connection
        conn.close()
    else:
        print("Database file does not exist. Creating new database...")
        
        # Create a new SQLite3 database connection
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()

        # Create tables based on the provided structure
        for table_schema in SCHEMA.values():
            cursor.executescript(table_schema)
        
        # Commit the changes
        conn.commit()
        
        # Close the connection
        conn.close()
        
        print("Database created successfully!")

if __name__ == "__main__":
    main()
