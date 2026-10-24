// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Pipeline - `gui.pipeline` (tooling; E3 of Specs/gui-lab-evolution-3.md).
// foundation.ui's counterpart: UI.Pipeline.
//
// The GUI's sources, cooked:
//   * GuiDocumentAsset (`.gml` markup) and GuiStyleSheetAsset (`.css`): a LINKED source file in the
//     project's Sources/ tree (Asset::fileName), as a script's; an asset with no linked file fails
//     the cook.
//   * The builders VALIDATE: a document through the GUI's markup loader with every element type the
//     tools register (the core's, the gamekit's, the toolkit's, the code editor's), a sheet through
//     the CSS parser and the check of its property names. What cannot be read fails the cook (markup
//     that does not parse); what was dropped (an unknown element or attribute, an at-rule, a
//     property no style or element takes) is a warning, each with its file and line where known.
//     The text then goes through to the cooked record (foundation.gui.resources).
//   * What a document or a sheet names by asset guid (`url("{guid}")`, `source="{guid}"`, a
//     document pushed by its guid) is recorded as a runtime reference of the product; a guid naming
//     no asset is a warning.
//   * One importer takes a dropped `.gml` or `.css` into Sources/ and links it; creators make a new
//     one from starter text (File > New, MCP's asset_create).
//
// Never linked by the runtime, nor in a web or shipping build.

module;
#include "Core/Prelude.h"
#include "Core/Log/Log.h"
#include "Core/Reflection/Reflect.h"

export module gui.pipeline;

import foundation.core;
import foundation.content;
import pipeline.core;
import pipeline.importer;
import foundation.gui;           // MarkupLoader, CSSParser, CheckStyleSheetNames, GuiDiagnostic
import foundation.gui.gamekit;   // its elements validate (a game's <Screen>s)
import foundation.gui.toolkit;   // its elements validate (an editor's)
import foundation.gui.code;      // the code editor validates
import foundation.gui.resources; // the cooked records

using namespace foundation::core;
namespace gui = foundation::gui;

export namespace pipeline
{
    inline constexpr StringView kGuiDocumentStarter =
        u8"<Panel class=\"page\" flex-direction=\"column\" align-items=\"center\" gap=\"12\" padding=\"24\">\n"
        u8"    <Label id=\"title\" text=\"New document\"/>\n"
        u8"    <Button id=\"ok\" text=\"OK\"/>\n"
        u8"</Panel>\n";

    inline constexpr StringView kGuiStyleSheetStarter =
        u8"/* A game's sheet over the GUI's theme: set its tokens, or style elements and classes. */\n"
        u8":root { --accent: #f3a047; }\n"
        u8".page { background-color: var(--surface); }\n";

    /// A GUI document: a LINKED `.gml` in Sources/.
    class GuiDocumentAsset final : public pipeline::Asset
    {
        RTTI_OBJECT(GuiDocumentAsset, pipeline::Asset)
    public:
        void Serialize(ISerializer& ar) override { pipeline::Asset::Serialize(ar); }
    };

    /// A GUI style sheet: a LINKED `.css` in Sources/, and the markup its editor page previews it
    /// against (editor-only: never cooked).
    class GuiStyleSheetAsset final : public pipeline::Asset
    {
        RTTI_OBJECT(GuiStyleSheetAsset, pipeline::Asset)
    public:
        String previewMarkup;

        void Serialize(ISerializer& ar) override
        {
            pipeline::Asset::Serialize(ar);
            SerializeAppended(ar, "previewMarkup", previewMarkup);
        }
    };

    /// Registers every element type a GUI document may name, once (the tools' set).
    inline void RegisterGuiValidationElements()
    {
        gui::RegisterGuiElements();
        gui::RegisterGamekitElements();
        gui::RegisterToolkitElements();
        gui::RegisterCodeElements();
    }

    /// Validates `markup` as a cook does, the tree it makes from `allocator`: false when it cannot
    /// be read; what was dropped and the reason it failed in `out`.
    [[nodiscard]] inline bool ValidateGuiDocument(StringView markup, Array<gui::GuiDiagnostic>& out, IAllocator& allocator)
    {
        RegisterGuiValidationElements();
        static const gui::ElementSet elements = gui::ElementSet::All();
        gui::MarkupLoader loader(elements, allocator);
        loader.SetDiagnostics(&out);
        return loader.LoadFromString(markup).Get() != nullptr;
    }

