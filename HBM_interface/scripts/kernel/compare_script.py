import os

computed_dir = "computed"
correct_dir  = "correct_results"

pairs = [
    ( "ct0_rl_0.txt", "relin_ct0_0.txt"),
    ( "ct0_rl_1.txt", "relin_ct0_1.txt"),
    ( "ct0_rl_2.txt", "relin_ct0_2.txt"),
    ( "ct0_rl_3.txt", "relin_ct0_3.txt"),
    ( "ct0_rl_4.txt", "relin_ct0_4.txt"),
    ( "ct0_rl_5.txt", "relin_ct0_5.txt"),
    ( "ct0_rl_6.txt", "relin_ct0_6.txt"),
    ( "ct0_rl_7.txt", "relin_ct0_7.txt"),
    ( "ct0_rl_8.txt", "relin_ct0_8.txt"),
    ( "ct0_rl_9.txt", "relin_ct0_9.txt"),
    ( "ct0_rl_10.txt", "relin_ct0_10.txt"),
    ( "ct0_rl_11.txt", "relin_ct0_11.txt"),
    ( "ct0_rl_12.txt", "relin_ct0_12.txt"),
    ( "ct0_rl_13.txt", "relin_ct0_13.txt"),
    ( "ct0_rl_14.txt", "relin_ct0_14.txt"),
    ( "ct0_rl_15.txt", "relin_ct0_15.txt"),
    ( "ct0_rl_16.txt", "relin_ct0_16.txt"),
    ( "ct0_rl_17.txt", "relin_ct0_17.txt"),
    ( "ct0_rl_18.txt", "relin_ct0_18.txt"),
    ( "ct0_rl_19.txt", "relin_ct0_19.txt"),
    ( "ct0_rl_20.txt", "relin_ct0_20.txt"),
    ( "ct0_rl_21.txt", "relin_ct0_21.txt"),
    ( "ct0_rl_22.txt", "relin_ct0_22.txt"),
    ( "ct0_rl_23.txt", "relin_ct0_23.txt"),
    ( "ct0_rl_24.txt", "relin_ct0_24.txt"),
    ( "ct0_rl_25.txt", "relin_ct0_25.txt"),
    ( "ct0_rl_26.txt", "relin_ct0_26.txt"),
    ( "ct0_rl_27.txt", "relin_ct0_27.txt"),
    ( "ct1_rl_0.txt", "relin_ct1_0.txt"),
    ( "ct1_rl_1.txt", "relin_ct1_1.txt"),
    ( "ct1_rl_2.txt", "relin_ct1_2.txt"),
    ( "ct1_rl_3.txt", "relin_ct1_3.txt"),
    ( "ct1_rl_4.txt", "relin_ct1_4.txt"),
    ( "ct1_rl_5.txt", "relin_ct1_5.txt"),
    ( "ct1_rl_6.txt", "relin_ct1_6.txt"),
    ( "ct1_rl_7.txt", "relin_ct1_7.txt"),
    ( "ct1_rl_8.txt", "relin_ct1_8.txt"),
    ( "ct1_rl_9.txt", "relin_ct1_9.txt"),
    ( "ct1_rl_10.txt", "relin_ct1_10.txt"),
    ( "ct1_rl_11.txt", "relin_ct1_11.txt"),
    ( "ct1_rl_12.txt", "relin_ct1_12.txt"),
    ( "ct1_rl_13.txt", "relin_ct1_13.txt"),
    ( "ct1_rl_14.txt", "relin_ct1_14.txt"),
    ( "ct1_rl_15.txt", "relin_ct1_15.txt"),
    ( "ct1_rl_16.txt", "relin_ct1_16.txt"),
    ( "ct1_rl_17.txt", "relin_ct1_17.txt"),
    ( "ct1_rl_18.txt", "relin_ct1_18.txt"),
    ( "ct1_rl_19.txt", "relin_ct1_19.txt"),
    ( "ct1_rl_20.txt", "relin_ct1_20.txt"),
    ( "ct1_rl_21.txt", "relin_ct1_21.txt"),
    ( "ct1_rl_22.txt", "relin_ct1_22.txt"),
    ( "ct1_rl_23.txt", "relin_ct1_23.txt"),
    ( "ct1_rl_24.txt", "relin_ct1_24.txt"),
    ( "ct1_rl_25.txt", "relin_ct1_25.txt"),
    ( "ct1_rl_26.txt", "relin_ct1_26.txt"),
    ( "ct1_rl_27.txt", "relin_ct1_27.txt")
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
