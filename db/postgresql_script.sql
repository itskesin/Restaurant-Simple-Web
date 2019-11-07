--tempo deletion to be removed at final product
DROP TABLE IF EXISTS Reservations 	CASCADE;
DROP TABLE IF EXISTS Favourites 	CASCADE;
DROP TABLE IF EXISTS Redemptions 	CASCADE;
DROP TABLE IF EXISTS Rest_Location 	CASCADE;
DROP TABLE IF EXISTS Rest_Cuisine 	CASCADE;
DROP TABLE IF EXISTS Owner_Rest 	CASCADE;
DROP TABLE IF EXISTS OpeningHours 	CASCADE;
DROP TABLE IF EXISTS Availability 	CASCADE;
DROP TABLE IF EXISTS Promotion 		CASCADE;
DROP TABLE IF EXISTS Fnb 			CASCADE;
DROP TABLE IF EXISTS Rewards 		CASCADE;
DROP TABLE IF EXISTS Locations 		CASCADE;
DROP TABLE IF EXISTS Cuisines 		CASCADE;
DROP TABLE IF EXISTS Restaurants 	CASCADE;
DROP TABLE IF EXISTS Diners 		CASCADE;
DROP TABLE IF EXISTS Workers 		CASCADE;
DROP TABLE IF EXISTS Owners 		CASCADE;
DROP TABLE IF EXISTS Admin 			CASCADE;
DROP TABLE IF EXISTS Users 			CASCADE;

-- MySQL retrieves and displays DATE values in 'YYYY-MM-DD' format
-- MySQL retrieves and displays TIME values in 'hh:mm:ss' format 
CREATE TABLE Users(
	name		varchar(255) 	NOT NULL,
	phoneNum 	varchar(8) 		NOT NULL,
	email 		varchar(255) 	NOT NULL CHECK (email LIKE '%@%.%'),
	uname 		varchar(255) 	PRIMARY KEY,
	password	varchar(255) 	NOT NULL,
	type		varchar(255) 	NOT NULL CHECK (type in ('Worker','Owner','Diner'))
);

CREATE TABLE Admin (
	uname 		varchar(255) 	PRIMARY KEY,
	password	varchar(255) 	NOT NULL
);

CREATE TABLE Owners (
	uname 		varchar(255) 	PRIMARY KEY,
	FOREIGN KEY (uname) REFERENCES Users(uname) ON DELETE cascade
);

CREATE TABLE Workers (
	uname 		varchar(255) 	PRIMARY KEY,
	FOREIGN KEY (uname) REFERENCES Users(uname) ON DELETE cascade
);

CREATE TABLE Diners (
	uname 		varchar(255) 	PRIMARY KEY,
	points 		integer DEFAULT '0' NOT NULL,
	FOREIGN KEY (uname) REFERENCES Users(uname) ON DELETE cascade
);

CREATE TABLE Restaurants (
    rname 		varchar(255),
	address 	varchar(255),
	PRIMARY KEY (rname, address)
);

CREATE TABLE Cuisines(
	cname 		varchar(255) 	PRIMARY KEY
);

CREATE TABLE Locations (
	area 		varchar(255) 	PRIMARY KEY
);


CREATE TABLE Rewards (
	rewardsCode	integer 		PRIMARY KEY, --can be changed to varchar
	pointsReq 	integer 		NOT NULL,
	s_date 		date 			NOT NULL,
	e_date		date 			NOT NULL,
	amountSaved	integer
);

--Diner related
CREATE TABLE Redemptions (
	dname 		varchar(255) 	REFERENCES Diners(uname) ON DELETE CASCADE,
	rewardsCode integer 	DEFAULT '0' REFERENCES Rewards(rewardsCode) ON DELETE SET DEFAULT, 
    rname 		varchar(255) DEFAULT 'Rest',
	address 	varchar(255) DEFAULT 'address', 
	date 		date, --history purpose
	time 		time, --history purpose
	PRIMARY KEY (dname, rewardsCode),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade
);

