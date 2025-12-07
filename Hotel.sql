-- ------------------------------------------------
-- LabWork 2
-- ------------------------------------------------

CREATE TABLE
	Discount (
		DiscountID SERIAL PRIMARY KEY,
		DscPercent NUMERIC(5, 2) NOT NULL CHECK (
			DscPercent >= 0
			AND DscPercent <= 100
		),
		DscCondition TEXT NOT NULL CHECK (
			DscCondition IN (
				'Soldier', 
				'Promocode', 
				'Student', 
				'Birthday', 
				'Regular'
			)
		),
		Amount NUMERIC(10, 2) CHECK (Amount >= 0)
	);

CREATE TABLE
	AdditionalService (
		ServiceID SERIAL PRIMARY KEY,
		ServiceName TEXT UNIQUE NOT NULL CHECK (
			ServiceName IN (
				'Transfer',
				'Breakfast',
				'SPA',
				'Excursion',
				'Gym',
				'Parking',
				'Security',
				'Airport Shuttle',
				'WiFi',
				'Room Service'
			)
		)
	);

CREATE TABLE
	Administrator (
		AdminID SERIAL PRIMARY KEY,
		FirstName TEXT NOT NULL,
		Surname TEXT NOT NULL,
		Patronymic TEXT,
		Login TEXT NOT NULL UNIQUE,
		Passwrd TEXT NOT NULL
	);

CREATE TABLE
	Manager (
		ManagerID SERIAL PRIMARY KEY,
		AdminID INT NOT NULL REFERENCES Administrator (AdminID),
		FirstName TEXT NOT NULL,
		Surname TEXT NOT NULL,
		Patronymic TEXT,
		Login TEXT NOT NULL UNIQUE,
		Passwrd TEXT NOT NULL
	);

CREATE TABLE
	Guest (
		GuestID SERIAL PRIMARY KEY,
		FirstName TEXT NOT NULL,
		Surname TEXT NOT NULL,
		Patronymic TEXT,
		PhoneNumber TEXT NOT NULL UNIQUE,
		Email TEXT NOT NULL UNIQUE,
		Passport CHAR(9) NOT NULL UNIQUE,
		BirthDate DATE NOT NULL
	);

CREATE TABLE
	Hotel (
		HotelID SERIAL PRIMARY KEY,
		AdminID INT NOT NULL REFERENCES Administrator (AdminID),
		Title TEXT NOT NULL,
		NumberOfStars INT NOT NULL CHECK (NumberOfStars BETWEEN 1 AND 5),
		Address TEXT NOT NULL,
		PhoneNumber TEXT NOT NULL UNIQUE,
		Email TEXT NOT NULL UNIQUE
	);

CREATE TABLE
	Room (
		RoomID SERIAL PRIMARY KEY,
		HotelID INT NOT NULL REFERENCES Hotel (HotelID),
		RoomType TEXT NOT NULL CHECK (
			RoomType IN ('Standard', 'Junior Suite', 'Suite', 'Deluxe')
		),
		BedSpace INT NOT NULL CHECK (BedSpace > 0),
		PricePerNight NUMERIC(10, 2) NOT NULL CHECK (PricePerNight >= 0),
		Status TEXT NOT NULL CHECK (Status IN ('Available', 'Booked', 'Maintenance'))
	);

CREATE TABLE
	HotelService (
		HotelServiceID SERIAL PRIMARY KEY,
		HotelID INT NOT NULL REFERENCES Hotel (HotelID),
		ServiceID INT NOT NULL REFERENCES AdditionalService (ServiceID),
		Price NUMERIC(10, 2) NOT NULL CHECK (Price >= 0),
		UNIQUE (HotelID, ServiceID)
	);

