#!/usr/bin/env python3
"""Run a Beef test project under AddressSanitizer/LeakSanitizer (Linux).

The Linux libBeefRT_d.a ships without BF_GC_SUPPORTED, so Beef objects are
allocated with plain malloc and the runtime's own leak checker is compiled
out: a Linux test run reports no leaks at all, and the leaks the Windows
runtime does report come without an allocation stack.

LD_PRELOADing the ASan runtime fills both gaps, because LeakSanitizer only
needs the malloc/free interception, not instrumented code.  BeefBuild itself
cannot be preloaded (ASan aborts on pre-existing faults inside the Beef
compiler), so this drives the already-linked test binary directly, standing
in for BeefBuild's test manager on the named pipe the binary expects:
BeefBuild creates /tmp/<name> (the binary writes) and /tmp/<name>__ (the
binary reads) and passes <name> as argv[1].

  Code/Tools/asan-test.py Sedulous.Mcp.Tests

Build the project with BeefBuild first; this only runs it.
"""
import glob
import os
import select
import subprocess
import sys
import time

CODE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TIMEOUT_SECONDS = 900
ASAN_OPTIONS = ":".join([
    "detect_leaks=1",
    # Both fire inside the Beef runtime's own allocator rather than in ported code.
    "new_delete_type_mismatch=0",
    "alloc_dealloc_mismatch=0",
    # Beef frames only appear with the slow unwinder, and they are the whole point.
    "fast_unwind_on_malloc=0",
    "malloc_context_size=30",
])


def find_asan_runtime():
    for pattern in ("/usr/lib/llvm-*/lib/clang/*/lib/linux/libclang_rt.asan-x86_64.so",
                    "/usr/lib/x86_64-linux-gnu/libasan.so.*"):
        found = sorted(glob.glob(pattern))
        if found:
            return found[-1]
    return None


def run(exe, env):
    name = "bfasan%d" % os.getpid()
    to_manager = "/tmp/" + name
    to_client = "/tmp/" + name + "__"
    for path in (to_manager, to_client):
        if os.path.exists(path):
            os.remove(path)
        os.mkfifo(path, 0o666)
    # O_RDWR so neither open blocks waiting for the other end.
    read_fd = os.open(to_manager, os.O_RDWR | os.O_NONBLOCK)
    write_fd = os.open(to_client, os.O_RDWR | os.O_NONBLOCK)

    proc = subprocess.Popen([exe, name], env=env)
    buf = b""
    index = -1
    failures = []
    deadline = time.time() + TIMEOUT_SECONDS
    while proc.poll() is None and time.time() < deadline:
        if not select.select([read_fd], [], [], 0.25)[0]:
            continue
        try:
            chunk = os.read(read_fd, 65536)
        except OSError:
            continue
        if not chunk:
            continue
        buf += chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            command = line.decode("utf8", "replace").rstrip("\r")
            parts = command.split("\t")
            if parts[0] in (":TestInit", ":TestBegin", ":TestQuery"):
                index += 1
                os.write(write_fd, (":TestRun\t%d\n" % index).encode())
            elif parts[0] in (":TestFail", ":TestFatal"):
                failures.append(command)
                print("FAIL: " + command)
                if parts[0] == ":TestFatal":
                    os.write(write_fd, b":TestContinue\n")
            elif parts[0] == ":TestWrite":
                sys.stdout.write(command[len(parts[0]) + 1:].replace("\r", "\n"))
                sys.stdout.flush()
    proc.wait()
    for path in (to_manager, to_client):
        if os.path.exists(path):
            os.remove(path)
    return proc.returncode, failures


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: asan-test.py <TestProjectName>\n")
        return 2
    project = sys.argv[1]
    exe = os.path.join(CODE_DIR, "build", "Test_Linux64", project, project)
    if not os.path.exists(exe):
        sys.stderr.write("no binary at %s; build it with BeefBuild -test first\n" % exe)
        return 2
    runtime = find_asan_runtime()
    if runtime is None:
        sys.stderr.write("no ASan runtime found (install clang or libasan)\n")
        return 2

    # A caller can override the whole option string, e.g. to cut memory during a sweep.
    env = dict(os.environ, LD_PRELOAD=runtime,
               ASAN_OPTIONS=os.environ.get("ASAN_OPTIONS") or ASAN_OPTIONS)
    code, failures = run(exe, env)
    # A nonzero exit with no test failure is LeakSanitizer's, and its report is above.
    print("%s: exit %d, %d test failure(s)" % (project, code, len(failures)))
    return code


if __name__ == "__main__":
    sys.exit(main())