--Weak Entity Sets
CREATE TABLE Fnb (
	rname 		varchar(255),
	address 	varchar(255),
    fname 		varchar(255),
	price 		numeric 		NOT NULL CHECK (price > 0),
	PRIMARY KEY (rname, address, fname),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade 
);

CREATE TABLE Promotion (
	rname 		varchar(255),
	address 	varchar(255),
	time 		time,
	discount 	numeric CHECK (discount > 0),
	PRIMARY KEY (rname, address, time, discount),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade
);


CREATE TABLE OpeningHours (
	rname 		varchar(255),
	address 	varchar(255),
	day 		varchar(255) CHECK (day in ('Mon','Tues','Wed','Thurs','Fri','Sat','Sun')),
	s_time 		time,
	hours 		integer 		NOT NULL CHECK (hours > 0),
	PRIMARY KEY(rname, address, day, s_time),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade
);

CREATE TABLE Availability (
	rname 		varchar(255),
	address 	varchar(255),
	day 		varchar(255) CHECK (day in ('Mon','Tues','Wed','Thurs','Fri','Sat','Sun')),
	date 		date,
	time		time,
	maxPax 		integer DEFAULT NULL CHECK (maxPax > 0),
	PRIMARY KEY(rname, address, date, time),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade
);


--Relation Set
--Restaurants related
CREATE TABLE Owner_Rest (
	rname 		varchar(255),
	address 	varchar(255),
	uname    	varchar(255),
	PRIMARY KEY (rname, address, uname),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade,
	FOREIGN KEY (uname) REFERENCES Owners(uname) ON DELETE cascade
);

CREATE TABLE Rest_Cuisine (
	rname 		varchar(255),
	address 	varchar(255),
	cname    	varchar(255),
	PRIMARY KEY (rname, address, cname),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade,
	FOREIGN KEY (cname) REFERENCES Cuisines(cname) ON DELETE cascade
);

CREATE TABLE Rest_Location (
	rname 		varchar(255),
	address 	varchar(255),
	area    	varchar(255),
	PRIMARY KEY (rname, address, area),
	FOREIGN KEY (area) REFERENCES Locations(area) ON DELETE cascade,
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade
);

--Both related
CREATE TABLE Favourites (
	dname 		varchar(255) 	REFERENCES Diners(uname) ON DELETE cascade,
	rname 		varchar(255),
	address		varchar(255),
	FOREIGN KEY (rname, address) REFERENCES Restaurants(rname, address) ON DELETE cascade,
	PRIMARY KEY (dname, rname)
);


CREATE TABLE Reservations (
	dname 		varchar(255) 	DEFAULT 'DEFAULT' REFERENCES Diners(uname) ON DELETE SET DEFAULT,
	rname 		varchar(255),
	address 	varchar(255),
	numPax 		integer			NOT NULL CHECK (numPax > 0),
	date 		date,		
	time 		time,
	status 		varchar(255)	DEFAULT 'Pending' NOT NULL CHECK (status in ('Pending','Confirmed','Completed')),
	rating 		integer DEFAULT NULL CHECK (rating >= 0 AND rating <= 5),
	PRIMARY KEY (dname, rname, address, date, time),
	FOREIGN KEY (rname, address, date, time) REFERENCES Availability (rname, address, date,time) ON DELETE cascade
);




CREATE OR REPLACE FUNCTION t_func3() 
RETURNS TRIGGER AS $$ 
DECLARE oldPoints integer;
DECLARE codePoints integer;
BEGIN 
	SELECT points into oldPoints from Diners where uname = NEW.dname;
	SELECT pointsReq into codePoints from Rewards where rewardsCode = NEW.rewardsCode;
	IF (oldPoints - codePoints < 0) THEN
		RAISE NOTICE 'Trigger 3'; RETURN NULL; 
	ELSE Update Diners SET points = (oldPoints - codePoints) WHERE uname = NEW.dname; RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig3
BEFORE INSERT ON Redemptions 
FOR EACH ROW
EXECUTE PROCEDURE t_func3();

CREATE OR REPLACE PROCEDURE delete_rest(rest varchar(155),addr varchar(255))
AS $$
BEGIN
	DELETE FROM Restaurants WHERE rname = rest AND address = addr;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION no_owner()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
