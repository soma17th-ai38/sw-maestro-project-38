-- =====================================================================
-- 노트북 추천 챗봇 — 더미 데이터 10건 (테스트/개발용)
--
-- 사용법:
--   sqlite3 db/laptops.db < db/schema.sql
--   sqlite3 db/laptops.db < db/seed_dummy.sql
--
-- 정책:
--   - schema.sql 의 모든 NOT NULL / UNIQUE 제약 충족
--   - OS 값은 부록 A.1.2 의 canonical 키워드 기준 ("Windows", "macOS", "FreeDOS", "Linux")
--     ※ Node D 가 `os LIKE '%Windows%'` 식으로 매칭하므로 버전 표기는 자유
--   - 해상도는 부록 A.1.1 의 canonical "WxH" 문자열만 사용
--   - 가격대는 80만~330만원 범위로 분산 (Node E LIMIT 5 검증용)
--   - brightness_nits 중 1건은 NULL (OQ-7 의 NULL-허용 매칭 검증용)
--   - detail_url 은 모두 고유 (UPSERT 키)
--
-- 검증:
--   sqlite3 db/laptops.db "SELECT COUNT(*) FROM laptops;"   -- 10
--   sqlite3 db/laptops.db "SELECT COUNT(*) FROM laptops
--     WHERE price_krw IS NULL OR cpu IS NULL OR ram_gb IS NULL OR storage_gb IS NULL;"  -- 0 (SM-6)
-- =====================================================================

BEGIN TRANSACTION;

-- 멱등성: 재실행 시 dummy URL 행만 정리 후 재삽입 (운영 데이터에 영향 없음)
DELETE FROM laptops WHERE detail_url LIKE 'https://prod.danawa.com/info/?pcode=DUMMY-%';
DELETE FROM laptops WHERE detail_url LIKE 'https://prod.danawa.com/info/?pcode=DUMMY2-%';
DELETE FROM laptops WHERE detail_url LIKE 'https://prod.danawa.com/info/?pcode=DUMMY3-%';

INSERT INTO laptops
    (product_name, screen_inch, weight_kg, os, resolution, brightness_nits,
     cpu, ram_gb, storage_gb, price_krw, thumbnail_url, detail_url, crawled_at)
