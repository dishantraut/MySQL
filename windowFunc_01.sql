-- https://www.youtube.com/watch?v=Ww71knvhQ-s&t=286s
drop table employee;

create table employee (
	emp_ID int,
	emp_NAME varchar(50),
	DEPT_NAME varchar(50),
	SALARY int
);

insert into
	employee
values
	(101, 'Mohan', 'Admin', 4000),
	(102, 'Rajkumar', 'HR', 3000),
	(103, 'Akbar', 'IT', 4000),
	(104, 'Dorvin', 'Finance', 6500),
	(105, 'Rohit', 'HR', 3000),
	(106, 'Rajesh', 'Finance', 5000),
	(107, 'Preet', 'HR', 7000),
	(108, 'Maryam', 'Admin', 4000),
	(109, 'Sanjay', 'IT', 6500),
	(110, 'Vasudha', 'IT', 7000),
	(111, 'Melinda', 'IT', 8000),
	(112, 'Komal', 'IT', 10000),
	(113, 'Gautham', 'Admin', 2000),
	(114, 'Manisha', 'HR', 3000),
	(115, 'Chandni', 'IT', 4500),
	(116, 'Satya', 'Finance', 6500),
	(117, 'Adarsh', 'HR', 3500),
	(118, 'Tejaswi', 'Finance', 5500),
	(119, 'Cory', 'HR', 8000),
	(120, 'Monica', 'Admin', 5000),
	(121, 'Rosalin', 'IT', 6000),
	(122, 'Ibrahim', 'IT', 8000),
	(123, 'Vikram', 'IT', 8000),
	(124, 'Dheeraj', 'IT', 11000);

COMMIT;

/* **************
 Video Summary
 ************** */
SELECT
	*
FROM
	employee;

-- Using Aggregate function AS Window Function
-- Without window function, SQL will reduce the no of records.
SELECT
	dept_name,
	max(salary)
FROM
	employee
GROUP BY
	dept_name;

-- By using MAX AS an window function, SQL will not reduce records but the result will be shown corresponding to each record.
SELECT
	emp.*,
	max(salary) OVER() AS max_salary
FROM
	employee emp;

SELECT
	emp.*,
	max(salary) OVER(PARTITION BY dept_name) AS max_salary
FROM
	employee emp;

-- row_number(), rank() and dense_rank()
SELECT
	e.*,
	row_number() OVER(PARTITION BY dept_name) AS rn
FROM
	employee e;

-- Fetch the first 2 employees FROM each department to join the company.
SELECT
	*
FROM
	(
		SELECT
			e.*,
			row_number() OVER(
				PARTITION BY dept_name
				ORDER BY
					emp_id
			) AS rn
		FROM
			employee e
	) x
WHERE
	x.rn < 3;

-- Fetch the top 3 employees in each department earning the max salary.
SELECT
	*
FROM
	(
		SELECT
			e.*,
			rank() OVER(
				PARTITION BY dept_name
				ORDER BY
					salary DESC
			) AS rnk
		FROM
			employee e
	) x
WHERE
	x.rnk < 4;

-- Checking the different between rank, dense_rnk and row_number window functions:
SELECT
	e.*,
	rank() OVER(
		PARTITION BY dept_name
		ORDER BY
			salary DESC
	) AS rnk,
	dense_rank() OVER(
		PARTITION BY dept_name
		ORDER BY
			salary DESC
	) AS dense_rnk,
	row_number() OVER(
		PARTITION BY dept_name
		ORDER BY
			salary DESC
	) AS rn
FROM
	employee e;

-- lead and lag
-- fetch a query to display if the salary of an employee is higher, lower or equal to the previous employee.
SELECT
	e.*,
	lag(salary) OVER(
		PARTITION BY dept_name
		ORDER BY
			emp_id
	) AS prev_empl_sal,
	case
		when e.salary > lag(salary) OVER(
			PARTITION BY dept_name
			ORDER BY
				emp_id
		) then 'Higher than previous employee'
		when e.salary < lag(salary) OVER(
			PARTITION BY dept_name
			ORDER BY
				emp_id
		) then 'Lower than previous employee'
		when e.salary = lag(salary) OVER(
			PARTITION BY dept_name
			ORDER BY
				emp_id
		) then 'Same than previous employee'
	end AS sal_range
FROM
	employee e;

-- Similarly using lead function to see how it is different FROM lag.
SELECT
	e.*,
	lag(salary) OVER(
		PARTITION BY dept_name
		ORDER BY
			emp_id
	) AS prev_empl_sal,
	lead(salary) OVER(
		PARTITION BY dept_name
		ORDER BY
			emp_id
	) AS next_empl_sal
FROM
	employee e;
