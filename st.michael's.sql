CREATE TABLE stm_employees (
	emp_id INT PRIMARY KEY,
	title VARCHAR(5),
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	date_hired DATE DEFAULT CURRENT_DATE,
	department_id INT,
	position VARCHAR(30),
	shift INT,
	salary INT
);

ALTER TABLE stm_employees
ADD FOREIGN KEY (department_id) REFERENCES stm_departments (department_id);

--

CREATE TABLE stm_departments (
	department_id INT PRIMARY KEY,
	department_name VARCHAR(20),
	department_count INT
);

--

CREATE TABLE stm_supplies (
	supplier_id INT PRIMARY KEY,
	supplier_name VARCHAR(20),
	item_name VARCHAR(20),
	cost FLOAT,
	department_specific BOOLEAN
);

--

CREATE TABLE stm_supply_orders (
	order_date DATE,
	order_internal_id INT,
	supplier_id INT,
	supply_item VARCHAR(20),
	cost FLOAT,
	fulfilled BOOLEAN
);


--

CREATE TABLE stm_insurance (
	insurance_policy_internal_id INT PRIMARY KEY,
	insurance_company VARCHAR(20),
	insurance_policy VARCHAR(20),
	deductible INT
);


--

CREATE TABLE stm_doctor_insurances (
	doctor_emp_id INT,
	practice_field VARCHAR(20),
	insurance_policy_id INT,
	does_hospital_participate BOOLEAN
);


ALTER TABLE stm_doctor_insurances
ADD FOREIGN KEY (insurance_policy_id) REFERENCES stm_insurance (insurance_policy_internal_id) ON DELETE CASCADE;

ALTER TABLE stm_doctor_insurances
ADD FOREIGN KEY (doctor_emp_id) REFERENCES stm_employees (emp_id) ON DELETE CASCADE;

--

CREATE TABLE stm_negotiations_insurance (
	insurance_policy_internal_id INT,
	procedure_id INT,
	negotiated_cost FLOAT,
	last_update DATE
);

ALTER TABLE stm_negotiations_insurance
ADD FOREIGN KEY (insurance_policy_internal_id) REFERENCES stm_insurance (insurance_policy_internal_id) ON DELETE CASCADE;


--


CREATE TABLE stm_procedures (
	procedure_id INT PRIMARY KEY,
	procedure_name VARCHAR(20),
	baseline_cost FLOAT
);

--

CREATE TABLE stm_patients (
	patient_id INT PRIMARY KEY,
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	insurance_company VARCHAR(20),
	insurance_policy_internal_id INT,
	personal_policy_id VARCHAR(30),
	date_of_visit TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_of_discharge TIMESTAMP,
	reason_for_visit VARCHAR(30),
	condition VARCHAR(20),
	department_name VARCHAR(20),
	department_id INT
);

--

CREATE TABLE stm_schedule (
	emp_id INT,
	shift INT,
	date DATE,
	shift_start TIME,
	shift_end TIME,
	department_id INT,
	full_time BOOLEAN
);

ALTER TABLE stm_schedule
ADD FOREIGN KEY (emp_id) REFERENCES stm_employees (emp_id);


-- create sequences for generating id numbers automatically

CREATE SEQUENCE emp_id_num
INCREMENT BY 1
MINVALUE 1000001
MAXVALUE 9999999
START 1
CACHE 20;


-- create function and trigger for adding and subtracting (when employees are deleted) the count of employees per department in the department table

CREATE FUNCTION icu_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE

icu_cnt integer;

BEGIN

SELECT COUNT(*) INTO icu_cnt
FROM stm_employees
WHERE department_id = 8;

UPDATE stm_departments
SET department_count = icu_cnt
WHERE department_id = 8; 

RETURN NEW;

END;
$$

CREATE TRIGGER icu_add
AFTER INSERT ON stm_employees
FOR EACH ROW 
EXECUTE PROCEDURE icu_count();

CREATE TRIGGER icu_subtract
AFTER DELETE ON stm_employees
FOR EACH ROW 
EXECUTE PROCEDURE icu_count();


--

-- insert values into tables

INSERT INTO stm_departments VALUES(nextval('dept_id_num'), 'Maintenance', 0),
									(nextval('dept_id_num'), 'Nursing', 0),
									(nextval('dept_id_num'), 'Food Service', 0),
									(nextval('dept_id_num'), 'Other Medical Staff', 0),
									(nextval('dept_id_num'), 'Administration', 0),
									(nextval('dept_id_num'), 'Executive', 0);					

INSERT INTO stm_employees (emp_id, title, first_name, last_name, department_id, position, shift, salary) 
	VALUES(nextval('emp_id_num'), 'Dr.', 'Johnathan', 'Davis', 1, 'Physician', 2, 75000);


INSERT INTO stm_insurance VALUES (nextval('insurance_id_num'), 'Horizon NCBSNJ', 'BlueCard PPO', 500);

INSERT INTO stm_schedule VALUES(1000020, 4, '06/16/21', '13:00:00', '21:00:00', 3, TRUE);

-- create another functino and trigger for generating employee emails automatically

CREATE OR REPLACE FUNCTION generate_email()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE

email_g VARCHAR(30);

BEGIN

SELECT LOWER(SUBSTRING(NEW.first_name, 1, 1)) || LOWER(NEW.last_name) || '@stmichaels.com' INTO email_g
FROM stm_employees
WHERE department_id IN(1, 3, 5, 6, 7, 8, 9);

INSERT INTO stm_emails VALUES(NEW.emp_id, email_g);

RETURN NEW;

END;
$$

CREATE TRIGGER generate_email
AFTER INSERT ON stm_employees
FOR EACH ROW 
EXECUTE PROCEDURE generate_email();

-- create view with the week's staff schedule

CREATE VIEW schedule_6_13_21 AS
SELECT date, e.emp_id, first_name, last_name, email, s.shift, shift_start, shift_end, d.department_name, position
FROM stm_employees e
RIGHT JOIN stm_schedule s ON e.emp_id = s.emp_id
INNER JOIN stm_emails em ON e.emp_id = em.emp_id
INNER JOIN stm_departments d ON e.department_id = d.department_id
WHERE date BETWEEN '06/13/21' AND '06/19/21';

