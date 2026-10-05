DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS lab_sessions;

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INTEGER NOT NULL
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES lab_sessions(session_id),
    lecturer VARCHAR(100) NOT NULL,
    number_of_workstations INTEGER NOT NULL,
    reservation_status VARCHAR(20) NOT NULL
);

INSERT INTO lab_sessions (session_name, available_workstations)
VALUES
('Database Systems Practical', 40),
('Mobile Application Development Practical', 8),
('Computer Networks Practical', 0);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;


DO $$
DECLARE
    v_available_workstations INTEGER;
BEGIN
    SELECT l.available_workstations
    INTO v_available_workstations
    FROM lab_sessions l
    WHERE l.session_id = 2;

    IF v_available_workstations = 0 THEN
        RAISE NOTICE 'Mobile Application Development Practical is full';
    ELSIF v_available_workstations <= 10 THEN
        RAISE NOTICE 'Mobile Application Development Practical is nearly full';
    ELSE
        RAISE NOTICE 'Mobile Application Development Practical has enough workstations';
    END IF;
END $$;


DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN
    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE 'Session preparation reminder: %', reminder_number;
        reminder_number := reminder_number + 1;
    END LOOP;

    FOR workstation_check IN 1..3 LOOP
        RAISE NOTICE 'Workstation check number: %', workstation_check;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_session_id INTEGER,
    p_lecturer VARCHAR,
    p_number_of_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available_workstations INTEGER;
BEGIN
    IF p_number_of_workstations <= 0 THEN
        RAISE EXCEPTION 'Number of workstations must be greater than zero';
    END IF;

    SELECT l.available_workstations
    INTO v_available_workstations
    FROM lab_sessions l
    WHERE l.session_id = p_session_id;

    IF v_available_workstations IS NULL THEN
        RAISE NOTICE 'Lab session does not exist';
    ELSIF p_number_of_workstations > v_available_workstations THEN
        RAISE NOTICE 'Not enough workstations available';
    ELSE
        UPDATE lab_sessions
        SET available_workstations = available_workstations - p_number_of_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations (
            session_id,
            lecturer,
            number_of_workstations,
            reservation_status
        )
        VALUES (
            p_session_id,
            p_lecturer,
            p_number_of_workstations,
            'Reserved'
        );

        RAISE NOTICE 'Workstations reserved successfully';
    END IF;
END;
$$;


CALL reserve_workstations(1, 'Mr Banda', 10);
CALL reserve_workstations(2, 'Mrs Phiri', 5);
CALL reserve_workstations(2, 'Dr Mwansa', 10);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;


CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id INTEGER;
    v_number_of_workstations INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT session_id, number_of_workstations, reservation_status
    INTO v_session_id, v_number_of_workstations, v_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF v_status IS NULL THEN
        RAISE NOTICE 'Reservation does not exist';
    ELSIF v_status = 'Cancelled' THEN
        RAISE NOTICE 'This reservation has already been cancelled';
    ELSE
        UPDATE lab_sessions
        SET available_workstations = available_workstations + v_number_of_workstations
        WHERE session_id = v_session_id;

        UPDATE reservations
        SET reservation_status = 'Cancelled'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE 'Reservation cancelled successfully';
    END IF;
END;
$$;


CALL cancel_reservation(1);
CALL cancel_reservation(1);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;


DO $$
DECLARE
    session_record RECORD;
    session_cursor CURSOR FOR
        SELECT l.session_id, l.session_name, l.available_workstations
        FROM lab_sessions l
        WHERE l.available_workstations <= 10;
BEGIN
    OPEN session_cursor;

    LOOP
        FETCH session_cursor INTO session_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Session ID: %, Session: %, Available workstations: %',
            session_record.session_id,
            session_record.session_name,
            session_record.available_workstations;
    END LOOP;

    CLOSE session_cursor;
END $$;


DO $$
BEGIN
    CALL reserve_workstations(1, 'Mr Tembo', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid input: number of workstations must be greater than zero';
END $$;


SELECT * FROM lab_sessions;
SELECT * FROM reservations;