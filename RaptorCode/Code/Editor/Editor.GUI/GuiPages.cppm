// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Editor::GUI - the `editor.gui` module: the editor's pages for the engine GUI's assets (E10 of
// Specs/gui-lab-evolution-3.md).
//
// GuiAssetEditorPage edits a `.gml` document or a `.css` sheet, its text in the linked Sources/
// file, beside a live preview the RUNTIME context's GuiSubsystem draws into the page's offscreen
// target (GuiSubsystem::CreatePreview / RenderPreview): the game's fonts, theme and sheets, so
// what shows is what the game will show. A sheet's page previews it over markup of its own (a
// second editor, kept on the asset as editor-only previewMarkup, never cooked; "Preview
// Document..." copies a document's markup in), the sheet applied to that tree alone, never to the
// game's GUI. Edits rebuild the preview after a short pause; what the cook would report (the
// loader's and the parser's diagnostics) marks the lines; a document that does not build keeps
// the last good preview. Save writes the source and the asset, then asks for the validating cook.
// The pages are foundation.ui's, as the editor is, until the editor's own move.

module;
#include "Core/Prelude.h"
#include "Core/Log/Log.h"

export module editor.gui;

import foundation.core;
import foundation.content;
import foundation.runtime.client;
import foundation.graphics;
import foundation.rhi;
import foundation.ui;
import foundation.ui.toolkit;
import foundation.ui.runtime;
import foundation.ui.viewport;
import foundation.gui;
import engine.gui;
import editor.core;
import editor.app;

using namespace foundation::core;

export namespace editor
{
    namespace runtime = foundation::runtime;
    namespace ui = foundation::ui;
    namespace rhi = foundation::rhi;
    namespace gui = foundation::gui;

    namespace gui_pages
    {
        /// What a sheet is previewed over with nothing chosen yet: a little of everything a sheet
        /// styles.
        inline constexpr StringView kStockPreviewMarkup = u8"<Panel class=\"page\" flex-direction=\"column\" gap=\"8\" padding=\"16\">\n"
                                                          u8"    <Label class=\"title\" text=\"Title\"/>\n"
                                                          u8"    <Label text=\"Body text.\"/>\n"
                                                          u8"    <Button text=\"Button\"/>\n"
                                                          u8"    <CheckBox text=\"Check box\"/>\n"
                                                          u8"    <Slider/>\n"
                                                          u8"</Panel>\n";

        /// The cook's diagnostics on `editor`'s lines, as its margin marks them (from 0; a
        /// diagnostic with no line on the first).
        inline void MarkLines(ui::toolkit::CodeEditView& editor, const Array<gui::GuiDiagnostic>& found)
        {
            Array<ui::toolkit::CodeDiagnostic> marks;
            for (const gui::GuiDiagnostic& diagnostic : found)
            {
                ui::toolkit::CodeDiagnostic mark;
                mark.isError = diagnostic.Level == gui::GuiDiagnostic::Severity::Error;
                mark.line = diagnostic.Line > 0 ? static_cast<i32>(diagnostic.Line) - 1 : 0;
                mark.message = diagnostic.Message;
                marks.PushBack(Move(mark));
            }
            editor.Document().SetDiagnostics(Move(marks));
            editor.Invalidate();
        }
    }

    class GuiAssetEditorPage final : public app::UIEditorPage
    {
    public:
        /// What the page edits: a document (its markup, previewed as it is) or a sheet (its CSS,
        /// previewed over markup of its own).
        enum class Kind : u8
        {
            Document,
            StyleSheet,
        };

        GuiAssetEditorPage(EditorContext& context, runtime::IApplicationHost& host, ui::runtime::UIHost& uiHost,
                           foundation::content::Instance& instance, Kind kind);

        [[nodiscard]] StringView Title() const override { return m_title.AsView(); }
        [[nodiscard]] ui::View* ContentView() override { return m_content.Get(); }
        [[nodiscard]] Status Save() override;
        void OnUpdate(runtime::IApplicationHost&, f32 dt) override;
        void OnAfterSceneRender(runtime::IApplicationHost&, foundation::graphics::FrameContext& frame) override;
        void OnClose() override;

        /// What the preview shows now (null before one built), and the text it was built from: for
        /// a test, and a tool.
        [[nodiscard]] gui::SceneRoot* PreviewRoot() const noexcept { return m_previewRoot.Get(); }
        [[nodiscard]] StringView Text() const noexcept { return m_text.AsView(); }
        [[nodiscard]] StringView StatusText() const noexcept { return m_statusText.AsView(); }
        /// The text as if typed, the preview rebuilt now (no pause): a test's and a tool's.
        void SetText(StringView text);

    private:
        void EnsureViewportBound();
        void RebuildPreview();
        void PickPreviewDocument();
        [[nodiscard]] String ReadSource(StringView fileName) const;
        void SetStatus(StringView text);

        EditorContext* m_context = nullptr;
        runtime::IApplicationHost* m_host = nullptr;
        ui::runtime::UIHost* m_uiHost = nullptr;
        engine::gui::GuiSubsystem* m_gui = nullptr; // the RUNTIME context's
        foundation::graphics::RenderWindow* m_hostWindow = nullptr;
        Kind m_kind;
        String m_title;
        String m_text;          // the asset's: the document's markup, or the sheet's CSS
        String m_previewMarkup; // a sheet's: what it is previewed over (editor-only, on the asset)
        f32 m_previewDelay = 0.0f;
        RefPtr<ui::View> m_content;
        RefPtr<app::PageToolbar> m_toolbar;
        RefPtr<ui::toolkit::CodeEditView> m_editor;
        RefPtr<ui::toolkit::CodeEditView> m_previewEditor; // a sheet's
        RefPtr<ui::Label> m_status;
        String m_statusText;
        RefPtr<ui::viewport::ViewportView> m_viewport;
        RefPtr<gui::SceneRoot> m_previewRoot; // in the RUNTIME context's GUI
    };

    /// The page for one of the GUI's asset types.
    class GuiAssetPageFactory final : public IEditorPageFactory
    {
    public:
        GuiAssetPageFactory(runtime::IApplicationHost& host, ui::runtime::UIHost& uiHost, GuiAssetEditorPage::Kind kind)
            : m_host(&host), m_uiHost(&uiHost), m_kind(kind)
        {
        }
        [[nodiscard]] const TypeInfo* PrimaryType() const override;
        [[nodiscard]] UniquePtr<EditorPage> CreatePage(EditorContext& context, foundation::content::Instance& instance) override;

    private:
        runtime::IApplicationHost* m_host;
        ui::runtime::UIHost* m_uiHost;
        GuiAssetEditorPage::Kind m_kind;
    };

    /// The editor executable's entry point for the GUI's pages.
    inline void RegisterGuiEditor(EditorContext& context, runtime::IApplicationHost& host, ui::runtime::UIHost& uiHost)
    {
        context.Pages().Register(UniquePtr<IEditorPageFactory>(
            editor::EditorRootAllocator().New<GuiAssetPageFactory>(host, uiHost, GuiAssetEditorPage::Kind::Document),
            editor::EditorRootAllocator()));
        context.Pages().Register(UniquePtr<IEditorPageFactory>(
            editor::EditorRootAllocator().New<GuiAssetPageFactory>(host, uiHost, GuiAssetEditorPage::Kind::StyleSheet),
            editor::EditorRootAllocator()));
    }
}
