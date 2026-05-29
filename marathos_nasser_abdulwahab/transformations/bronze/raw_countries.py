"""Bronze layer - BONUS raw ingestion of country codes.

Source: LLM-generated CSV with IOC 3-letter codes mapped to country names
and continents, uploaded to /Volumes/marathos/default/raw/countries/.
Streaming ingestion, similar pattern as raw_marathon.
"""

from pyspark import pipelines as dp

BASE_DIR = "/Volumes/marathos/default/raw"

schema = (
    spark.read.format("csv")
    .options(header=True, inferSchema=True)
    .load(f"{BASE_DIR}/countries/country_codes.csv")
    .schema
)


@dp.table(
    name="marathos.bronze.raw_countries",
    comment="Raw country codes (IOC 3-letter) and country names",
    table_properties={
        "delta.columnMapping.mode": "name",
        "delta.minReaderVersion": "2",
        "delta.minWriterVersion": "5",
    },
)
def raw_countries():
    return (
        spark.readStream.format("csv")
        .options(header=True, encoding="UTF-8")
        .schema(schema)
        .load(f"{BASE_DIR}/countries")
    )
