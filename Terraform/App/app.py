from flask import Flask, request, jsonify
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)

# Enable Prometheus metrics
metrics = PrometheusMetrics(app)

@app.route('/')
def hello_world():
    return 'Hello, World!'

stores = [
    {
        "name": "My Store",
        "items": [
            {
                "name": "Chair",
                "price": 15.99
            }
        ]
    }
]

@app.get('/store')
def get_stores():
    return {"stores": stores}


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)