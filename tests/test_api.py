# tests/test_api.py
import os
# make tests use in-memory SQLite
os.environ["DATABASE_URL"] = "sqlite:///:memory:"

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_and_get_task():
    # create
    r = client.post("/tasks", json={"title":"unit test", "description":"desc"})
    assert r.status_code == 200
    data = r.json()
    assert data["title"] == "unit test"
    assert "id" in data
    tid = data["id"]
    # get
    r2 = client.get(f"/tasks/{tid}")
    assert r2.status_code == 200
    got = r2.json()
    assert got["id"] == tid
