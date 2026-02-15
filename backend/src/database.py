# src/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from config import settings

connect_args = {}
if "ssl" in str(settings.DB_URL):
    # Для asyncpg іноді треба явно дозволяти SSL, якщо він є в URL
    pass

# Створення асинхронного двигуна
engine = create_async_engine(
    settings.DB_URL,
    echo=False, # True для дебагу SQL запитів
    future=True
)

# Фабрика сесій (використовується і в API, і в Worker)
async_session_factory = async_sessionmaker(
    engine, 
    expire_on_commit=False, 
    class_=AsyncSession
)

Base = declarative_base()

# Dependency для FastAPI (впорскування сесії в роути)
async def get_db():
    async with async_session_factory() as session:
        yield session

# Функція для створення таблиць при старті (для MVP без Alembic)
async def init_db():
    async with engine.begin() as conn:
        # Імпортуємо моделі тут, щоб SQLAlchemy їх побачила перед створенням
        from models import User, Document
        await conn.run_sync(Base.metadata.create_all)
