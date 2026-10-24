// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Fuzz - the fuzz targets (E10 of Specs/gui-lab-evolution-2.md) and what feeds them: seeds from
// the sandbox's own pages and string table, and a deterministic mutator. Shared by the ctest runner
// (FuzzTests.cpp: every seed, then a seeded run of mutations of each) and the libFuzzer entries
// (LibFuzzer.cpp, built with OPTION_GUI_LIBFUZZER under clang). A target takes any bytes and must
// neither crash nor hang; what it builds is thrown away.

#pragma once

#include <algorithm>
#include <cstdio>
#include <filesystem>
#include <string>
#include <vector>

namespace guifuzz
{
    namespace core = foundation::core;
    namespace gui = foundation::gui;
    using core::u32;
    using core::u64;
    using core::usize;
    using core::f32;

    /// A deterministic source of numbers (xorshift64*), so a failing mutation is found again from its seed.
    struct Random
    {
        u64 state;
        explicit Random(u64 seed) : state(seed != 0 ? seed : 0x9e3779b97f4a7c15ull) {}
        u64 Next()
        {
            state ^= state >> 12;
            state ^= state << 25;
            state ^= state >> 27;
            return state * 0x2545f4914f6cdd1dull;
        }
        u32 Below(u32 bound) { return bound == 0 ? 0u : static_cast<u32>(Next() % bound); }
        f32 Unit() { return static_cast<f32>(Next() >> 40) / static_cast<f32>(1u << 24); }
    };

    /// Mutates `text` a few times: a byte flipped, a span cut or doubled, a piece of syntax or a
    /// stray byte put in, the end cut off. `tokens` is the target's syntax.
    inline std::string Mutate(std::string text, Random& random, const char* const* tokens, usize tokenCount)
    {
        const u32 edits = 1 + random.Below(6);
        for (u32 e = 0; e < edits; ++e)
        {
            const usize size = text.size();
            const usize at = size == 0 ? 0 : random.Below(static_cast<u32>(size));
            switch (random.Below(7))
            {
            case 0: // flip a byte
                if (size > 0)
                    text[at] = static_cast<char>(text[at] ^ static_cast<char>(1u << random.Below(8)));
                break;
            case 1: // cut a span
                if (size > 0)
                    text.erase(at, 1 + random.Below(static_cast<u32>(std::min<usize>(size - at, 64))));
                break;
            case 2: // double a span
                if (size > 0)
                    text.insert(at, text.substr(at, 1 + random.Below(static_cast<u32>(std::min<usize>(size - at, 64)))));
                break;
            case 3: // a piece of syntax
                text.insert(at, tokens[random.Below(static_cast<u32>(tokenCount))]);
                break;
            case 4: // a byte of anything, a broken UTF-8 lead among them
                text.insert(at, 1, static_cast<char>(random.Below(256)));
                break;
            case 5: // the end cut off
                text.resize(at);
                break;
            default: // a run nested deep
                text.insert(at, std::string(1 + random.Below(200), tokens[random.Below(static_cast<u32>(tokenCount))][0]));
                break;
            }
        }
        return text;
    }

    inline constexpr const char* kCssTokens[] = {
        "{", "}", ";", ":", "(", ")", ",", "\"", "'", "/*", "*/", "@media ", "@keyframes x ", "@import ",
        "var(--a)", "var(--a, var(--b))", "calc(1px + 50%)", "::thumb", ":hover", ":not(", ">", "+", "~", "*",
        "#id", ".cls", "[attr=v]", "!important", "url(", "rgba(1,2,3", "#ff00ff", "1e999", "-0.5px", "100%",
        "transition: all 1s;", "animation: x 1s infinite;", "--a: ", "\\", "\n", "\t", "\xF0\x9F", "\xC3",
    };
    inline constexpr const char* kMarkupTokens[] = {
        "<", ">", "</", "/>", "=\"", "\"", "'", "&amp;", "&#x1F600;", "&bogus;", "<!--", "-->", "<![CDATA[",
        "]]>", "<?xml ?>", "<button", "<panel>", "</panel>", "<label text=\"", "style=\"", "class=\"", "id=\"",
        "{{name}}", "{{", "}}", "data-x=\"", "-count=\"", "-args=\"", "\xEF\xBB\xBF", "\0", "\xE2\x80\xAE",
    };
    inline constexpr const char* kKeymapTokens[] = {
        "Ctrl+", "Shift+", "Alt+", "Super+", "+", " ", "K", "F12", "Escape", "Pad.South", "Pad.", "&&", "||", "!",
        "(", ")", "editing", "menu && !popup", "\xC3\xA9", "Ctrl+K Ctrl+", "++", "  ",
    };
    inline constexpr const char* kXmlTokens[] = {
        "<", ">", "</", "/>", "=\"", "\"", "<Entry", "<Locale", "</Locales>", "&lt;", "&#0;", "&#xFFFFFF;",
        "<?xml version=\"1.0\"?>", "<!DOCTYPE x>", "type=\"", "{0}", "{1, plural, one {a} other {b}}", "\xC3",
    };

