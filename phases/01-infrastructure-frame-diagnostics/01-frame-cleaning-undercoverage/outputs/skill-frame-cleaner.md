---
name: skill-frame-cleaner
description: Automated census frame cleaning pipeline with deduplication, out-of-scope removal, imputation, and coverage checks
version: 1.0.0
phase: 1
lesson: 1
tags: [frame-cleaning, deduplication, undercoverage, imputation, coverage]
---

# Skill: Frame Cleaner

## What It Does

Automated pipeline for cleaning census sampling frames. Handles deduplication, out-of-scope removal, missing value imputation, and coverage diagnostics against external population totals.

## Python Implementation

```python
import pandas as pd
import numpy as np
from datetime import datetime


class FrameCleaner:
    """Automated census frame cleaning pipeline."""

    def __init__(self, frame: pd.DataFrame):
        self.raw_frame = frame.copy()
        self.frame = frame.copy()
        self.log = []
        self._log(f"Pipeline initialized with {len(frame):,} records")

    def _log(self, message: str):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log.append(f"[{timestamp}] {message}")

    def deduplicate(self, key_columns: list) -> 'FrameCleaner':
        before = len(self.frame)
        self.frame = self.frame.drop_duplicates(
            subset=key_columns, keep='first'
        )
        removed = before - len(self.frame)
        self._log(f"Deduplication: {removed:,} duplicates removed "
                  f"(keys: {key_columns})")
        return self

    def remove_out_of_scope(self, status_col: str = 'status',
                            valid_status: str = 'Occupied') -> 'FrameCleaner':
        before = len(self.frame)
        mask = self.frame[status_col] == valid_status
        removed_statuses = self.frame[~mask][status_col].value_counts()
        self.frame = self.frame[mask]
        removed = before - len(self.frame)
        self._log(f"Out-of-scope: {removed:,} records removed")
        for status, count in removed_statuses.items():
            self._log(f"  - {status}: {count:,}")
        return self

    def impute_missing(self, columns: list,
                       group_col: str = None) -> 'FrameCleaner':
        for col in columns:
            n_missing = self.frame[col].isna().sum()
            if n_missing == 0:
                continue
            if group_col and group_col in self.frame.columns:
                self.frame[col] = self.frame.groupby(group_col)[col].transform(
                    lambda x: x.fillna(x.median())
                )
            else:
                self.frame[col] = self.frame[col].fillna(
                    self.frame[col].median()
                )
            self._log(f"Imputed {n_missing:,} missing values in '{col}'")
        return self

    def coverage_check(self, geo_col: str,
                       external_totals: dict) -> pd.DataFrame:
        frame_counts = self.frame.groupby(geo_col).size()
        results = []
        for geo, expected in external_totals.items():
            observed = frame_counts.get(geo, 0)
            coverage = observed / expected * 100 if expected > 0 else 0
            results.append({
                'geography': geo,
                'frame_count': observed,
                'external_count': expected,
                'coverage_pct': round(coverage, 1),
                'status': 'OK' if 90 <= coverage <= 110 else 'WARNING'
            })
        self._log("Coverage check completed")
        return pd.DataFrame(results)

    def report(self) -> str:
        lines = [
            "=" * 60,
            "  FRAME CLEANING REPORT",
            "=" * 60,
            f"  Original records : {len(self.raw_frame):>10,}",
            f"  Final records    : {len(self.frame):>10,}",
            f"  Records removed  : {len(self.raw_frame) - len(self.frame):>10,}",
            f"  Missing values   : {self.frame.isna().sum().sum():>10,}",
            "",
            "--- Pipeline Log ---"
        ]
        lines.extend(f"  {entry}" for entry in self.log)
        lines.append("=" * 60)
        return "\n".join(lines)


# --- Usage Example ---
# cleaner = FrameCleaner(raw_census_frame)
# cleaner.deduplicate(['gov_id', 'ea_id', 'hh_size', 'head_age'])
# cleaner.remove_out_of_scope()
# cleaner.impute_missing(['hh_size', 'head_age', 'hh_income'], group_col='gov_id')
# coverage = cleaner.coverage_check('gov_id', external_totals)
# print(cleaner.report())
# clean_frame = cleaner.frame
```
