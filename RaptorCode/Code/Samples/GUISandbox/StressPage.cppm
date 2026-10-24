// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUISandbox - the Stress page (E8a of Specs/gui-lab-evolution.md): the worst case the GUI's
// performance work is measured on. Its markup (pages/stress.xml) holds the controls; this builds
// the sections into #stress-root at a load from 1 to 20: a long column of rows, text in several
// faces and sizes, every box effect at once, running animations, a list and a table of 100,000
// rows, deep nesting, and many generated rules (Rules) for the cascade to match against.

module;
#include "Core/Prelude.h"
#include <cstdio> // printf: the build times

export module gui.sandbox.stress;

import foundation.core;
import foundation.fonts;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace gui = foundation::gui;

export namespace sandbox
{
    class StressPage
    {
    public:
        /// The rows of the list and of the table, whatever the load (they are virtualized).
        static constexpr i32 kViewRows = 100000;
        /// Classes the rows take in turn, which the generated rules name.
        static constexpr i32 kRowKinds = 50;

        StressPage(IAllocator& allocator, fonts::CachedFont* font) : m_allocator(allocator), m_font(font) {}

        /// Rules for the page's sheet: `count` per load, most matching nothing, as a large
        /// stylesheet's do, the rest matching rows through descendant and child selectors.
        [[nodiscard]] static String Rules(i32 count)
        {
            String css;
            for (i32 i = 0; i < count; ++i)
            {
                const i32 kind = i % kRowKinds;
                switch (i % 4)
                {
                case 0:
                    css += Format(u8".stress-root .k{} > .cell {{ margin-left: 0px; }}\n", kind);
                    break;
                case 1:
                    css += Format(u8".alt .k{} .tag {{ letter-spacing: 0px; }}\n", kind);
                    break;
                case 2:
                    css += Format(u8".unused-{} .stress-row .note {{ color: #ff00ff; }}\n", i);
                    break;
                default:
                    css += Format(u8".stress-row.k{} + .stress-row > .cell {{ border-radius: 3px; }}\n", kind);
                    break;
                }
            }
            return css;
        }

        /// Finds its controls and its root under `page` and wires them.
        void Attach(gui::Node& page)
        {
            m_root = Find(page, u8"stress-root");
            m_stats = Cast<gui::Label>(Find(page, u8"stress-stats"));
            auto* load = Cast<gui::NumberField>(Find(page, u8"stress-load"));
            StressPage* self = this;
            if (auto* build = Cast<gui::Button>(Find(page, u8"stress-build")))
                build->SetOnClick([self, load]() { self->Build(load != nullptr ? static_cast<i32>(load->GetValue()) : 1); });
            if (auto* restyle = Cast<gui::Button>(Find(page, u8"stress-restyle")))
                restyle->SetOnClick([self]() { self->ToggleAlt(); });
            if (auto* animate = Cast<gui::CheckBox>(Find(page, u8"stress-animate")))
                animate->SetOnToggled([self](bool on) { self->SetAnimating(on); });
            if (load != nullptr)
                load->SetValue(static_cast<f64>(m_load));
        }

        /// The load the page is built at (1 to 20) the first time it is shown.
        void SetLoad(i32 load) noexcept { m_load = Clamp(load, 1, 20); }
        [[nodiscard]] i32 GetLoad() const noexcept { return m_load; }
        [[nodiscard]] bool IsBuilt() const noexcept { return m_built; }

        /// Builds the sections again at `load`.
        void Build(i32 load)
        {
            if (m_root == nullptr)
                return;
            SetLoad(load);
            // Each section's build time is printed: building is part of the worst case too.
            Stopwatch watch = Stopwatch::StartNew();
            const auto timed = [&watch](const char* what)
            {
                std::printf("GUISandbox stress: %s built in %.1f ms\n", what, watch.Elapsed().AsMilliseconds());
                std::fflush(stdout);
                watch.Restart();
            };
            m_root->RemoveAllChildren();
            timed("the old sections removed");
            BuildColumn(*Section(u8"Rows", u8"stress-column"), 400 * m_load);
            timed("rows");
            BuildText(*Section(u8"Text", u8"stress-text"), 40 * m_load);
            timed("text");
            BuildEffects(*Section(u8"Box effects", u8"stress-wrap"), 24 * m_load);
            timed("effects");
            BuildAnimations(*Section(u8"Animations", u8"stress-anim"), 150 * m_load);
            timed("animations");
            BuildViews(*Section(u8"A list and a table of 100,000 rows", u8"stress-views"));
            timed("views");
            BuildDeep(*Section(u8"Nesting", u8"stress-deep"), Min(100 * m_load, 500));
            timed("nesting");
            m_built = true;
        }

