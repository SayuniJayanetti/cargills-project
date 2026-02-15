--transform the raw data--

CREATE TABLE silver_sales AS
SELECT
    TRY_TO_NUMBER(ordernumber) AS ordernumber,
    TRY_TO_NUMBER(quantityordered) AS quantityordered,
    TRY_TO_NUMBER(priceeach) AS priceeach,
    TRY_TO_NUMBER(orderlinenumber) AS orderlinenumber,
    TRY_TO_NUMBER(sales) AS sales,
    TRY_TO_TIMESTAMP(orderdate, 'MM/DD/YYYY HH24:MI') AS orderdate,
    INITCAP(status) AS status,
    TRY_TO_NUMBER(qtr_id) AS qtr_id,
    TRY_TO_NUMBER(month_id) AS month_id,
    TRY_TO_NUMBER(year_id) AS year_id,
    INITCAP(productline) AS productline,
    TRY_TO_NUMBER(msrp) AS msrp,
    productcode,
    INITCAP(customername) AS customername,
    REGEXP_REPLACE(phone, '[^0-9\+]', '') AS phone,
    INITCAP(addressline1) AS addressline1,
    COALESCE(NULLIF(addressline2, ''), 'N/A') AS addressline2,
    city,
    COALESCE(NULLIF(state, ''), 'N/A') AS state,
    COALESCE(NULLIF(postalcode, ''), 'N/A') AS postalcode,
    country,
    territory,
    INITCAP(contactlastname) AS contactlastname,
    INITCAP(contactfirstname) AS contactfirstname,
    INITCAP(dealsize) AS dealsize
FROM cargills_raw.bronze_sales
WHERE ordernumber IS NOT NULL;


SELECT * --noqa:AM04
FROM silver_sales;
