import os

computed_dir = "computed"
correct_dir  = "correct_results"

pairs = [
    ("ct0_rl_0.txt", "relin_ct0_0.txt"),
    ("ct0_rl_1.txt", "relin_ct0_1.txt"),
    ("ct1_rl_0.txt", "relin_ct1_0.txt"),
    ("ct1_rl_1.txt", "relin_ct1_1.txt"),
]

def read_decimal_file(path):
    values = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if line == "":
                continue
            # force base-10 interpretation
            values.append(int(line, 16))
    return values


for comp_name, corr_name in pairs:
    comp_path = os.path.join(computed_dir, comp_name)
    corr_path = os.path.join(correct_dir, corr_name)

    comp_vals = read_decimal_file(comp_path)
    corr_vals = read_decimal_file(corr_path)

    print(f"\n=== Comparing {comp_name}  <->  {corr_name} ===")

    if len(comp_vals) != len(corr_vals):
        print(f"[SIZE MISMATCH] computed={len(comp_vals)} correct={len(corr_vals)}")

    mismatch = False
    for i, (a, b) in enumerate(zip(comp_vals, corr_vals)):
        if a != b:
            print(f"[FAIL] index {i}")
            print(f"  computed = {a}")
            print(f"  correct  = {b}")
            print(f"  diff     = {a - b}")
            mismatch = True
            break

    if not mismatch:
        print("[OK] All values match ✅")
