// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Fuzz - what is left of it after the GUI.Fuzz.Tests port: the libFuzzer entry
// (LLVMFuzzerTestOneInput), one executable per target (GUI_FUZZ_TARGET: 1 CSS, 2 markup, 3 keymap,
// 4 string table, 5 input on a sandbox page), built with -fsanitize=fuzzer,address under clang
// (OPTION_GUI_LIBFUZZER) for long runs. Beef has no libFuzzer, and the spec leaves the optional
// libFuzzer build out (Documentation/Specs/gui-port.md, Projects).
// The rest is Code/Foundation/Sedulous.GUI.Fuzz.Tests/src/FuzzTargets.bf (the targets, the seeds,
// the mutator, and this entry's choice of target and of page as FuzzTargets.FuzzOne) and
// Code/Foundation/Sedulous.GUI.Fuzz.Tests/src/FuzzTests.bf (the seeded runs).

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size)
{
    const std::string bytes(reinterpret_cast<const char*>(data), size);
    // guifuzz::FuzzOne(GUI_FUZZ_TARGET, bytes, pages, sheets), the pages and sheets the sandbox's
    // (static: read once).
    return 0;
}
