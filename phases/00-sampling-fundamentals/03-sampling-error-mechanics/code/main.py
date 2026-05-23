# ============================================================
# Lesson 0.3: Sampling Error vs Non-Sampling Error Mechanics
# Python — From Scratch
# ============================================================

import numpy as np
import pandas as pd
from scipy.special import expit

np.random.seed(2024)

# --- Population setup ---
N = 200000
income = np.random.lognormal(mean=7.2, sigma=0.9, size=N)

# Non-response: higher income = more likely to respond
response_propensity = expit(-1.5 + 0.3 * (income - income.mean()) / income.std())

theta = np.mean(income)
print(f"True population mean: {theta:.2f}")

# --- Experiment ---
sample_sizes = [100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000]
B = 1000

print(f"\n{'n':>10} | {'Sampling RMSE':>14} | {'NR Bias':>14} | {'Total RMSE':>14}")
print("-" * 60)

prev_rmse = float('inf')
results = []

for n in sample_sizes:
    srs_est = np.zeros(B)
    nr_est = []

    for b in range(B):
        idx = np.random.choice(N, size=n, replace=False)

        # Scenario A: Full response
        srs_est[b] = np.mean(income[idx])

        # Scenario B: Non-response
        responds = np.random.binomial(1, response_propensity[idx])
        if responds.sum() > 0:
            nr_est.append(np.mean(income[idx[responds == 1]]))

    nr_est = np.array(nr_est)

    sampling_rmse = np.sqrt(np.mean((srs_est - theta)**2))
    nr_bias = abs(np.mean(nr_est) - theta)
    total_rmse = np.sqrt(np.mean((nr_est - theta)**2))

    print(f"{n:>10,} | {sampling_rmse:>14.2f} | {nr_bias:>14.2f} | {total_rmse:>14.2f}")

    results.append({
        'n': n, 'sampling_rmse': sampling_rmse,
        'nr_bias': nr_bias, 'total_rmse': total_rmse
    })

    assert sampling_rmse <= prev_rmse * 1.1, \
        f"Sampling RMSE should decrease: {sampling_rmse} vs {prev_rmse}"
    prev_rmse = sampling_rmse

print("\n[PASS] Sampling error decreases with n.")

biases = [r['nr_bias'] for r in results]
assert max(biases) / min(biases) < 3, "NR bias should be persistent"
print("[PASS] Non-response bias remains persistent across sample sizes.")

last = results[-1]
assert last['nr_bias'] > last['sampling_rmse'], \
    "At large n, bias should dominate"
print("[PASS] At large n, bias dominates total error.")

# ============================================================
# Production: Non-response pattern analysis
# ============================================================

N2 = 50000
n2 = 2000

population = pd.DataFrame({
    'id': range(N2),
    'income': np.random.lognormal(7.2, 0.9, N2),
    'age': np.random.randint(18, 76, N2),
    'urban': np.random.binomial(1, 0.6, N2)
})

sample_df = population.sample(n=n2, random_state=2024).copy()
sample_df['resp_prob'] = expit(-0.5 + 0.2 *
    (sample_df['income'] - sample_df['income'].mean()) /
    sample_df['income'].std())
sample_df['responded'] = np.random.binomial(1, sample_df['resp_prob'])

print(f"\nResponse rate: {sample_df['responded'].mean()*100:.1f}%")

resp = sample_df[sample_df['responded'] == 1]
non_resp = sample_df[sample_df['responded'] == 0]

print(f"\n{'Variable':<15} {'Respondents':>12} {'Non-Resp':>12} {'Difference':>12}")
print("-" * 55)
for col in ['income', 'age', 'urban']:
    r_mean = resp[col].mean()
    nr_mean = non_resp[col].mean()
    print(f"{col:<15} {r_mean:>12.2f} {nr_mean:>12.2f} {r_mean - nr_mean:>12.2f}")

true_mean = population['income'].mean()
naive_mean = resp['income'].mean()
print(f"\nTrue population mean : {true_mean:.2f}")
print(f"Naive (resp only)    : {naive_mean:.2f}")
print(f"Bias                 : {naive_mean - true_mean:.2f}")
