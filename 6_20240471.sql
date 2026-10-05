DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS events;

CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    available_seats INTEGER NOT NULL
);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(event_id),
    student_number VARCHAR(30) NOT NULL,
    number_of_seats INTEGER NOT NULL,
    booking_status VARCHAR(20) NOT NULL
);

INSERT INTO events (event_name, available_seats)
VALUES
('Technology Conference', 100),
('Engineering Seminar', 50),
('Computer Science Workshop', 80);

SELECT * FROM events;
SELECT * FROM bookings;


DO $$
DECLARE
    v_available_seats INTEGER;
BEGIN
    SELECT e.available_seats
    INTO v_available_seats
    FROM events e
    WHERE e.event_id = 2;

    IF v_available_seats = 0 THEN
        RAISE NOTICE 'Engineering Seminar is full';
    ELSIF v_available_seats <= 10 THEN
        RAISE NOTICE 'Engineering Seminar is nearly full';
    ELSE
        RAISE NOTICE 'Engineering Seminar has plenty of seats';
    END IF;
END $$;


DO $$
DECLARE
    reminder_day INTEGER := 1;
BEGIN
    WHILE reminder_day <= 3 LOOP
        RAISE NOTICE 'Booking reminder day: %', reminder_day;
        reminder_day := reminder_day + 1;
    END LOOP;

    FOR entrance_check IN 1..3 LOOP
        RAISE NOTICE 'Entrance check number: %', entrance_check;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE book_seats(
    p_event_id INTEGER,
    p_student_number VARCHAR,
    p_number_of_seats INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available_seats INTEGER;
BEGIN
    IF p_number_of_seats <= 0 THEN
        RAISE EXCEPTION 'Number of seats must be greater than zero';
    END IF;

    SELECT e.available_seats
    INTO v_available_seats
    FROM events e
    WHERE e.event_id = p_event_id;

    IF v_available_seats IS NULL THEN
        RAISE NOTICE 'Event does not exist';
    ELSIF p_number_of_seats > v_available_seats THEN
        RAISE NOTICE 'Not enough seats available';
    ELSE
        UPDATE events
        SET available_seats = available_seats - p_number_of_seats
        WHERE event_id = p_event_id;

        INSERT INTO bookings (
            event_id,
            student_number,
            number_of_seats,
            booking_status
        )
        VALUES (
            p_event_id,
            p_student_number,
            p_number_of_seats,
            'Booked'
        );

        RAISE NOTICE 'Seats booked successfully';
    END IF;
END;
$$;


CALL book_seats(1, 'MU301', 10);
CALL book_seats(2, 'MU302', 5);
CALL book_seats(2, 'MU303', 50);

SELECT * FROM events;
SELECT * FROM bookings;


CREATE OR REPLACE PROCEDURE cancel_booking(
    p_booking_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_event_id INTEGER;
    v_number_of_seats INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT event_id, number_of_seats, booking_status
    INTO v_event_id, v_number_of_seats, v_status
    FROM bookings
    WHERE booking_id = p_booking_id;

    IF v_status IS NULL THEN
        RAISE NOTICE 'Booking does not exist';
    ELSIF v_status = 'Cancelled' THEN
        RAISE NOTICE 'This booking has already been cancelled';
    ELSE
        UPDATE events
        SET available_seats = available_seats + v_number_of_seats
        WHERE event_id = v_event_id;

        UPDATE bookings
        SET booking_status = 'Cancelled'
        WHERE booking_id = p_booking_id;

        RAISE NOTICE 'Booking cancelled successfully';
    END IF;
END;
$$;


CALL cancel_booking(1);
CALL cancel_booking(1);

SELECT * FROM events;
SELECT * FROM bookings;


DO $$
DECLARE
    event_record RECORD;
    event_cursor CURSOR FOR
        SELECT e.event_id, e.event_name, e.available_seats
        FROM events e
        WHERE e.available_seats <= 10;
BEGIN
    OPEN event_cursor;

    LOOP
        FETCH event_cursor INTO event_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Event ID: %, Event: %, Available seats: %',
            event_record.event_id,
            event_record.event_name,
            event_record.available_seats;
    END LOOP;

    CLOSE event_cursor;
END $$;


DO $$
BEGIN
    CALL book_seats(3, 'MU304', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid input: number of seats must be greater than zero';
END $$;


SELECT * FROM events;
SELECT * FROM bookings;