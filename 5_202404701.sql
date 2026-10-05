DROP TABLE IF EXISTS tool_loans;
DROP TABLE IF EXISTS tools;

CREATE TABLE tools (
    tool_id SERIAL PRIMARY KEY,
    tool_name VARCHAR(100) NOT NULL,
    available_quantity INTEGER NOT NULL
);

CREATE TABLE tool_loans (
    loan_id SERIAL PRIMARY KEY,
    tool_id INTEGER REFERENCES tools(tool_id),
    student_number VARCHAR(30) NOT NULL,
    quantity INTEGER NOT NULL,
    loan_status VARCHAR(20) NOT NULL
);

INSERT INTO tools (tool_name, available_quantity)
VALUES
('Hammer', 10),
('Screwdriver', 5),
('Spanner', 8);

SELECT * FROM tools;
SELECT * FROM tool_loans;


DO $$
DECLARE
    v_available_quantity INTEGER;
BEGIN
    SELECT t.available_quantity
    INTO v_available_quantity
    FROM tools t
    WHERE t.tool_id = 2;

    IF v_available_quantity = 0 THEN
        RAISE NOTICE 'Screwdriver is unavailable';
    ELSIF v_available_quantity <= 3 THEN
        RAISE NOTICE 'Screwdriver is low on stock';
    ELSE
        RAISE NOTICE 'Screwdriver is readily available';
    END IF;
END $$;


DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN
    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE 'Workshop safety reminder: %', reminder_number;
        reminder_number := reminder_number + 1;
    END LOOP;

    FOR inspection_number IN 1..3 LOOP
        RAISE NOTICE 'Tool inspection number: %', inspection_number;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE issue_tool(
    p_tool_id INTEGER,
    p_student_number VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available_quantity INTEGER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    SELECT t.available_quantity
    INTO v_available_quantity
    FROM tools t
    WHERE t.tool_id = p_tool_id;

    IF v_available_quantity IS NULL THEN
        RAISE NOTICE 'Tool does not exist';
    ELSIF p_quantity > v_available_quantity THEN
        RAISE NOTICE 'Not enough tools available';
    ELSE
        UPDATE tools
        SET available_quantity = available_quantity - p_quantity
        WHERE tool_id = p_tool_id;

        INSERT INTO tool_loans (
            tool_id,
            student_number,
            quantity,
            loan_status
        )
        VALUES (
            p_tool_id,
            p_student_number,
            p_quantity,
            'Issued'
        );

        RAISE NOTICE 'Tool issued successfully';
    END IF;
END;
$$;


CALL issue_tool(1, 'MU201', 2);
CALL issue_tool(2, 'MU202', 3);
CALL issue_tool(2, 'MU203', 5);

SELECT * FROM tools;
SELECT * FROM tool_loans;


CREATE OR REPLACE PROCEDURE return_tool(
    p_loan_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tool_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT tool_id, quantity, loan_status
    INTO v_tool_id, v_quantity, v_status
    FROM tool_loans
    WHERE loan_id = p_loan_id;

    IF v_status IS NULL THEN
        RAISE NOTICE 'Tool loan does not exist';
    ELSIF v_status = 'Returned' THEN
        RAISE NOTICE 'This tool loan has already been returned';
    ELSE
        UPDATE tools
        SET available_quantity = available_quantity + v_quantity
        WHERE tool_id = v_tool_id;

        UPDATE tool_loans
        SET loan_status = 'Returned'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Tool returned successfully';
    END IF;
END;
$$;


CALL return_tool(1);
CALL return_tool(1);

SELECT * FROM tools;
SELECT * FROM tool_loans;


DO $$
DECLARE
    tool_record RECORD;
    tool_cursor CURSOR FOR
        SELECT t.tool_id, t.tool_name, t.available_quantity
        FROM tools t
        WHERE t.available_quantity <= 3;
BEGIN
    OPEN tool_cursor;

    LOOP
        FETCH tool_cursor INTO tool_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Tool ID: %, Tool: %, Available quantity: %',
            tool_record.tool_id,
            tool_record.tool_name,
            tool_record.available_quantity;
    END LOOP;

    CLOSE tool_cursor;
END $$;


DO $$
BEGIN
    CALL issue_tool(3, 'MU204', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid quantity: quantity must be greater than zero';
END $$;


SELECT * FROM tools;
SELECT * FROM tool_loans;