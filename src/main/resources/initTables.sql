-- =====================================================
-- COMPLETE LIBRARY SCRIPT (CAN BE RUN MULTIPLE TIMES)
-- =====================================================

-- DISABLE FOREIGN KEY CHECKS
SET session_replication_role = 'replica';

-- =====================================================
-- DROP ALL TABLES (IF EXIST)
-- =====================================================
DROP TABLE IF EXISTS rental_history CASCADE;
DROP TABLE IF EXISTS rentals CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS genres CASCADE;

-- ENABLE FOREIGN KEY CHECKS
SET session_replication_role = 'origin';

-- =====================================================
-- CREATE TABLES
-- =====================================================

-- 1. GENRES
CREATE TABLE genres (
                        id SERIAL PRIMARY KEY,
                        title VARCHAR(100) NOT NULL UNIQUE,
                        description TEXT
);

-- 2. AUTHORS
CREATE TABLE authors (
                         id SERIAL PRIMARY KEY,
                         full_name VARCHAR(200) NOT NULL,
                         birth_year INTEGER,
                         country VARCHAR(100)
);

-- 3. BOOKS
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

-- 4. USERS
CREATE TABLE users (
                       id SERIAL PRIMARY KEY,
                       name VARCHAR(200) NOT NULL,
                       email VARCHAR(100) UNIQUE NOT NULL,
                       phone VARCHAR(20),
                       address TEXT,
                       registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. RENTALS
CREATE TABLE rentals (
                         id SERIAL PRIMARY KEY,
                         user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                         book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
                         rental_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         due_date DATE NOT NULL DEFAULT CURRENT_DATE + INTERVAL '14 days',
                         return_date DATE,
                         status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'returned', 'overdue'))
);

-- 6. RENTAL HISTORY
CREATE TABLE rental_history (
                                id SERIAL PRIMARY KEY,
                                user_id INTEGER NOT NULL REFERENCES users(id),
                                book_id INTEGER NOT NULL REFERENCES books(id),
                                rented_at TIMESTAMP NOT NULL,
                                returned_at TIMESTAMP
);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_genre ON books(genre_id);
CREATE INDEX idx_books_author ON books(author_id);
CREATE INDEX idx_rentals_user ON rentals(user_id);
CREATE INDEX idx_rentals_book ON rentals(book_id);
CREATE INDEX idx_rentals_status ON rentals(status);
