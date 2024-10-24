A = []
B = []

TP = 32

with open('/home/berenaydogan/Desktop/Project/Simulation/A.txt', 'r') as file:
    for line in file:
        hex_line = line.strip()
        A.append(int(hex_line, 16))

with open('/home/berenaydogan/Desktop/Project/Simulation/B.txt', 'r') as file:
    for line in file:
        hex_line = line.strip()
        B.append(int(hex_line, 16))

num_elements_A = len(A)
num_elements_B = len(B)

min_num_elements = min(num_elements_A, num_elements_B);

num_TP = min_num_elements // TP
num_elements_C = num_TP * TP

with open('/home/berenaydogan/Desktop/Project/Simulation/q.txt', 'r') as file:
    content = file.read().strip()
    q = int(content, 16)

T = pow(2, -68, q) 

C = []

for i in range(num_elements_C): 
    res = hex((A[i] * B[i] * T) % q)
    C.append(res)

with open('/home/berenaydogan/Desktop/Project/Simulation/python_results.txt', 'w') as file:
    for num in C:
        hex_value = num[2:] 
        file.write(hex_value + '\n') 