CREATE TABLE
	Booking (
		BookingID SERIAL PRIMARY KEY,
		GuestID INT NOT NULL REFERENCES Guest (GuestID),
		ManagerID INT NOT NULL REFERENCES Manager (ManagerID),
		RoomID INT NOT NULL REFERENCES Room (RoomID),
		DiscountID INT REFERENCES Discount (DiscountID),
		DateCheckIn DATE NOT NULL,
		DateCheckOut DATE NOT NULL,
		NumberOfNights INT GENERATED ALWAYS AS ((DateCheckOut - DateCheckIn)) STORED,
		Status TEXT NOT NULL CHECK (
			Status IN (
				'Pending',
				'Confirmed',
				'CheckedIn',
				'CheckedOut',
				'Cancelled'
			)
		),
		Promocode TEXT,
		Amount NUMERIC(10, 2) CHECK (Amount >= 0),
		CHECK (DateCheckOut > DateCheckIn)
	);

CREATE TABLE
	BookingService (
		BookingID INT NOT NULL REFERENCES Booking (BookingID),
		HotelServiceID INT NOT NULL REFERENCES HotelService (HotelServiceID),
		PRIMARY KEY (BookingID, HotelServiceID)
	);

CREATE TABLE
	Payment (
		PaymentID SERIAL PRIMARY KEY,
		BookingID INT NOT NULL UNIQUE REFERENCES Booking (BookingID),
		PaymentMethod TEXT NOT NULL CHECK (PaymentMethod IN ('Cash', 'Card', 'Crypto')),
		Amount NUMERIC(10, 2) NOT NULL CHECK (Amount >= 0),
		Currency TEXT NOT NULL CHECK (Currency IN ('UAH', 'EUR', 'USD', 'BTC', 'USDT')),
		Status TEXT NOT NULL CHECK (Status IN ('Applied', 'Declined', 'Pending')),
		PaymentTime TIMESTAMP NOT NULL
	);

REASSIGN OWNED BY administrator TO postgres;
DROP OWNED BY administrator;
DROP ROLE administrator;

REASSIGN OWNED BY manager TO postgres;
DROP OWNED BY manager;
DROP ROLE manager;

REASSIGN OWNED BY guest TO postgres;
DROP OWNED BY guest;
DROP ROLE guest;

REASSIGN OWNED BY user_admin TO postgres;
DROP OWNED BY user_admin;
DROP ROLE user_admin;

REASSIGN OWNED BY user_manager TO postgres;
DROP OWNED BY user_manager;
DROP ROLE user_manager;

REASSIGN OWNED BY user_guest TO postgres;
DROP OWNED BY user_guest;
DROP ROLE user_guest;

CREATE ROLE administrator LOGIN PASSWORD 'administrator';
GRANT ALL PRIVILEGES ON DATABASE "Hotel" TO administrator;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO administrator;

CREATE ROLE manager LOGIN PASSWORD 'manager';
GRANT CONNECT ON DATABASE "Hotel" TO manager;
GRANT USAGE ON SCHEMA public TO manager;
GRANT SELECT, UPDATE (Status) ON Booking TO manager;
GRANT SELECT, UPDATE (Status) ON Room TO manager;
GRANT SELECT ON Guest TO manager;
GRANT SELECT ON Hotel TO manager;
GRANT SELECT ON Payment TO manager;

CREATE ROLE guest LOGIN PASSWORD 'guest';
GRANT CONNECT ON DATABASE "Hotel" TO guest;
GRANT USAGE ON SCHEMA public TO guest;
GRANT INSERT ON Booking TO guest;
GRANT INSERT ON BookingService TO guest;
GRANT SELECT ON Discount TO guest;
GRANT SELECT ON AdditionalService TO guest;
GRANT SELECT ON HotelService TO guest;
GRANT SELECT ON Booking TO guest;
GRANT SELECT ON Room TO guest;
GRANT SELECT ON Hotel TO guest;
GRANT SELECT ON Payment TO guest;

CREATE ROLE user_admin LOGIN PASSWORD 'administrator1';
CREATE ROLE user_manager LOGIN PASSWORD 'manager1';
CREATE ROLE user_guest LOGIN PASSWORD 'guest1';

GRANT administrator TO user_admin;
GRANT manager TO user_manager;
GRANT guest TO user_guest;

