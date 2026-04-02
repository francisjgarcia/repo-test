import sys
import os
from app import app

sys.path.insert(0,
                os.path.abspath(os.path.join(os.path.dirname(__file__),
                                             "../src")))


def test_health():
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_index():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.get_json()
