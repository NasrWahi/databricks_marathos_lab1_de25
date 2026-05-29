"""Silver layer - cleaned country.

Reads the bronze country table, snake_cases the columns,
and outputs a clean table that will be used by the gold dim_country.
"""

from pyspark import pipelines as dp

from utils.utils import rename_columns_to_snake_case


@dp.table(
    name="marathos.silver.countries",
    comment="Cleaned country code (BONUS)",
    table_properties={
        "delta.columnMapping.mode": "name",
        "delta.minReaderVersion": "2",
        "delta.minWriterVersion": "5",
    },
)
def countries():
    df = spark.readStream.table("marathos.bronze.raw_countries")
    df = rename_columns_to_snake_case(df)
    return df.select("country_code", "country_name", "continent")
    