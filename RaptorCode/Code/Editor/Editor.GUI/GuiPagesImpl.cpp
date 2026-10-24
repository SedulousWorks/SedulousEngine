// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Editor::GUI - implementation unit: the GUI asset page's layout, its preview, its save.

module;
#include "Core/Prelude.h"
#include "Core/Log/Log.h"

module editor.gui;

import foundation.core;
import foundation.vfs;
import foundation.content;
import foundation.runtime.client;
import foundation.graphics;
import foundation.rhi;
import foundation.vg.renderer;
import foundation.ui;
import foundation.ui.toolkit;
import foundation.ui.runtime;
import foundation.ui.viewport;
import foundation.gui;
import gui.pipeline; // the assets, their validation, the starters
import pipeline.core;             // Asset: the linked source every one of them has
import engine.gui;
import editor.core;
import editor.app;

using namespace foundation::core;
namespace rhi = foundation::rhi;
namespace runtime = foundation::runtime;
namespace ui = foundation::ui;
namespace vg = foundation::vg;
namespace gui = foundation::gui;

namespace editor
{
    namespace
    {
        // A code editor filling the space its column gives it.
        RefPtr<ui::toolkit::CodeEditView> MakeEditor(IAllocator& allocator, StringView text, bool markup)
        {
            RefPtr<ui::toolkit::CodeEditView> editor = MakeRef<ui::toolkit::CodeEditView>(allocator);
            editor->AllowBreakpoints = false; // nothing to break on
            if (markup) // markup is XML, which the toolkit lexes; CSS is plain text until it has a lexer
                editor->SetLexer(UniquePtr<ui::toolkit::ICodeLexer>(allocator.New<ui::toolkit::XmlLexer>(), allocator));
            editor->SetText(text);
            return editor;
        }
    }

    GuiAssetEditorPage::GuiAssetEditorPage(EditorContext& context, runtime::IApplicationHost& host, ui::runtime::UIHost& uiHost,
                                           foundation::content::Instance& instance, Kind kind)
        : app::UIEditorPage(context.Allocator()), m_context(&context), m_host(&host), m_uiHost(&uiHost), m_kind(kind),
          m_title(instance.Name())
    {
        m_gui = host.Ctx().GetSubsystem<engine::gui::GuiSubsystem>();
        SetInstanceId(instance.Id());
        RefPtr<ISerializable> object = instance.ReadObject();
        auto* asset = Cast<pipeline::Asset>(object.Get());
        if (asset != nullptr && !asset->fileName.IsEmpty())
            m_text = ReadSource(asset->fileName.View());
        else
            LOG_ERROR(u8"Editor", u8"GUI asset has no linked source file: the page opens empty (import the file again)");
        if (auto* sheet = Cast<pipeline::GuiStyleSheetAsset>(object.Get()))
            m_previewMarkup = sheet->previewMarkup;
        if (m_kind == Kind::StyleSheet && m_previewMarkup.IsEmpty())
            m_previewMarkup = String(gui_pages::kStockPreviewMarkup); // previewed over something from the start

        auto row = MakeRef<ui::FlexLayout>(Allocator());
        row->Direction = ui::Orientation::Horizontal;
        row->Spacing = 8.0f;

        // Left: the asset's own text.
        m_editor = MakeEditor(Allocator(), m_text.AsView(), m_kind == Kind::Document);
        GuiAssetEditorPage* self = this;
        m_editor->OnTextChanged.Add(
            [self]()
            {
                self->m_text = self->m_editor->Text();
                self->MarkDirty();
                self->m_previewDelay = 0.35f; // rebuilt shortly after typing stops
            });
        {
            ui::LayoutStyle lp;
            lp.FlexGrow = 1.0f;
            lp.Height = ui::SizeSpec::Match();
            row->AddView(m_editor.Get(), lp);
        }

        // Right: [a sheet's document picker] and the status, a sheet's preview markup, the preview.
        auto right = MakeRef<ui::FlexLayout>(Allocator());
        right->Direction = ui::Orientation::Vertical;
        right->Spacing = 4.0f;
        auto bar = MakeRef<ui::FlexLayout>(Allocator());
        bar->Direction = ui::Orientation::Horizontal;
        bar->Spacing = 8.0f;
        if (m_kind == Kind::StyleSheet)
        {
            auto pick = MakeRef<ui::Button>(Allocator(), StringView(u8"Preview Document..."));
            pick->OnClick.Add([self](ui::ButtonBase*) { self->PickPreviewDocument(); });
            bar->AddView(pick.Get());
        }
        m_status = MakeRef<ui::Label>(Allocator(), StringView(u8""));
        m_status->FontSize.SetValue(12.0f);
        {
            ui::LayoutStyle lp;
            lp.FlexGrow = 1.0f;
            bar->AddView(m_status.Get(), lp);
        }
        {
            ui::LayoutStyle lp;
            lp.Width = ui::SizeSpec::Match();
            right->AddView(bar.Get(), lp);
        }
        if (m_kind == Kind::StyleSheet)
        {
            m_previewEditor = MakeEditor(Allocator(), m_previewMarkup.AsView(), true);
            m_previewEditor->OnTextChanged.Add(
                [self]()
                {
                    self->m_previewMarkup = self->m_previewEditor->Text();
                    self->MarkDirty(); // kept on the asset
                    self->m_previewDelay = 0.35f;
                });
            ui::LayoutStyle lp;
            lp.Width = ui::SizeSpec::Match();
            lp.FlexGrow = 1.0f;
            right->AddView(m_previewEditor.Get(), lp);
        }
        // The preview: an offscreen target the runtime's GUI draws into; the editor shows it.
        m_viewport = MakeRef<ui::viewport::ViewportView>(Allocator());
        m_viewport->ClearColor = rhi::ClearColor{0.313f, 0.332f, 0.366f, 1.0f};
        {
            ui::LayoutStyle lp;
            lp.Width = ui::SizeSpec::Match();
            lp.FlexGrow = m_kind == Kind::StyleSheet ? 2.0f : 1.0f;
            right->AddView(m_viewport.Get(), lp);
        }
        {
            ui::LayoutStyle lp;
            lp.FlexGrow = 1.0f;
            lp.Height = ui::SizeSpec::Match();
            row->AddView(right.Get(), lp);
        }
        m_toolbar = MakeRef<app::PageToolbar>(Allocator(), *this, m_context->Actions(), app::PageToolbar::Standard::Save);
        m_content = app::PageToolbar::Frame(Allocator(), *m_toolbar, *row);
        RebuildPreview();
    }

