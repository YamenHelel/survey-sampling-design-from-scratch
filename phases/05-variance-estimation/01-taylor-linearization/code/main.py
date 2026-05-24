# ============================================================
# Lesson 5.1: Taylor Series Linearization from Scratch
# Python — No specialized survey packages
# ============================================================

import numpy as np
import pandas as pd
from scipy.special import expit, logit

np.random.seed(2024)

# --- Generate sample ---
H = 4
a_h = 20
b = 15

records = []
psu_counter = 0

for h in range(1, H + 1):
    stratum_rate = np.random.uniform(0.05, 0.25)
    for i in range(a_h):
        psu_counter += 1
        psu_rate = expit(logit(stratum_rate) + np.random.normal(0, 0.5))
        for j in range(b):
            lf = np.random.binomial(1, 0.65)
            unemp = np.random.binomial(1, psu_rate) if lf == 1 else 0
            records.append({
                'stratum': h, 'psu_id': psu_counter,
                'labor_force': lf, 'unemployed': unemp,
                'weight': 500.0
            })

df = pd.DataFrame(records)
print(f"Sample: {len(df)} obs, {H} strata, {psu_counter} PSUs")

# --- Ratio estimate ---
Y_hat = (df['weight'] * df['unemployed']).sum()
X_hat = (df['weight'] * df['labor_force']).sum()
R_hat = Y_hat / X_hat
print(f"\nUnemployment rate: {R_hat:.4f} ({R_hat*100:.1f}%)")

# --- Linearized residuals ---
df['e_i'] = df['unemployed'] - R_hat * df['labor_force']

# --- Taylor variance ---
var_taylor = 0.0

for h in range(1, H + 1):
    stratum = df[df['stratum'] == h]
    psus = stratum['psu_id'].unique()
    a = len(psus)

    z_hi = np.array([
        (stratum[stratum['psu_id'] == p]['weight'] *
         stratum[stratum['psu_id'] == p]['e_i']).sum()
        for p in psus
    ])

    z_bar = z_hi.mean()
    ss = np.sum((z_hi - z_bar) ** 2)
    var_taylor += (a / (a - 1)) * ss

var_R = var_taylor / X_hat ** 2
se_R = np.sqrt(var_R)
cv_R = se_R / R_hat * 100

print(f"\n--- Taylor Linearization ---")
print(f"  SE(R_hat) : {se_R:.6f}")
print(f"  CV        : {cv_R:.1f}%")
print(f"  95% CI    : [{R_hat - 1.96*se_R:.4f}, {R_hat + 1.96*se_R:.4f}]")

# Assertion: CV should be reasonable
assert cv_R < 30, f"CV too high: {cv_R}%"
print(f"\n[PASS] Variance estimation completed (CV={cv_R:.1f}%).")
