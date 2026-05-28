"""Utility functions for the Marathos ETL pipeline.

Further evaluations. Reusable helpers shared across the bronze, silver and gold layers. 
Defining each cleaning rule once here rather than later in the transformations with inlines.
Follows the principles and should keep the silver layer short and readable.
"""

import re

from pyspark.sql import Column
from pyspark.sql.functions import col, lower, regexp_extract, split, when


# 'Labbsnack' update + testing.
# 1 mile = 1.60934 km. Used to normalise 'mi' events to km.
MILES_TO_KM = 1.60934

# Plausible ultra-marathon average speed (km/h).
# Source: Scientific Reports (Nature) 100 km ultra study, recommended by LLM,
# also summarized its relevant points,
# examples that capped speed at 21 km/h to remove outliers.
# Link: (nature.com/articles/s41598-025-09502-0).
# The 100 km world record averages ~16.4 km/h, so 21 leaves head-room while
# filtering data-entry errors such as "10000 km/h".
MAX_PLAUSIBLE_SPEED_KMH = 21.0


# Short, concise comments, docstrings and necessary inlines are present,
# also type annotations are included for functions that call for it.


def to_snake_case(name):
    """Convert a column name to snake_case, handling whitespace and slashes.

    Example: 'Event distance/length' -> 'event_distance_length'
    """
    # Replaces slashes with a space
    name = re.sub(r"[/\\]", " ", name)
    return re.sub(r"\s+", "_", name.strip().casefold())


def rename_columns_to_snake_case(df):
    """Returning a new DF (DataFrame) with all column names rewritten in snake_case."""
    new_columns = [to_snake_case(column) for column in df.columns]
    return df.toDF(*new_columns)


def parse_event_distance_value(distance_col: Column) -> Column:
    """Extract the numeric value from a string like '50km' -> 50.0."""
    return regexp_extract(distance_col, r"^([0-9.]+)", 1).cast("double")


def parse_event_distance_unit(distance_col: Column) -> Column:
    """Extract the lowercased unit from a string like '50km' -> 'km'."""
    return lower(regexp_extract(distance_col, r"([a-zA-Z]+)$", 1))


def classify_event_type(unit_col: Column) -> Column:
    """Map the event unit to a type.

    km/mi -> 'distance', h -> 'length', anything else -> 'invalid' and should be dropped downstream.
    """
    return (
        when(unit_col.isin("km", "mi"), "distance")
        .when(unit_col == "h", "length")
        .otherwise("invalid")
    )


def parse_performance_to_seconds(performance_col: Column) -> Column:
    """Convert a time like '8:30:49 h' into total seconds (for distance races)."""
    parts = split(performance_col, ":")
    return (
        parts.getItem(0).cast("int") * 3600
        + parts.getItem(1).cast("int") * 60
        # last segment still carries the ' h' suffix, strip it
        + split(parts.getItem(2), " ").getItem(0).cast("int")
    )


def parse_performance_to_km(performance_col: Column) -> Column:
    """Extract the km value from a distance like '250.5 km' (for length races)."""
    return regexp_extract(performance_col, r"([0-9.]+)", 1).cast("double")


def is_valid_row(event_type_col: Column, performance_col: Column) -> Column:
    """Check that the performance unit actually matches the event type.

    distance race -> performance must be a time ('h'); length race ->
    performance must be a distance ('km'). Everything else, invalid.
    """
    return (
        (event_type_col == "distance") & performance_col.rlike(r"\bh\b")
    ) | (
        (event_type_col == "length") & performance_col.rlike(r"\bkm\b")
    )


def event_distance_in_km(unit_col: Column, value_col: Column, performance_km_col: Column) -> Column:
    """Return the race distance in km regardless of event type.

    km -> value as-is, mi -> value converted to km, h -> the performance (km).
    """
    return (
        when(unit_col == "km", value_col)
        .when(unit_col == "mi", value_col * MILES_TO_KM)
        .when(unit_col == "h", performance_km_col)
    )


def event_time_in_hours(event_type_col: Column, performance_seconds_col: Column, value_col: Column) -> Column:
    """Return the race time in hours regardless of event type.

    distance race -> performance seconds to hours, length race -> event length.
    """
    return (
        when(event_type_col == "distance", performance_seconds_col / 3600.0)
        .when(event_type_col == "length", value_col)
    )


def recompute_average_speed(distance_km_col: Column, time_h_col: Column) -> Column:
    """Recompute average speed (km/h) from distance and time.

    The raw athlete_average_speed has plenty of bad values, so it is recomputed from cleaned inputs. 
    Division by zero should return null and is filtered downstream.
    """
    return when(time_h_col > 0, distance_km_col / time_h_col)


def is_plausible_speed(speed_col: Column) -> Column:
    """True when a recomputed speed is within 0, MAX_PLAUSIBLE_SPEED_KMH."""
    return (speed_col > 0) & (speed_col <= MAX_PLAUSIBLE_SPEED_KMH)
