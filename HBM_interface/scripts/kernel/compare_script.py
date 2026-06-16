import os
import sys

computed_dir = "computed"
correct_dir  = "test_vectors"

# allowed inputs: 2, 4, 7, 14, 29
if len(sys.argv) != 2:
    print("Usage: python compare.py <2|4|7|14|29>")
    sys.exit(1)

num_parts = int(sys.argv[1])

if num_parts not in [2, 4, 7, 14, 29]:
    print("Input must be one of: 2, 4, 7, 14, 29")
    sys.exit(1)

pairs = []

for ct_id in [0, 1]:
    for i in range(num_parts):
        pairs.append(
            (
                f"relin_ct{ct_id}_{i}.txt",
                f"relin_ct{ct_id}_{i}.txt"
            )
        )


def read_decimal_file(path):
    values = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if line == "":
                continue

            # Use base 16 because files contain hex values
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