DECLARE rest VARCHAR(255);
DECLARE addr VARCHAR(255);
BEGIN 
	WITH rest_involved AS(
		SELECT rname,address FROM Owner_Rest
		WHERE OLD.uname = Owner_Rest.uname
	),
	owners_involved AS(
		SELECT rname,O.address AS address from Owner_Rest O JOIN rest_involved R
		ON O.rname = R.rname AND O.address = R.address
		GROUP BY rname,address
		HAVING count(uname) > 1 --0 if after
	)
	SELECT COUNT(*) INTO count FROM owners_involved;
	WHILE count <> 0 LOOP 
		SELECT rname, address INTO rest, addr
		FROM owners_involved
		ORDER BY rname,address
		LIMIT 1;
		
		--CALL delete_rest(rest,addr);
		--alternatively
		DELETE FROM Restaurants WHERE rname = rest AND address = addr;
		count := count - 1;
	END LOOP;
		
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_rest
BEFORE DELETE ON Owners
FOR EACH ROW
EXECUTE PROCEDURE no_owner();

--insert user, check type add diner or owner
CREATE OR REPLACE FUNCTION which_type()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
BEGIN 
	IF (NEW.type = 'Owner') THEN
		SELECT COUNT(*) INTO count FROM Diners WHERE NEW.uname = Diners.uname;
		IF (count > 0) THEN RETURN NULL;
		ELSE
			BEGIN
				INSERT INTO Owners VALUES (NEW.uname);
				RETURN NEW;
			END;
		END IF;
	ELSIF (NEW.type = 'Diner') THEN
		SELECT COUNT(*) INTO count FROM Owners WHERE NEW.uname = Owners.uname;
		IF (count > 0) THEN RETURN NULL;
		ELSE
			BEGIN
				INSERT INTO Diners VALUES (NEW.uname,0);
				RETURN NEW;
			END;
		END IF;	
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_type
AFTER INSERT ON Users
FOR EACH ROW
EXECUTE PROCEDURE which_type();


--Trig: if new reservation, check availability. Update avail if has_avail
--DROP FUNCTION IF EXISTS has_avail;
CREATE OR REPLACE FUNCTION has_avail()
RETURNS TRIGGER AS $$
DECLARE mPax INTEGER;
DECLARE t_rname VARCHAR(255);
DECLARE t_address VARCHAR(255);
DECLARE t_day VARCHAR(10);
DECLARE t_date DATE;
DECLARE t_time Time;
BEGIN 
	SELECT A.maxPax, A.time, A.date, A.rname,A.address,A.day INTO mPax, t_time, t_date,t_rname,t_address,t_day
	FROM Availability A
	WHERE A.rname = NEW.rname AND A.address = NEW.address AND A.time = NEW.time AND A.date = NEW.date;
	
	IF ((mPax - NEW.numPax) >= 0) THEN
		Update Availability SET maxPax = (mPax - NEW.numPax) WHERE rname = t_rname AND address = t_address AND time = t_time AND date = t_date;
		RAISE NOTICE 'Reservation added';
		RETURN NEW;
	ELSE RAISE NOTICE 'No availability, insufficient Pax'; RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;

--DROP TRIGGER IF EXISTS check_avail ON Reservations;
CREATE TRIGGER check_avail
BEFORE INSERT ON Reservations
FOR EACH ROW
EXECUTE PROCEDURE has_avail();

--Trig: if reservation status is updated to Completed, add points
CREATE OR REPLACE FUNCTION is_completed()
RETURNS TRIGGER AS $$
DECLARE old_points INTEGER;
BEGIN 
	SELECT D.points INTO old_points
	FROM Diners D
	WHERE NEW.dname = D.uname;
	Update Diners SET points = (old_points + 5) WHERE NEW.dname = D.uname;
	RAISE NOTICE 'Points added to diner';
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_status
AFTER UPDATE ON Reservations
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'Completed')
EXECUTE PROCEDURE is_completed();

