"""Silver layer - cleaned one big table (OBT) of ultra-marathon results.

Invalid and implausible rows will be dropped, and outputs a flat, typed table. 
IDs like event_id, date_id will deliberately NOT be found nore created here -
it will be generated later with the dimensional model in mind,
therefore keeping silver a pure streaming cleaning step.
"""

from pyspark import pipelines as dp
from pyspark.sql.functions import col, coalesce, lit, split, to_date, when, round as spark_round

from utils.utils import (
    rename_columns_to_snake_case,
    parse_event_distance_value,
    parse_event_distance_unit,
    classify_event_type,
    parse_performance_to_seconds,
    parse_performance_to_km,
    is_valid_row,
    event_distance_in_km,
    event_time_in_hours,
    recompute_average_speed,
    is_plausible_speed,
)


@dp.table(
    name="marathos.silver.marathon_obt",
    comment="Cleaned ultra-marathon results - one big table",
    table_properties={
        "delta.columnMapping.mode": "name",
        "delta.minReaderVersion": "2",
        "delta.minWriterVersion": "5",
    },
)
def marathon_obt():
    df = spark.readStream.table("marathos.bronze.raw_marathon")
    df = rename_columns_to_snake_case(df)

    # Parse event distance/length into value, unit and type
    df = (
        df.withColumn("event_distance_value", parse_event_distance_value(col("event_distance_length")))
        .withColumn("event_distance_unit", parse_event_distance_unit(col("event_distance_length")))
        .withColumn("event_type", classify_event_type(col("event_distance_unit")))
    )

    # Parse performance: seconds for distance races, km for length races
    df = (
        df.withColumn(
            "performance_seconds",
            when(col("event_type") == "distance", parse_performance_to_seconds(col("athlete_performance"))),
        )
        .withColumn(
            "performance_km",
            when(col("event_type") == "length", parse_performance_to_km(col("athlete_performance"))),
        )
    )

    # Drops rows that fail the validity rule.. invalid units, mismatched performance
    df = df.filter(is_valid_row(col("event_type"), col("athlete_performance")))

    # Recompute average speed from cleaned distance and time, then drop implausible values
    df = (
        df.withColumn(
            "distance_km",
            event_distance_in_km(col("event_distance_unit"), col("event_distance_value"), col("performance_km")),
        )
        .withColumn(
            "time_h",
            event_time_in_hours(col("event_type"), col("performance_seconds"), col("event_distance_value")),
        )
        .withColumn("recomputed_speed_kmh", recompute_average_speed(col("distance_km"), col("time_h")))
    )
    df = df.filter(is_plausible_speed(col("recomputed_speed_kmh")))

    # Derived columns
    # Event start date and athlete age at the event
    df = (
        df.withColumn("event_start_date", to_date(split(col("event_dates"), "-").getItem(0), "d.M.yyyy"))
        .withColumn("athlete_year_of_birth", col("athlete_year_of_birth").try_cast("int"))
        .withColumn("age_at_event", (col("year_of_event") - col("athlete_year_of_birth")).try_cast("int"))
    )

    # Fill soft nulls so downstream grouping does not lose rows
    df = (
        df.withColumn("athlete_club", coalesce(col("athlete_club"), lit("unknown")))
        .withColumn("athlete_country", coalesce(col("athlete_country"), lit("unknown")))
        .withColumn("athlete_age_category", coalesce(col("athlete_age_category"), lit("unknown")))
    )

    # Round numeric columns for readability
    df = (
        df.withColumn("recomputed_speed_kmh", spark_round(col("recomputed_speed_kmh"), 2))
        .withColumn("performance_km", spark_round(col("performance_km"), 3))
        .withColumn("event_distance_value", spark_round(col("event_distance_value"), 3))
    )

    return df.select(
        # raw material for the gold dimensions
        "athlete_id",
        "event_name",
        "event_start_date",
        "year_of_event",
        # event attributes
        "event_distance_value",
        "event_distance_unit",
        "event_type",
        "event_number_of_finishers",
        # athlete attributes
        "athlete_gender",
        "athlete_country",
        "athlete_age_category",
        "athlete_club",
        "athlete_year_of_birth",
        "age_at_event",
        # performance (one of seconds/km is populated depending on event_type)
        "performance_seconds",
        "performance_km",
        "recomputed_speed_kmh",
        "athlete_average_speed",  # raw value -> transparency
    )
