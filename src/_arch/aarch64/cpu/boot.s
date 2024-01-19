// 将一个符号地址加载到指定寄存器中
.macro ADR_REL register, symbol
	adrp	\register, \symbol
	add	\register, \register, #:lo12:\symbol
.endm


.section .text._start

//------------------------------------------------------------------------------
// fn _start() kernel entry
//------------------------------------------------------------------------------
_start:
	// Only proceed on the boot core. Park it otherwise.
	mrs x0, MPIDR_EL1        // 读取当前核心的 ID 寄存器值到 x0
	and x0, x0, {CONST_CORE_ID_MASK} // 使用位掩码过滤出核心 ID
	ldr x1, BOOT_CORE_ID      // 从地址 BOOT_CORE_ID 加载期望的引导核心 ID 到 x1
	cmp x0, x1                // 比较当前核心 ID 与期望的引导核心 ID
	b.ne .L_parking_loop      // 如果不相等，跳转到 .L_parking_loop


	// If execution reaches here, it is the boot core.

	// Initialize DRAM.
	ADR_REL	x0, __bss_start
	ADR_REL x1, __bss_end_exclusive

// 循环为bss段填充0，然后跳掉下一个标签
.L_bss_init_loop:
    cmp x0, x1              // 比较 x0 和 x1 寄存器的值
    b.eq .L_prepare_rust    // 如果相等，跳转到 .L_prepare_rust 标签
    stp xzr, xzr, [x0], #16 // 将 xzr 寄存器的值存储到 x0 地址，然后 x0 加上 16
    b .L_bss_init_loop      // 无条件跳转回 .L_bss_init_loop 标签


// Prepare the jump to Rust code.
.L_prepare_rust:
    // Set the stack pointer.
    ADR_REL x0, __boot_core_stack_end_exclusive // 将 __boot_core_stack_end_exclusive 符号的地址加载到 x0
    mov sp, x0                                  // 将 x0 的值设置为栈指针寄存器 sp

    // Jump to Rust code.
    b _start_rust                                // 无条件跳转到 _start_rust 标签

	// Infinitely wait for events (aka "park the core").
.L_parking_loop:
    // wfe：aarch64 instruction[wait for event]
	wfe
	b	.L_parking_loop

// 告诉链接器 _start 的大小是从 _start 标签开始到当前位置的地址差。
.size	_start, . - _start
.type	_start, function
.global	_start