        /// Shows the last frame's costs on the page.
        void ShowStats(const gui::FrameStats& stats)
        {
            if (m_stats == nullptr)
                return;
            String text(u8"Last frame at load ");
            text += Format(u8"{}: ", m_load);
            text += stats.Describe().AsView();
            m_stats->SetText(text.AsView());
        }

    private:
        [[nodiscard]] static gui::Node* Find(gui::Node& node, StringView id)
        {
            if (const auto* widget = Cast<gui::UIWidget>(&node); widget != nullptr && widget->GetId() == id)
                return &node;
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (gui::Node* found = Find(*node.GetChildAt(i), id))
                    return found;
            return nullptr;
        }

        template <typename T>
        RefPtr<T> Add(gui::Node& parent, StringView cls = {})
        {
            RefPtr<T> node = MakeRef<T>(m_allocator);
            if (cls.Size() != 0)
                node->AddClass(cls);
            parent.AddChild(node.Get());
            return node;
        }
        RefPtr<gui::Label> AddLabel(gui::Node& parent, StringView cls, StringView text)
        {
            RefPtr<gui::Label> label = Add<gui::Label>(parent, cls);
            label->SetText(text);
            return label;
        }

        // A titled section whose body (returned) takes `cls`.
        gui::Node* Section(const char8_t* title, const char8_t* cls)
        {
            RefPtr<gui::Panel> section = Add<gui::Panel>(*m_root, u8"section");
            (void)AddLabel(*section, u8"section-title", StringView(title));
            return Add<gui::Panel>(*section, StringView(cls)).Get();
        }

        void BuildColumn(gui::Node& column, i32 rows)
        {
            for (i32 i = 0; i < rows; ++i)
            {
                RefPtr<gui::Panel> row = Add<gui::Panel>(column, u8"stress-row");
                row->AddClass(Format(u8"k{}", i % kRowKinds).AsView());
                (void)AddLabel(*row, u8"tag", Format(u8"Row {}", i).AsView());
                (void)Add<gui::UIWidget>(*row, u8"cell");
                (void)Add<gui::UIWidget>(*row, u8"cell");
                (void)AddLabel(*row, u8"note", u8"a note that the sibling rules dim");
            }
        }

        void BuildText(gui::Node& body, i32 count)
        {
            static constexpr const char8_t* kSizes[4] = {u8"t1", u8"t2", u8"t3", u8"t4"};
            for (i32 i = 0; i < count; ++i)
            {
                if (i % 5 == 4)
                {
                    RefPtr<gui::RichText> rich = Add<gui::RichText>(body, u8"t");
                    rich->AddClass(StringView(kSizes[i % 4]));
                    rich->SetWhiteSpace(gui::TextWhiteSpace::Normal);
                    rich->SetText(u8"Rich text with [b]bold[/b], [i]italic[/i] and [color=#e69138]coloured[/color] runs, wrapped at the page's width like the rest.");
                    continue;
                }
                RefPtr<gui::Label> label = AddLabel(body, u8"t", Format(u8"Line {}: a sentence long enough to wrap onto a second line at the page's width, shaped and measured every time the text or its width changes.", i).AsView());
                label->AddClass(StringView(kSizes[i % 4]));
                label->SetWhiteSpace(gui::TextWhiteSpace::Normal);
            }
        }

