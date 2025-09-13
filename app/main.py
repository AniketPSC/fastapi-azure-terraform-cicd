# app/main.py
import os
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app.models import Task
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Create DB tables (safe to call each start)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Todo API (FastAPI)")

# Pydantic models
class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None

class TaskOut(TaskCreate):
    id: int
    completed: bool

    class Config:
        orm_mode = True

# DB dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Optional Key Vault integration: if KEY_VAULT_URL is set, try to read a secret named "sample-secret"
KEY_VAULT_URL = os.getenv("KEY_VAULT_URL")
if KEY_VAULT_URL:
    try:
        credential = DefaultAzureCredential()
        kv_client = SecretClient(vault_url=KEY_VAULT_URL, credential=credential)
        # Try reading "sample-secret" (it may or may not exist)
        try:
            secret = kv_client.get_secret("sample-secret")
            print("Key Vault: sample-secret =", secret.value)
        except Exception as e:
            print("Key Vault: couldn't fetch sample-secret yet:", e)
    except Exception as e:
        print("Key Vault setup failed locally:", e)

@app.get("/")
def root():
    return {"message": "Hello - FastAPI Todo app running"}

@app.post("/tasks", response_model=TaskOut)
def create_task(payload: TaskCreate, db: Session = Depends(get_db)):
    db_task = Task(title=payload.title, description=payload.description)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@app.get("/tasks", response_model=List[TaskOut])
def list_tasks(db: Session = Depends(get_db)):
    return db.query(Task).all()

@app.get("/tasks/{task_id}", response_model=TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    t = db.query(Task).filter(Task.id == task_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Task not found")
    return t

@app.put("/tasks/{task_id}", response_model=TaskOut)
def update_task(task_id: int, payload: TaskCreate, db: Session = Depends(get_db)):
    t = db.query(Task).filter(Task.id == task_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Task not found")
    t.title = payload.title
    t.description = payload.description
    db.commit()
    db.refresh(t)
    return t

@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    t = db.query(Task).filter(Task.id == task_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(t)
    db.commit()
    return {}
