-- =====================================================
-- ТЕСТОВЫЕ ДАННЫЕ БОЛЬШОГО ОБЪЕМА (ИСПРАВЛЕНО)
-- =====================================================

-- СНАЧАЛА СОЗДАЕМ АВТОРОВ И ЖАНРЫ (ЭТО УЖЕ ЕСТЬ)
-- ... (весь код создания genres и authors остается без изменений)

-- =====================================================
-- 3. КНИГИ (500+ через генерацию) - ИСПРАВЛЕНО!
-- =====================================================

-- Получаем реальные мин/макс ID после вставки авторов
DO $$
DECLARE
min_author_id INTEGER;
    max_author_id INTEGER;
    min_genre_id INTEGER;
    max_genre_id INTEGER;
BEGIN
SELECT MIN(id), MAX(id) INTO min_author_id, max_author_id FROM authors;
SELECT MIN(id), MAX(id) INTO min_genre_id, max_genre_id FROM genres;

-- Генерируем 500 книг с существующими ID
INSERT INTO books (title, genre_id, author_id, publication_year, isbn, total_copies, available_copies)
SELECT
    'Книга ' || n || ' - ' ||
    CASE (random() * 9)::int
            WHEN 0 THEN 'Путь'
            WHEN 1 THEN 'Тайна'
            WHEN 2 THEN 'Звезда'
            WHEN 3 THEN 'Ветер'
            WHEN 4 THEN 'Судьба'
            WHEN 5 THEN 'Ночь'
            WHEN 6 THEN 'День'
            WHEN 7 THEN 'Свет'
            WHEN 8 THEN 'Тень'
            ELSE 'Мечта'
END || ' ' ||
        CASE (random() * 9)::int
            WHEN 0 THEN 'воина'
            WHEN 1 THEN 'мага'
            WHEN 2 THEN 'пророка'
            WHEN 3 THEN 'героя'
            WHEN 4 THEN 'странника'
            WHEN 5 THEN 'поэта'
            WHEN 6 THEN 'короля'
            WHEN 7 THEN 'демона'
            WHEN 8 THEN 'ангела'
            ELSE 'призрака'
END,
        -- Генерируем ID в пределах существующих
        (random() * (max_genre_id - min_genre_id) + min_genre_id)::int,
        (random() * (max_author_id - min_author_id) + min_author_id)::int,
        (1900 + (random() * 124)::int),
        'ISBN-' || LPAD(n::text, 5, '0') || '-' || LPAD((random() * 9999)::int::text, 4, '0'),
        1 + (random() * 9)::int,
        1 + (random() * 9)::int
    FROM generate_series(1, 500) AS n;
END $$;

-- =====================================================
-- 4. ПОЛЬЗОВАТЕЛИ (200+) - ИСПРАВЛЕНО
-- =====================================================
INSERT INTO users (name, email, phone, address)
SELECT
    'Пользователь ' || n,
    'user' || n || '@email.com',
    '+7-' || LPAD(FLOOR(random() * 999)::text, 3, '0') || '-' ||
    LPAD(FLOOR(random() * 999)::text, 3, '0') || '-' ||
    LPAD(FLOOR(random() * 99)::text, 2, '0'),
    'ул. ' || CASE FLOOR(random() * 10)::int
        WHEN 0 THEN 'Ленина'
        WHEN 1 THEN 'Пушкина'
        WHEN 2 THEN 'Гагарина'
        WHEN 3 THEN 'Советская'
        WHEN 4 THEN 'Мира'
        WHEN 5 THEN 'Лесная'
        WHEN 6 THEN 'Садовая'
        WHEN 7 THEN 'Парковая'
        WHEN 8 THEN 'Школьная'
        ELSE 'Молодежная'
END || ', д.' || FLOOR(random() * 100 + 1)::int ||
    CASE WHEN random() > 0.5 THEN ', кв.' || FLOOR(random() * 200 + 1)::int ELSE '' END
FROM generate_series(1, 200) AS n;

-- =====================================================
-- 5. АРЕНДА (1000+ с разными статусами) - ИСПРАВЛЕНО
-- =====================================================
DO $$
DECLARE
min_user_id INTEGER;
    max_user_id INTEGER;
    min_book_id INTEGER;
    max_book_id INTEGER;
BEGIN
SELECT MIN(id), MAX(id) INTO min_user_id, max_user_id FROM users;
SELECT MIN(id), MAX(id) INTO min_book_id, max_book_id FROM books;

-- Активные аренды (300)
INSERT INTO rentals (user_id, book_id, rental_date, due_date, status)
SELECT
    FLOOR(random() * (max_user_id - min_user_id + 1) + min_user_id)::int,
    FLOOR(random() * (max_book_id - min_book_id + 1) + min_book_id)::int,
            CURRENT_DATE - (FLOOR(random() * 30)::int * INTERVAL '1 day'),
    CURRENT_DATE + (FLOOR(random() * 14)::int * INTERVAL '1 day'),
    'active'
FROM generate_series(1, 300)
    ON CONFLICT DO NOTHING;