--trig if del user then del from owner/diner as well
CREATE OR REPLACE FUNCTION which_type_del()
RETURNS TRIGGER AS $$
BEGIN 
	IF (OLD.type = 'Owner') THEN
		DELETE FROM Owners WHERE uname = OLD.uname;
	ELSIF (OLD.type = 'Diner') THEN
		DELETE FROM Diners WHERE uname = OLD.uname;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_type_del
AFTER DELETE ON Users
FOR EACH ROW
EXECUTE PROCEDURE which_type_del();





--Insertion
INSERT INTO Admin VALUES('admin','password');

INSERT INTO Users VALUES ('Alice','12345678','alice@restaurant.com','alice99','password','Owner');
INSERT INTO Users VALUES ('Bob','12345678','Bob@restaurant.com','bob99','password','Owner');
INSERT INTO Users VALUES ('Charlie','12345678','Charlie@restaurant.com','charlie99','password','Owner');
INSERT INTO Users VALUES ('Delta','12345678','Delta@restaurant.com','delta99','password','Diner');
INSERT INTO Users VALUES ('Echo','12345678','Echo@restaurant.com','echo99','password','Diner');
INSERT INTO Users VALUES ('Foxtrot','12345678','Foxtrot@restaurant.com','foxtrot99','password','Diner');
INSERT INTO Users VALUES ('default','12345678','default@restaurant.com','default','defaultpass','Diner'); --reserved


INSERT INTO Restaurants VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456');
INSERT INTO Restaurants VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456');
INSERT INTO Restaurants VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789');
INSERT INTO Restaurants VALUES ('rest','address'); --reserved

INSERT INTO Cuisines VALUES ('Japanese');
INSERT INTO Cuisines VALUES ('Korean');
INSERT INTO Cuisines VALUES ('Western');
INSERT INTO Cuisines VALUES ('Chinese');
INSERT INTO Cuisines VALUES ('Malay');
INSERT INTO Cuisines VALUES ('Indian');
INSERT INTO Cuisines VALUES ('Italian');
INSERT INTO Cuisines VALUES ('French');
INSERT INTO Cuisines VALUES ('Vegetarian');
INSERT INTO Cuisines VALUES ('International');

INSERT INTO Locations VALUES ('Balestier');
INSERT INTO Locations VALUES ('Eunos');
INSERT INTO Locations VALUES ('Changi');
INSERT INTO Locations VALUES ('Jurong');

INSERT INTO Rewards VALUES ('0001', 100, DATE('2019-10-15'),DATE('2019-10-31'),10);
INSERT INTO Rewards VALUES ('0011', 110, DATE('2019-11-1'),DATE('2019-11-30'),11);
INSERT INTO Rewards VALUES ('0010', 20, DATE('2019-11-16'),DATE('2019-11-17'),2);
INSERT INTO Rewards VALUES ('0',0,Date('2000-01-01'),DATE('9999-12-31'),0); --reserved

--INSERT INTO Redemptions VALUES ('echo99','0001', 'Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456', DATE('2019-10-24'), '21:54:12');
--INSERT INTO Redemptions VALUES ('foxtrot99','0010', 'Pastamazing','123 Gowhere Road #01-22 Singapore 123456', DATE('2019-10-24'), '21:54:12');

INSERT INTO Fnb VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fried Chicken',15.0);
INSERT INTO Fnb VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Spicy Chicken',16.0);
INSERT INTO Fnb VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Cheese Fries',3.5);
INSERT INTO Fnb VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Chilli Fries',2.5);
INSERT INTO Fnb VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Expensive pasta',18.0);
INSERT INTO Fnb VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Cheap pasta',11.9);

INSERT INTO Promotion VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','15:00',0.2);

