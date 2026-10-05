CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL,
    available_bed_spaces INTEGER NOT NULL
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(30) NOT NULL,
    room_id INTEGER REFERENCES hostel_rooms(room_id),
    allocation_status VARCHAR(20) NOT NULL
);

INSERT INTO hostel_rooms (room_number, available_bed_spaces)
VALUES
('Room A1', 4),
('Room A2', 0),
('Room B1', 5);

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;


DO $$
DECLARE
    available_spaces INTEGER;
BEGIN
    SELECT available_bed_spaces
    INTO available_spaces
    FROM hostel_rooms
    WHERE room_id = 2;

    IF available_spaces = 0 THEN
        RAISE NOTICE 'Room A2 is full';
    ELSIF available_spaces = 1 THEN
        RAISE NOTICE 'Room A2 has one space left';
    ELSE
        RAISE NOTICE 'Room A2 has several spaces available';
    END IF;
END $$;


DO $$
DECLARE
    inspection_day INTEGER := 1;
BEGIN
    WHILE inspection_day <= 3 LOOP
        RAISE NOTICE 'Hostel inspection day: %', inspection_day;
        inspection_day := inspection_day + 1;
    END LOOP;

    FOR room_check IN 1..3 LOOP
        RAISE NOTICE 'Room check number: %', room_check;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE allocate_room(
    p_room_id INTEGER,
    p_student_number VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    available_spaces INTEGER;
BEGIN
    IF TRIM(p_student_number) = '' THEN
        RAISE EXCEPTION 'Student number cannot be blank';
    END IF;

    SELECT available_bed_spaces
    INTO available_spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    IF available_spaces IS NULL THEN
        RAISE NOTICE 'Room does not exist';
    ELSIF available_spaces <= 0 THEN
        RAISE NOTICE 'Room is full';
    ELSE
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations (
            student_number,
            room_id,
            allocation_status
        )
        VALUES (
            p_student_number,
            p_room_id,
            'Allocated'
        );

        RAISE NOTICE 'Student allocated successfully';
    END IF;
END;
$$;


CALL allocate_room(1, 'MU101');
CALL allocate_room(3, 'MU102');
CALL allocate_room(2, 'MU103');

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;


CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT room_id, allocation_status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF v_status IS NULL THEN
        RAISE NOTICE 'Allocation does not exist';
    ELSIF v_status = 'Checked Out' THEN
        RAISE NOTICE 'This allocation has already been checked out';
    ELSE
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces + 1
        WHERE room_id = v_room_id;

        UPDATE allocations
        SET allocation_status = 'Checked Out'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully';
    END IF;
END;
$$;

CALL check_out(1);
CALL check_out(1);

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;


DO $$
DECLARE
    room_record RECORD;
    room_cursor CURSOR FOR
        SELECT room_id, room_number, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;
BEGIN
    OPEN room_cursor;

    LOOP
        FETCH room_cursor INTO room_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Room ID: %, Room: %, Available spaces: %',
            room_record.room_id,
            room_record.room_number,
            room_record.available_bed_spaces;
    END LOOP;

    CLOSE room_cursor;
END $$;


DO $$
BEGIN
    CALL allocate_room(3, '');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid input: student number cannot be blank';
END $$;


SELECT * FROM hostel_rooms;

SELECT * FROM allocations;

