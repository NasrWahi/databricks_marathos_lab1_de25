# Data Engineering Project: Marathos

## Ultra-Marathon ETL Pipeline on Databricks

# Overview

This project implements a complete data engineering pipeline built on Databricks, designed to ingest, clean and model two centuries of ultra-marathon race results and serve them through an interactive dashboard and Genie space. Built as a data engineering lab using Lakeflow Declarative Pipelines and a medallion architecture (bronze -> silver -> gold), the pipeline turns ~7.46 million raw race records into a clean dimensional model ready for analysis.

The primary dataset is real data from Kaggle: [The big dataset of ultra-marathon running] (https://www.kaggle.com/datasets/aiaiaidavid/the-big-dataset-of-ultra-marathon-running?select=TWO_CENTURIES_OF_UM_RACES.csv), covering races from 1798 to 2022 across 13 columns. Two small supplementary datasets used for the bonus tasks: a country-code mapping and an LLM-generated marathon, generated for educational purposes, and can be found under `data_samples/`.

Every cleaning rule is defined once in a shared `utils/` module rather than inlined across the transformations, surrogate keys are generated in exactly one place, and each layer of the medallion architecture has a single, clear responsibility.

The project consists of four main parts:

1. **ETL Pipeline** that ingests raw race data and processes it through a medallion architecture
2. **Exploratory Data Analysis** across the bronze, silver and gold layers
3. **Dimensional Model** with a fact table, dimensions and per marathon-type views
4. **Dashboard and Genie space** for visual analysis and natural-language querying

# Objectives

- Design and implement a complete data flow from raw ingestion to a dimensional model and visualisation.
- Apply a medallion architecture with streaming ingestion and incremental processing via Lakeflow Declarative Pipelines.
- Apply data engineering principles: separation of concerns, a DRY code structure and reproducible pipelines.
- Generate surrogate keys and model a star/snowflake schema in the gold layer.
- Serve insights through a Databricks dashboard and Genie space.

# Architecture

The pipeline runs as a single Lakeflow Declarative Pipeline against the `marathos` Unity Catalog, with schemas `bronze`, `silver` and `gold`, and raw files staged in the `default.raw` volume. Each layer has one responsibility: bronze ingests, silver cleans, and gold models. Shared cleaning logic lives in `utils/utils.py`, so each rule exists in exactly one place and the silver layer stays short and readable.

Ultra-marathon races come in two types: *distance* races (a fixed distance, timed) and *length* races (a fixed time, measured by distance covered). This distinction drives the cleaning logic, and most gold views are split by `event_type`.

# Features

## ETL Pipeline

A reproducible flow that processes the raw data through three medallion stages:

1. **Bronze** (PySpark, streaming `@dp.table`): Raw ingestion of the race and country files, keeping the original column names via Delta column mapping.
2. **Silver** (PySpark, streaming `@dp.table`): A cleaned one big table (OBT). Invalid and implausible rows are dropped, types are converted, and average speed is recomputed from cleaned inputs. No surrogate IDs are created here, keeping silver a pure streaming cleaning step.
3. **Gold** (SQL materialized views): A dimensional model where surrogate keys are generated with `DENSE_RANK`/`ROW_NUMBER` (which need a batch read and cannot live in the streaming silver layer).

## Dimensional Model

A `fct_results` fact table joined to `dim_event`, `dim_athlete`, `dim_date` and `dim_country`. The model is a star schema with a snowflaked country dimension (`dim_country` joins through `dim_athlete`). On top sit a `mart_sweden` mart and two views each for distance and length races (top performers and per-country statistics).

## Dashboard

A Databricks dashboard, **Marathos Sweden**, scoped to Swedish ultra-marathon events. It includes a top-events parameter, an event-type filter with cross-filtering, and visuals for top events by finishes, average speed by event type, gender distribution and total finishes — including the streamed LLM-generated events.

## Genie Space

A **Marathos** Genie space connected to the gold schema lets users ask questions in natural language. The `genie/validate_genie_answers.ipynb` notebook documents the evaluation: each question is answered manually first, then compared against Genie's generated SQL to catch any reasoning errors.

## Data Quality & Validation

The `validation/` folder holds SQL checks that confirm the pipeline behaves as intended: streaming verification (row counts before and after the LLM data, Delta history), null-handling checks that should all return zero, and scoping and distribution checks.

## Code Quality

- All cleaning logic is collected in `utils/utils.py`. The transformations stay thin and import what they need rather than duplicating it.
- Constants such as the miles-to-km factor and the plausible-speed cap live in one place, with their sources documented.
- All comments and docstrings are written in English. Data values, event names and country codes remain in their source form.
- Correct data engineering terminology is used throughout: medallion layers, streaming tables, materialized views, dimensions, fact table and surrogate keys.

# Installation & Usage

## Essential Requirements

- A Databricks workspace with Unity Catalog (Databricks Free Edition with Serverless compute works)
- Permission to create a catalog, schemas, a volume and a Lakeflow pipeline
- The Kaggle dataset `TWO_CENTURIES_OF_UM_RACES.csv`

# 1. Setup Environment

## Create the catalog, schemas and volume:

Run `setup_unity_catalog.ipynb`, which creates the `marathos` catalog, the `bronze`, `silver` and `gold` schemas, and the `default.raw` volume.

## Upload the data:

Upload the files into the volume:

```
TWO_CENTURIES_OF_UM_RACES.csv  ->  /Volumes/marathos/default/raw/data
country_codes.csv              ->  /Volumes/marathos/default/raw/countries
```

# 2. Execution

## Create and run the pipeline:

Create a Lakeflow Declarative Pipeline with `transformations/` as the source code and `marathos` as the default catalog, then run it. Use a full refresh on the first run so all downstream tables are built.

## Open the dashboard and Genie space:

Open the **Marathos Sweden** dashboard (refresh its datasets after a pipeline run) and the **Marathos** Genie space.

# 3. Verification

After execution, verify the following:

- **Tables**: the `marathos` catalog should contain the bronze, silver and gold tables, including the four dimensions, the fact table, the mart and the four views.
- **Streaming**: run the checks in `validation/` — bronze row counts should reflect the streamed LLM data, and null checks should return zero.
- **Dashboard**: all tiles in the Marathos Sweden dashboard should render without errors.
- **Genie**: the Marathos space should answer the questions in line with the manually-written queries.