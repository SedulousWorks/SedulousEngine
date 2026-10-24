// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The GUI asset pages' headless halves (E10 of Specs/gui-lab-evolution-3.md): what the cook reports
// marks the editor's lines, and the markup a sheet is first previewed over builds clean.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.ui;
import foundation.ui.toolkit;
import foundation.gui;
import gui.pipeline;
import editor.gui;

using namespace foundation::core;
namespace toolkit = foundation::ui::toolkit;
namespace gui = foundation::gui;

TEST_CASE("gui editor: what the cook reports marks the editor's lines, and clears when clean")
{
    RefPtr<toolkit::CodeEditView> view = MakeRef<toolkit::CodeEditView>(DefaultAllocator());
    toolkit::CodeEditView& editor = *view;
    const StringView broken = u8"<Panel>\n  <NoSuchElement/>\n</Panel>";
    editor.SetText(broken);
    Array<gui::GuiDiagnostic> found;
    (void)pipeline::ValidateGuiDocument(broken, found, DefaultAllocator());
    REQUIRE_FALSE(found.IsEmpty()); // an element nothing makes is dropped, and said so
    editor::gui_pages::MarkLines(editor, found);
    REQUIRE(editor.Document().Diagnostics().Size() == found.Size());
    CHECK(found[0].Line == 2u); // the dropped element's own line
    CHECK(editor.Document().Diagnostics()[0].line == 1); // the editor counts from 0
    CHECK_FALSE(editor.Document().Diagnostics()[0].message.IsEmpty());

    Array<gui::GuiDiagnostic> none;
    editor::gui_pages::MarkLines(editor, none);
    CHECK(editor.Document().Diagnostics().IsEmpty());
}

TEST_CASE("gui editor: the markup a sheet is first previewed over builds clean")
{
    Array<gui::GuiDiagnostic> found;
    CHECK(pipeline::ValidateGuiDocument(editor::gui_pages::kStockPreviewMarkup, found, DefaultAllocator()));
    CHECK(found.IsEmpty());
}
