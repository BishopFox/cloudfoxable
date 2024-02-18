import os
import boto3
import sys
import pymysql

def lambda_handler(event, context):
    # Hardcoded test data (replace this with your actual test data)
    create_sql_table = """
CREATE TABLE IF NOT EXISTS credit_cards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    card_holder_name VARCHAR(255) NOT NULL,
    card_number VARCHAR(16) NOT NULL,
    expiry_date DATE NOT NULL,
    cvv INT NOT NULL,
    notes TEXT
);
"""

    test_data = """
INSERT INTO credit_cards (card_holder_name, card_number, expiry_date, cvv, notes)
VALUES ('Jane Smith', '2345678923456789', '2024-06-30', 456, NULL),
       ('Alice Johnson', '3456789034567890', '2023-12-31', 789, NULL),
       ('Bob Brown', '4567890145678901', '2023-05-31', 321, 'FLAG{DidYouKnowDatabasesHoldSensitiveData}'),
       ('Charlie Davis', '5678901256789012', '2022-11-30', 654, NULL),
       ('John Doe', '1234567812345678', '2025-01-31', 123, NULL);
"""


    # RDS Configuration
    rds_host  = os.environ.get('RDS_HOST')
    name = os.environ.get('RDS_USER')
    password = os.environ.get('RDS_PASSWORD')
    db_name = os.environ.get('RDS_DB_NAME')

    try:
        print(rds_host, name, password, db_name)
        conn = pymysql.connect(host=rds_host, user=name, passwd=password, database=db_name)
    except Exception as e:
        print(f"ERROR: Unexpected error: Could not connect to MySql instance. Details: {e}")
        sys.exit()

    print("SUCCESS: Connection to RDS mysql instance succeeded")
    
    with conn.cursor() as cur:
        cur.execute(create_sql_table)
        cur.execute(test_data)
        conn.commit()

    return "Data loaded into RDS successfully!"
