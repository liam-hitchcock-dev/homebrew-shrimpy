import AppKit
import Darwin

// MARK: - Terminal Detection

func parentPID(of pid: pid_t) -> pid_t {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
    let result = sysctl(&mib, 4, &info, &size, nil, 0)
    if result == 0 {
        return info.kp_eproc.e_ppid
    }
    return -1
}

func detectTerminalBundleID() -> String? {
    var pid = getppid()
    while pid > 1 {
        if let app = NSRunningApplication(processIdentifier: pid),
           let bundleID = app.bundleIdentifier,
           kTerminalBundleIDs.contains(bundleID) {
            return bundleID
        }
        pid = parentPID(of: pid)
    }
    return nil
}
