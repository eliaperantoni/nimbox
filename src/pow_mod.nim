import bigints

proc pow_mod*(base, exp, modulus: BigInt): BigInt =
    result = 1.init_big_int

    var
        n = base
        exp = exp

    while exp > 0.init_big_int:
        if (exp and 1.init_big_int) != 0.init_big_int:
            result *= n
        n = (n * n) mod modulus
        exp = exp shr 1

    result = result mod modulus
