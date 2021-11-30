import bigints
from strutils import parse_int

const
    chunk_size = 16 # How many bytes in a block
    n = "9516311845790656153499716760847001433441357".init_big_int
    e = "65537".init_big_int
    d = "5617843187844953170308463622230283376298685".init_big_int

# Assert that no message can be larger than n
assert 2.init_big_int.pow(8 * chunk_size) - 1.init_big_int < n

type
    Block = array[chunk_size, byte]

proc to_big_int(b: Block): BigInt =
    for i in 0..<chunk_size:
        result += b[chunk_size-i-1].init_big_int * 2.init_big_int.pow(8 * i.int32)

proc from_big_int(big_int: BigInt): Block =
    var big_int = big_int
    for i in 0..<chunk_size:
        var r: BigInt
        (big_int, r) = big_int.divmod(2.init_big_int.pow(8))
        result[chunk_size-i-1] = r.to_string.parse_int.byte

proc pow_mod(base, exp, modulus: BigInt): BigInt =
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

echo pow_mod(12.init_big_int, 9.init_big_int, 10.init_big_int)