VALUES
    -- 1. 초경량 비즈니스 — LG gram
    ('LG gram 14Z90S-G.AA50K',
     14.0, 0.99, 'Windows 11', '1920x1200', 400,
     'Intel Core Ultra 5-125H', 16, 256, 1690000,
     'https://img.danawa.com/prod_img/500000/dummy01.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0001',
     '2026-05-07T10:00:00.000Z'),

    -- 2. 학생용 보급형 — 삼성 갤럭시북4
    ('삼성전자 갤럭시북4 NT750XGR-A51A',
     15.6, 1.55, 'Windows 11', '1920x1080', 250,
     'Intel Core i5-1335U', 16, 512, 1290000,
     'https://img.danawa.com/prod_img/500000/dummy02.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0002',
     '2026-05-07T10:00:00.000Z'),

    -- 3. 디자이너용 고휘도 — 애플 MacBook Air M3
    ('Apple 맥북에어 13 M3 8C-10C 16GB 512GB',
     13.6, 1.24, 'macOS', '2560x1664', 500,
     'Apple M3', 16, 512, 1990000,
     'https://img.danawa.com/prod_img/500000/dummy03.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0003',
     '2026-05-07T10:00:00.000Z'),

    -- 4. 개발자 워크스테이션 — MacBook Pro M3 Pro
    ('Apple 맥북프로 14 M3 Pro 11C-14C 18GB 1TB',
     14.2, 1.61, 'macOS', '3024x1964', 600,
     'Apple M3 Pro', 18, 1024, 3290000,
     'https://img.danawa.com/prod_img/500000/dummy04.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0004',
     '2026-05-07T10:00:00.000Z'),

    -- 5. 게이밍 16인치 — ASUS TUF
    ('ASUS TUF Gaming A16 FA607PI-N3023',
     16.0, 2.20, 'FreeDOS', '2560x1600', 300,
     'AMD Ryzen 9 7940HX', 16, 1024, 2150000,
     'https://img.danawa.com/prod_img/500000/dummy05.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0005',
     '2026-05-07T10:00:00.000Z'),

    -- 6. 가성비 보급형 — 레노버 IdeaPad
    ('레노버 아이디어패드 슬림3 15IRH8',
     15.6, 1.62, 'FreeDOS', '1920x1080', 250,
     'Intel Core i5-13420H', 8, 256, 850000,
     'https://img.danawa.com/prod_img/500000/dummy06.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0006',
     '2026-05-07T10:00:00.000Z'),

    -- 7. 시니어/사무용 — HP 파빌리온 (밝기 NULL — OQ-7 NULL 허용 검증용)
    ('HP 파빌리온 15-eg3088TU',
     15.6, 1.75, 'Windows 11', '1920x1080', NULL,
     'Intel Core i7-1355U', 16, 512, 1390000,
     'https://img.danawa.com/prod_img/500000/dummy07.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0007',
     '2026-05-07T10:00:00.000Z'),

    -- 8. 리눅스 개발자용 — Dell XPS
    ('DELL XPS 13 Plus 9340 DEVELOPER EDITION',
     13.4, 1.24, 'Linux', '2880x1800', 500,
     'Intel Core Ultra 7-155H', 32, 1024, 2890000,
     'https://img.danawa.com/prod_img/500000/dummy08.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0008',
     '2026-05-07T10:00:00.000Z'),

    -- 9. 휴대성 + QHD — ASUS ZenBook
    ('ASUS 젠북14 OLED UX3405MA-PP193',
     14.0, 1.20, 'Windows 11', '2880x1800', 400,
     'Intel Core Ultra 7-155H', 16, 512, 1750000,
     'https://img.danawa.com/prod_img/500000/dummy09.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0009',
     '2026-05-07T10:00:00.000Z'),

    -- 10. 라이젠 가성비 — Acer Swift Go
    ('Acer 스위프트Go SFG14-71-71M3',
     14.0, 1.32, 'Windows 11', '2240x1400', 300,
     'AMD Ryzen 7 7840U', 16, 512, 1190000,
     'https://img.danawa.com/prod_img/500000/dummy10.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY-0010',
     '2026-05-07T10:00:00.000Z');

COMMIT;

-- =====================================================================
-- 추가 더미 데이터 10건 (2차)
-- =====================================================================

BEGIN TRANSACTION;

INSERT INTO laptops
    (product_name, screen_inch, weight_kg, os, resolution, brightness_nits,
     cpu, ram_gb, storage_gb, price_krw, thumbnail_url, detail_url, crawled_at)
