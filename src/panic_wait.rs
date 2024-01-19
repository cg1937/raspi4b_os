//! A panic handler that infinitely waits.

use crate::{cpu, println};
use core::panic::PanicInfo;

/// Stop immediately, if called a second time.
/// 在 panic 处理期间防止重入。通过原子布尔变量 PANIC_IN_PROGRESS，
/// 函数确保在 panic 处理进行期间不会再次触发 panic。
/// 这是在裸机或嵌入式系统中处理 panic 时一种常见的防御措施。
fn panic_prevent_reenter() {
    use core::sync::atomic::{AtomicBool, Ordering};

    #[cfg(not(target_arch = "aarch64"))]
    compile_error!("Add the target_arch to above's check if the following code is safe to use");

    static PANIC_IN_PROGRESS: AtomicBool = AtomicBool::new(false);

    if !PANIC_IN_PROGRESS.load(Ordering::Relaxed) {
        PANIC_IN_PROGRESS.store(true, Ordering::Relaxed);

        return;
    }

    cpu::wait_forever()
}

//--------------------------------------------------------------------------------------------------
// Private Code
//--------------------------------------------------------------------------------------------------

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    // Protect against panic infinite loops if any of the following code panics itself.
    panic_prevent_reenter();

    let (location, line, column) = match info.location() {
        Some(loc) => (loc.file(), loc.line(), loc.column()),
        _ => ("???", 0, 0),
    };

    println!(
        "Kernel panic!\n\n\
         Panic location:\n      File '{}', line {}, column {}\n\n\
         {}",
        location,
        line,
        column,
        info.message().unwrap_or(&format_args!("")),
    );

    cpu::wait_forever()
}
