-- =====================================================
-- ПОЛНЫЙ СКРИПТ БИБЛИОТЕКИ (МОЖНО ЗАПУСКАТЬ МНОГО РАЗ)
-- =====================================================

-- ОТКЛЮЧАЕМ ПРОВЕРКУ ВНЕШНИХ КЛЮЧЕЙ
SET session_replication_role = 'replica';

-- =====================================================
-- УДАЛЯЕМ ВСЕ ТАБЛИЦЫ (ЕСЛИ СУЩЕСТВУЮТ)
-- =====================================================
DROP TABLE IF EXISTS rental_history CASCADE;
DROP TABLE IF EXISTS rentals CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS genres CASCADE;

-- ВКЛЮЧАЕМ ПРОВЕРКУ ВНЕШНИХ КЛЮЧЕЙ
SET session_replication_role = 'origin';

-- =====================================================
-- СОЗДАНИЕ ТАБЛИЦ
-- =====================================================

-- 1. ЖАНРЫ
CREATE TABLE genres (
                        id SERIAL PRIMARY KEY,
                        title VARCHAR(100) NOT NULL UNIQUE,
                        description TEXT
);

-- 2. АВТОРЫ
CREATE TABLE authors (
                         id SERIAL PRIMARY KEY,
                         full_name VARCHAR(200) NOT NULL,
                         birth_year INTEGER,
                         country VARCHAR(100)
);

-- 3. КНИГИ
CREATE TABLE books (
                       id SERIAL PRIMARY KEY,
                       title VARCHAR(255) NOT NULL,
                       genre_id INTEGER NOT NULL REFERENCES genres(id) ON DELETE RESTRICT,
                       author_id INTEGER NOT NULL REFERENCES authors(id) ON DELETE RESTRICT,
                       publication_year INTEGER CHECK (publication_year > 1400),
                       isbn VARCHAR(20) UNIQUE,
                       total_copies INTEGER DEFAULT 1 CHECK (total_copies >= 0),
                       available_copies INTEGER DEFAULT 1 CHECK (available_copies >= 0)
);

-- 4. ПОЛЬЗОВАТЕЛИ
CREATE TABLE users (
                       id SERIAL PRIMARY KEY,
                       name VARCHAR(200) NOT NULL,
                       email VARCHAR(100) UNIQUE NOT NULL,
                       phone VARCHAR(20),
                       address TEXT,
                       registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. АРЕНДА
CREATE TABLE rentals (
                         id SERIAL PRIMARY KEY,
                         user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                         book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
                         rental_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         due_date DATE NOT NULL DEFAULT CURRENT_DATE + INTERVAL '14 days',
                         return_date DATE,
                         status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'returned', 'overdue'))
);

-- 6. ИСТОРИЯ АРЕНД
CREATE TABLE rental_history (
                                id SERIAL PRIMARY KEY,
                                user_id INTEGER NOT NULL REFERENCES users(id),
                                book_id INTEGER NOT NULL REFERENCES books(id),
                                rented_at TIMESTAMP NOT NULL,
                                returned_at TIMESTAMP
);

-- =====================================================
-- ИНДЕКСЫ
-- =====================================================
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_genre ON books(genre_id);
CREATE INDEX idx_books_author ON books(author_id);
CREATE INDEX idx_rentals_user ON rentals(user_id);
CREATE INDEX idx_rentals_book ON rentals(book_id);
CREATE INDEX idx_rentals_status ON rentals(status);