    /// The file's bytes, or nothing.
    inline std::string ReadBytes(const std::filesystem::path& path)
    {
        std::string out;
        if (FILE* file = std::fopen(path.string().c_str(), "rb"))
        {
            char buffer[4096];
            usize n = 0;
            while ((n = std::fread(buffer, 1, sizeof buffer, file)) > 0)
                out.append(buffer, n);
            std::fclose(file);
        }
        return out;
    }

    /// The sandbox's pages with this extension (`.css`, `.xml`), its main sheet among them: real
    /// input, every feature the GUI has written down once.
    inline std::vector<std::string> SandboxSeeds(const char* extension)
    {
        std::vector<std::string> seeds;
        const core::String root = foundation::vfs::FindDataRoot();
        const std::filesystem::path base =
            std::filesystem::path(std::string(reinterpret_cast<const char*>(root.CStr()))) / "Assets/ui/sandbox";
        std::error_code ec;
        const std::filesystem::path dirs[2] = {base, base / "pages"};
        for (const std::filesystem::path& dir : dirs)
        {
            for (const auto& entry : std::filesystem::directory_iterator(dir, ec))
                if (entry.is_regular_file() && entry.path().extension() == extension)
                    seeds.push_back(ReadBytes(entry.path()));
        }
        return seeds;
    }

    /// Inputs a fuzzer found once, kept to run every time: Data/Tests/GUI/Fuzz/<kind>/*.
    inline std::vector<std::string> FoundSeeds(const char* kind)
    {
        std::vector<std::string> seeds;
        const core::String root = foundation::vfs::FindDataRoot();
        const std::filesystem::path dir =
            std::filesystem::path(std::string(reinterpret_cast<const char*>(root.CStr()))) / "Tests/GUI/Fuzz" / kind;
        std::error_code ec;
        for (const auto& entry : std::filesystem::directory_iterator(dir, ec))
            if (entry.is_regular_file())
                seeds.push_back(ReadBytes(entry.path()));
        return seeds;
    }

    inline core::StringView View(const std::string& text)
    {
        return core::StringView(reinterpret_cast<const core::utf8char*>(text.data()), text.size());
    }

    // === The targets ===

    /// A sheet parsed, then applied to a small tree of every element kind.
    inline void FuzzCss(const std::string& text)
    {
        gui::RegisterGuiElements();
        auto root = core::MakeRef<gui::SceneRoot>(core::DefaultAllocator(), core::MakeRef<gui::GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{320.0f, 240.0f});
        static const gui::ElementSet elements = gui::ElementSet::All();
        gui::MarkupLoader loader(elements, core::DefaultAllocator());
        if (core::RefPtr<gui::Node> tree = loader.LoadFromString(core::StringView(
                u8"<panel><button text=\"b\"/><label class=\"note\" text=\"l\"/><textfield/><slider/>"
                u8"<checkbox/><listbox/><scrollview><label text=\"in\"/></scrollview></panel>")))
            root->AddChild(tree.Get());
        gui::StyleManager styles(gui::CSSParser::Parse(View(text)));
        styles.ApplyTree(*root.Get());
        root->UpdateLayout();
    }

    /// Markup loaded into a root, styled, laid out and drawn.
    inline void FuzzMarkup(const std::string& text)
    {
        gui::RegisterGuiElements();
        auto root = core::MakeRef<gui::SceneRoot>(core::DefaultAllocator(), core::MakeRef<gui::GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{320.0f, 240.0f});
        static const gui::ElementSet elements = gui::ElementSet::All();
        gui::MarkupLoader loader(elements, core::DefaultAllocator());
        core::RefPtr<gui::Node> tree = loader.LoadFromString(View(text));
        if (!tree)
            return;
        root->AddChild(tree.Get());
        gui::StyleManager styles(gui::CSSParser::Parse(core::StringView(u8"* { padding: 2; } button { background-color: #333; }")));
        styles.ApplyTree(*root.Get());
        root->UpdateLayout();
        foundation::vg::VGContext canvas;
        gui::DrawContext dc{canvas};
        root->Draw(dc);
    }