    /// Validates `css` as a cook does: what the parser skipped and the property names nothing takes,
    /// in `out`. A sheet always reads (the parser is best effort): its problems are warnings.
    inline void ValidateGuiStyleSheet(StringView css, Array<gui::GuiDiagnostic>& out)
    {
        RegisterGuiValidationElements();
        const gui::StyleSheet sheet = gui::CSSParser::Parse(css, {}, &out);
        gui::CheckStyleSheetNames(sheet, out);
    }

    /// The asset guids `text` names (`{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}`), each once, in order.
    [[nodiscard]] inline Array<Guid> FindGuidReferences(StringView text)
    {
        constexpr usize kForm = 36; // the canonical spelling, braces aside
        Array<Guid> found;
        for (usize i = 0; i + kForm + 1 < text.Size(); ++i)
        {
            if (text[i] != u8'{' || text[i + kForm + 1] != u8'}')
                continue;
            Guid id;
            if (!Guid::TryParse(text.SubStr(i + 1, kForm), id))
                continue;
            bool seen = false;
            for (const Guid& known : found)
                seen = seen || known == id;
            if (!seen)
                found.PushBack(id);
            i += kForm + 1;
        }
        return found;
    }

    namespace detail
    {
        // Says each diagnostic into the log with its asset's file and line.
        inline void LogGuiDiagnostics(StringView file, const Array<gui::GuiDiagnostic>& said)
        {
            for (const gui::GuiDiagnostic& d : said)
            {
                if (d.Level == gui::GuiDiagnostic::Severity::Error)
                    LOG_ERROR(u8"GUI", u8"{}:{}: {}", file, d.Line, d.Message.AsView());
                else
                    LOG_WARNING(u8"GUI", u8"{}:{}: {}", file, d.Line, d.Message.AsView());
            }
        }
        // The guids `text` names that are assets of the source database; the others are warned of.
        inline void AddGuidReferences(StringView file, StringView text, pipeline::AssetBuildContext& ctx, Array<Guid>& out, bool warn)
        {
            for (const Guid& id : FindGuidReferences(text))
            {
                const bool known = (ctx.sourceDb != nullptr && ctx.sourceDb->GetInstance(id) != nullptr) ||
                                   (ctx.db != nullptr && ctx.db->GetInstance(id) != nullptr);
                if (known)
                    out.PushBack(id);
                else if (warn)
                {
                    utf8char spelled[37] = {};
                    id.ToChars(spelled);
                    LOG_WARNING(u8"GUI", u8"{}: names the guid {}, which is no asset", file, StringView(spelled));
                }
            }
        }
    }

    /// Cooks a linked GUI source as `Cooked` after `validate(text, said)` (false: the cook fails).
    template <typename SourceAsset, typename Cooked, String Cooked::* Text>
    class GuiTextAssetBuilder : public pipeline::DefaultAssetBuilder
    {
    public:
        [[nodiscard]] const TypeInfo* AssetType() const override { return &SourceAsset::StaticType(); }
        [[nodiscard]] const TypeInfo* ProductType() const override { return &Cooked::StaticType(); }

        // What the source names by guid: the product refers to it at runtime.
        void ScanDependencies(const pipeline::Asset& asset, pipeline::AssetBuildContext& ctx, pipeline::AssetDependencies& out) override
        {
            String text;
            if (asset.fileName.IsEmpty() || !ReadSourceText(ctx, asset.fileName.View(), text).IsOk())
                return;
            detail::AddGuidReferences(asset.fileName.View(), text.AsView(), ctx, out.references, false);
        }

        [[nodiscard]] Status Build(const pipeline::Asset& asset, pipeline::AssetBuildContext& ctx) override
        {
            if (ctx.output == nullptr)
                return Status{ErrorCode::InvalidArgument};
            if (asset.fileName.IsEmpty())
            {
                LOG_ERROR(u8"GUI", u8"a GUI asset has no linked source file - cook failed");
                return Status{ErrorCode::InvalidArgument};
            }
            String text;
            if (const Status read = ReadSourceText(ctx, asset.fileName.View(), text); !read.IsOk())
            {
                LOG_ERROR(u8"GUI", u8"'{}': source file missing - cook failed", asset.fileName.View());
                return read;
            }
            Array<gui::GuiDiagnostic> said;
            const bool readable = Validate(text.AsView(), said, *ctx.allocator);
            detail::LogGuiDiagnostics(asset.fileName.View(), said);
            if (!readable)
            {
                LOG_ERROR(u8"GUI", u8"'{}' cannot be read - cook failed", asset.fileName.View());
                return Status{ErrorCode::InvalidArgument};
            }
            Array<Guid> references;
            detail::AddGuidReferences(asset.fileName.View(), text.AsView(), ctx, references, true);
            Cooked cooked;
            cooked.*Text = Move(text);
            return ctx.output->WriteObject(cooked);
        }

