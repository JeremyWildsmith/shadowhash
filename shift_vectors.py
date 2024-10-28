
def password_shift_right_vectors():
    print("Nx.tensor([")
    for s in range(150):
        d = [((w - s) + 149) % 149 + 1 for w in range(149)]
        print("[0, " + ",".join([str(w) for w in d]) + "],")

    print("], type: {:u, 8})")
    
def m32b_shift_right_vectors():
    print("Nx.tensor([")
    for s in range(256):
        d = [((w - s) + 256) % 256 for w in range(256)]
        print("[" + ",".join([str(w) for w in d]) + "],")

    print("], type: {:u, 8})")

m32b_shift_right_vectors()