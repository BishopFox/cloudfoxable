import os
import boto3
import pymysql

def lambda_handler(event, context):
    # Hardcoded test data (replace this with your actual test data)
    test_data = """
    CREATE TABLE IF NOT EXISTS credit_cards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    card_holder_name VARCHAR(255) NOT NULL,
    card_number VARCHAR(16) NOT NULL,
    expiry_date DATE NOT NULL,
    cvv INT NOT NULL,
    notes TEXT
    );

    INSERT INTO credit_cards (card_holder_name, card_number, expiry_date, cvv, notes)
    VALUES ('Jane Smith', '2345678923456789', '2024-06-30', 456, NULL),
        ('Alice Johnson', '3456789034567890', '2023-12-31', 789, NULL),
        ('Bob Brown', '4567890145678901', '2023-05-31', 321, 'FLAG{DidYouKnowDatabasesHoldSensitiveData}'),
        ('Charlie Davis', '5678901256789012', '2022-11-30', 654, NULL),
        ('John Doe', '1234567812345678', '2025-01-31', 123, NULL);
    """


       

    # RDS Configuration
    rds_host  = os.environ.get('RDS_HOST')
    name = os.environ.get('DB_USERNAME')
    password = os.environ.get('DB_PASSWORD')
    db_name = os.environ.get('DB_NAME')

    try:
        conn = pymysql.connect(rds_host, user=name, passwd=password, db=db_name, connect_timeout=5)
    except:
        print("ERROR: Unexpected error: Could not connect to MySql instance.")
        sys.exit()

    print("SUCCESS: Connection to RDS mysql instance succeeded")
    
    with conn.cursor() as cur:
        cur.execute(test_data)
        conn.commit()

    return "Data loaded into RDS successfully!"
