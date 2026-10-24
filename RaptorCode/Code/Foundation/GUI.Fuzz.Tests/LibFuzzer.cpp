// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Fuzz - a libFuzzer entry for one target (GUI_FUZZ_TARGET: 1 CSS, 2 markup, 3 keymap, 4 string
// table, 5 input on the Controls page), for long runs with -fsanitize=fuzzer,address
// (OPTION_GUI_LIBFUZZER). Seed it with the sandbox's files: `GUI.Fuzz.Css Data/Assets/ui/sandbox`.
#include "Core/Prelude.h"
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <string>
#include <vector>

import foundation.core;
import foundation.vfs;
import foundation.vg;
import foundation.xml;
import foundation.xml.serialization;
import foundation.i18n;
import foundation.gui;
import foundation.gui.testing;

#include "Fuzz.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size)
{
    const std::string bytes(reinterpret_cast<const char*>(data), size);
#if GUI_FUZZ_TARGET == 1
    guifuzz::FuzzCss(bytes);
#elif GUI_FUZZ_TARGET == 2
    guifuzz::FuzzMarkup(bytes);
#elif GUI_FUZZ_TARGET == 3
    guifuzz::FuzzKeymap(bytes);
#elif GUI_FUZZ_TARGET == 4
    guifuzz::FuzzStringTable(bytes);
#else
    static const std::vector<std::string> pages = guifuzz::SandboxSeeds(".xml");
    static const std::vector<std::string> sheets = guifuzz::SandboxSeeds(".css");
    if (!pages.empty())
        guifuzz::FuzzInput(pages[size % pages.size()], sheets.empty() ? std::string() : sheets[size % sheets.size()], bytes);
#endif
    return 0;
}
