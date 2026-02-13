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

-- =====================================================
-- POPULATE DATA (WITHOUT DUPLICATION ERRORS)
-- =====================================================

-- GENRES (only INSERT without conflicts, since table is new)
INSERT INTO genres (title, description) VALUES
                                            ('Science Fiction', 'Science fiction, cyberpunk, alternative history'),
                                            ('Detective', 'Crime investigations, thrillers'),
                                            ('Novel', 'Love stories, psychological prose');

-- AUTHORS
INSERT INTO authors (full_name, birth_year, country) VALUES
                                                         ('Arkady and Boris Strugatsky', 1925, 'USSR'),
                                                         ('Agatha Christie', 1890, 'United Kingdom'),
                                                         ('Leo Tolstoy', 1828, 'Russia');

-- BOOKS
INSERT INTO books (title, genre_id, author_id, publication_year, isbn, total_copies, available_copies) VALUES
                                                                                                           ('Roadside Picnic', 1, 1, 1972, '978-5-17-118196-5', 3, 3),
                                                                                                           ('Hard to Be a God', 1, 1, 1964, '978-5-17-118197-2', 2, 2),
                                                                                                           ('Murder on the Orient Express', 2, 2, 1934, '978-5-699-41236-7', 2, 2),
                                                                                                           ('Anna Karenina', 3, 3, 1877, '978-5-04-088654-8', 3, 3);

-- USERS
INSERT INTO users (name, email, phone, address) VALUES
                                                    ('John Smith', 'john@email.com', '+1-555-123-4567', '123 Main St'),
                                                    ('Mary Johnson', 'mary@email.com', '+1-555-234-5678', '456 Oak Ave'),
                                                    ('Alex Brown', 'alex@email.com', '+1-555-345-6789', '789 Pine Rd');

-- ACTIVE RENTALS
INSERT INTO rentals (user_id, book_id, rental_date, due_date, status) VALUES
                                                                          (1, 3, CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '9 days', 'active'),
                                                                          (2, 4, CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE + INTERVAL '12 days', 'active');

-- RETURNED RENTALS
INSERT INTO rentals (user_id, book_id, rental_date, return_date, due_date, status) VALUES
                                                                                       (1, 1, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE - INTERVAL '16 days', CURRENT_DATE - INTERVAL '16 days', 'returned'),
                                                                                       (2, 2, CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE - INTERVAL '6 days', 'returned');

-- =====================================================
-- UPDATE available_copies (WITHOUT "UPDATE without WHERE" ERROR)
-- =====================================================
UPDATE books
SET available_copies = total_copies - (
    SELECT COUNT(*)
    FROM rentals
    WHERE book_id = books.id AND status IN ('active', 'overdue')
)
WHERE EXISTS (
    SELECT 1
    FROM rentals
    WHERE book_id = books.id AND status IN ('active', 'overdue')
);
-- WHERE EXISTS updates only books that have active rentals
-- Other books keep available_copies = total_copies

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- SELECT 'genres' as table_name, COUNT(*) FROM genres
-- UNION ALL
-- SELECT 'authors', COUNT(*) FROM authors
-- UNION ALL
-- SELECT 'books', COUNT(*) FROM books
-- UNION ALL
-- SELECT 'users', COUNT(*) FROM users
-- UNION ALL
-- SELECT 'rentals', COUNT(*) FROM rentals;
