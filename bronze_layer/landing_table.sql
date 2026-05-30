--create a storage integration--
CREATE OR REPLACE STORAGE INTEGRATION sf_s3_integration
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::880079110908:role/cargills-snowflake-role'
STORAGE_ALLOWED_LOCATIONS = ('s3://cargills-sales-project/landing/');


--get the STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID
--paste them in the IAM Role--
DESCRIBE INTEGRATION sf_s3_integration;


--create a file format--
CREATE OR REPLACE FILE FORMAT my_csv_format
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
NULL_IF = ('', 'NULL', 'null')
EMPTY_FIELD_AS_NULL = TRUE
TRIM_SPACE = TRUE
DATE_FORMAT = 'AUTO'
TIME_FORMAT = 'AUTO'
TIMESTAMP_FORMAT = 'AUTO'
ENCODING = 'ISO-8859-1';


-- Create an external stage--
CREATE OR REPLACE STAGE landing_stage
    URL = 's3://cargills-sales-project/landing/'
    STORAGE_INTEGRATION = sf_s3_integration
    FILE_FORMAT = my_csv_format;


LIST @landing_stage;


--creating the landing table in bronze layer--
CREATE TABLE bronze_sales (
    ordernumber VARCHAR,
    quantityordered VARCHAR,
    priceeach VARCHAR,
    orderlinenumber VARCHAR,
    sales VARCHAR,
    orderdate VARCHAR,
    status VARCHAR,
    qtr_id VARCHAR,
    month_id VARCHAR,
    year_id VARCHAR,
    productline VARCHAR,
    msrp VARCHAR,
    productcode VARCHAR,
    customername VARCHAR,
    phone VARCHAR,
    addressline1 VARCHAR,
    addressline2 VARCHAR,
    city VARCHAR,
    state VARCHAR,
    postalcode VARCHAR,
    country VARCHAR,
    territory VARCHAR,
    contactlastname VARCHAR,
    contactfirstname VARCHAR,
    dealsize VARCHAR
);


--copy the data from s3 to the landing table--
COPY INTO bronze_sales
FROM @landing_stage
FILE_FORMAT = (FORMAT_NAME = my_csv_format)
ON_ERROR = 'CONTINUE';

SELECT * --noqa:AM04
FROM bronze_sales
ORDER BY ordernumber
LIMIT 30;
