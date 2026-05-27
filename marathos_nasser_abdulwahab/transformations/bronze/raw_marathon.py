"""Bronze layer - raw ingestion of the ultra-marathon dataset."""

from pyspark import pipelines as dp

BASE_DIR = "/Volumes/marathos/default/raw"

# Inferring schema from a single read of the data
schema = (
    spark.read.format("csv")
    .options(header=True, inferSchema=True)
    .load(f"{BASE_DIR}/data/TWO_CENTURIES_OF_UM_RACES.csv")
    .schema
)


@dp.table(
    name="marathos.bronze.raw_marathon",
    comment="Raw ultra-marathon race records (1798-2022, ~7M rows)",
    table_properties={
        # column mapping lets us keep names like 'Event distance/length' until we
        # rename them in later layers
        "delta.columnMapping.mode": "name",
        "delta.minReaderVersion": "2",
        "delta.minWriterVersion": "5",
    },
)
def raw_marathon():
    return (
        spark.readStream.format("csv")
        .options(header=True, encoding="UTF-8")
        .schema(schema)
        .load(f"{BASE_DIR}/data")
    )