    protected:
        [[nodiscard]] virtual bool Validate(StringView text, Array<gui::GuiDiagnostic>& said, IAllocator& allocator) const = 0;
    };

    class GuiDocumentAssetBuilder final : public GuiTextAssetBuilder<GuiDocumentAsset, gui::GuiDocumentSource, &gui::GuiDocumentSource::markup>
    {
    protected:
        [[nodiscard]] bool Validate(StringView text, Array<gui::GuiDiagnostic>& said, IAllocator& allocator) const override
        {
            return ValidateGuiDocument(text, said, allocator);
        }
    };

    class GuiStyleSheetAssetBuilder final
        : public GuiTextAssetBuilder<GuiStyleSheetAsset, gui::GuiStyleSheetSource, &gui::GuiStyleSheetSource::css>
    {
    protected:
        [[nodiscard]] bool Validate(StringView text, Array<gui::GuiDiagnostic>& said, IAllocator&) const override
        {
            ValidateGuiStyleSheet(text, said);
            return true;
        }
    };

    /// Drag-drop importer for `.gml` and `.css` files: STAGED into Sources/ and LINKED, as a
    /// document or a sheet by the extension.
    class GuiFileImporter final : public pipeline::IFileImporter
    {
    public:
        [[nodiscard]] StringView Label() const override { return u8"GUI document or style sheet"; }
        [[nodiscard]] bool Accepts(StringView extension) const override { return extension == u8"gml" || extension == u8"css"; }

        [[nodiscard]] pipeline::ImportPlan DescribeImport(StringView sourcePath, const pipeline::ImportOptions*, Object*) override
        {
            return pipeline::SingleAssetPlan(sourcePath); // one asset, named after the stem
        }

        [[nodiscard]] pipeline::ImportPlan StoredSelection(foundation::content::Group& group, StringView sourcePath) override
        {
            return pipeline::SingleAssetStoredSelection(group, sourcePath, IsSheet(sourcePath) ? u8"GuiStyleSheetAsset" : u8"GuiDocumentAsset");
        }

        [[nodiscard]] Result<foundation::content::Instance*> Import(StringView sourcePath, const pipeline::ImportContext& context,
                                                                     foundation::content::Group& group,
                                                                     const pipeline::ImportOptions* options, Object*,
                                                                     Array<pipeline::DeferredImportWrite>*) override
        {
            Result<String> fileName = pipeline::CopyIntoSources(context, sourcePath);
            if (!fileName.HasValue())
                return Err(fileName.Error());
            const StringView stem = pipeline::FileStemOf(fileName.Value().AsView());
            const bool sheet = IsSheet(sourcePath);
            foundation::content::Instance* instance = group.CreateInstance(
                pipeline::SingleAssetName(options, stem), sheet ? GuiStyleSheetAsset::StaticType() : GuiDocumentAsset::StaticType());
            if (instance == nullptr)
                return Err(ErrorCode::Unknown);
            Status written;
            if (sheet)
            {
                GuiStyleSheetAsset asset;
                asset.fileName = foundation::vfs::SourcePath(fileName.Value().AsView());
                written = instance->WriteObject(asset);
            }
            else
            {
                GuiDocumentAsset asset;
                asset.fileName = foundation::vfs::SourcePath(fileName.Value().AsView());
                written = instance->WriteObject(asset);
            }
            if (!written.IsOk())
                return Err(written.Code());
            return instance;
        }

    private:
        [[nodiscard]] static bool IsSheet(StringView path)
        {
            return path.Size() >= 4 && path.SubStr(path.Size() - 4, 4) == StringView(u8".css");
        }
    };

    inline void RegisterGuiAssets()
    {
        GlobalTypeRegistry().Register(GuiDocumentAsset::StaticType(), TypeDomain(u8"Pipeline"));
        RegisterSerializable<GuiDocumentAsset>();
        GlobalTypeRegistry().Register(GuiStyleSheetAsset::StaticType(), TypeDomain(u8"Pipeline"));
        RegisterSerializable<GuiStyleSheetAsset>();
    }

    /// The GUI's New Asset creators: a document and a style sheet, each a linked source file
    /// written from starter text. Defined in GuiCreatorsImpl.cpp.
    void RegisterGuiCreators(AssetCreatorRegistry& registry);

    // The assets' StaticType() are defined WITH their reflected attributes in GuiAssetImpl.cpp.
}
