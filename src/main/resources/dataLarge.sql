-- =====================================================
-- LARGE VOLUME TEST DATA (FIXED)
-- =====================================================

-- AUTHORS AND GENRES ARE ALREADY CREATED
-- ... (all genres and authors creation code remains unchanged)

-- =====================================================
-- 3. BOOKS (500+ via generation) - FIXED!
-- =====================================================

-- Get real min/max IDs after authors insertion
DO $$
DECLARE
min_author_id INTEGER;
    max_author_id INTEGER;
    min_genre_id INTEGER;
    max_genre_id INTEGER;
BEGIN
SELECT MIN(id), MAX(id) INTO min_author_id, max_author_id FROM authors;
SELECT MIN(id), MAX(id) INTO min_genre_id, max_genre_id FROM genres;

-- Generate 500 books with existing IDs
INSERT INTO books (title, genre_id, author_id, publication_year, isbn, total_copies, available_copies)
SELECT
    'Book ' || n || ' - ' ||
    CASE (random() * 9)::int
            WHEN 0 THEN 'Path'
            WHEN 1 THEN 'Secret'
            WHEN 2 THEN 'Star'
            WHEN 3 THEN 'Wind'
            WHEN 4 THEN 'Fate'
            WHEN 5 THEN 'Night'
            WHEN 6 THEN 'Day'
            WHEN 7 THEN 'Light'
            WHEN 8 THEN 'Shadow'
            ELSE 'Dream'
END || ' ' ||
        CASE (random() * 9)::int
            WHEN 0 THEN 'of Warrior'
            WHEN 1 THEN 'of Mage'
            WHEN 2 THEN 'of Prophet'
            WHEN 3 THEN 'of Hero'
            WHEN 4 THEN 'of Wanderer'
            WHEN 5 THEN 'of Poet'
            WHEN 6 THEN 'of King'
            WHEN 7 THEN 'of Demon'
            WHEN 8 THEN 'of Angel'
            ELSE 'of Ghost'
END,
        -- Generate IDs within existing range
        (random() * (max_genre_id - min_genre_id) + min_genre_id)::int,
        (random() * (max_author_id - min_author_id) + min_author_id)::int,
        (1900 + (random() * 124)::int),
        'ISBN-' || LPAD(n::text, 5, '0') || '-' || LPAD((random() * 9999)::int::text, 4, '0'),
        1 + (random() * 9)::int,
        1 + (random() * 9)::int
    FROM generate_series(1, 500) AS n;
END $$;

-- =====================================================
-- 4. USERS (200+) - FIXED
-- =====================================================
INSERT INTO users (name, email, phone, address)
SELECT
    'User ' || n,
    'user' || n || '@email.com',
    '+1-555-' || LPAD(FLOOR(random() * 999)::text, 3, '0') || '-' ||
    LPAD(FLOOR(random() * 999)::text, 3, '0') || '-' ||
    LPAD(FLOOR(random() * 99)::text, 2, '0'),
    'Street ' || CASE FLOOR(random() * 10)::int
        WHEN 0 THEN 'Main'
        WHEN 1 THEN 'Oak'
        WHEN 2 THEN 'Pine'
        WHEN 3 THEN 'Maple'
        WHEN 4 THEN 'Cedar'
        WHEN 5 THEN 'Elm'
        WHEN 6 THEN 'Birch'
        WHEN 7 THEN 'Park'
        WHEN 8 THEN 'Lake'
        ELSE 'Hill'