INSERT INTO OpeningHours VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Mon','09:00:00',13);
INSERT INTO OpeningHours VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Tues','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Wed','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Thurs','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Fri','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sat','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sun','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Mon','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Mon','17:00:00',5);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Tues','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Tues','17:00:00',5);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Wed','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Wed','17:00:00',5);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Thurs','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Thurs','17:00:00',5);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fri','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fri','17:00:00',5);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sat','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sat','17:00:00',5);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sun','09:00:00',6);
INSERT INTO OpeningHours VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sun','17:00:00',5);
INSERT INTO OpeningHours VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon','11:30:00',13);
INSERT INTO OpeningHours VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Tues','11:30:00',13);
INSERT INTO OpeningHours VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed','11:30:00',13);
INSERT INTO OpeningHours VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Thurs','11:30:00',13);
INSERT INTO OpeningHours VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri','11:30:00',13);
INSERT INTO OpeningHours VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sat','11:30:00',13);
INSERT INTO OpeningHours VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun','11:30:00',13);

INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Mon',DATE('2019-11-04'),'12:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Mon',DATE('2019-11-04'),'13:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Mon',DATE('2019-11-04'),'14:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Mon',DATE('2019-11-04'),'19:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Mon',DATE('2019-11-04'),'20:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Mon',DATE('2019-11-04'),'21:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Tues',DATE('2019-11-05'),'12:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Tues',DATE('2019-11-05'),'13:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Tues',DATE('2019-11-05'),'14:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Tues',DATE('2019-11-05'),'19:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Tues',DATE('2019-11-05'),'20:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Tues',DATE('2019-11-05'),'21:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Wed',DATE('2019-11-06'),'12:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Wed',DATE('2019-11-06'),'13:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Wed',DATE('2019-11-06'),'14:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Wed',DATE('2019-11-06'),'19:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Wed',DATE('2019-11-06'),'20:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Wed',DATE('2019-11-06'),'21:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Thurs',DATE('2019-11-07'),'12:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Thurs',DATE('2019-11-07'),'13:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Thurs',DATE('2019-11-07'),'14:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Thurs',DATE('2019-11-07'),'19:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Thurs',DATE('2019-11-07'),'20:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Thurs',DATE('2019-11-07'),'21:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Fri',DATE('2019-11-08'),'12:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Fri',DATE('2019-11-08'),'13:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Fri',DATE('2019-11-08'),'14:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Fri',DATE('2019-11-08'),'19:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Fri',DATE('2019-11-08'),'20:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Fri',DATE('2019-11-08'),'21:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sat',DATE('2019-11-09'),'12:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sat',DATE('2019-11-09'),'13:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sat',DATE('2019-11-09'),'14:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sat',DATE('2019-11-09'),'19:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sat',DATE('2019-11-09'),'20:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sat',DATE('2019-11-09'),'21:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sun',DATE('2019-11-10'),'12:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sun',DATE('2019-11-10'),'13:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sun',DATE('2019-11-10'),'14:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sun',DATE('2019-11-10'),'19:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sun',DATE('2019-11-10'),'20:00:00',15);
INSERT INTO Availability VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Sun',DATE('2019-11-10'),'21:00:00',15);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Mon',DATE('2019-11-04'),'17:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Mon',DATE('2019-11-04'),'18:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Mon',DATE('2019-11-04'),'19:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Mon',DATE('2019-11-04'),'20:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Mon',DATE('2019-11-04'),'21:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Tues',DATE('2019-11-05'),'17:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Tues',DATE('2019-11-05'),'18:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Tues',DATE('2019-11-05'),'19:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Tues',DATE('2019-11-05'),'20:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Tues',DATE('2019-11-05'),'21:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Wed',DATE('2019-11-06'),'17:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Wed',DATE('2019-11-06'),'18:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Wed',DATE('2019-11-06'),'19:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Wed',DATE('2019-11-06'),'20:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Wed',DATE('2019-11-06'),'21:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Thurs',DATE('2019-11-07'),'17:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Thurs',DATE('2019-11-07'),'18:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Thurs',DATE('2019-11-07'),'19:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Thurs',DATE('2019-11-07'),'20:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Thurs',DATE('2019-11-07'),'21:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fri',DATE('2019-11-08'),'17:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fri',DATE('2019-11-08'),'18:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fri',DATE('2019-11-08'),'19:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fri',DATE('2019-11-08'),'20:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Fri',DATE('2019-11-08'),'21:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sat',DATE('2019-11-09'),'17:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sat',DATE('2019-11-09'),'18:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sat',DATE('2019-11-09'),'19:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sat',DATE('2019-11-09'),'20:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sat',DATE('2019-11-09'),'21:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sun',DATE('2019-11-10'),'17:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sun',DATE('2019-11-10'),'18:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sun',DATE('2019-11-10'),'19:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sun',DATE('2019-11-10'),'20:00:00',10);
INSERT INTO Availability VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Sun',DATE('2019-11-10'),'21:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon',DATE('2019-11-04'),'12:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon',DATE('2019-11-04'),'13:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon',DATE('2019-11-04'),'14:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon',DATE('2019-11-04'),'18:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon',DATE('2019-11-04'),'19:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon',DATE('2019-11-04'),'20:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Mon',DATE('2019-11-04'),'21:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Tues',DATE('2019-11-05'),'12:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Tues',DATE('2019-11-05'),'13:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Tues',DATE('2019-11-05'),'14:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Tues',DATE('2019-11-05'),'18:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Tues',DATE('2019-11-05'),'19:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Tues',DATE('2019-11-05'),'20:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed',DATE('2019-11-06'),'12:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed',DATE('2019-11-06'),'13:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed',DATE('2019-11-06'),'14:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed',DATE('2019-11-06'),'18:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed',DATE('2019-11-06'),'19:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed',DATE('2019-11-06'),'20:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Wed',DATE('2019-11-06'),'21:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Thurs',DATE('2019-11-07'),'12:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Thurs',DATE('2019-11-07'),'13:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Thurs',DATE('2019-11-07'),'14:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Thurs',DATE('2019-11-07'),'18:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Thurs',DATE('2019-11-07'),'19:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Thurs',DATE('2019-11-07'),'20:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri',DATE('2019-11-08'),'12:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri',DATE('2019-11-08'),'13:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri',DATE('2019-11-08'),'14:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri',DATE('2019-11-08'),'18:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri',DATE('2019-11-08'),'19:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri',DATE('2019-11-08'),'20:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Fri',DATE('2019-11-08'),'21:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sat',DATE('2019-11-09'),'12:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sat',DATE('2019-11-09'),'13:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sat',DATE('2019-11-09'),'14:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sat',DATE('2019-11-09'),'18:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sat',DATE('2019-11-09'),'19:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sat',DATE('2019-11-09'),'20:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun',DATE('2019-11-10'),'12:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun',DATE('2019-11-10'),'13:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun',DATE('2019-11-10'),'14:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun',DATE('2019-11-10'),'18:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun',DATE('2019-11-10'),'19:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun',DATE('2019-11-10'),'20:00:00',10);
INSERT INTO Availability VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Sun',DATE('2019-11-10'),'21:00:00',10);

