import bigints
from strutils import parse_int
import pow_mod

const
    clear_block_size = 16 # How many bytes in a cleartext block
    cipher_block_size = 32 # How many bytes in a ciphertext block

    n = "9516311845790656153499716760847001433441357".init_big_int
    e = "65537".init_big_int
    d = "5617843187844953170308463622230283376298685".init_big_int

# Assert that no cleartext can be larger than n
assert 2.init_big_int.pow(8 * clear_block_size) - 1.init_big_int <= n

# Assert that all ciphertexts lower than n can fit in a block
assert 2.init_big_int.pow(8 * cipher_block_size) - 1.init_big_int >= n

type
    Block[L: static[int]] = array[L, byte]

proc block_to_int[L: static[int]](b: Block[L]): BigInt =
    for i in 0..<L:
        result += b[L-i-1].init_big_int * 2.init_big_int.pow(8 * i.int32)

proc int_to_block[L: static[int]](big_int: BigInt): Block[L] =
    var big_int = big_int
    for i in 0..<L:
        var r: BigInt
        (big_int, r) = big_int.divmod(2.init_big_int.pow(8))
        result[L-i-1] = r.to_string.parse_int.byte

func string_to_bytes(str: string): seq[byte] =
  @(str.to_open_array_byte(0, str.high))

func bytes_to_string(bytes: open_array[byte]): string =
  let length = bytes.len
  if length > 0:
    result = new_string(length)
    copy_mem(result.cstring, bytes[0].unsafe_addr, length)

proc bytes_to_blocks[L: static[int]](data: open_array[byte], padding_aware: bool): seq[Block[L]] =
    # Convert open array to a sequence so we can remove bytes as they're handled
    var data: seq[byte] = @data

    while true:
        var
            bloc: Block[L]
            last_i = -1

        # While the block isn't full and there is bytes to be added
        for i in 0..<min(L, data.len):
            bloc[i] = data[i]
            last_i = i

        # If didn't assign any byte to the block that means that the data length is a multiple of the block's size.
        # The choice is between adding a last block full of padding bytes or not.
        if last_i == -1 and not padding_aware:
            break

        if last_i < L - 1:
            # If the data didn't fill the block completely pad with:
            # https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS#5_and_PKCS#7
            let pad_with: byte = (L-data.len).byte
            for i in last_i+1..<L:
                bloc[i] = pad_with

            result.add bloc
            break
        else:
            # Otherwise remove the bytes from the head
            result.add bloc
            data = data[L..data.high]

proc blocks_to_bytes[L: static[int]](blocks: open_array[Block[L]], padding_aware: bool): seq[byte] =
    for bloc in blocks[0..<blocks.len-1]:
        for i in 0..<L:
            result.add bloc[i]

    if padding_aware:
        let last_block = blocks[^1]
        let padded_with = last_block[^1]

        for i in 0..<L.uint32-padded_with:
            result.add last_block[i]
    else:
        result.add blocks[blocks.high]

when defined(encoder):
    let m = stdin.read_all
    let blocks = bytes_to_blocks[clear_block_size](m.string_to_bytes, padding_aware=true)

    var encoded_blocks: seq[Block[cipher_block_size]]
    encoded_blocks.new_seq blocks.len

    for i in blocks.low..blocks.high:
        encoded_blocks[i] = blocks[i].block_to_int.pow_mod(d, n).int_to_block[:cipher_block_size]

    let c = blocks_to_bytes(encoded_blocks, padding_aware=false).bytes_to_string
    stdout.write c

when defined(decoder):
    let c = stdin.read_all
    let blocks = bytes_to_blocks[cipher_block_size](c.string_to_bytes, padding_aware=false)

    var decoded_blocks: seq[Block[clear_block_size]]
    decoded_blocks.new_seq blocks.len

    for i in blocks.low..blocks.high:
        decoded_blocks[i] = blocks[i].block_to_int.pow_mod(e, n).int_to_block[:clear_block_size]

    let m = blocks_to_bytes(decoded_blocks, padding_aware=true).bytes_to_string
    stdout.write m

when not defined(encoder) and not defined(decoder):
    static:
        echo "You should compile with either -d:encoder -d:decoder"
