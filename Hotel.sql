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

SELECT payment.bookingid, payment.Amount 
FROM Payment
WHERE payment.amount >= 2500;

SELECT guest.firstname, guest.Surname
FROM Guest
WHERE (firstname LIKE 'A%' OR firstname LIKE 'E%')
  AND NOT (BirthDate BETWEEN '1990-01-01' AND '1995-12-31');

SELECT booking.numberofnights, booking.status,booking.amount
FROM Booking
WHERE booking.numberofnights > 3 
	AND (booking.status = 'Confirmed' OR booking.status = 'CheckedIn')
	AND NOT (booking.promocode IS NULL);

SELECT guest.firstname, guest.surname, guest.birthdate, AGE(CURRENT_DATE, guest.birthdate) AS age
FROM Guest
WHERE EXTRACT(YEAR FROM AGE(CURRENT_DATE, guest.birthdate)) >= 30;

SELECT guest.firstname, guest.surname, guest.birthdate, 
	   EXTRACT(YEAR FROM AGE(CURRENT_DATE, guest.birthdate)) AS age
FROM Guest
WHERE MOD(EXTRACT(YEAR FROM AGE(CURRENT_DATE, guest.birthdate)), 5) = 0;

SELECT booking.bookingid, booking.datecheckin, booking.status, booking.amount
FROM Booking
WHERE EXTRACT(MONTH FROM booking.datecheckin) IN (6, 7, 8);

SELECT room.roomid, room.roomtype, room.PricePerNight
FROM Room
WHERE room.PricePerNight BETWEEN 100 AND 250
  AND room.Status = 'Available';

SELECT hotel.title, hotel.numberofstars, hotel.phonenumber
FROM Hotel
WHERE hotel.phonenumber ILIKE '%3805%';

SELECT adm.firstname, adm.surname, hotel.title
FROM (
	SELECT * 
	FROM Administrator)  AS adm
JOIN Hotel ON adm.adminid = hotel.adminid;

SELECT room.roomid, room.roomtype, room.status,
(SELECT h.title 
FROM HOTEL h
WHERE h.hotelid = room.hotelid)
FROM Room;

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

SELECT g.firstname, g.surname
FROM Guest g
CROSS JOIN Room r;

SELECT  h.title, h.numberofstars, h.address, g.firstname, g.surname
FROM Hotel h
JOIN Room r ON r.hotelid = h.hotelid
JOIN Booking b ON b.roomid = r.roomid
JOIN Guest g ON g.guestid = b.guestid
WHERE h.address ILIKE '%Kyiv%';

SELECT m.firstname, m.surname, b.bookingid, b.status
FROM Manager m
JOIN Booking b ON m.managerid = b.managerid
ORDER BY m.firstname;

SELECT g.firstname, g.surname, b.bookingid
FROM Guest g
LEFT JOIN Booking b ON g.guestid = b.guestid
WHERE b.bookingid IS NULL;

SELECT r.roomid, r.roomtype, b.bookingid
FROM Room r
RIGHT JOIN Booking b ON r.roomid = b.roomid
WHERE r.status = 'Available';

SELECT a.adminid, a.firstname, a.surname, 'Administrator' AS role
FROM Administrator a
UNION
SELECT m.managerid, m.firstname, m.surname, 'Manager' AS role
FROM Manager m;

SELECT h.title, h.numberofstars, h.address
FROM Hotel h
WHERE h.address ILIKE '%Kyiv%' OR h.address ILIKE '%Odesa%'
INTERSECT
SELECT h.title, h.numberofstars, h.address
FROM Hotel h
WHERE h.numberofstars = 5;