ALTER TABLE Guest
    ADD CONSTRAINT chk_birthdate CHECK (BirthDate <= CURRENT_DATE - INTERVAL '18 years');

ALTER TABLE Payment
    ALTER COLUMN Currency SET DEFAULT 'UAH';

ALTER TABLE Booking
    ALTER COLUMN Status SET DEFAULT 'Pending';

ALTER TABLE Guest
	DROP CONSTRAINT guest_phonenumber_key;

ALTER TABLE Hotel
	DROP CONSTRAINT hotel_phonenumber_key;

-- ------------------------------------------------
-- LabWork 3
-- ------------------------------------------------

-- Вивести всі бронювання з сумою платежу більше або рівною 2500
SELECT payment.bookingid, payment.Amount 
FROM Payment
WHERE payment.amount >= 2500;

-- Вивести імена та прізвища гостей, чиї імена починаються на 'A' або 'E',але не народжені в період з 1990 по 1995 р
SELECT guest.firstname, guest.Surname
FROM Guest
WHERE (firstname LIKE 'A%' OR firstname LIKE 'E%')
  AND NOT (BirthDate BETWEEN '1990-01-01' AND '1995-12-31');

-- Вивести кількість ночей , статус та суму платежу бронювань ,
-- де кількість ночей більше 3, статус 'Confirmed' або 'CheckedIn', та присутній промокод
SELECT booking.numberofnights, booking.status,booking.amount
FROM Booking
WHERE booking.numberofnights > 3 
	AND (booking.status = 'Confirmed' OR booking.status = 'CheckedIn')
	AND NOT (booking.promocode IS NULL);

-- Вивести імена, прізвища, дату народження та вік гостей , які старші за 30 років
SELECT guest.firstname, guest.surname, guest.birthdate, AGE(CURRENT_DATE, guest.birthdate) AS age
FROM Guest
WHERE EXTRACT(YEAR FROM AGE(CURRENT_DATE, guest.birthdate)) >= 30;

-- Вивести імена , прізвища, дату народження та вік гостей , вік яких є кратним 5
SELECT guest.firstname, guest.surname, guest.birthdate, 
	   EXTRACT(YEAR FROM AGE(CURRENT_DATE, guest.birthdate)) AS age
FROM Guest
WHERE MOD(EXTRACT(YEAR FROM AGE(CURRENT_DATE, guest.birthdate)), 5) = 0;

-- Вивести ідентифікатори бронювань , дати заїзду , статус  та суму платежу 
-- для бронювань , де дата заїзду припадає на літні місяці
SELECT booking.bookingid, booking.datecheckin, booking.status, booking.amount
FROM Booking
WHERE EXTRACT(MONTH FROM booking.datecheckin) IN (6, 7, 8);

-- Вивести ідентифікатори номерів , типи номерів  та ціну за ніч 
-- для номерів , де ціна за ніч знаходиться в діапазоні від 100 до 250 та статус 'Available'
SELECT room.roomid, room.roomtype, room.PricePerNight
FROM Room
WHERE room.PricePerNight BETWEEN 100 AND 250
  AND room.Status = 'Available';

-- Вивести назви готелів , кількість зірок та номери телефонів для готелів, номери телефонів які починаються з 5
SELECT hotel.title, hotel.numberofstars, hotel.phonenumber
FROM Hotel
WHERE hotel.phonenumber ILIKE '%3805%';

-- Вивести імена , прізвища адміністраторів та назви готелів,якими вони керують
SELECT adm.firstname, adm.surname, hotel.title
FROM (
	SELECT * 
	FROM Administrator)  AS adm
JOIN Hotel ON adm.adminid = hotel.adminid;

-- Вивести ідентифікатори номерів, типи номерів, статус та назви готелів, яким вони належать
SELECT room.roomid, room.roomtype, room.status,
(SELECT h.title 
FROM HOTEL h
WHERE h.hotelid = room.hotelid)
FROM Room;