    String GuiAssetEditorPage::ReadSource(StringView fileName) const
    {
        if (m_context->Project() == nullptr)
            return {};
        const String path = PathJoin(m_context->Project()->SourcesRoot().AsView(), fileName);
        Result<Array<byte>> bytes = ReadFile(path.AsView());
        if (!bytes.HasValue())
            return {};
        return String(StringView(reinterpret_cast<const utf8char*>(bytes.Value().Data()), bytes.Value().Size()));
    }

    void GuiAssetEditorPage::SetStatus(StringView text)
    {
        m_statusText = String(text);
        m_status->SetText(text);
    }

    void GuiAssetEditorPage::SetText(StringView text)
    {
        m_editor->SetText(text); // OnTextChanged keeps m_text and marks the page dirty
        m_text = String(text);
        RebuildPreview();
        m_previewDelay = 0.0f;
    }

    Status GuiAssetEditorPage::Save()
    {
        foundation::content::Instance* instance =
            m_context->Project() != nullptr ? m_context->Project()->SourceDb().GetInstance(InstanceId()) : nullptr;
        if (instance == nullptr)
            return Status{ErrorCode::NotFound};
        RefPtr<ISerializable> object = instance->ReadObject();
        auto* asset = Cast<pipeline::Asset>(object.Get());
        if (asset == nullptr)
            return Status{ErrorCode::NotFound};
        if (asset->fileName.IsEmpty())
        {
            LOG_ERROR(u8"Editor", u8"GUI asset has no linked source file: save refused");
            return Status{ErrorCode::NotSupported};
        }
        const String path = PathJoin(m_context->Project()->SourcesRoot().AsView(), asset->fileName.View());
        const Status fileWritten = WriteFile(path.AsView(), Span<const byte>(reinterpret_cast<const byte*>(m_text.Data()), m_text.Size()));
        if (!fileWritten.IsOk())
            return fileWritten;
        if (auto* sheet = Cast<pipeline::GuiStyleSheetAsset>(asset))
            sheet->previewMarkup = m_previewMarkup; // editor-only, kept on the asset
        // The asset written again so the validating cook sees it, then asked for.
        const Status written = instance->WriteObject(*asset);
        if (written.IsOk())
        {
            ClearDirty();
            if (m_context->OnCookRequested)
                m_context->OnCookRequested(false);
        }
        return written;
    }

    void GuiAssetEditorPage::OnUpdate(runtime::IApplicationHost&, f32 dt)
    {
        if (m_toolbar.Get() != nullptr)
            m_toolbar->Refresh();
        EnsureViewportBound();
        if (m_previewDelay > 0.0f)
        {
            m_previewDelay -= dt;
            if (m_previewDelay <= 0.0f)
                RebuildPreview();
        }
    }

    void GuiAssetEditorPage::OnAfterSceneRender(runtime::IApplicationHost&, foundation::graphics::FrameContext& frame)
    {
        if (!m_viewport->IsReady() || !frame.valid)
            return;
        m_viewport->ClearContent(*frame.encoder); // the target defined every frame: the editor samples it
        if (m_gui == nullptr || !m_previewRoot)
            return;
        const u32 width = m_viewport->RenderWidth();
        const u32 height = m_viewport->RenderHeight();
        if (width == 0 || height == 0)
            return;
        frame.encoder->TransitionTexture(m_viewport->ColorTexture(), m_viewport->ColorState(), rhi::ResourceState::RenderTarget);
        m_gui->RenderPreview(*m_previewRoot, *frame.encoder, m_viewport->ColorTargetView(), m_viewport->ColorFormat(), width, height,
                             frame.frameIndex);
        frame.encoder->TransitionTexture(m_viewport->ColorTexture(), rhi::ResourceState::RenderTarget, rhi::ResourceState::ShaderRead);
        m_viewport->SetColorState(rhi::ResourceState::ShaderRead);
    }