        void BuildEffects(gui::Node& body, i32 count)
        {
            static constexpr const char8_t* kKinds[5] = {u8"", u8"fx-glass", u8"fx-blur", u8"fx-multiply", u8"fx-group"};
            for (i32 i = 0; i < count; ++i)
            {
                const StringView kind(kKinds[i % 5]);
                if (kind == StringView(u8"fx-group"))
                {
                    // A group fading as one picture, with children of its own.
                    RefPtr<gui::Panel> group = Add<gui::Panel>(body, u8"fx");
                    group->AddClass(kind);
                    (void)AddLabel(*group, u8"", u8"group");
                    (void)AddLabel(*group, u8"", u8"of two");
                    continue;
                }
                RefPtr<gui::Label> box = AddLabel(body, u8"fx", Format(u8"effect {}", i).AsView());
                if (kind.Size() != 0)
                    box->AddClass(kind);
            }
        }

        void BuildAnimations(gui::Node& body, i32 count)
        {
            m_animations = &body;
            for (i32 i = 0; i < count; ++i)
            {
                RefPtr<gui::UIWidget> box = Add<gui::UIWidget>(body, i % 2 == 0 ? u8"spin" : u8"pulse");
                box->SetInlineStyle(u8"animation-delay", Format(u8"{}ms", (i * 37) % 1000).AsView());
            }
            SetAnimating(m_animating);
        }

        void BuildViews(gui::Node& body)
        {
            if (!m_listModel)
            {
                m_listModel = MakeUnique<gui::StringListModel>(m_allocator);
                Array<String> rows;
                for (i32 i = 0; i < kViewRows; ++i)
                    rows.PushBack(Format(u8"List row {}", i));
                m_listModel->SetItems(Move(rows));
                m_tableModel = MakeUnique<gui::TableModel>(m_allocator);
                Array<String> columns;
                columns.PushBack(String(u8"Name"));
                columns.PushBack(String(u8"Score"));
                columns.PushBack(String(u8"Group"));
                m_tableModel->SetColumns(Move(columns));
                for (i32 i = 0; i < kViewRows; ++i)
                {
                    Array<gui::Variant> cells;
                    cells.PushBack(gui::Variant(Format(u8"Entry {}", i).AsView()));
                    cells.PushBack(gui::Variant(static_cast<i64>((i * 7919) % 1000)));
                    cells.PushBack(gui::Variant(Format(u8"G{}", i % 12).AsView()));
                    m_tableModel->AddRow(Move(cells));
                }
            }
            RefPtr<gui::ListView> list = Add<gui::ListView>(body);
            list->SetSize(Float2{260.0f, 240.0f});
            list->SetFont(m_font);
            list->SetRowHeight(22.0f);
            list->SetModel(m_listModel.Get());
            RefPtr<gui::TableView> table = Add<gui::TableView>(body);
            table->SetSize(Float2{360.0f, 240.0f});
            table->SetFont(m_font);
            table->SetRowHeight(22.0f);
            table->SetModel(m_tableModel.Get());
        }

        void BuildDeep(gui::Node& body, i32 levels)
        {
            gui::Node* at = &body;
            for (i32 i = 0; i < levels; ++i)
                at = Add<gui::Panel>(*at, u8"deep").Get();
            (void)AddLabel(*at, u8"", Format(u8"{} levels down", levels).AsView());
        }

        void ToggleAlt()
        {
            auto* root = Cast<gui::UIWidget>(m_root);
            if (root == nullptr)
                return;
            m_alt = !m_alt;
            if (m_alt)
                root->AddClass(u8"alt");
            else
                root->RemoveClass(u8"alt");
        }
        void SetAnimating(bool animating)
        {
            m_animating = animating;
            auto* body = Cast<gui::UIWidget>(m_animations);
            if (body == nullptr)
                return;
            if (animating)
                body->RemoveClass(u8"still");
            else
                body->AddClass(u8"still");
        }

        IAllocator& m_allocator;
        fonts::CachedFont* m_font = nullptr;
        gui::Node* m_root = nullptr;  // in the page, which the sandbox owns
        gui::Label* m_stats = nullptr;
        gui::Node* m_animations = nullptr;
        i32 m_load = 1;
        bool m_built = false;
        bool m_alt = false;
        bool m_animating = true;
        // The views' models: the sandbox keeps this page alive longer than its GUI, so the views
        // (their clients) go first.
        UniquePtr<gui::StringListModel> m_listModel;
        UniquePtr<gui::TableModel> m_tableModel;
    };
}