-- Вивести імена  та прізвища гостей, які мають бронювання в номерах зі статусом 'Booked'
SELECT g.firstname, g.surname
FROM Guest g
WHERE g.guestid IN (
    SELECT b.guestid
    FROM Booking b
    WHERE b.roomid IN (
        SELECT roomid
        FROM Room
        WHERE status = 'Booked'
    )
);

-- Вивести імена  та прізвища гостей , які мають принаймні один відхилений платіж
SELECT g.firstname, g.surname
FROM Guest g
WHERE EXISTS (
	SELECT *
	FROM Payment p
	WHERE p.bookingid IN (
		SELECT b.bookingid
		FROM Booking b
		WHERE b.guestid = g.guestid
	) AND p.status = 'Declined'
);

-- Вивести всі можливі комбінації гостей та номерів, незалежно від наявності бронювань.
SELECT g.firstname, g.surname
FROM Guest g
CROSS JOIN Room r;

-- Вивести назви готелів, кількість зірок, адреси та імена з прізвищами гостей, які мають бронювання в готелі у Києві.
SELECT  h.title, h.numberofstars, h.address, g.firstname, g.surname
FROM Hotel h
JOIN Room r ON r.hotelid = h.hotelid
JOIN Booking b ON b.roomid = r.roomid
JOIN Guest g ON g.guestid = b.guestid
WHERE h.address ILIKE '%Kyiv%';

-- Вивести імена , прізвища менеджерів та ідентифікатори бронювань, якими вони керують, відсортовані за іменами менеджерів
SELECT m.firstname, m.surname, b.bookingid, b.status
FROM Manager m
JOIN Booking b ON m.managerid = b.managerid
ORDER BY m.firstname;

-- Вивести імена , прізвища гостей та ідентифікатори бронювань для гостей, які не мають жодного бронювання
SELECT g.firstname, g.surname, b.bookingid
FROM Guest g
LEFT JOIN Booking b ON g.guestid = b.guestid
WHERE b.bookingid IS NULL;

-- Вивести ідентифікатори номерів, типи номерів та ідентифікатори бронювань для всіх номерів, навіть якщо вони не заброньовані
SELECT r.roomid, r.roomtype, b.bookingid
FROM Room r
RIGHT JOIN Booking b ON r.roomid = b.roomid
WHERE r.status = 'Available';

-- Вивести імена , прізвища та ролі всіх адміністраторів і менеджерів
SELECT a.adminid, a.firstname, a.surname, 'Administrator' AS role
FROM Administrator a
UNION
SELECT m.managerid, m.firstname, m.surname, 'Manager' AS role
FROM Manager m;

-- Вивести назви готелів , кількість зірок та адреси для готелів, які знаходяться в Києві або Одесі та мають 5 зірок
SELECT h.title, h.numberofstars, h.address
FROM Hotel h
WHERE h.address ILIKE '%Kyiv%' OR h.address ILIKE '%Odesa%'
INTERSECT
SELECT h.title, h.numberofstars, h.address
FROM Hotel h
WHERE h.numberofstars = 5;

-- За певний період вивести перелік вільних номерів, з вказанням місткості, комфортності та ціни за добу перебування.
SELECT r.roomid, r.roomtype, r.bedspace, r.PricePerNight
FROM Room r
WHERE r.status = 'Available'
AND NOT EXISTS(SELECT *
FROM Booking b
WHERE b.roomid = r.roomid
AND b.DateCheckIn <= '2025-07-31'
AND b.DateCheckOut >= '2025-07-01');

-- За вказаний користувачем період вивести ПІБ клієнтів, котрі бронювали номер, однак не заїхали в нього.
SELECT g.firstname, g.surname, g.patronymic
FROM Guest g
JOIN Booking b ON g.guestid = b.guestid
WHERE b.datecheckin >= '2025-01-01' AND b.datecheckin <= '2025-12-31'
AND b.status IN ('Pending', 'Confirmed', 'Cancelled');

-- ------------------------------------------------
-- LabWork 4
-- ------------------------------------------------

-- Визначте загальну кількість бронювань та загальний дохід готелю за листопад 2025 року.
SELECT 
	COUNT(*) AS total_bookings,
	SUM(b.Amount) AS total_revenue
