# NimBox

A collection of toys written in the glorious [Nim](https://nim-lang.org/) programming language.

---

## RSA

The same source file can be compiled to two different binaries: one encrypts and the other decrypts.

Either will:
1. Read a sequence of bytes from standard input
2. Chop it up into blocks of static length
3. Apply the exponentiation
4. Convert the resulting blocks back to a sequence of bytes
5. Write the encrypted bytes to standard output

[PKCS#7](https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS#5_and_PKCS#7) is used for padding blocks.

The public and private keys are hardcoded in `src/rsa.nim`.

It is worth mentioning that blocks of cleartext are 16 bytes long while blocks of ciphertext are 32 bytes long. This
means that encrypted files take double the space (ouch!).

The reason for this is (assuming `N=PQ`):
+ Cleartext blocks have to be small because their integer representation must always be smaller than `N` for the
decryption process to work
+ Ciphertext blocks have to be large because their integer representation must be able to host any number resulting
from the exponentiation modulo `N`

### Building

```shell
$ nimble build -d:encoder -d:release rsa
$ mv rsa encode
$ nimble build -d:decoder -d:release rsa
$ mv rsa decode
```

### Usage

```shell
$ cat clear_file | ./encode > encrypted_file
$ cat encrypted_file | ./decode > decrypted_file
# Shouldn't output anything
$ diff clear_file decrypted_file
```
