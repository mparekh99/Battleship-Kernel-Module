# Battleship Kernel Module

## Introduction

I attempted to implemented the game **"Battleship"** as a character device driver. The game involves generating a random board (optionally customizable by the user for size and number of battleships) where the player interacts by inputting cell numbers. The driver returns whether the player's shot is a "hit," "miss," or if they have "sunk" an enemy battleship. The player can also:

- Check previous moves via **lseek**.
- Create a new board with different parameters using **ioctl**.
- Receive a victory message once all ships are sunk.

In case of errors, the driver will return the appropriate error value (negative). The module doesn't support concurrency.

This implementation is based on inspiration from Hila's and Andrey's document, and it follows the system call specifications outlined below.

---

## Syscall Specification

### `open(2)`
- **Description**: Returns a file descriptor associated with the device driver.
- **Behavior**: On success, returns a file descriptor with the offset pointing to the last written byte. A player can read from the file and receive the result of the last move.
- **Parameters**:
  - `const char *pathname`: Path to the device driver.
  - `int flags`: Mode for opening the file.
- **Returns**: File descriptor on success, or an error value on failure.
- **Failure Modes**:
  - `'EACCES'`: Access to the file is not allowed.
  - `'EINVAL'`: Invalid value in flags.

### `close(2)`
- **Description**: Closes the file associated with the given file descriptor without changing the internal state.
- **Behavior**: Closes the file in the process's file descriptor table.
- **Parameters**: `int fd`: File descriptor to close.
- **Returns**: `0` on success, or an error value on failure.
- **Failure Modes**:
  - `'EBADF'`: Invalid file descriptor.

### `read(2)`
- **Description**: Reads up to `count` bytes from the file descriptor `fd` into the buffer, starting at `buf`. Reads the player’s move and the result.
- **Behavior**: Attempts to read `count` bytes into a buffer. Moves and results are returned in the format `(xx,yy):r` where `r` is the result (`h` for hit, `m` for miss, `s` for sunk).
- **Parameters**:
  - `int fd`: File descriptor.
  - `void *buf`: Pointer to the buffer.
  - `int count`: Number of bytes to read (9 bytes per move).
- **Returns**: Number of bytes read on success, or an error value on failure.
- **Failure Modes**:
  - `'EBADF'`: Invalid file descriptor.
  - `'EFAULT'`: Buffer is outside accessible address space.
  - `'EINVAL'`: Invalid parameters.
  
### `write(2)`
- **Description**: Writes the player's move to the file referred by the file descriptor `fd`.
- **Behavior**: The user writes a valid move (7 bytes) in the form `(xx,yy)`. If the move is valid, the result is stored and can be read later.
- **Parameters**:
  - `int fd`: File descriptor.
  - `void *buf`: Pointer to the buffer containing the move.
  - `int count`: Number of bytes to write (7 bytes per move).
- **Returns**: Number of moves successfully written on success, or an error value on failure.
- **Failure Modes**:
  - `'EBADF'`: Invalid file descriptor.
  - `'EFAULT'`: Buffer is outside accessible address space.
  - `'EINVAL'`: Invalid move format or out-of-bound coordinates.
  
### `lseek(2)`
- **Description**: Repositions the read file offset.
- **Behavior**: Changes the file offset based on the directive (`SEEK_SET`, `SEEK_CUR`, or `SEEK_END`).
- **Parameters**:
  - `int fd`: File descriptor.
  - `off_t offset`: Number of bytes to offset by.
  - `int whence`: Directive indicating how the offset is applied.
- **Returns**: New file offset on success, or an error value on failure.
- **Failure Modes**:
  - `'EBADF'`: Invalid file descriptor.
  - `'EINVAL'`: Invalid offset or whence value.
  
### `ioctl(2)`
- **Description**: Controls the device, used to re-create the game with different parameters or to perform undo/redo operations.
- **Behavior**: Recreates the board based on new parameters (board size and number of ships). Ships cannot overlap, and the number of ships cannot exceed the number of cells on the board.
- **Parameters**:
  - `int fd`: File descriptor.
  - `int board_size`: Size of the board (a square with size `board_size * board_size`).
  - `int ships`: Number of ships.
- **Returns**: `0` on success, `-1` on failure.
- **Failure Modes**:
  - `'EBADF'`: Invalid file descriptor.
  - `'EINVAL'`: Invalid board size or number of ships.

---

## Resource Lifecycle

### Initialization:
- Upon initialization, a 20x20 board is allocated with a random ship location. The board and any moves performed on it are persistent, even across open/close operations.

### Termination:
- Upon termination (via `exit()` or `release()`), all resources are released.

---

## Example Usage

A legal sequence of writes can be: (1,1)(1,2)(1,3)

A corresponding sequence of reads could be: (1,1)h,(1,2)h,(1,3)s



This sequence shows a horizontal ship that was sunk in three moves.

---

## Development Process

### Git Patches:
During the development of this kernel module, I practiced creating **Git patches** to effectively manage changes in the codebase. I regularly used Git to track changes and create patches, allowing for clear, organized development and easy collaboration.

### Test-Driven Development (TDD):
To ensure my syscall functions met the given specifications, I employed **Test-Driven Development (TDD)**. I began by writing tests that specified how each syscall should behave according to the provided requirements. After writing each test, I implemented the corresponding function in the kernel module to pass the test. This iterative process ensured correctness and helped me catch issues early.

### Testing:
I used the provided test file to validate my implementation of each syscall. The tests covered various scenarios like invalid moves, board size changes, and ensuring that file offsets were correctly adjusted after reading/writing moves. This robust testing approach helped ensure that the game functionality was implemented correctly and efficiently.

---

## Conclusion

This Battleship Kernel Module is a semi-functional implementation of the classic game, leveraging kernel programming and syscalls to simulate the game mechanics. It demonstrates a solid understanding of Linux kernel development and the ability to design, implement, and test system calls effectively.