FROM Booking b
WHERE DateCheckIn >= '2025-11-01' AND DateCheckOut <= '2025-11-30';

-- Визначте загальний дохід кожного готелю за літньо-осінній період 2025 року, згрупувавши результати за назвою готелю та статусом бронювання.
SELECT h.title, b.status, SUM(b.amount) AS total_revenue
FROM Booking b
JOIN Room r ON b.roomid = r.roomid
JOIN Hotel h ON r.hotelid = h.hotelid
WHERE b.status = 'Confirmed' 
AND b.DateCheckIn >= '2025-06-01' 
AND b.DateCheckOut <= '2025-11-30'
GROUP BY h.title, b.status;

-- Вивести імена , прізвища та кількість бронювань для гостей, які мають більше одного бронювання
SELECT g.firstname, g.surname, COUNT(b.bookingid) AS total_bookings
FROM Guest g
JOIN Booking b ON g.guestid = b.guestid
GROUP BY g.guestid
HAVING COUNT(b.bookingid) > 1

-- Визначте середню суму бронювання для бронювань, зроблених у літній період 2025 року, якщо ця сума перевищує 500.
SELECT AVG(b.amount) AS average_booking_amount
FROM Booking b
WHERE b.DateCheckIn >= '2025-06-01' AND b.DateCheckOut <= '2025-08-31'
HAVING AVG(b.amount) > 500;

-- Виведіть усі бронювання та пронумерйте їх у порядку зростання дати заїзду та дати виїзду.
SELECT b.bookingid, b.datecheckin, b.datecheckout, b.amount,
ROW_NUMBER() OVER (ORDER BY b.datecheckin, b.datecheckout) AS row_num
FROM Booking b;

-- Виведіть назви готелів та перелік типів номерів, які вони пропонують
SELECT h.title, STRING_AGG(DISTINCT r.roomtype, ', ') AS room_types
FROM Hotel h
JOIN Room r ON h.hotelid = r.hotelid
GROUP BY h.title;

-- Виведіть назви готелів, типи номерів, статус бронювання та суми платежів, відсортовані за назвою готелю за зростанням та сумою платежу за спаданням.
SELECT h.title, r.roomtype, b.status, b.amount
FROM Booking b
JOIN Room r ON b.roomid = r.roomid
JOIN Hotel h ON r.hotelid = h.hotelid
ORDER BY h.title ASC, b.amount DESC;

-- За певний, вказаний користувачем період, вивести найбільш популярний номер (тобто номер, котрий бронювали найбільшу кількість разів).
SELECT h.title AS hotel_title, r.roomid, r.roomtype, 
COUNT(b.roomid) AS total_bookings
FROM Booking b
JOIN Room r ON b.roomid = r.roomid
JOIN Hotel h ON r.hotelid = h.hotelid
WHERE b.DateCheckIn >= '2025-01-01' AND b.DateCheckOut <= '2025-12-31'
GROUP BY h.title, r.roomid, r.roomtype
ORDER BY total_bookings DESC
LIMIT 1;

-- За минулий рік вивести ПІБ клієнтів, котрі зупинялись в готелі більш ніж 3 рази та мали знижку постійного клієнта.
SELECT h.title AS hotel_title, g.firstname, g.surname, g.patronymic, d.dsccondition
FROM Booking b
JOIN Room r ON b.roomid = r.roomid
JOIN Hotel h ON r.hotelid = h.hotelid
JOIN Guest g ON b.guestid = g.guestid
JOIN Discount d ON b.discountid = d.discountid
WHERE d.dsccondition = 'Regular' 
AND b.DateCheckIn >= '2025-01-01' 
AND b.DateCheckOut <= '2025-12-31'
GROUP BY h.title,g.firstname, g.surname, g.patronymic, d.dsccondition
HAVING COUNT(b.bookingid) > 3;

