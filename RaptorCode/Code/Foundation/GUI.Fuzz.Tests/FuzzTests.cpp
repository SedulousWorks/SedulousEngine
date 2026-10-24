// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Fuzz - the fuzz targets in ctest (E10 of Specs/gui-lab-evolution-2.md): each target takes
// every seed, then a seeded run of mutations of each, and must neither crash nor hang. A crash a
// long libFuzzer run finds goes in as a seed here, so every lane runs it from then on. The count
// of mutations per seed is GUI_FUZZ_RUNS (default 40), so a long local run is one variable away.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include <algorithm>
#include <cstdio>
#include <cstdlib>
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

using namespace guifuzz;

namespace
{
    usize Runs()
    {
        if (const char* value = std::getenv("GUI_FUZZ_RUNS"))
            return static_cast<usize>(std::max(1L, std::strtol(value, nullptr, 10)));
        return 40;
    }

    // Every seed, then Runs() mutations of each, through `target`; the seed of a mutation is its
    // index, so a failure names what to replay.
    template <typename Target>
    void Run(const std::vector<std::string>& seeds, const char* const* tokens, usize tokenCount, Target target)
    {
        REQUIRE_FALSE(seeds.empty());
        for (const std::string& seed : seeds)
            target(seed);
        const usize runs = Runs();
        for (usize s = 0; s < seeds.size(); ++s)
        {
            for (usize r = 0; r < runs; ++r)
            {
                Random random(0x5eed0000ull + s * 100003ull + r);
                target(Mutate(seeds[s], random, tokens, tokenCount));
            }
        }
    }

    template <usize N>
    usize Count(const char* const (&)[N]) { return N; }
}

TEST_CASE("fuzz: the CSS parser and cascade take any sheet")
{
    std::vector<std::string> seeds = SandboxSeeds(".css");
    for (std::string& found : FoundSeeds("css"))
        seeds.push_back(std::move(found));
    seeds.push_back("");
    seeds.push_back("@media (min-width: 10px) { button { color: red } } @keyframes k { 0% { opacity: 0 } }");
    seeds.push_back("a { b: c; } } } { { ; ;; : : var(--x, var(--y, var(--z)))");
    Run(seeds, kCssTokens, Count(kCssTokens), [](const std::string& text) { FuzzCss(text); });
}

TEST_CASE("fuzz: the markup loader takes any markup")
{
    std::vector<std::string> seeds = SandboxSeeds(".xml");
    for (std::string& found : FoundSeeds("markup"))
        seeds.push_back(std::move(found));
    seeds.push_back("");
    seeds.push_back("<panel><panel><panel><button text=\"{{a.b}}\" style=\"color: red\"/></panel></panel></panel>");
    seeds.push_back("<unknown attr=\"\"><label text=\"&#x110000;\"/></unknown>");
    Run(seeds, kMarkupTokens, Count(kMarkupTokens), [](const std::string& text) { FuzzMarkup(text); });
}

TEST_CASE("fuzz: the keymap takes any bindings")
{
    std::vector<std::string> seeds = FoundSeeds("keymap");
    seeds.push_back("Ctrl+S|file.save|\nCtrl+K Ctrl+C|edit.comment|editing && !readonly\nPad.South|ui.activate|menu");
    seeds.push_back("|||\n+\nCtrl+\n(((((\n");
    Run(seeds, kKeymapTokens, Count(kKeymapTokens), [](const std::string& text) { FuzzKeymap(text); });
}

TEST_CASE("fuzz: the string table reader takes any XML")
{
    std::vector<std::string> seeds;
    const core::String root = foundation::vfs::FindDataRoot();
    seeds.push_back(ReadBytes(std::filesystem::path(std::string(reinterpret_cast<const char*>(root.CStr()))) /
                              "Assets/ui/sandbox/i18n/sandbox.strings.xml"));
    REQUIRE_FALSE(seeds[0].empty());
    for (std::string& found : FoundSeeds("strings"))
        seeds.push_back(std::move(found)); // cells-not-one-a-locale: an entry short of the locales' cells
    seeds.push_back("<?xml version=\"1.0\"?><a><b/></a>");
    Run(seeds, kXmlTokens, Count(kXmlTokens), [](const std::string& text) { FuzzStringTable(text); });
}

TEST_CASE("fuzz: a page takes any stream of input")
{
    // Each sandbox page with its own sheet, under random input streams.
    const std::vector<std::string> pages = SandboxSeeds(".xml");
    const std::vector<std::string> sheets = SandboxSeeds(".css");
    REQUIRE_FALSE(pages.empty());
    const usize runs = std::max<usize>(1, Runs() / 8);
    for (usize p = 0; p < pages.size(); ++p)
    {
        const std::string& sheet = sheets.empty() ? std::string() : sheets[p % sheets.size()];
        for (usize r = 0; r < runs; ++r)
        {
            Random random(0x1a7e0000ull + p * 7919ull + r);
            std::string stream;
            for (u32 n = 0; n < 2000; ++n)
                stream.push_back(static_cast<char>(random.Below(256)));
            FuzzInput(pages[p], sheet, stream);
        }
    }
}
