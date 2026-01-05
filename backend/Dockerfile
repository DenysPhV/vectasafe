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

# Команда запуску
CMD ["python", "main.py"]