-- Створити представлення для відображення інформації про бронювання
CREATE OR REPLACE VIEW BookingInfo AS
SELECT 
    h.title       AS hotel_title,
    g.firstname   AS guest_firstname,
    g.surname     AS guest_surname,
    g.patronymic  AS guest_patronymic,
    r.roomtype    AS room_type,
    b.amount      AS booking_amount
FROM Booking b
JOIN Room r   ON b.roomid   = r.roomid
JOIN Hotel h  ON r.hotelid  = h.hotelid
JOIN Guest g  ON b.guestid  = g.guestid;

SELECT * FROM BookingInfo;

-- Створити представлення для відображення історії бронювань клієнтів
CREATE OR REPLACE VIEW ClientBookingHistory AS
SELECT
    b.hotel_title,
    b.guest_firstname,
    b.guest_surname,
    b.guest_patronymic,
    bk.datecheckin  AS checkin_date,
    bk.datecheckout AS checkout_date,
    bk.status       AS booking_status,
    b.booking_amount
FROM BookingInfo b
JOIN Booking bk ON b.booking_amount = bk.amount;

SELECT * FROM ClientBookingHistory;

-- Оновити представлення BookingInfo для включення додаткової інформації про бронювання
CREATE OR REPLACE VIEW BookingInfo AS
SELECT 
	h.title       AS hotel_title,
	g.firstname   AS guest_firstname,
	g.surname     AS guest_surname,
	g.patronymic  AS guest_patronymic,
	r.roomtype    AS room_type,
	b.amount      AS booking_amount,
	b.datecheckin AS checkin_date,
	b.datecheckout AS checkout_date,
	b.status      AS booking_status
FROM Booking b
JOIN Room r   ON b.roomid   = r.roomid
JOIN Hotel h  ON r.hotelid  = h.hotelid
JOIN Guest g  ON b.guestid  = g.guestid;

SELECT * FROM BookingInfo;

-- -------------------------------------------------
-- LabWork 5
-- -------------------------------------------------


