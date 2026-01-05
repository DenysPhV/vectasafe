from fastapi import FastAPI
import os
import uvicorn

app = FastAPI(title="VectaSafe API")

@app.get("/")
def read_root():
    return {"message": "Welcome to VectaSafe API via Global LB!"}

@app.get("/health")
def health_check():
    """Цей ендпоінт використовується Load Balancer'ом для перевірки життя сервісу"""
    return {"status": "ok"}

if __name__ == "__main__":
    # Запускаємо сервер на всіх інтерфейсах (0.0.0.0) та порті 8080
    uvicorn.run(app, host="0.0.0.0", port=8080)