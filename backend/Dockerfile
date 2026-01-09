# Використовуємо легкий образ Python
FROM python:3.11-slim

# Встановлюємо робочу директорію
WORKDIR /app

# Копіюємо файл залежностей та встановлюємо їх
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код застосунку
COPY . .

# Вказуємо порт, який буде слухати контейнер (інформативно)
EXPOSE 8080

# Запускаємо uvicorn напряму.
# --host 0.0.0.0: щоб слухати всі інтерфейси
# --port 8080: порт, який ви відкрили через EXPOSE
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]