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
				'Parking'
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
		PasswordHash BYTEA NOT NULL
	);

CREATE TABLE
	Manager (
		ManagerID SERIAL PRIMARY KEY,
		AdminID INT NOT NULL REFERENCES Administrator (AdminID),
		FirstName TEXT NOT NULL,
		Surname TEXT NOT NULL,
		Patronymic TEXT,
		Login TEXT NOT NULL UNIQUE,
		PasswordHash BYTEA NOT NULL
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
