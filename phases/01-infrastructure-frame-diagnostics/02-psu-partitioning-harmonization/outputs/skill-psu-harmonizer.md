---
name: skill-psu-harmonizer
description: Reusable PSU harmonization engine that splits oversized and merges undersized EAs within geographic constraints
version: 1.0.0
phase: 1
lesson: 2
tags: [psu, harmonization, splitting, merging, enumeration-area]
---

# Skill: PSU Harmonizer

## What It Does

Harmonizes PSU sizes by splitting oversized EAs and merging undersized ones within geographic groupings. Preserves total household count and reduces size variability.

## Python Implementation

```python
import pandas as pd
import numpy as np


def harmonize_psus(ea_frame: pd.DataFrame,
                   size_col: str = 'n_hh',
                   geo_col: str = 'dist_id',
                   id_col: str = 'ea_id',
                   m_min: int = 80,
                   m_max: int = 150,
                   m_target: int = 110) -> pd.DataFrame:
    """
    Harmonize PSU sizes by splitting oversized and merging undersized EAs.

    Parameters
    ----------
    ea_frame : DataFrame with EA-level data
    size_col : column containing household counts
    geo_col  : column for geographic grouping (merges within same group)
    id_col   : EA identifier column
    m_min    : minimum acceptable PSU size
    m_max    : maximum acceptable PSU size
    m_target : target PSU size for splitting

    Returns
    -------
    DataFrame with harmonized PSUs
    """
    total_hh_before = ea_frame[size_col].sum()

    # Step 1: Split
    records = []
    for _, row in ea_frame.iterrows():
        if row[size_col] > m_max:
            k = int(np.ceil(row[size_col] / m_target))
            base = row[size_col] // k
            rem = row[size_col] - base * k
            for j in range(k):
                records.append({
                    'psu_id': f"{row[id_col]}_S{j+1}",
                    geo_col: row[geo_col],
                    size_col: base + (1 if j < rem else 0)
                })
        else:
            records.append({
                'psu_id': row[id_col],
                geo_col: row[geo_col],
                size_col: row[size_col]
            })

    psus = pd.DataFrame(records)
    psus['active'] = True

    # Step 2: Merge within geography
    for geo in psus[geo_col].unique():
        geo_mask = (psus[geo_col] == geo) & psus['active']
        while True:
            undersized = psus.index[geo_mask & (psus[size_col] < m_min)]
            if len(undersized) == 0:
                break
            curr = undersized[0]
            cands = psus.index[
                geo_mask & (psus.index != curr) &
                (psus[size_col] + psus.loc[curr, size_col] <= m_max * 1.2)
            ]
            if len(cands) == 0:
                break
            combined = psus.loc[cands, size_col] + psus.loc[curr, size_col]
            best = cands[np.abs(combined - m_target).argmin()]
            psus.loc[best, size_col] += psus.loc[curr, size_col]
            psus.loc[best, 'psu_id'] += f"+{psus.loc[curr, 'psu_id']}"
            psus.loc[curr, 'active'] = False
            geo_mask = (psus[geo_col] == geo) & psus['active']

    result = psus[psus['active']].drop(columns=['active']).reset_index(drop=True)

    # Verify
    assert result[size_col].sum() == total_hh_before, "HH count mismatch!"
    return result
```

## Usage

```python
# harmonized = harmonize_psus(ea_frame, size_col='n_hh', geo_col='dist_id')
# print(f"PSUs: {len(ea_frame)} -> {len(harmonized)}")
# print(f"CV: {harmonized['n_hh'].std()/harmonized['n_hh'].mean()*100:.1f}%")
```
