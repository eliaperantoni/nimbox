import bigints
from strutils import parse_int

const
    block_size = 16 # How many bytes in a block
    n = "9516311845790656153499716760847001433441357".init_big_int
    e = "65537".init_big_int
    d = "5617843187844953170308463622230283376298685".init_big_int

# Assert that no message can be larger than n
assert 2.init_big_int.pow(8 * block_size) - 1.init_big_int < n

type
    Block = array[block_size, byte]

proc block_to_int(b: Block): BigInt =
    for i in 0..<block_size:
        result += b[block_size-i-1].init_big_int * 2.init_big_int.pow(8 * i.int32)

proc int_to_block(big_int: BigInt): Block =
    var big_int = big_int
    for i in 0..<block_size:
        var r: BigInt
        (big_int, r) = big_int.divmod(2.init_big_int.pow(8))
        result[block_size-i-1] = r.to_string.parse_int.byte

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

func string_to_bytes(str: string): seq[byte] =
  @(str.toOpenArrayByte(0, str.high))

func bytes_to_string(bytes: open_array[byte]): string =
  let length = bytes.len
  if length > 0:
    result = new_string(length)
    copy_mem(result.cstring, bytes[0].unsafe_addr, length)

proc bytes_to_blocks(data: open_array[byte], padding_aware: bool): seq[Block] =
    # Convert open array to a sequence so we can remove bytes as they're handled
    var data: seq[byte] = @data

    while true:
        var
            bloc: Block
            last_i = -1

        # While the block isn't full and there is bytes to be added
        for i in 0..<min(block_size, data.len):
            bloc[i] = data[i]
            last_i = i

        # If didn't assign any byte to the block that means that the data length is a multiple of the block's size.
        # The choice is between adding a last block full of padding bytes or not.
        if last_i == -1 and not padding_aware:
            break

        if last_i < block_size - 1:
            # If the data didn't fill the block completely pad with:
            # https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS#5_and_PKCS#7
            let pad_with: byte = (block_size-data.len).byte
            for i in last_i+1..<block_size:
                bloc[i] = pad_with

            result.add bloc
            break
        else:
            # Otherwise remove the bytes from the head
            result.add bloc
            data = data[block_size..data.high]

proc blocks_to_bytes(blocks: open_array[Block], padding_aware: bool): seq[byte] =
    for bloc in blocks[0..<blocks.len-1]:
        for i in 0..<block_size:
            result.add bloc[i]

    if padding_aware:
        let last_block = blocks[^1]
        let padded_with = last_block[^1]

        for i in 0..<block_size.uint32-padded_with:
            result.add last_block[i]
    else:
        result.add blocks[blocks.high]

when defined(encoder):
    let m = stdin.read_line
    let blocks = bytes_to_blocks(m.string_to_bytes, padding_aware=true)

    var encoded_blocks: seq[Block]
    encoded_blocks.new_seq blocks.len

    for i in blocks.low..blocks.high:
        echo blocks[i]
        echo blocks[i].block_to_int
        echo blocks[i].block_to_int.int_to_block

        echo blocks[i].block_to_int
        echo blocks[i].block_to_int.pow_mod(d, n).int_to_block.block_to_int.pow_mod(e, n)

        encoded_blocks[i] = blocks[i].block_to_int.pow_mod(d, n).int_to_block

    let c = blocks_to_bytes(encoded_blocks, padding_aware=false).bytes_to_string
    stdout.write c

when defined(decoder):
    let c = stdin.read_line
    let blocks = bytes_to_blocks(c.string_to_bytes, padding_aware=false)

    var decoded_blocks: seq[Block]
    decoded_blocks.new_seq blocks.len

    for i in blocks.low..blocks.high:
        decoded_blocks[i] = blocks[i].block_to_int.pow_mod(e, n).int_to_block

    echo decoded_blocks

    let m = blocks_to_bytes(decoded_blocks, padding_aware=true).bytes_to_string
    stdout.write m

when not defined(encoder) and not defined(decoder):
    static:
        echo "You should compile with either -d:encoder -d:decoder"
