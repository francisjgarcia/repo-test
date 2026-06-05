import sys

# Agregar /app al PYTHONPATH para que encuentre src/ desde el contenedor
if '/app' not in sys.path:
    sys.path.insert(0, '/app')

from src.app import app


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