INSERT INTO Owner_Rest VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','alice99');
INSERT INTO Owner_Rest VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','bob99');
INSERT INTO Owner_Rest VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','bob99');
INSERT INTO Owner_Rest VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','charlie99');

INSERT INTO Rest_Cuisine VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Western');
INSERT INTO Rest_Cuisine VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Italian');
INSERT INTO Rest_Cuisine VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Western');

INSERT INTO Rest_Location VALUES ('Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456','Eunos');
INSERT INTO Rest_Location VALUES ('Pastamazing','123 Gowhere Road #01-27 Singapore 123456','Changi');
INSERT INTO Rest_Location VALUES ('What the fries','456 Hungry Road #01-36 Singapore 456789','Jurong');

INSERT INTO Favourites VALUES ('foxtrot99','Pastamazing','123 Gowhere Road #01-27 Singapore 123456');
INSERT INTO Favourites VALUES ('delta99','Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456');
INSERT INTO Favourites VALUES ('delta99','What the fries','456 Hungry Road #01-36 Singapore 456789');
INSERT INTO Favourites VALUES ('echo99','Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456');

INSERT INTO Reservations VALUES ('foxtrot99','Pastamazing','123 Gowhere Road #01-27 Singapore 123456',4, DATE('2019-11-07'),'13:00:00','Completed',NULL);
INSERT INTO Reservations VALUES ('foxtrot99','Pastamazing','123 Gowhere Road #01-27 Singapore 123456',4, DATE('2019-11-05'),'12:00:00','Confirmed',NULL);
INSERT INTO Reservations VALUES ('foxtrot99','Pastamazing','123 Gowhere Road #01-27 Singapore 123456',4, DATE('2019-11-04'),'13:00:00','Confirmed',NULL);
INSERT INTO Reservations VALUES ('echo99','Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456',3, DATE('2019-11-04'),'19:00:00','Confirmed',NULL);
INSERT INTO Reservations VALUES ('echo99','Wonder Chickin','123 Gowhere Road #02-54 Singapore 123456',2, DATE('2019-11-07'),'19:00:00','Confirmed',NULL);
INSERT INTO Reservations VALUES ('echo99','Pastamazing','123 Gowhere Road #01-27 Singapore 123456',4, DATE('2019-11-07'),'19:00:00','Confirmed',NULL);
INSERT INTO Reservations VALUES ('foxtrot99','What the fries','456 Hungry Road #01-36 Singapore 456789',4, DATE('2019-11-07'),'13:00:00','Confirmed',NULL);
INSERT INTO Reservations VALUES ('foxtrot99','Pastamazing','123 Gowhere Road #01-27 Singapore 123456',4, DATE('2019-11-07'),'20:00:00','Confirmed',NULL);
INSERT INTO Reservations VALUES ('foxtrot99','Pastamazing','123 Gowhere Road #01-27 Singapore 123456',4, DATE('2019-11-06'),'20:00:00','Confirmed',NULL);