    void GuiAssetEditorPage::OnClose()
    {
        m_previewRoot = nullptr;
        m_viewport->Shutdown();
    }

    void GuiAssetEditorPage::EnsureViewportBound()
    {
        ui::RootView* root = m_viewport->Root();
        if (root == nullptr)
            return;
        foundation::graphics::RenderWindow* window = m_uiHost->WindowForRoot(root);
        if (window == nullptr || window == m_hostWindow)
            return;
        vg::renderer::VGRenderer* renderer = m_uiHost->RendererFor(window);
        if (renderer == nullptr)
            return;
        if (m_hostWindow == nullptr)
            m_viewport->Initialize(m_host->Graphics()->Raw(), renderer, m_host->Shell()->Input(), window->Window().Id());
        else
            m_viewport->AttachToWindow(renderer, window->Window().Id());
        m_hostWindow = window;
    }

    void GuiAssetEditorPage::RebuildPreview()
    {
        // What the cook would report, on the lines it is about.
        Array<gui::GuiDiagnostic> found;
        bool builds = true;
        if (m_kind == Kind::Document)
            builds = pipeline::ValidateGuiDocument(m_text.AsView(), found, Allocator());
        else
            pipeline::ValidateGuiStyleSheet(m_text.AsView(), found);
        gui_pages::MarkLines(*m_editor, found);
        if (m_kind == Kind::StyleSheet)
        {
            Array<gui::GuiDiagnostic> previewFound;
            builds = pipeline::ValidateGuiDocument(m_previewMarkup.AsView(), previewFound, Allocator());
            gui_pages::MarkLines(*m_previewEditor, previewFound);
        }
        if (!builds)
        {
            SetStatus(u8"Does not build: showing the last good preview.");
            return;
        }
        if (m_gui == nullptr)
        {
            SetStatus(u8"No GUI in the runtime: no preview.");
            return;
        }
        // The real preview, in the runtime's GUI (its fonts, theme and the game's sheets).
        RefPtr<gui::SceneRoot> fresh = m_kind == Kind::Document ? m_gui->CreatePreview(m_text.AsView())
                                                                : m_gui->CreatePreview(m_previewMarkup.AsView(), m_text.AsView());
        if (!fresh)
        {
            SetStatus(u8"Does not build: showing the last good preview.");
            return;
        }
        m_previewRoot = fresh;
        if (found.IsEmpty())
        {
            SetStatus(u8"OK");
            return;
        }
        String text(found[0].Level == gui::GuiDiagnostic::Severity::Error ? u8"Error: " : u8"Warning: ");
        text.Append(found[0].Message.AsView());
        if (found.Size() > 1)
            text.Append(Format(u8" (+{} more)", found.Size() - 1).AsView());
        SetStatus(text.AsView());
    }

    void GuiAssetEditorPage::PickPreviewDocument()
    {
        if (m_context->Project() == nullptr || m_content.Get() == nullptr)
            return;
        Array<String> typeNames;
        typeNames.PushBack(String(u8"GuiDocumentAsset"));
        auto dialog = MakeRef<app::AssetPickerDialog>(Allocator(), *m_context, Move(typeNames));
        GuiAssetEditorPage* self = this;
        dialog->OnPicked = [self](const Guid& picked)
        {
            if (picked.IsNil() || self->m_context->Project() == nullptr)
                return;
            foundation::content::Instance* instance = self->m_context->Project()->SourceDb().GetInstance(picked);
            if (instance == nullptr)
                return;
            RefPtr<ISerializable> object = instance->ReadObject();
            auto* document = Cast<pipeline::GuiDocumentAsset>(object.Get());
            if (document == nullptr || document->fileName.IsEmpty())
                return; // an unlinked document has no text to preview over
            const String markup = self->ReadSource(document->fileName.View());
            self->m_previewMarkup = markup;
            self->m_previewEditor->SetText(markup.AsView()); // copied once: the page's to change now
            self->MarkDirty();                               // kept on the sheet's asset
            self->m_previewDelay = 0.05f;
        };
        dialog->Show(m_content->Context);
    }

    const TypeInfo* GuiAssetPageFactory::PrimaryType() const
    {
        return m_kind == GuiAssetEditorPage::Kind::Document ? &pipeline::GuiDocumentAsset::StaticType()
                                                            : &pipeline::GuiStyleSheetAsset::StaticType();
    }

    UniquePtr<EditorPage> GuiAssetPageFactory::CreatePage(EditorContext& context, foundation::content::Instance& instance)
    {
        auto* page = editor::EditorRootAllocator().New<GuiAssetEditorPage>(context, *m_host, *m_uiHost, instance, m_kind);
        return UniquePtr<EditorPage>(page, editor::EditorRootAllocator());
    }
}