    /// Lines of `keys|command|context` bound into a keymap, then keystrokes matched against it.
    inline void FuzzKeymap(const std::string& text)
    {
        gui::Keymap keymap;
        usize start = 0;
        while (start <= text.size())
        {
            const usize end = std::min(text.find('\n', start), text.size());
            const std::string line = text.substr(start, end - start);
            const usize a = line.find('|');
            const usize b = a == std::string::npos ? std::string::npos : line.find('|', a + 1);
            const std::string keys = line.substr(0, a);
            const std::string command = a == std::string::npos ? "c" : line.substr(a + 1, b == std::string::npos ? std::string::npos : b - a - 1);
            const std::string context = b == std::string::npos ? "" : line.substr(b + 1);
            (void)keymap.Bind(View(keys), View(command), View(context));
            (void)gui::ParseKeystroke(View(keys));
            start = end + 1;
        }
    }

    /// A string table read from XML, then asked for its texts.
    inline void FuzzStringTable(const std::string& text)
    {
        foundation::i18n::RegisterStringTableType();
        foundation::xml::XmlDocument document(core::DefaultAllocator());
        if (document.Parse(View(text)) != foundation::xml::XmlResult::Ok)
            return;
        foundation::xml::XmlSerializer reader(document);
        foundation::i18n::StringTable table;
        table.Serialize(reader);
        foundation::i18n::Localization localization;
        localization.AddTable(&table);
        (void)localization.Text(core::StringView(u8"lang.changed"));
        localization.SetLanguage(core::StringView(u8"ar"));
        (void)localization.Text(core::StringView(u8"gui.ok"));
    }

    /// A sandbox page under a stream of input the bytes decide: pointer, wheel, keys, text and
    /// composition (broken UTF-8 included), touch, pad, file drops, and frames between them.
    inline void FuzzInput(const std::string& markup, const std::string& sheet, const std::string& bytes)
    {
        gui::RegisterGuiElements();
        auto root = core::MakeRef<gui::SceneRoot>(core::DefaultAllocator(), core::MakeRef<gui::GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{640.0f, 480.0f});
        static const gui::ElementSet elements = gui::ElementSet::All();
        gui::MarkupLoader loader(elements, core::DefaultAllocator());
        core::RefPtr<gui::Node> tree = loader.LoadFromString(View(markup));
        if (tree)
            root->AddChild(tree.Get());
        gui::StyleManager styles(gui::CSSParser::Parse(View(sheet)));
        foundation::gui::testing::Tester tester(*root.Get(), &styles);
        gui::EventDispatcher& input = *root->GetEventDispatcher();
        usize at = 0;
        const auto next = [&]() -> u32 { return at < bytes.size() ? static_cast<u32>(static_cast<unsigned char>(bytes[at++])) : 0u; };
        const auto point = [&]() { return core::Float2{static_cast<f32>(next()) * 2.6f - 10.0f, static_cast<f32>(next()) * 2.0f - 10.0f}; };
        while (at < bytes.size())
        {
            switch (next() % 14)
            {
            case 0: (void)input.InjectMouseMove(point(), next() & 15u); break;
            case 1: (void)input.InjectMouseDown(point(), static_cast<gui::MouseButton>(next() % 5), next() & 15u); break;
            case 2: (void)input.InjectMouseUp(point(), static_cast<gui::MouseButton>(next() % 5), next() & 15u); break;
            case 3: (void)input.InjectMouseWheel(point(), core::Float2{static_cast<f32>(next()) - 128.0f, static_cast<f32>(next()) - 128.0f}); break;
            case 4: (void)input.InjectKeyDown(next() % 80u, next() & 15u); break; // unknown codes among them
            case 5: (void)input.InjectKeyUp(next() % 80u, next() & 15u); break;
            case 6:
            {
                std::string text;
                for (u32 n = next() % 6; n > 0; --n)
                    text.push_back(static_cast<char>(next()));
                (void)input.InjectText(View(text));
                break;
            }
            case 7:
            {
                std::string text;
                for (u32 n = next() % 6; n > 0; --n)
                    text.push_back(static_cast<char>(next()));
                (void)input.InjectComposition(View(text), static_cast<core::i32>(next() % 8) - 2);
                break;
            }
            case 8: (void)input.InjectTouchDown(next() % 3u, point()); break;
            case 9: (void)input.InjectTouchMove(next() % 3u, point()); break;
            case 10: (void)input.InjectTouchUp(next() % 3u, point()); break;
            case 11: input.InjectPadButton(static_cast<gui::PadButton>(next() % 8u)); break;
            case 12:
            {
                core::Array<core::String> paths;
                paths.PushBack(core::String(u8"/tmp/a file.png"));
                (void)input.InjectFileDrop(point(), paths);
                break;
            }
            default: tester.Advance(core::Duration::FromSeconds(static_cast<f32>(next()) / 255.0f)); break;
            }
        }
        tester.Frame();
        foundation::vg::VGContext canvas;
        gui::DrawContext dc{canvas};
        root->Draw(dc);
    }
}
