CREATE Database BookStore;

USE BookStore;

CREATE TABLE Books1 (
    id INT,
    name VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price INT NOT NULL
);

CREATE TABLE Books2 (
    id INT,
    name VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price INT NOT NULL
);

INSERT INTO
    Books1
VALUES
    (1, 'Book1', 'Cat1', 1800),
    (2, 'Book2', 'Cat2', 1500),
    (3, 'Book3', 'Cat3', 2000),
    (4, 'Book4', 'Cat4', 1300),
    (5, 'Book5', 'Cat5', 1500),
    (6, 'Book6', 'Cat6', 5000),
    (7, 'Book7', 'Cat7', 8000),
    (8, 'Book8', 'Cat8', 5000),
    (9, 'Book9', 'Cat9', 5400),
    (10, 'Book10', 'Cat10', 3200);

INSERT INTO
    Books2
VALUES
    (6, 'Book6', 'Cat6', 5000),
    (7, 'Book7', 'Cat7', 8000),
    (8, 'Book8', 'Cat8', 5000),
    (9, 'Book9', 'Cat9', 5400),
    (10, 'Book10', 'Cat10', 3200),
    (11, 'Book11', 'Cat11', 5000),
    (12, 'Book12', 'Cat12', 8000),
    (13, 'Book13', 'Cat13', 5000),
    (14, 'Book14', 'Cat14', 5400),
    (15, 'Book15', 'Cat15', 3200);


/*
 - Right SELECT Query EXCEPT Left SELECT Query
 - Yes, it is that simple to execute an EXCEPT statement.
 - Next, we will use the SQL EXCEPT statement to select records from the Books1 table that are not present in the Books2 table. 
 - You can see that the records from ids 6 to 10 are the same in both tables.
 - So, if the Book1 table is on the left of the EXCEPT operator and Books2 table is on the right, the records with ids 1 to 5 will be selected from the table Books1.
 - You can see that only records with ids 1 to 5 have been selected from the Books1 table since the records with ids 6 to 10 also exist in the Books2 table.
 */
SELECT
    id,
    name,
    category,
    price
FROM
    Books1
EXCEPT
SELECT
    id,
    name,
    category,
    price
FROM
    Books2;


/*
 - Similarly, if the Books2 table is on the left side of the SQL EXCEPT statement and the Books1 table is on the right,
 you will see records from the Books2 table not present in the Books1 table.
 - You can see that only records with ids 11 to 15 have been selected since records with ids 6-10 from the Books2 table, also exist in the Books1 table.
 */
SELECT
    id,
    name,
    category,
    price
FROM
    Books2
Except
SELECT
    id,
    name,
    category,
    price
FROM
    Books1;


/*
 In the script above, we have two SELECT statements operating on a single table i.e. Books1.
 The SELECT statement on the right-hand side of the EXCEPT statement selects all the records where the price is greater than 5000. 
 The SELECT statement on the left side of the EXCEPT statement returns all the records from the Books1 table.
 Next, the EXCEPT statement filters the records selected by the SELECT statement on the right, from the records returned by the SELECT statement on the left. 
 Hence, we are only left with the records from the Books table, where the price is not greater than 5000.
 */
SELECT
    id,
    name,
    category,
    price
FROM
    Books1
Except
SELECT
    id,
    name,
    category,
    price
FROM
    Books1
WHERE
    price > 5000;


/*
 EXCEPT vs NOT NULL
 Now that you know how an EXCEPT statement works, it is important to understand the difference between SQL EXCEPT statement and NOT IN statement. 
 There are two major differences:
 The EXCEPT statement only returns the distinct records, whereas a NOT IN statement returns all the records that are not filtered by the NOT IN statement
 In the EXCEPT statement, the comparison between two SELECT statements is based on all the columns in both the tables. 
 While a NOT IN statement compares values from a single column
 Here is an example of how a NOT IN statement can be used to filter all records from the Books1 table, that also exist in the Books2 table:
 You can see that here the comparison between the first and second columns is only based on the id column.
 */
SELECT
    id,
    name,
    category,
    price
FROM
    Books1
WHERE
    id NOT IN (
        SELECT
            id
        from
            Books2
    );


-- * Conclusion * --
-- The SQL EXCEPT statement is used to filter records based on the intersection of records returned via two SELECT statements. 
-- The records that are common between the two tables are filtered from the table on the left side of the SQL EXCEPT statement and the remaining records are returned.
-- In this article, we looked at how to use an EXCEPT statement to filter records from two tables as well as from a single table. 
-- The article also covered the difference between the EXCEPT and NOT IN statements.
