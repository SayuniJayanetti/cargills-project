# Cargills Sales Data Warehouse Project

This project demonstrates a data warehouse pipeline using the Medallion Architecture (Bronze → Silver → Gold) on Snowflake.

## Layers
- **Bronze Layer:** Loading raw data from _AWS S3_ into Snowflake. The whole batch of data is loaded as it is in `VARCHAR` data type.
- **Silver Layer:** Data type conversion, cleaning, and standardization for downstream analytics.
- **Gold Layer:** Data modelled into marts (dimension and fact tables) for reporting in Power BI.

## Components
- Scripts for file format, stage, and COPY INTO commands.
- Transformation logic in Silver layer.
- Stored procedure and task automation for Gold layer refresh.

## Code Quality
- To ensure the readability and maintainability, styling was added with SQLFluff.
- _noqa:AM04_ rule suppressor was used on `select *` columns.

### Get Started with SQLFluff Styling

**1. Install the dependencies using `uv`**

```bash 
uv sync
```

**2. Check for styling improvement**

_Project wide_
```bash
sqlfluff lint --dialect snowflake
```

_Specific files only_
```bash
sqlfluff lint --dialect snowflake bronze_layer/landing_table.sql
```

**3. Apply fixable style fixes**

```bash
sqlfluff fix --dialect snowflake
```