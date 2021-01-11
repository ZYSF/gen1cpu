# Modes

## Mode Switching

Generally speaking, there are two basic modes of operation:

 * User mode (a protected mode for running applications)
 * System mode (an unprotected mode for initialisation and system functions)

The mode is specified by the flags, but these can't be changed directly (at least without creating a heap of nasty edge cases).

Besides the user-mode/system-mode flag there are also flags to enable/disable exceptions, and there can be other kinds of modes indicated by the flags as well (for example, a mode advanced chip could use these to enable/disable caching or other functionality).

Regardless of which modes are supported, there are exactly three scenarios in which mode switching occurs:

 1. At reset, the mode flags are initialised to sane values (it will be operating in system mode, with interrupts disabled)
 2. Manually using a `before` (0xB4) instruction (which generally "returns from a system call" but might otherwise be used just to jump to a different mode)
 3. When an exception occurs (which is either triggered by an invalid or misbehaving instruction, or by a timer/bus/IO device)

## Exceptions

The exception number (and the address at which the exception occurred) can be determined from the control registers.

### EXCN_BADDOG (1)

Unable to fetch instruction (i.e. bad instruction address or fatal bus error).

### EXCN_INVALIDINSTR (2)

Instruction was fetched but not recognised as valid by the decoder.

### EXCN_SYSMODEINSTR (3)

Instruction was fetched and could presumably be decoded, but requires system mode and was run in user mode.

### EXCN_BUSERROR	(4)

The instruction was fetched/decoded but the memory or extension I/O triggered a bus exception.

### EXCN_REGISTERERROR (6)

The instruction was fetched/decoded but referred to a register which was unimplemented or blocked.

### EXCN_ALUERROR (7)

The instruction was fetched/decoded but the ALU operation triggered an error (e.g. bad operation or division by zero).

### EXCN_RESERVED (8)

This exception number is reserved for system calls (which would currently trigger an EXCN_INVALIDINSTR).

### EXCN_DINGDONG (9)

This exception is triggered by the internal timer unit (if enabled) i.e. for multitasking or other regular checks.

### EXCN_HARDWARE (10)

This exception is triggered by external hardware, typically an interrupt controller (which should have it's own mechanism for interrupt numbers).
