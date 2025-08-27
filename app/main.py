from flask import Flask
from prometheus_client import Gauge, make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from flask import request

app = Flask(__name__)
REQUEST_COUNT = Gauge('http_requests_total', 'Total HTTP Requests')

@app.route('/')
def hello_world():
    REQUEST_COUNT.inc()
    return 'Hello, World!'

app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
