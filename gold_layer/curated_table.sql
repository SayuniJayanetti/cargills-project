--manually create the dim tables and fact table and populate the tables--
CREATE TABLE CARGILLS_CURATED.DIM_DATE AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ORDERDATE) AS DATE_KEY,
    ORDERDATE,
    MIN(QTR_ID) AS QTR_ID,
    MIN(MONTH_ID) AS MONTH_ID,
    MIN(YEAR_ID) AS YEAR_ID,
    CONCAT('Q', MIN(QTR_ID)) AS QUARTERNAME,
    DAYNAME(ORDERDATE) AS DAYOFWEEK
FROM CARGILLS_CLEAN.SILVER_SALES
WHERE ORDERDATE IS NOT NULL
GROUP BY ORDERDATE
ORDER BY ORDERDATE;


CREATE TABLE CARGILLS_CURATED.DIM_CUSTOMER AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CUSTOMERNAME) AS CUSTOMER_KEY,
    CUSTOMERNAME,
    MAX(PHONE) AS PHONE,
    MAX(ADDRESSLINE1) AS ADDRESSLINE1,
    MAX(ADDRESSLINE2) AS ADDRESSLINE2,
    MAX(CITY) AS CITY,
    MAX(STATE) AS STATE,
    MAX(POSTALCODE) AS POSTALCODE,
    MAX(COUNTRY) AS COUNTRY,
    MAX(TERRITORY) AS TERRITORY,
    MAX(CONTACTLASTNAME) AS CONTACTLASTNAME,
    MAX(CONTACTFIRSTNAME) AS CONTACTFIRSTNAME
FROM CARGILLS_CLEAN.SILVER_SALES
WHERE CUSTOMERNAME IS NOT NULL
GROUP BY CUSTOMERNAME
ORDER BY CUSTOMERNAME;


CREATE TABLE CARGILLS_CURATED.DIM_PRODUCT AS
SELECT
    ROW_NUMBER() OVER (ORDER BY PRODUCTCODE) AS PRODUCT_KEY,
    MIN(PRODUCTLINE) AS PRODUCTLINE,
    PRODUCTCODE,
    MAX(MSRP) AS MSRP,
    MAX(DEALSIZE) AS DEALSIZE
FROM CARGILLS_CLEAN.SILVER_SALES
WHERE PRODUCTCODE IS NOT NULL
GROUP BY PRODUCTCODE
ORDER BY PRODUCTCODE;


CREATE TABLE CARGILLS_CURATED.FACT_SALES AS
SELECT
    D.DATE_KEY,
    C.CUSTOMER_KEY,
    P.PRODUCT_KEY,
    S.ORDERNUMBER,
    S.ORDERLINENUMBER,
    S.QUANTITYORDERED,
    S.PRICEEACH,
    S.SALES,
    S.STATUS
FROM CARGILLS_CLEAN.SILVER_SALES AS S
INNER JOIN CARGILLS_CURATED.DIM_DATE AS D ON S.ORDERDATE = D.ORDERDATE
INNER JOIN CARGILLS_CURATED.DIM_CUSTOMER AS C ON S.CUSTOMERNAME = C.CUSTOMERNAME
INNER JOIN CARGILLS_CURATED.DIM_PRODUCT AS P ON S.PRODUCTCODE = P.PRODUCTCODE;

SELECT * --noqa:AM04
FROM CARGILLS_EXAMPLE.FACT_SALES;


--stored procedure to truncate and insert data into dim and fact tables--