-- Просроченные аренды (200)
INSERT INTO rentals (user_id, book_id, rental_date, due_date, status)
SELECT
    FLOOR(random() * (max_user_id - min_user_id + 1) + min_user_id)::int,
    FLOOR(random() * (max_book_id - min_book_id + 1) + min_book_id)::int,
            CURRENT_DATE - (30 + FLOOR(random() * 30)::int) * INTERVAL '1 day',
    CURRENT_DATE - (FLOOR(random() * 15)::int * INTERVAL '1 day'),
    'overdue'
FROM generate_series(1, 200)
ON CONFLICT DO NOTHING;

-- Возвращенные аренды (500)
INSERT INTO rentals (user_id, book_id, rental_date, return_date, due_date, status)
SELECT
    FLOOR(random() * (max_user_id - min_user_id + 1) + min_user_id)::int,
    FLOOR(random() * (max_book_id - min_book_id + 1) + min_book_id)::int,
            CURRENT_DATE - (60 + FLOOR(random() * 100)::int) * INTERVAL '1 day',
    CURRENT_DATE - (10 + FLOOR(random() * 30)::int) * INTERVAL '1 day',
    CURRENT_DATE - (14 + FLOOR(random() * 30)::int) * INTERVAL '1 day',
    'returned'
FROM generate_series(1, 500)
ON CONFLICT DO NOTHING;
END $$;

-- =====================================================
-- 6. ОБНОВЛЕНИЕ available_copies
-- =====================================================
UPDATE books b
SET available_copies = GREATEST(0, b.total_copies - COALESCE((
                                                                 SELECT COUNT(*)
                                                                 FROM rentals r
                                                                 WHERE r.book_id = b.id AND r.status IN ('active', 'overdue')
                                                             ), 0));

-- =====================================================
-- 7. ИСТОРИЯ АРЕНД (из возвращенных)
-- =====================================================
INSERT INTO rental_history (user_id, book_id, rented_at, returned_at)
SELECT DISTINCT user_id, book_id, rental_date, return_date
FROM rentals
WHERE return_date IS NOT NULL
    ON CONFLICT DO NOTHING;

-- =====================================================
-- 8. ПРОВЕРКА ЦЕЛОСТНОСТИ ДАННЫХ
-- =====================================================
DO $$
DECLARE
orphan_books INTEGER;
    orphan_rentals INTEGER;
BEGIN
    -- Проверяем книги без авторов
SELECT COUNT(*) INTO orphan_books FROM books b
                                           LEFT JOIN authors a ON b.author_id = a.id
WHERE a.id IS NULL;

IF orphan_books > 0 THEN
        RAISE NOTICE 'ВНИМАНИЕ: Найдено % книг без авторов!', orphan_books;
ELSE
        RAISE NOTICE '✓ Книги: все имеют авторов';
END IF;

    -- Проверяем аренды без пользователей или книг
SELECT COUNT(*) INTO orphan_rentals FROM rentals r
                                             LEFT JOIN users u ON r.user_id = u.id
                                             LEFT JOIN books b ON r.book_id = b.id
WHERE u.id IS NULL OR b.id IS NULL;

IF orphan_rentals > 0 THEN
        RAISE NOTICE 'ВНИМАНИЕ: Найдено % аренд с битыми ссылками!', orphan_rentals;
ELSE
        RAISE NOTICE '✓ Аренды: все ссылки целы';
END IF;
END $$;

-- =====================================================
-- 9. СТАТИСТИКА
-- =====================================================
SELECT '=== СТАТИСТИКА БАЗЫ ДАННЫХ ===' as info;
SELECT 'Жанры: ' || COUNT(*) FROM genres;
SELECT 'Авторы: ' || COUNT(*) FROM authors;
SELECT 'Книги: ' || COUNT(*) FROM books;
SELECT 'Пользователи: ' || COUNT(*) FROM users;
SELECT 'Аренды всего: ' || COUNT(*) FROM rentals;
SELECT '  - Активные: ' || COUNT(*) FROM rentals WHERE status = 'active';
SELECT '  - Просроченные: ' || COUNT(*) FROM rentals WHERE status = 'overdue';
SELECT '  - Возвращенные: ' || COUNT(*) FROM rentals WHERE status = 'returned';
SELECT 'История аренд: ' || COUNT(*) FROM rental_history;

-- Топ популярных книг
SELECT
    b.title,
    g.title as genre,
    a.full_name as author,
    COUNT(r.id) as rental_count,
    b.total_copies,
    b.available_copies
FROM books b
         JOIN genres g ON b.genre_id = g.id
         JOIN authors a ON b.author_id = a.id
         LEFT JOIN rentals r ON b.id = r.book_id
GROUP BY b.id, g.title, a.full_name
ORDER BY rental_count DESC
    LIMIT 10;

-- Активные должники
SELECT
    u.name,
    u.email,
    COUNT(r.id) as overdue_books,
    SUM(CURRENT_DATE - r.due_date) as total_days_overdue
FROM users u
         JOIN rentals r ON u.id = r.user_id
WHERE r.status = 'overdue'
GROUP BY u.id
ORDER BY total_days_overdue DESC
    LIMIT 10;