VALUES
    -- 11. 최신 애플 — MacBook Air M4
    ('Apple 맥북에어 15 M4 10C-10C 16GB 512GB',
     15.3, 1.51, 'macOS', '2880x1864', 500,
     'Apple M4', 16, 512, 2190000,
     'https://img.danawa.com/prod_img/500000/dummy11.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0001',
     '2026-05-12T10:00:00.000Z'),

    -- 12. 대화면 비즈니스 — LG gram 17
    ('LG gram 17Z90S-G.AA5CK',
     17.0, 1.35, 'Windows 11', '2560x1600', 350,
     'Intel Core Ultra 7-155H', 16, 512, 2090000,
     'https://img.danawa.com/prod_img/500000/dummy12.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0002',
     '2026-05-12T10:00:00.000Z'),

    -- 13. 프리미엄 비즈니스 — ThinkPad X1 Carbon
    ('레노버 씽크패드 X1 Carbon Gen12 21KC0037KR',
     14.0, 1.12, 'Windows 11', '1920x1200', 400,
     'Intel Core Ultra 7-164U', 32, 1024, 3190000,
     'https://img.danawa.com/prod_img/500000/dummy13.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0003',
     '2026-05-12T10:00:00.000Z'),

    -- 14. 고성능 게이밍 — MSI Titan GT77
    ('MSI Titan GT77 HX 13VI-065KR',
     17.3, 3.10, 'Windows 11', '3840x2160', 400,
     'Intel Core i9-13980HX', 64, 2048, 5990000,
     'https://img.danawa.com/prod_img/500000/dummy14.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0004',
     '2026-05-12T10:00:00.000Z'),

    -- 15. 게이밍 OLED — ASUS ROG Zephyrus G16
    ('ASUS ROG 제피러스 G16 GU605MZ-QP047',
     16.0, 1.85, 'Windows 11', '2560x1600', 500,
     'Intel Core Ultra 9-185H', 32, 1024, 3790000,
     'https://img.danawa.com/prod_img/500000/dummy15.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0005',
     '2026-05-12T10:00:00.000Z'),

    -- 16. 프리미엄 삼성 — 갤럭시북4 Pro 360
    ('삼성전자 갤럭시북4 프로 360 NT960QGK-KG72G',
     16.0, 1.66, 'Windows 11', '2880x1800', 500,
     'Intel Core Ultra 7-155H', 32, 1024, 2990000,
     'https://img.danawa.com/prod_img/500000/dummy16.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0006',
     '2026-05-12T10:00:00.000Z'),

    -- 17. 게이밍 보급형 — HP OMEN 16
    ('HP OMEN 16-xf0161AX',
     16.1, 2.29, 'FreeDOS', '1920x1080', 300,
     'AMD Ryzen 7 7745HX', 16, 512, 1690000,
     'https://img.danawa.com/prod_img/500000/dummy17.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0007',
     '2026-05-12T10:00:00.000Z'),

    -- 18. 가성비 AMD — 레노버 IdeaPad 5 Pro
    ('레노버 아이디어패드 5 Pro 16ARP8',
     16.0, 1.99, 'Windows 11', '2560x1600', NULL,
     'AMD Ryzen 5 7535HS', 16, 512, 1090000,
     'https://img.danawa.com/prod_img/500000/dummy18.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0008',
     '2026-05-12T10:00:00.000Z'),

    -- 19. 학생용 초저가 — Dell Inspiron 15
    ('DELL 인스피론 15 3520 D563014KR',
     15.6, 1.81, 'Windows 11', '1920x1080', 220,
     'Intel Core i3-1215U', 8, 256, 750000,
     'https://img.danawa.com/prod_img/500000/dummy19.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0009',
     '2026-05-12T10:00:00.000Z'),

    -- 20. MacBook Pro M4 Pro — 전문가용
    ('Apple 맥북프로 16 M4 Pro 14C-20C 24GB 512GB',
     16.2, 2.14, 'macOS', '3456x2234', 1000,
     'Apple M4 Pro', 24, 512, 3990000,
     'https://img.danawa.com/prod_img/500000/dummy20.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY2-0010',
     '2026-05-12T10:00:00.000Z');

COMMIT;

-- =====================================================================
-- 추가 더미 데이터 30건 (3차)
-- =====================================================================

BEGIN TRANSACTION;

INSERT INTO laptops
    (product_name, screen_inch, weight_kg, os, resolution, brightness_nits,
     cpu, ram_gb, storage_gb, price_krw, thumbnail_url, detail_url, crawled_at)
