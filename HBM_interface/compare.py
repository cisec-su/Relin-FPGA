file1 = "/home/cisec/emre/relin_new/HBM_interface/scripts/kernel/test_vectors/ct2_1.txt"
file2 = "/home/cisec/emre/relin_new/HBM_interface/scripts/kernel/kernel_4096_I_64_readback_1.txt"

def compare_hex_files(f1, f2):
    with open(f1) as a, open(f2) as b:
        lines1 = a.readlines()
        lines2 = b.readlines()

    n = min(len(lines1), len(lines2))

    mismatch = False

    for i in range(n):
        try:
            v1 = int(lines1[i].strip(), 16)
            v2 = int(lines2[i].strip(), 16)
        except ValueError:
            print(f"[ERROR] Line {i}: invalid hex")
            mismatch = True
            continue

        if v1 != v2:
            mismatch = True
            print(f"[FAIL] line {i}")
            print(f"  file1 hex = {lines1[i].strip()} ({v1})")
            print(f"  file2 hex = {lines2[i].strip()} ({v2})")
            print(f"  diff      = {v1 - v2}")
        else:
            print(f"[OK] line {i}: {v1}")

    if len(lines1) != len(lines2):
        print(f"[WARN] Different file lengths: {len(lines1)} vs {len(lines2)}")

    if not mismatch:
        print("\n✅ All values match!")
    else:
        print("\n❌ Differences detected.")


compare_hex_files(file1, file2)

print("aa")