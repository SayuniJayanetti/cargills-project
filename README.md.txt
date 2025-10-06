# Cargills Sales Data Warehouse Project

This project demonstrates a data warehouse pipeline using the Medallion Architecture (Bronze → Silver → Gold) on Snowflake.

## Layers
- **Bronze Layer:** Raw data from AWS S3 loaded into Snowflake (all VARCHAR).
- **Silver Layer:** Data cleaned, typed, and standardized.
- **Gold Layer:** Data modeled into dimension and fact tables for reporting in Power BI.

## Components
- Scripts for file format, stage, and COPY INTO commands.
- Transformation logic in Silver layer.
- Stored procedure and task automation for Gold layer refresh.
