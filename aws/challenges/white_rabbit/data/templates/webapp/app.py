from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def hello():
    return f"Hello from Flask! Env: {os.getenv('FLASK_ENV')}"

if __name__ == "__main__":
    app.run()