--CREATE VIEW test(Rname, address)as 
--WITH X AS (
	--SELECT numPax, COUNT(numPax) as freq FROM Reservations R WHERE R.dname = 'foxtrot99' AND R.status = 'Completed' GROUP BY R.numPax ORDER BY freq DESC LIMIT 1 
--),
--Y AS (
	--SELECT R1.rname,R1.address FROM X JOIN (SELECT rname, address, AVG(numPax) as numPax FROM Reservations R1 GROUP BY rname,address) AS R1 ON X.numPax = R1.numPax
--),
--Z AS (
	--SELECT cname FROM (SELECT C.cname FROM Reservations R, Rest_Cuisine C WHERE dname = 'foxtrot99' AND status = 'Completed') AS C 
	--GROUP BY cname ORDER BY COUNT(cname) DESC LIMIT 3
--)
--SELECT Y.rname, Y.address FROM Z NATURAL JOIN Rest_Cuisine JOIN Y ON Rest_Cuisine.rname = Y.rname AND Rest_Cuisine.address = Y.address;
--SELECT * FROM test;


--CREATE VIEW test(Rname, address)as 
--WITH X AS (
	--SELECT rname, address, MONTH(date) AS month, COUNT(*) AS count FROM Reservations R WHERE R.rname='Pastamazing' AND R.address='123 Gowhere Road #01-27 Singapore 123456' AND YEAR(date)='2019'
	--GROUP BY rname, address, MONTH(date)
--),
--Y AS (
	--SELECT rname, address, MONTH(date) AS month, AVG(rating) AS rating FROM Reservations R WHERE R.rname='Pastamazing' AND R.address='123 Gowhere Road #01-27 Singapore 123456' AND YEAR(date)='2019'
	--GROUP BY rname, address, MONTH(date)
--)
--SELECT * FROM X NATURAL JOIN Y;


--CREATE VIEW test(Rname, address)as 
--WITH X AS (
	--SELECT area, COUNT(area) AS count FROM Reservations R, Rest_Location L WHERE R.status = 'Completed' AND R.dname = 'foxtrot99' AND R.rname = L.rname AND R.address = L.address
	--GROUP BY area	
--), 
--Y AS (
	--SELECT area, MAX(count) FROM X GROUP by area
--)
--SELECT DISTINCT R.rname, R.address FROM Restaurants R NATURAL JOIN Rest_Location L INNER JOIN Y ON L.area= Y.area;
--SELECT * FROM test;