VALUES
    -- 21. 초저가 — 레노버 IdeaPad 1
    ('레노버 아이디어패드 1 15ALC7 82R400GAKR',
     15.6, 1.65, 'FreeDOS', '1920x1080', 250,
     'AMD Ryzen 3 5300U', 8, 256, 650000,
     'https://img.danawa.com/prod_img/500000/dummy21.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0001',
     '2026-05-12T10:00:00.000Z'),

    -- 22. 초저가 — ASUS VivoBook Go 14
    ('ASUS 비보북 Go 14 E410KA-BV127',
     14.0, 1.46, 'FreeDOS', '1920x1080', 220,
     'Intel Celeron N4500', 4, 128, 490000,
     'https://img.danawa.com/prod_img/500000/dummy22.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0002',
     '2026-05-12T10:00:00.000Z'),

    -- 23. 초저가 — HP 15s
    ('HP 15s-fq5095TU',
     15.6, 1.69, 'FreeDOS', '1920x1080', 250,
     'Intel Core i3-1215U', 8, 256, 620000,
     'https://img.danawa.com/prod_img/500000/dummy23.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0003',
     '2026-05-12T10:00:00.000Z'),

    -- 24. 보급형 — Acer Aspire 5
    ('Acer 아스파이어 5 A515-58M-599N',
     15.6, 1.77, 'FreeDOS', '1920x1080', 300,
     'Intel Core i5-13420H', 8, 512, 890000,
     'https://img.danawa.com/prod_img/500000/dummy24.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0004',
     '2026-05-12T10:00:00.000Z'),

    -- 25. 보급형 — MSI Modern 15
    ('MSI 모던15 B13M-297KR',
     15.6, 1.60, 'FreeDOS', '1920x1080', 250,
     'Intel Core i5-13420H', 16, 512, 990000,
     'https://img.danawa.com/prod_img/500000/dummy25.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0005',
     '2026-05-12T10:00:00.000Z'),

    -- 26. 보급형 AMD — Dell Inspiron 15 5535
    ('DELL 인스피론 15 5535 D563058KR',
     15.6, 1.74, 'Windows 11', '1920x1080', 250,
     'AMD Ryzen 5 7530U', 16, 512, 1050000,
     'https://img.danawa.com/prod_img/500000/dummy26.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0006',
     '2026-05-12T10:00:00.000Z'),

    -- 27. 보급형 AMD — ASUS VivoBook 16X
    ('ASUS 비보북 16X M1603QA-MB514',
     16.0, 1.88, 'FreeDOS', '1920x1080', 300,
     'AMD Ryzen 5 5600H', 16, 512, 950000,
     'https://img.danawa.com/prod_img/500000/dummy27.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0007',
     '2026-05-12T10:00:00.000Z'),

    -- 28. 보급형 — 레노버 IdeaPad 5
    ('레노버 아이디어패드 5 15ABA7 82SG006KKR',
     15.6, 1.66, 'Windows 11', '1920x1080', 300,
     'AMD Ryzen 5 5625U', 16, 512, 890000,
     'https://img.danawa.com/prod_img/500000/dummy28.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0008',
     '2026-05-12T10:00:00.000Z'),

    -- 29. 중급 — LG gram 16
    ('LG gram 16 16Z90S-G.AA5CK',
     16.0, 1.19, 'Windows 11', '2560x1600', 350,
     'Intel Core Ultra 5-125H', 16, 512, 1790000,
     'https://img.danawa.com/prod_img/500000/dummy29.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0009',
     '2026-05-12T10:00:00.000Z'),

    -- 30. 중급 2-in-1 — 레노버 Yoga 7i Gen 9
    ('레노버 요가 7i Gen9 83DJCTO1WWKR',
     14.0, 1.39, 'Windows 11', '1920x1200', 400,
     'Intel Core Ultra 5-125U', 16, 512, 1390000,
     'https://img.danawa.com/prod_img/500000/dummy30.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0010',
     '2026-05-12T10:00:00.000Z'),

    -- 31. 중급 2-in-1 — HP Envy x360 14
    ('HP 엔비 x360 14-fc0061TU',
     14.0, 1.38, 'Windows 11', '2560x1600', 400,
     'Intel Core Ultra 5-125U', 16, 512, 1490000,
     'https://img.danawa.com/prod_img/500000/dummy31.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0011',
     '2026-05-12T10:00:00.000Z'),

    -- 32. 중급 — Dell Inspiron 16 Plus
    ('DELL 인스피론 16 Plus 7630 D563059KR',
     16.0, 1.86, 'Windows 11', '1920x1200', 300,
     'Intel Core i5-13500H', 16, 512, 1190000,
     'https://img.danawa.com/prod_img/500000/dummy32.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0012',
     '2026-05-12T10:00:00.000Z'),

    -- 33. 중급 크리에이터 — ASUS VivoBook Pro 16
    ('ASUS 비보북 프로16 K6602VU-N1020',
     16.0, 1.88, 'FreeDOS', '1920x1080', 300,
     'Intel Core i9-13900H', 16, 512, 1590000,
     'https://img.danawa.com/prod_img/500000/dummy33.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0013',
     '2026-05-12T10:00:00.000Z'),

    -- 34. 중급 — Acer Swift X 14
    ('Acer 스위프트 X SFX14-72G-7480',
     14.5, 1.64, 'Windows 11', '2560x1440', 400,
     'Intel Core Ultra 5-125H', 16, 512, 1490000,
     'https://img.danawa.com/prod_img/500000/dummy34.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0014',
     '2026-05-12T10:00:00.000Z'),

    -- 35. 중급 — Microsoft Surface Laptop 6
    ('Microsoft 서피스 랩탑6 ZJQ-00043',
     13.5, 1.34, 'Windows 11', '2256x1504', 400,
     'Intel Core Ultra 5-134H', 16, 256, 1990000,
     'https://img.danawa.com/prod_img/500000/dummy35.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0015',
     '2026-05-12T10:00:00.000Z'),

    -- 36. 중급 ARM — 삼성 Galaxy Book4 Edge
    ('삼성전자 갤럭시북4 Edge NT940XMA-KB2',
     14.0, 1.17, 'Windows 11', '2880x1800', 350,
     'Snapdragon X Elite X1E-80-100', 16, 512, 1790000,
     'https://img.danawa.com/prod_img/500000/dummy36.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0016',
     '2026-05-12T10:00:00.000Z'),

    -- 37. 고급 — Apple MacBook Pro 14 M4
    ('Apple 맥북프로 14 M4 10C-10C 16GB 512GB',
     14.2, 1.55, 'macOS', '3024x1964', 1000,
     'Apple M4', 16, 512, 2490000,
     'https://img.danawa.com/prod_img/500000/dummy37.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0017',
     '2026-05-12T10:00:00.000Z'),

    -- 38. 고급 — LG gram Pro 16
    ('LG gram Pro 16 16Z90SP-K.AA79U1',
     16.0, 1.24, 'Windows 11', '2560x1600', 350,
     'Intel Core Ultra 7-258V', 32, 1024, 2690000,
     'https://img.danawa.com/prod_img/500000/dummy38.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0018',
     '2026-05-12T10:00:00.000Z'),

    -- 39. 고급 2-in-1 — HP Spectre x360 14
    ('HP 스펙터 x360 14-ef2023TU',
     13.5, 1.34, 'Windows 11', '1920x1280', 400,
     'Intel Core Ultra 7-155U', 16, 512, 2390000,
     'https://img.danawa.com/prod_img/500000/dummy39.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0019',
     '2026-05-12T10:00:00.000Z'),

    -- 40. 고급 OLED — ASUS ZenBook Pro 14 OLED
    ('ASUS 젠북프로14 OLED UX6404VI-P1069',
     14.5, 1.55, 'Windows 11', '2880x1800', 550,
     'Intel Core i9-13900H', 32, 1024, 2890000,
     'https://img.danawa.com/prod_img/500000/dummy40.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0020',
     '2026-05-12T10:00:00.000Z'),

    -- 41. 고급 4K — Dell XPS 15 9530
    ('DELL XPS 15 9530 D563060KR',
     15.6, 1.86, 'Windows 11', '3456x2160', 500,
     'Intel Core i7-13700H', 32, 1024, 3290000,
     'https://img.danawa.com/prod_img/500000/dummy41.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0021',
     '2026-05-12T10:00:00.000Z'),

    -- 42. 고급 — 삼성 Galaxy Book4 Ultra
    ('삼성전자 갤럭시북4 울트라 NT960XGL-KG5',
     16.0, 1.86, 'Windows 11', '2880x1800', 500,
     'Intel Core Ultra 9-185H', 32, 1024, 3490000,
     'https://img.danawa.com/prod_img/500000/dummy42.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0022',
     '2026-05-12T10:00:00.000Z'),

    -- 43. 고급 비즈니스 — ThinkPad X1 Extreme Gen 5
    ('레노버 씽크패드 X1 Extreme Gen5 21DE000NKR',
     16.0, 1.86, 'Windows 11', '2560x1600', 400,
     'Intel Core i7-12800H', 32, 1024, 3190000,
     'https://img.danawa.com/prod_img/500000/dummy43.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0023',
     '2026-05-12T10:00:00.000Z'),

    -- 44. 게이밍 중급 — Lenovo Legion 5 Pro
    ('레노버 리전5 Pro 16ARX8 82WM0094KR',
     16.0, 2.49, 'Windows 11', '2560x1600', 300,
     'AMD Ryzen 7 7745HX', 16, 512, 1690000,
     'https://img.danawa.com/prod_img/500000/dummy44.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0024',
     '2026-05-12T10:00:00.000Z'),

    -- 45. 게이밍 보급 — ASUS TUF Gaming A15
    ('ASUS TUF Gaming A15 FA507NV-N1023',
     15.6, 2.30, 'FreeDOS', '1920x1080', 300,
     'AMD Ryzen 7 7745HX', 16, 512, 1390000,
     'https://img.danawa.com/prod_img/500000/dummy45.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0025',
     '2026-05-12T10:00:00.000Z'),

    -- 46. 게이밍 인텔 — MSI Katana 15
    ('MSI 카타나 15 B13VGK-1025KR',
     15.6, 2.20, 'FreeDOS', '1920x1080', 250,
     'Intel Core i7-13620H', 16, 512, 1790000,
     'https://img.danawa.com/prod_img/500000/dummy46.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0026',
     '2026-05-12T10:00:00.000Z'),

    -- 47. 게이밍 AMD 16인치 — Acer Nitro 16
    ('Acer 니트로16 AN16-41-R0T1',
     16.0, 2.50, 'FreeDOS', '2560x1600', 300,
     'AMD Ryzen 7 7745HX', 16, 512, 1590000,
     'https://img.danawa.com/prod_img/500000/dummy47.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0027',
     '2026-05-12T10:00:00.000Z'),

    -- 48. 게이밍 하이엔드 — ASUS ROG Strix G16
    ('ASUS ROG 스트릭스 G16 G614JZR-N4055',
     16.0, 2.50, 'Windows 11', '2560x1600', 300,
     'Intel Core i9-14900HX', 32, 1024, 4190000,
     'https://img.danawa.com/prod_img/500000/dummy48.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0028',
     '2026-05-12T10:00:00.000Z'),

    -- 49. 게이밍 최고사양 — Dell Alienware m18
    ('DELL 에일리언웨어 m18 R1 AWm18R1-7950',
     18.0, 4.20, 'Windows 11', '1920x1080', 480,
     'Intel Core i9-13980HX', 32, 2048, 5490000,
     'https://img.danawa.com/prod_img/500000/dummy49.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0029',
     '2026-05-12T10:00:00.000Z'),

    -- 50. 게이밍 AMD 하이엔드 — Lenovo Legion Pro 7i
    ('레노버 리전 Pro 7i 16IRX8 82WK007YKR',
     16.0, 2.80, 'Windows 11', '2560x1600', 300,
     'Intel Core i9-13900HX', 32, 1024, 3690000,
     'https://img.danawa.com/prod_img/500000/dummy50.jpg',
     'https://prod.danawa.com/info/?pcode=DUMMY3-0030',
     '2026-05-12T10:00:00.000Z');

COMMIT;

-- =====================================================================
-- 빠른 검증 쿼리 (참고)
-- =====================================================================
-- SELECT COUNT(*) AS total FROM laptops;
-- SELECT os, COUNT(*) FROM laptops GROUP BY os;
-- SELECT product_name, price_krw FROM laptops ORDER BY price_krw ASC LIMIT 5;
-- SELECT product_name FROM laptops WHERE brightness_nits IS NULL OR brightness_nits >= 300;
