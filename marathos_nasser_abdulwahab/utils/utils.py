"""Utility functions for the Marathos ETL pipeline."""
import re

def to_snake_case(name):

    # Replace slashes (+ other separators) with a space first so they get,
    # collapsed with the rest of the whitespace handling
    name = re.sub(r"[/\\]", " ", name)
    return re.sub(r"\s+", "_", name.strip().casefold())


def rename_columns_to_snake_case(df):
    """Returning a new DF (DataFrame) with all column names rewritten in snake_case."""
    new_columns = [to_snake_case(column) for column in df.columns]
    return df.toDF(*new_columns)