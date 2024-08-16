import os
from flask import Flask, jsonify
from flask_cors import CORS
import sqlite3
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Get the absolute path to the database file
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATABASE_PATH = os.path.join(BASE_DIR, 'database.db')

# Test for connect successfully
@app.route('/')
def home():
    return "Flask server is running successfully!"

def get_db_connection():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/brands', methods=['GET'])
def get_brands():
    conn = get_db_connection()
    brands = conn.execute('SELECT * FROM brands').fetchall()
    conn.close()
    return jsonify([dict(brand) for brand in brands])

@app.route('/api/promotions', methods=['GET'])
def get_promotions():
    conn = get_db_connection()
    promotions = conn.execute('''
        SELECT p.id, p.promotion_type, p.start_date, p.end_date, b.brand_name, w.content_title
        FROM promotions p
        JOIN brands b ON p.brand_id = b.brand_id
        JOIN web_scraping w ON p.scraping_id = w.scraping_id
        WHERE p.end_date >= ?
        ORDER BY p.start_date
    ''', (int(datetime.now().timestamp()),)).fetchall()
    conn.close()
    
    return jsonify([{
        'id': promo['id'],
        'brand': promo['brand_name'],
        'type': promo['promotion_type'],
        'startDate': datetime.fromtimestamp(promo['start_date']).isoformat(),
        'endDate': datetime.fromtimestamp(promo['end_date']).isoformat(),
        'title': promo['content_title']
    } for promo in promotions])

if __name__ == '__main__':
    app.run(debug=True)