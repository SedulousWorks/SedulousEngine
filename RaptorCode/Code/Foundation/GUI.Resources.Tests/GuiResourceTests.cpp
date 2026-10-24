// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Resources (E2 of Specs/gui-lab-evolution-3.md): a cooked GUI document and style sheet read back
// through their factories, their text intact, and the module the engine composition takes them from.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include <filesystem>

import foundation.core;
import foundation.vfs;
import foundation.content;
import foundation.resource;
import foundation.gui.resources;

using namespace foundation::core;
using namespace foundation::resource;
using namespace foundation::gui;
namespace content = foundation::content;

namespace
{
    constexpr StringView kMarkup = u8"<Screen covers=\"true\"><Button id=\"play\" text=\"@menu.play\"/></Screen>";
    constexpr StringView kCss = u8"screen:entering { opacity: 0; } button { background: url(\"{6b1c0d3e-0000-4000-8000-000000000001}\"); }";

    void RemoveAll(StringView dir)
    {
        std::error_code ec;
        std::filesystem::remove_all(std::filesystem::path(reinterpret_cast<const char*>(String(dir).CStr())), ec);
    }
}

TEST_CASE("gui.resources: a cooked document and sheet bind as their products, the text intact")
{
    RegisterGuiResource();
    RemoveAll(u8"scratch_guiresource_db");
    REQUIRE(CreateDirectories(u8"scratch_guiresource_db"));
    {
        foundation::vfs::NativeFileSystem mount(u8"scratch_guiresource_db", DefaultAllocator());
        content::ContentDatabase db(DefaultAllocator(), mount, BinarySerializerFactory(), u8".rasset");
        content::Instance* title = db.RootGroup()->CreateInstance(u8"title", GuiDocumentSource::StaticType());
        content::Instance* theme = db.RootGroup()->CreateInstance(u8"theme", GuiStyleSheetSource::StaticType());
        REQUIRE(title != nullptr);
        REQUIRE(theme != nullptr);
        GuiDocumentSource document;
        document.markup = String(kMarkup);
        REQUIRE(title->WriteObject(document).IsOk());
        GuiStyleSheetSource sheet;
        sheet.css = String(kCss);
        REQUIRE(theme->WriteObject(sheet).IsOk());

        GuiDocumentFactory documents(DefaultAllocator());
        GuiStyleSheetFactory sheets(DefaultAllocator());
        CHECK(documents.ProductType() == &GuiDocument::StaticType());
        CHECK(documents.CookedType() == &GuiDocumentSource::StaticType());
        CHECK(sheets.ProductType() == &GuiStyleSheet::StaticType());
        CHECK(sheets.CookedType() == &GuiStyleSheetSource::StaticType());
        ResourceManager manager(DefaultAllocator(), db);
        manager.AddFactory(&documents);
        manager.AddFactory(&sheets);
        Proxy<GuiDocument> boundDocument = manager.Bind<GuiDocument>(title->Id());
        Proxy<GuiStyleSheet> boundSheet = manager.Bind<GuiStyleSheet>(theme->Id());
        REQUIRE(boundDocument);
        REQUIRE(boundSheet);
        CHECK(boundDocument->markup.AsView() == kMarkup);
        CHECK(boundSheet->css.AsView() == kCss);
    }
    RemoveAll(u8"scratch_guiresource_db");
}

TEST_CASE("gui.resources: the module offers both factories under its own id")
{
    CHECK(kGuiResourceModule.id == StringView(u8"gui"));
    REQUIRE(kGuiResourceModule.factoryCount == 2u);
}