CREATE OR REPLACE PROCEDURE CARGILLS_CURATED.refresh_silver_to_gold()
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS
$$
    // dim_date
    snowflake.createStatement({
        sqlText: `TRUNCATE TABLE IF EXISTS CARGILLS_CURATED.dim_date;`
    }).execute();

    snowflake.createStatement({
        sqlText: `
            INSERT INTO CARGILLS_CURATED.dim_date
            SELECT 
                ROW_NUMBER() OVER (ORDER BY ORDERDATE) AS DATE_KEY,
                ORDERDATE,
                MIN(QTR_ID)   AS QTR_ID,
                MIN(MONTH_ID) AS MONTH_ID,
                MIN(YEAR_ID)  AS YEAR_ID,
                CONCAT('Q', MIN(QTR_ID)) AS QuarterName,
                DAYNAME(ORDERDATE) AS DayOfWeek
            FROM CARGILLS_CLEAN.silver_sales
            WHERE ORDERDATE IS NOT NULL
            GROUP BY ORDERDATE
            ORDER BY ORDERDATE;
        `
    }).execute();

    // dim_customer
    snowflake.createStatement({
        sqlText: `TRUNCATE TABLE IF EXISTS CARGILLS_CURATED.dim_customer;`
    }).execute();

    snowflake.createStatement({
        sqlText: `
            INSERT INTO CARGILLS_CURATED.dim_customer
            SELECT 
                ROW_NUMBER() OVER (ORDER BY CUSTOMERNAME) AS CUSTOMER_KEY,
                CUSTOMERNAME,
                MAX(PHONE) AS PHONE,
                MAX(ADDRESSLINE1) AS ADDRESSLINE1,
                MAX(ADDRESSLINE2) AS ADDRESSLINE2,
                MAX(CITY) AS CITY,
                MAX(STATE) AS STATE,
                MAX(POSTALCODE) AS POSTALCODE,
                MAX(COUNTRY) AS COUNTRY,
                MAX(TERRITORY) AS TERRITORY,
                MAX(CONTACTLASTNAME) AS CONTACTLASTNAME,
                MAX(CONTACTFIRSTNAME) AS CONTACTFIRSTNAME
            FROM CARGILLS_CLEAN.silver_sales
            WHERE CUSTOMERNAME IS NOT NULL
            GROUP BY CUSTOMERNAME
            ORDER BY CUSTOMERNAME;
        `
    }).execute();

    // dim_product
    snowflake.createStatement({
        sqlText: `TRUNCATE TABLE IF EXISTS CARGILLS_CURATED.dim_product;`
    }).execute();

    snowflake.createStatement({
        sqlText: `
            INSERT INTO CARGILLS_CURATED.dim_product
            SELECT 
                ROW_NUMBER() OVER (ORDER BY PRODUCTCODE) AS PRODUCT_KEY,
                MIN(PRODUCTLINE) AS PRODUCTLINE,
                PRODUCTCODE,
                MAX(MSRP) AS MSRP,
                MAX(DEALSIZE) AS DEALSIZE
            FROM CARGILLS_CLEAN.silver_sales
            WHERE PRODUCTCODE IS NOT NULL
            GROUP BY PRODUCTCODE
            ORDER BY PRODUCTCODE;
        `
    }).execute();

    // fact_sales
    snowflake.createStatement({
        sqlText: `TRUNCATE TABLE IF EXISTS CARGILLS_CURATED.fact_sales;`
    }).execute();

    snowflake.createStatement({
        sqlText: `
            INSERT INTO CARGILLS_CURATED.fact_sales
            SELECT 
                d.DATE_KEY,
                c.CUSTOMER_KEY,
                p.PRODUCT_KEY,
                s.ORDERNUMBER,
                s.ORDERLINENUMBER,
                s.QUANTITYORDERED,
                s.PRICEEACH,
                s.SALES,
                s.STATUS
            FROM CARGILLS_CLEAN.silver_sales s
            JOIN CARGILLS_CURATED.dim_date d ON s.ORDERDATE = d.ORDERDATE
            JOIN CARGILLS_CURATED.dim_customer c ON s.CUSTOMERNAME = c.CUSTOMERNAME
            JOIN CARGILLS_CURATED.dim_product p ON s.PRODUCTCODE = p.PRODUCTCODE;
        `
    }).execute();

    return '✅ Refreshed curated layer successfully (truncate + insert)';
$$;


--creating task to run the proc--
CREATE OR REPLACE TASK CURATED_REFRESH_TASK
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 49 7 * * * UTC'
AS
    CALL CARGILLS_CURATED.refresh_silver_to_gold();

ALTER TASK CURATED_REFRESH_TASK RESUME;

SHOW TASKS LIKE 'curated_refresh_task';

SELECT * --noqa:AM04
FROM CARGILLS_CURATED.FACT_SALES;