CREATE OR REPLACE PROCEDURE CalculateTotalBookingAmountWithDiscount(
    IN p_BookingID INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_NumberOfNights INT;
    v_PricePerNight  NUMERIC(10,2);
    v_GuestID        INT;

    totalAmount NUMERIC(10,2) := 0;
    FinishedBookings INT;

    AdditionalPrices       NUMERIC[] := '{}';
    AdditionalServiceCount INT;
    i INT := 1;
BEGIN
    -- Отримати кількість ночей, ціну номера і гостя
    SELECT b.NumberOfNights,
           r.PricePerNight,
           b.GuestID
    INTO   v_NumberOfNights,
           v_PricePerNight,
           v_GuestID
    FROM Booking b
    JOIN Room r ON r.RoomID = b.RoomID
    WHERE b.BookingID = p_BookingID;

    -- Розрахунок базової вартості проживання
    totalAmount := totalAmount + (v_NumberOfNights * v_PricePerNight);

    -- Отримати всі додаткові послуги як масив цін
	SELECT ARRAY_AGG(hs.Price)
	INTO AdditionalPrices
	FROM BookingService bs
	JOIN HotelService hs ON bs.HotelServiceID = hs.HotelServiceID
	JOIN AdditionalService ad ON hs.ServiceID = ad.ServiceID
	WHERE bs.BookingID = p_BookingID;

    IF AdditionalPrices IS NULL THEN
        AdditionalPrices := '{}';
    END IF;

    AdditionalServiceCount := array_length(AdditionalPrices, 1);

    -- WHILE — додати кожну послугу до totalAmount
    WHILE i <= COALESCE(AdditionalServiceCount, 0) LOOP
        totalAmount := totalAmount + AdditionalPrices[i];
        i := i + 1;
    END LOOP;

    -- Порахувати кількість завершених бронювань гостя
    SELECT COUNT(*)
    INTO   FinishedBookings
    FROM Booking b
    WHERE b.GuestID = v_GuestID
      AND b.Status  = 'Confirmed';

    -- Застосувати знижку за лояльністю
    IF FinishedBookings > 4 THEN
        totalAmount := totalAmount * 0.90;
    ELSIF FinishedBookings BETWEEN 2 AND 4 THEN
        totalAmount := totalAmount * 0.95;
    END IF;

    -- Оновити суму в Booking
    UPDATE Booking
    SET Amount = totalAmount
    WHERE BookingID = p_BookingID;
END;
$$;

CALL CalculateTotalBookingAmountWithDiscount(1);

-- Створити процедуру для застосування сезонних знижок до бронювань у літній період
CREATE OR REPLACE PROCEDURE ApplySeasonalDiscounts()
LANGUAGE plpgsql
AS $$
DECLARE
    seasonal_discount NUMERIC(5,2) := 10.00; -- 10%
BEGIN
    UPDATE Booking
    SET Amount = Amount * (1 - seasonal_discount / 100)
    WHERE DateCheckIn BETWEEN DATE '2025-06-01' AND DATE '2025-08-31'
      AND DateCheckOut BETWEEN DATE '2025-06-01' AND DATE '2025-08-31';
END;
$$;

CALL ApplySeasonalDiscounts();

-- Створити функцію для розрахунку загальної суми бронювання без знижок
CREATE OR REPLACE FUNCTION CalculateBookingTotal(p_BookingID INT)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_NumberOfNights INT;
    v_PricePerNight  NUMERIC(10,2);
    totalAmount      NUMERIC(10,2) := 0;
BEGIN
    SELECT b.NumberOfNights,
           r.PricePerNight
    INTO   v_NumberOfNights,
           v_PricePerNight
    FROM Booking b
    JOIN Room r ON r.RoomID = b.RoomID
    WHERE b.BookingID = p_BookingID;

    totalAmount := v_NumberOfNights * v_PricePerNight;

    RETURN totalAmount;
END;
$$;
SELECT CalculateBookingTotal(1) AS total_booking_amount;

-- Створити процедуру для оновлення ціни номера
CREATE OR REPLACE PROCEDURE UpdateRoomPrice(
    IN p_RoomID INT,
    IN p_NewPrice NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_OldPrice NUMERIC(10,2);
BEGIN
    -- Отримати стару ціну та тип номера
    SELECT r.PricePerNight
    INTO   v_OldPrice
    FROM   Room r
    WHERE  r.RoomID = p_RoomID;

    -- Оновити ціну
    UPDATE Room
    SET PricePerNight = p_NewPrice
    WHERE RoomID = p_RoomID;

    -- Логування
    RAISE NOTICE 'Room ID %: Price updated from % to %', 
                 p_RoomID, v_OldPrice, p_NewPrice;
END;
$$;
CALL UpdateRoomPrice(5, 534.61)

-- Створити функцію для отримання типу номера та ціни за ніч
CREATE OR REPLACE FUNCTION GetRoomTypeAndPrice(p_RoomID INT)
RETURNS TABLE(RoomType TEXT, PricePerNight NUMERIC(10,2))
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT r.RoomType, r.PricePerNight
    FROM Room r
    WHERE r.RoomID = p_RoomID;
END;
$$;

SELECT * FROM GetRoomTypeAndPrice(3);

-- Створити функцію для отримання всіх бронювань певного гостя
CREATE OR REPLACE FUNCTION GetAllGuestBookings(p_GuestID INT)
RETURNS TABLE(BookingID INT, FirstName TEXT, Surname TEXT, DateCheckIn DATE, DateCheckOut DATE, Status TEXT, Amount NUMERIC(10,2))
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT b.BookingID, g.firstname, g.surname, b.DateCheckIn, b.DateCheckOut, b.Status, b.Amount
	FROM Booking b
	JOIN Guest g ON b.GuestID = g.GuestID
	WHERE b.GuestID = p_GuestID;
END;
$$;

SELECT * FROM GetAllGuestBookings(18);

-- Процедура для обробки лояльності гостей
CREATE OR REPLACE PROCEDURE ProcessGuestLoyalty()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;

    guest_cursor CURSOR FOR
        SELECT g.GuestID, g.FirstName, g.Surname
        FROM Guest g;

    bookings_count INT;
BEGIN
    -- Відкрити курсор
    OPEN guest_cursor;
	LOOP

	FETCH guest_cursor INTO rec;
	EXIT WHEN NOT FOUND;

	SELECT COUNT(*) INTO bookings_count
	FROM Booking b
	WHERE b.GuestID = rec.GuestID;

	-- Перевірка лояльності гостя
	IF bookings_count > 2 THEN
		RAISE NOTICE 'Guest % % is a loyal customer with % bookings.', rec.FirstName, rec.Surname, bookings_count;
	ELSE
		RAISE NOTICE 'Guest % % has % bookings and is not loyal.', rec.FirstName, rec.Surname, bookings_count;
	END IF;

	END LOOP;
	CLOSE guest_cursor;
END;
$$;

CALL ProcessGuestLoyalty();

-- Тригер-функція для логування видалення гостя
CREATE OR REPLACE FUNCTION LogGuestDeletion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	RAISE NOTICE 'Guest with ID % and Name % % was deleted.', OLD.GuestID, OLD.FirstName, OLD.Surname;
	RETURN OLD;
END;
$$;

-- Тригер для логування видалення гостя
CREATE TRIGGER GuestDeletionTrigger
AFTER DELETE ON Guest
FOR EACH ROW
EXECUTE FUNCTION LogGuestDeletion();

-- Тригер-функція для оновлення статусу бронювання
CREATE OR REPLACE FUNCTION UpdateBookingStatus()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	IF NEW.Status = 'CheckedIn' THEN
		RAISE NOTICE 'Booking ID % has been checked in on %', NEW.BookingID, CURRENT_TIMESTAMP;
	ELSIF NEW.Status = 'CheckedOut' THEN
		RAISE NOTICE 'Booking ID % has been checked out on %', NEW.BookingID, CURRENT_TIMESTAMP;
	ELSIF NEW.Status = 'Cancelled' THEN
		RAISE NOTICE 'Booking ID % has been cancelled on %', NEW.BookingID, CURRENT_TIMESTAMP;
	ELSIF NEW.Status = 'Confirmed' THEN
		RAISE NOTICE 'Booking ID % has been confirmed on %', NEW.BookingID, CURRENT_TIMESTAMP;
	ELSIF NEW.Status = 'Pending' THEN
		RAISE NOTICE 'Booking ID % is pending as of %', NEW.BookingID, CURRENT_TIMESTAMP;
	END IF;
	RETURN NEW;
END;
$$;

-- Тригер для оновлення статусу бронювання
CREATE TRIGGER BookingStatusUpdateTrigger
AFTER UPDATE OF Status ON Booking
FOR EACH ROW
EXECUTE FUNCTION UpdateBookingStatus();

-- Тригер-функція для обчислення суми бронювання при вставці нового запису
CREATE OR REPLACE FUNCTION NewBookingInsered()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_nights INT;
    v_price  NUMERIC(10,2);
BEGIN
	IF NEW.DateCheckOut <= NEW.DateCheckIn THEN
        RAISE EXCEPTION 
            'Invalid booking dates for BookingID %: check-in = %, check-out = %',
            NEW.BookingID, NEW.DateCheckIn, NEW.DateCheckOut;
	END IF;

	v_nights := (NEW.DateCheckOut - NEW.DateCheckIn);

    SELECT r.PricePerNight
    INTO v_price
    FROM Room r
    WHERE r.RoomID = NEW.RoomID;

    NEW.Amount := v_nights * v_price;

    RAISE NOTICE 
        'New booking inserted: BookingID %, GuestID %, RoomID %, Nights %, Amount %, Created at %',
        NEW.BookingID, NEW.GuestID, NEW.RoomID, v_nights, NEW.Amount, CURRENT_TIMESTAMP;

	RETURN NEW;
END;
$$;

-- Тригер для обчислення суми бронювання при вставці нового запису
CREATE TRIGGER NewBookingInsertedTrigger
BEFORE INSERT ON Booking
FOR EACH ROW
EXECUTE FUNCTION NewBookingInsered();
