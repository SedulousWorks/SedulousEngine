// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// foundation.gui.inspector - :inspector partition
//
// Inspector: the GUI's inspector (E8e of Specs/gui-lab-evolution.md), built from the GUI's own
// widgets in a root of its own on the inspected GUI's context, which a host shows as a pane beside
// the root it inspects. The Elements tab lists the tree (live: rebuilt when its shape changes) over
// the selected node's details: what it is, its states with toggles that force them, its box, its
// styles grouped by rule with sheet and line (inherited ones under their ancestor), its reflected
// properties edited live as markup sets them, its bindings, commands and listeners, and how it
// measures. Picking (the host routes the pointer over the inspected root here while it is on)
// outlines what is under the pointer, the wheel walking out and in through what holds it (gpui's),
// and a click selects it. The Frames tab draws the frame costs the host records. The host draws
// DrawOverTarget over the inspected root: the box model of the node under the pointer and of the
// one selected.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.inspector:inspector;

import foundation.core;
import foundation.fonts;
import foundation.vg;
import foundation.gui;
import :queries;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;

export namespace foundation::gui::inspector
{
    /// How the inspector writes: its font (a family the host's font service knows) and size.
    struct InspectorOptions
    {
        core::String FontFamily{core::StringView(u8"Roboto")};
        f32 FontSize = 13.0f;
    };

    /// The last few seconds of frame costs, drawn as stacked bars (style, layout, draw).
    class FramesGraph : public UIWidget
    {
        RTTI_OBJECT(FramesGraph, UIWidget)
    public:
        static constexpr usize kFrames = 240;
        FramesGraph() { SetTag(core::StringView(u8"framesgraph")); }

        void Record(const FrameStats& stats)
        {
            Sample s{static_cast<f32>(stats.StyleMs), static_cast<f32>(stats.LayoutMs), static_cast<f32>(stats.DrawMs)};
            if (m_samples.Size() < kFrames)
                m_samples.PushBack(s);
            else
            {
                m_samples[m_next] = s;
                m_next = (m_next + 1) % kFrames;
            }
            Invalidate();
        }
        [[nodiscard]] usize SampleCount() const noexcept { return m_samples.Size(); }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& local) override
        {
            vg::VGContext& g = ctx.VG();
            g.FillRect(local.ToRectangle(), core::Color{0.08f, 0.09f, 0.11f, 1.0f});
            // A line at 16.7 ms (a 60 Hz frame); the bars scale to the larger of it and the worst.
            f32 worst = 16.7f;
            for (const Sample& s : m_samples)
                worst = core::Max(worst, s.Style + s.Layout + s.Draw);
            const f32 scale = local.height / worst;
            const f32 budget = local.Bottom() - 16.7f * scale;
            g.FillRect(core::Rectangle{local.x, budget, local.width, 1.0f}, core::Color{1.0f, 1.0f, 1.0f, 0.25f});
            const f32 w = local.width / static_cast<f32>(kFrames);
            for (usize i = 0; i < m_samples.Size(); ++i)
            {
                const Sample& s = m_samples[(m_samples.Size() < kFrames ? i : (m_next + i) % kFrames)];
                const f32 x = local.x + static_cast<f32>(i) * w;
                f32 y = local.Bottom();
                const auto bar = [&](f32 ms, core::Color color)
                {
                    const f32 h = ms * scale;
                    g.FillRect(core::Rectangle{x, y - h, core::Max(w - 0.5f, 0.5f), h}, color);
                    y -= h;
                };
                bar(s.Style, core::Color{0.95f, 0.65f, 0.25f, 1.0f});
                bar(s.Layout, core::Color{0.35f, 0.8f, 0.45f, 1.0f});
                bar(s.Draw, core::Color{0.4f, 0.6f, 1.0f, 1.0f});
            }
        }

    private:
        struct Sample
        {
            f32 Style, Layout, Draw;
        };
        Array<Sample> m_samples;
        usize m_next = 0;
    };
    RTTI_DEFINE_OBJECT(FramesGraph, "rtti::gui::inspector")

    class Inspector
    {
    public:
        Inspector(IAllocator& allocator, RefPtr<GUIContext> context, fonts::IFontService* fontService, InspectorOptions options = {})
            : m_allocator(allocator), m_options(core::Move(options))
        {
            m_root = core::MakeRef<SceneRoot>(allocator, core::Move(context));
            m_font = fontService != nullptr ? fontService->GetFont(m_options.FontFamily.AsView(), m_options.FontSize) : nullptr;
            m_root->SetDebugFont(m_font);
            m_styles.SetFontService(fontService);
            m_styles.SetUserAgentSheet(CSSParser::Parse(DefaultThemeCSS(), core::StringView(u8"theme")));
            m_styles.SetStyleSheet(CSSParser::Parse(Sheet().AsView(), core::StringView(u8"inspector")));
            Build();
        }
        Inspector(const Inspector&) = delete;
        Inspector& operator=(const Inspector&) = delete;
        ~Inspector()
        {
            // The views hold the models: they go before them.
            if (m_root)
                m_root->RemoveAllChildren();
        }

        /// What it inspects: a root and the style manager that styles it (for the styles' origins).
        void Inspect(SceneRoot* target, StyleManager* targetStyles)
        {
            m_target = target;
            m_targetStyles = targetStyles;
            m_signature = 0;
            Select(nullptr);
        }
        [[nodiscard]] SceneRoot* GetTarget() const noexcept { return m_target; }
        [[nodiscard]] SceneRoot& GetRoot() const noexcept { return *m_root; }
        /// Its root held, for a host that draws it as a pane of a window.
        [[nodiscard]] RefPtr<SceneRoot> GetRootRef() const noexcept { return m_root; }
        [[nodiscard]] StyleManager& GetStyles() noexcept { return m_styles; }

        /// Once a frame, before its root's style pass: the tree when its shape changed, the details
        /// now and then (values move).
        void Refresh()
        {
            if (m_target == nullptr)
                return;
            ++m_refreshes;
            if (m_refreshes % 10 == 1) // the shape's signature walks the tree: a few times a second
            {
                const u64 signature = Signature(*m_target);
                if (signature != m_signature)
                {
                    m_signature = signature;
                    RebuildTree();
                }
            }
            // The details again when the selection changed, and now and then for values that moved,
            // but not under a field being edited there.
            Node* selected = GetSelected();
            if (selected != m_detailsFor || m_detailsStale || (m_refreshes % 60 == 0 && !EditingDetails()))
                RebuildDetails();
        }

        // === The tree's branches ===
        /// Folds `node`'s branch away in the tree (its descendants leave the list) or opens it.
        void SetCollapsed(Node* node, bool collapsed)
        {
            if (node == nullptr || IsCollapsed(node) == collapsed)
                return;
            if (collapsed)
                m_collapsed.PushBack(node);
            else
                for (usize i = 0; i < m_collapsed.Size(); ++i)
                    if (m_collapsed[i] == node)
                    {
                        m_collapsed.RemoveAt(i);
                        break;
                    }
            if (m_target != nullptr)
                RebuildTree();
        }
        [[nodiscard]] bool IsCollapsed(const Node* node) const
        {
            for (const Node* n : m_collapsed)
                if (n == node)
                    return true;
            return false;
        }

        // === Selection ===
        void Select(Node* node)
        {
            // What holds it opens, so its row shows.
            bool opened = false;
            for (Node* n = node != nullptr ? node->GetParent() : nullptr; n != nullptr; n = n->GetParent())
                for (usize i = 0; i < m_collapsed.Size(); ++i)
                    if (m_collapsed[i] == n)
                    {
                        m_collapsed.RemoveAt(i);
                        opened = true;
                        break;
                    }
            if (opened && m_target != nullptr)
                RebuildTree();
            m_selected = node != nullptr ? node->TakeElementRef() : Node::ElementRef{};
            m_selectedRaw = node;
            if (node != nullptr && m_tree != nullptr)
                for (usize i = 0; i < m_entries.Size(); ++i)
                    if (m_entries[i].Target == node)
                    {
                        m_selecting = true;
                        m_tree->SetSelectedItem(static_cast<i32>(i));
                        m_tree->ScrollToItem(static_cast<i32>(i));
                        m_selecting = false;
                    }
            RebuildDetails();
        }
        /// The node selected while it lives (null once it is gone).
        [[nodiscard]] Node* GetSelected() const
        {
            if (m_selected.table != nullptr)
                return m_selected.table->Resolve(m_selected.slot, m_selected.generation);
            return m_selectedRaw != nullptr && m_target != nullptr && Contains(*m_target, m_selectedRaw) ? m_selectedRaw : nullptr;
        }

        // === Picking ===
        void SetPicking(bool picking)
        {
            m_picking = picking;
            m_hoverPath.Clear();
            if (m_pick != nullptr)
                m_pick->SetChecked(picking);
            if (m_target != nullptr)
                m_target->Invalidate();
        }
        [[nodiscard]] bool IsPicking() const noexcept { return m_picking; }
        /// The pointer at `world` (the inspected root's world) while picking: what is under it.
        void PickHover(core::Float2 world)
        {
            if (!m_picking || m_target == nullptr)
                return;
            Array<Node*> path;
            for (Node* n = m_target->OverFind(world); n != nullptr && n != m_target; n = n->GetParent())
                path.PushBack(n);
            if (path.Size() == m_hoverPath.Size() && (path.IsEmpty() || path[0] == m_hoverPath[0]))
                return;
            m_hoverPath = core::Move(path);
            m_hoverLevel = 0;
            m_target->Invalidate();
        }
        /// The wheel while picking: out to what holds the node (up) or back in (down).
        void PickWheel(f32 delta)
        {
            if (!m_picking || m_hoverPath.IsEmpty())
                return;
            const i32 level = static_cast<i32>(m_hoverLevel) + (delta > 0.0f ? 1 : -1);
            m_hoverLevel = static_cast<usize>(core::Clamp(level, 0, static_cast<i32>(m_hoverPath.Size()) - 1));
            m_target->Invalidate();
        }
        /// A click while picking: selects what is outlined and stops picking.
        void PickClick()
        {
            if (!m_picking)
                return;
            Node* picked = GetHovered();
            SetPicking(false);
            if (picked != nullptr)
                Select(picked);
        }
        /// Selects the first widget `selector` matches in the inspected root (the query field's
        /// Enter); how many it matched.
        usize SelectQuery(core::StringView selector)
        {
            if (m_target == nullptr)
                return 0;
            const Array<Node*> found = Query(*m_target, selector);
            m_queryCount->SetText(core::Format(u8"{} found", found.Size()).AsView());
            if (!found.IsEmpty())
                Select(found[0]);
            return found.Size();
        }

        /// What picking outlines (null when nothing, or when it is gone since the pointer moved).
        [[nodiscard]] Node* GetHovered() const
        {
            if (!m_picking || m_hoverLevel >= m_hoverPath.Size() || m_target == nullptr)
                return nullptr;
            Node* node = m_hoverPath[m_hoverLevel];
            return Contains(*m_target, node) ? node : nullptr;
        }

        /// The frames tab's next bar (the inspected root's last frame).
        void RecordFrame(const FrameStats& stats)
        {
            if (m_frames != nullptr)
                m_frames->Record(stats);
        }

        /// Over the inspected root, drawn in its world with the canvas untransformed: the box
        /// model (margin orange, padding green, content blue) of what picking outlines, else of the
        /// node selected, with its name.
        void DrawOverTarget(DrawContext& ctx) const
        {
            const Node* node = GetHovered();
            if (node == nullptr)
                node = GetSelected();
            if (node == nullptr || !node->IsTreeVisible())
                return;
            vg::VGContext& g = ctx.VG();
            const Transform2D world = node->GetWorldTransform();
            const Thickness m = node->GetMargin();
            const Rect border = node->GetLocalBounds();
            const Rect margin{-m.Left, -m.Top, border.width + m.TotalHorizontal(), border.height + m.TotalVertical()};
            const Rect content = node->GetContentBounds();
            g.FillRect(world.TransformRect(margin).ToRectangle(), core::Color{1.0f, 0.6f, 0.2f, 0.25f});
            g.FillRect(world.TransformRect(border).ToRectangle(), core::Color{0.3f, 0.85f, 0.4f, 0.25f});
            g.FillRect(world.TransformRect(content).ToRectangle(), core::Color{0.35f, 0.55f, 1.0f, 0.3f});
            const Rect box = world.TransformRect(border);
            g.StrokeRect(box.ToRectangle(), core::Color{0.35f, 0.55f, 1.0f, 0.9f}, 1.0f);
            if (m_font != nullptr)
            {
                const core::String text = core::Format(u8"{}  {}x{}", Label(*node), static_cast<i32>(node->GetSize().x),
                                                       static_cast<i32>(node->GetSize().y));
                const f32 width = 7.0f * static_cast<f32>(text.Size()) + 10.0f;
                const f32 y = box.y >= 20.0f ? box.y - 20.0f : box.Bottom();
                g.FillRect(core::Rectangle{box.x, y, width, 20.0f}, core::Color{0.05f, 0.06f, 0.08f, 0.9f});
                g.DrawText(text.AsView(), m_font, core::Rectangle{box.x + 5.0f, y, width - 5.0f, 20.0f}, fonts::TextAlignment::Left,
                           fonts::VerticalAlignment::Middle, core::Color{0.85f, 0.9f, 1.0f, 1.0f});
            }
        }

        /// The details' rows (for tests): each label's and field's text, in order.
        [[nodiscard]] Array<core::String> DetailsText() const
        {
            Array<core::String> out;
            const auto walk = [&out](auto& self, const Node& node) -> void
            {
                if (const gui::Label* label = core::Cast<gui::Label>(&node))
                    out.PushBack(core::String(label->GetText()));
                else if (const TextField* field = core::Cast<TextField>(&node))
                    out.PushBack(core::String(field->GetText()));
                for (usize i = 0; i < node.ChildCount(); ++i)
                    self(self, *node.GetChildAt(i));
            };
            if (m_details != nullptr)
                walk(walk, *m_details);
            return out;
        }
        [[nodiscard]] usize TreeRowCount() const noexcept { return m_entries.Size(); }

    private:
        [[nodiscard]] core::String Sheet() const
        {
            const core::String family = m_options.FontFamily;
            const i32 size = static_cast<i32>(m_options.FontSize);
            core::String css = core::Format(
                u8".inspector, .inspector label, .inspector button, .inspector textfield, .inspector checkbox, .inspector tab"
                u8" {{ font-family: {}; font-size: {}px; }}\n",
                family, size);
            css += core::StringView(
                u8".inspector { width: 100%; height: 100%; flex-direction: column; background-color: #181b21; padding: 6px; gap: 6px; color: #d6dbe3; }\n"
                u8".ibar { flex-direction: row; align-items: center; gap: 6px; height: 28px; flex-shrink: 0; }\n"
                u8".itabs > tabbar { flex-shrink: 0; }\n"
                u8".ibar textfield { flex-grow: 1; height: 26px; }\n"
                u8".ibar button { height: 26px; padding-left: 10px; padding-right: 10px; }\n"
                u8".itabs { flex-grow: 1; min-height: 0px; }\n"
                u8".ielements { flex-direction: column; gap: 6px; flex-grow: 1; min-height: 0px; }\n"
                u8".itree { flex-grow: 2; min-height: 160px; }\n"
                u8".idetails { flex-grow: 3; min-height: 160px; overflow-x: hidden; }\n"
                u8".idetailbody { flex-direction: column; gap: 2px; padding: 4px; }\n"
                u8".ihead { color: #ffffff; font-size: 15px; }\n"
                u8".isection { color: #7fb2ff; margin-top: 8px; }\n"
                u8".irule { color: #e6c07b; margin-top: 4px; }\n"
                u8".iline { color: #c8ced8; white-space: normal; }\n"
                u8".idim { color: #7d8594; }\n"
                u8".iover { color: #6b7280; }\n"
                u8".iforce { flex-direction: row; flex-wrap: wrap; gap: 8px; }\n"
                u8".iprop { flex-direction: row; align-items: center; gap: 6px; height: 24px; }\n"
                u8".iprop label { width: 140px; color: #c8ced8; }\n"
                u8".iprop textfield { flex-grow: 1; height: 22px; }\n"
                u8"framesgraph { flex-grow: 1; min-height: 120px; }\n");
            return css;
        }

        template <typename T>
        RefPtr<T> Add(Node& parent, core::StringView cls = {})
        {
            RefPtr<T> node = core::MakeRef<T>(m_allocator);
            if (cls.Size() != 0)
                if (UIWidget* w = core::Cast<UIWidget>(node.Get()))
                    w->AddClass(cls);
            parent.AddChild(node.Get());
            return node;
        }
        RefPtr<gui::Label> Text(Node& parent, core::StringView cls, core::StringView text)
        {
            RefPtr<gui::Label> label = Add<gui::Label>(parent, cls);
            label->SetText(text);
            return label;
        }

        void Build()
        {
            RefPtr<Panel> shell = Add<Panel>(*m_root, core::StringView(u8"inspector"));
            m_shell = shell.Get();
            RefPtr<Panel> bar = Add<Panel>(*shell, core::StringView(u8"ibar"));
            RefPtr<CheckBox> pick = Add<CheckBox>(*bar);
            pick->SetText(core::StringView(u8"Pick"));
            m_pick = pick.Get();
            Inspector* self = this;
            pick->SetOnToggled([self](bool on) { if (on != self->m_picking) self->SetPicking(on); });
            RefPtr<TextField> query = Add<TextField>(*bar);
            query->SetPlaceholder(core::StringView(u8"selector, Enter to select the first match"));
            query->SetOnSubmit([self](core::StringView text) { (void)self->SelectQuery(text); });
            m_queryCount = Text(*bar, core::StringView(u8"idim"), core::StringView{}).Get();

            RefPtr<TabView> tabs = Add<TabView>(*shell, core::StringView(u8"itabs"));
            TabPage* elements = tabs->AddPage(core::StringView(u8"Elements"));
            elements->SetClosable(false);
            elements->AddClass(core::StringView(u8"ielements"));
            m_model = core::MakeUnique<StringListModel>(m_allocator);
            RefPtr<ListView> tree = Add<ListView>(*elements, core::StringView(u8"itree"));
            tree->SetFont(m_font);
            tree->SetRowHeight(m_options.FontSize + 7.0f);
            tree->SetModel(m_model.Get());
            tree->SetOnSelectionChanged([self](ModelIndex index)
            {
                if (self->m_selecting || !index.IsValid() || static_cast<usize>(index.Row) >= self->m_entries.Size())
                    return;
                Node* node = self->m_entries[static_cast<usize>(index.Row)].Target;
                if (self->m_target != nullptr && Contains(*self->m_target, node)) // the tree may have changed since
                    self->Select(node);
            });
            // A row activated (a double click, Enter) folds its branch or opens it.
            tree->SetOnActivated([self](ModelIndex index)
            {
                if (!index.IsValid() || static_cast<usize>(index.Row) >= self->m_entries.Size())
                    return;
                Node* node = self->m_entries[static_cast<usize>(index.Row)].Target;
                if (self->m_target != nullptr && Contains(*self->m_target, node) && node->ChildCount() != 0)
                    self->SetCollapsed(node, !self->IsCollapsed(node));
            });
            m_tree = tree.Get();
            RefPtr<ScrollView> details = Add<ScrollView>(*elements, core::StringView(u8"idetails"));
            m_details = Add<Panel>(*details, core::StringView(u8"idetailbody")).Get();

            TabPage* frames = tabs->AddPage(core::StringView(u8"Frames"));
            frames->SetClosable(false);
            frames->AddClass(core::StringView(u8"ielements"));
            (void)Text(*frames, core::StringView(u8"idim"), core::StringView(u8"Style (orange), layout (green) and draw (blue) of each frame drawn; the line is 16.7 ms."));
            m_frames = Add<FramesGraph>(*frames).Get();
        }

        // The focus is in the details (a property being edited).
        [[nodiscard]] bool EditingDetails() const
        {
            for (const Node* n = m_root->GetEventDispatcher()->GetFocusNode(); n != nullptr; n = n->GetParent())
                if (n == m_details)
                    return true;
            return false;
        }
        // Whether `node` is in the tree under `root` (a raw pointer checked before it is used).
        [[nodiscard]] static bool Contains(Node& root, const Node* node)
        {
            if (&root == node)
                return true;
            for (usize i = 0; i < root.ChildCount(); ++i)
                if (Contains(*root.GetChildAt(i), node))
                    return true;
            return false;
        }
        // The tree's shape: each node and its children's arrangement, hashed in order.
        [[nodiscard]] static u64 Signature(Node& root)
        {
            u64 hash = core::kFnv1a64OffsetBasis;
            const auto walk = [&hash](auto& self, Node& node) -> void
            {
                const Node* address = &node;
                const u32 generation = node.ChildrenGeneration();
                hash = core::HashBytes(&address, sizeof(address), hash);
                hash = core::HashBytes(&generation, sizeof(generation), hash);
                for (usize i = 0; i < node.ChildCount(); ++i)
                    self(self, *node.GetChildAt(i));
            };
            walk(walk, root);
            return hash;
        }

        void RebuildTree()
        {
            // The whole tree, less what folded branches hold; a fold of a node gone is forgotten.
            const Array<TreeEntry> all = Tree(*m_target);
            for (usize i = m_collapsed.Size(); i-- > 0;)
            {
                bool present = false;
                for (const TreeEntry& e : all)
                    present = present || e.Target == m_collapsed[i];
                if (!present)
                    m_collapsed.RemoveAt(i);
            }
            m_entries.Clear();
            u32 foldedBelow = ~0u; // the depth of the fold being skipped, none when ~0
            for (const TreeEntry& e : all)
            {
                if (foldedBelow != ~0u && e.Depth > foldedBelow)
                    continue;
                foldedBelow = IsCollapsed(e.Target) ? e.Depth : ~0u;
                m_entries.PushBack(e);
            }
            Array<core::String> rows;
            for (const TreeEntry& e : m_entries)
            {
                core::String row;
                // Indented by no-break spaces: a row's white space collapses, theirs does not.
                for (u32 d = 0; d < e.Depth; ++d)
                    row += core::StringView(u8"\u00A0\u00A0\u00A0");
                // A branch says whether it is open (-) or folded (+); a leaf leaves the room.
                row += core::StringView(e.Target->ChildCount() == 0 ? u8"\u00A0\u00A0" : IsCollapsed(e.Target) ? u8"+\u00A0" : u8"-\u00A0");
                row += e.Label.AsView();
                if (!e.Shown)
                    row += core::StringView(u8"  (hidden)");
                rows.PushBack(core::Move(row));
            }
            m_selecting = true;
            m_model->SetItems(core::Move(rows));
            m_selecting = false;
            if (Node* selected = GetSelected())
                for (usize i = 0; i < m_entries.Size(); ++i)
                    if (m_entries[i].Target == selected)
                    {
                        m_selecting = true;
                        m_tree->SetSelectedItem(static_cast<i32>(i));
                        m_selecting = false;
                    }
        }


        void RebuildDetails()
        {
            if (m_details == nullptr)
                return;
            m_details->RemoveAllChildren();
            m_detailsStale = false;
            Node* node = GetSelected();
            m_detailsFor = node;
            if (node == nullptr)
            {
                (void)Text(*m_details, core::StringView(u8"idim"), core::StringView(u8"Nothing selected: pick a node, choose one in the tree, or query a selector."));
                return;
            }
            const NodeDescription d = Describe(*node);
            Panel& body = *m_details;
            (void)Text(body, core::StringView(u8"ihead"), Label(*node).AsView());
            if (d.Tag.Size() != 0)
                (void)Text(body, core::StringView(u8"idim"), core::Format(u8"<{}>", d.Tag).AsView());

            // States, and the toggles that force them for the style pass.
            (void)Text(body, core::StringView(u8"isection"), core::StringView(u8"States"));
            core::String states;
            for (const core::String& s : d.States)
            {
                if (states.Size() != 0)
                    states += core::StringView(u8", ");
                states += s.AsView();
            }
            (void)Text(body, core::StringView(u8"iline"), states.Size() != 0 ? states.AsView() : core::StringView(u8"(none)"));
            RefPtr<Panel> force = Add<Panel>(body, core::StringView(u8"iforce"));
            struct Forceable
            {
                const char8_t* Name;
                u32 State;
            };
            static constexpr Forceable kForceable[] = {
                {u8":hover", Node::StateHover},     {u8":active", Node::StateActive},
                {u8":focus", Node::StateFocus},     {u8":focus-visible", Node::StateFocusVisible},
                {u8":checked", Node::StateChecked}, {u8":disabled", Node::StateDisabled},
            };
            for (const Forceable& f : kForceable)
            {
                RefPtr<CheckBox> box = Add<CheckBox>(*force);
                box->SetText(core::StringView(f.Name));
                box->SetChecked((node->GetForcedStyleStates() & f.State) != 0);
                Inspector* self = this;
                const u32 state = f.State;
                box->SetOnToggled([self, state](bool on)
                {
                    if (Node* n = self->GetSelected())
                        n->SetForcedStyleStates(on ? (n->GetForcedStyleStates() | state) : (n->GetForcedStyleStates() & ~state));
                });
            }

            // The box.
            (void)Text(body, core::StringView(u8"isection"), core::StringView(u8"Box"));
            (void)Text(body, core::StringView(u8"iline"),
                       core::Format(u8"at {}, {}  size {} x {}", static_cast<i32>(d.Bounds.x), static_cast<i32>(d.Bounds.y),
                                    static_cast<i32>(node->GetSize().x), static_cast<i32>(node->GetSize().y)).AsView());
            const auto sides = [](const Thickness& t)
            {
                return core::Format(u8"{} {} {} {}", static_cast<i32>(t.Top), static_cast<i32>(t.Right), static_cast<i32>(t.Bottom),
                                    static_cast<i32>(t.Left));
            };
            (void)Text(body, core::StringView(u8"iline"), core::Format(u8"margin {}   padding {}", sides(d.Margin), sides(d.Padding)).AsView());
            {
                const core::Float2 wanted = node->Measure(LayoutConstraints{});
                (void)Text(body, core::StringView(u8"idim"),
                           core::Format(u8"measures {} x {} unbounded", static_cast<i32>(wanted.x), static_cast<i32>(wanted.y)).AsView());
            }

            // Styles, grouped by rule (the winner of each property first; overridden ones dim). A
            // rule's declaration and the inline style's are fields: Enter edits the rule itself
            // (every node it matches follows), or the node's inline style.
            if (const UIWidget* widget = core::Cast<UIWidget>(node); widget != nullptr && m_targetStyles != nullptr)
            {
                (void)Text(body, core::StringView(u8"isection"), core::StringView(u8"Styles"));
                (void)Text(body, core::StringView(u8"idim"), core::StringView(u8"Grouped by rule; a dim name is overridden. Enter edits the rule (or the inline style)."));
                const Array<StyleExplanation> explained = m_targetStyles->ExplainStyle(*widget);
                struct Line
                {
                    core::String Property;
                    core::String Value;
                    bool Won = true;
                    bool Important = false;
                    bool Editable = false;
                    bool Inline = false;
                    const StyleRule* Rule = nullptr;
                };
                struct Group
                {
                    core::String Header;
                    Array<Line> Lines;
                };
                Array<Group> groups;
                const auto group = [&groups](const core::String& header) -> Group&
                {
                    for (Group& g : groups)
                        if (g.Header == header)
                            return g;
                    groups.PushBack(Group{header, {}});
                    return groups[groups.Size() - 1];
                };
                for (const StyleExplanation& e : explained)
                {
                    if (e.Origin == StyleOrigin::Inherited && e.InheritedFrom != nullptr)
                    {
                        group(core::Format(u8"inherited from {}", Label(*e.InheritedFrom))).Lines.PushBack(Line{e.Property, e.Value});
                        continue;
                    }
                    if (e.Origin == StyleOrigin::Code)
                        group(core::String(core::StringView(u8"set by code"))).Lines.PushBack(Line{e.Property, {}});
                    for (usize i = 0; i < e.Declarations.Size(); ++i)
                    {
                        const StyleDeclarationSource& d = e.Declarations[i];
                        const core::String header = d.Inline ? core::String(core::StringView(u8"inline style"))
                                                             : core::Format(u8"{}   {}:{}", d.Selector, d.Sheet, d.Line);
                        group(header).Lines.PushBack(Line{e.Property, d.Value, i == 0 && e.Origin != StyleOrigin::Code, d.Important,
                                                          true, d.Inline, d.Rule});
                    }
                }
                Inspector* self = this;
                for (const Group& g : groups)
                {
                    (void)Text(body, core::StringView(u8"irule"), g.Header.AsView());
                    for (const Line& line : g.Lines)
                    {
                        if (!line.Editable)
                        {
                            (void)Text(body, core::StringView(u8"iline"),
                                       line.Value.Size() != 0 ? core::Format(u8"{}: {}", line.Property, line.Value).AsView() : line.Property.AsView());
                            continue;
                        }
                        RefPtr<Panel> row = Add<Panel>(body, core::StringView(u8"iprop"));
                        (void)Text(*row, core::StringView(line.Won ? u8"iline" : u8"iover"), line.Property.AsView());
                        RefPtr<TextField> field = Add<TextField>(*row);
                        field->SetText(line.Important ? core::Format(u8"{} !important", line.Value).AsView() : line.Value.AsView());
                        const core::String property = line.Property;
                        const StyleRule* rule = line.Rule; // compared, never followed: a sheet replaced since makes it a miss
                        const bool inlineStyle = line.Inline;
                        field->SetOnSubmit([self, property, rule, inlineStyle](core::StringView text)
                        {
                            Node* n = self->GetSelected();
                            if (n == nullptr || self->m_targetStyles == nullptr)
                                return;
                            if (inlineStyle)
                                (void)SetProperty(*n, property.AsView(), text);
                            else if (rule != nullptr)
                                (void)self->m_targetStyles->EditDeclaration(rule, property.AsView(), text);
                            self->m_detailsStale = true; // shown again next refresh, not under this field's call
                        });
                    }
                }
                if (groups.IsEmpty())
                    (void)Text(body, core::StringView(u8"idim"), core::StringView(u8"(no rule sets anything)"));
            }

            // Reflected properties, edited as markup sets them (Enter applies).
            (void)Text(body, core::StringView(u8"isection"), core::StringView(u8"Properties"));
            for (const ReflectedValue& p : d.Properties)
            {
                RefPtr<Panel> row = Add<Panel>(body, core::StringView(u8"iprop"));
                // A translated one names its key ("text @menu.play").
                const core::StringView shown = p.CssName.Size() != 0 ? p.CssName.AsView() : p.Name.AsView();
                (void)Text(*row, {}, p.Key.Size() != 0 ? core::Format(u8"{} @{}", shown, p.Key).AsView() : shown);
                if (p.ReadOnly)
                {
                    (void)Text(*row, core::StringView(u8"idim"), p.Value.AsView());
                    continue;
                }
                RefPtr<TextField> field = Add<TextField>(*row);
                field->SetText(p.Value.AsView());
                Inspector* self = this;
                const core::String name = p.Name;
                field->SetOnSubmit([self, name](core::StringView text)
                {
                    if (Node* n = self->GetSelected())
                        (void)SetProperty(*n, name.AsView(), text);
                });
            }

            // What a screen reader is told of it (E9d), and what in the GUI it would trip on.
            {
                (void)Text(body, core::StringView(u8"isection"), core::StringView(u8"Accessibility"));
                const AccessDescription a = DescribeAccess(*node);
                if (!a.Own)
                    (void)Text(body, core::StringView(u8"idim"),
                               a.ReadAs.Size() != 0 ? core::Format(u8"no node of its own: read as part of {}", a.ReadAs).AsView()
                                                    : core::StringView(u8"not read: hidden, or in no GUI"));
                else
                {
                    const auto joined = [](const Array<core::String>& items)
                    {
                        core::String out;
                        for (const core::String& item : items)
                        {
                            if (out.Size() != 0)
                                out += core::StringView(u8", ");
                            out += item.AsView();
                        }
                        return out.Size() != 0 ? out : core::String(core::StringView(u8"(none)"));
                    };
                    (void)Text(body, core::StringView(u8"iline"), core::Format(u8"{} \"{}\"", a.Role, a.Name).AsView());
                    if (a.Value.Size() != 0)
                        (void)Text(body, core::StringView(u8"iline"), core::Format(u8"value {}", a.Value).AsView());
                    if (a.Description.Size() != 0)
                        (void)Text(body, core::StringView(u8"iline"), core::Format(u8"description {}", a.Description).AsView());
                    (void)Text(body, core::StringView(u8"idim"), core::Format(u8"states {}", joined(a.States)).AsView());
                    (void)Text(body, core::StringView(u8"idim"), core::Format(u8"actions {}", joined(a.Actions)).AsView());
                }
                if (SceneRoot* root = node->GetSceneRoot())
                {
                    const Array<AccessIssue> issues = AuditAccess(*root);
                    (void)Text(body, core::StringView(u8"idim"),
                               issues.IsEmpty() ? core::StringView(u8"audit: nothing in this GUI a screen reader trips on")
                                                : core::Format(u8"audit: {} in this GUI", issues.Size()).AsView());
                    for (const AccessIssue& issue : issues)
                        (void)Text(body, core::StringView(u8"iline"), core::Format(u8"{}: {}", Label(*issue.Target), issue.Message).AsView());
                }
            }

            const auto list = [&](const char8_t* title, const Array<core::String>& items)
            {
                if (items.IsEmpty())
                    return;
                (void)Text(body, core::StringView(u8"isection"), core::StringView(title));
                for (const core::String& item : items)
                    (void)Text(body, core::StringView(u8"iline"), item.AsView());
            };
            list(u8"Commands", d.Commands);
            list(u8"Listeners", d.Listeners);
            if (d.Bindings != 0)
                (void)Text(body, core::StringView(u8"idim"), core::Format(u8"{} bindings", d.Bindings).AsView());
        }

        IAllocator& m_allocator;
        InspectorOptions m_options;
        fonts::CachedFont* m_font = nullptr;
        RefPtr<SceneRoot> m_root;
        StyleManager m_styles;
        SceneRoot* m_target = nullptr;              // not owned: the host's
        StyleManager* m_targetStyles = nullptr; // edits its rules (the styles' fields)
        bool m_detailsStale = false;            // an edit wants the details shown again
        UniquePtr<StringListModel> m_model;         // before the views (they go first, in the destructor)
        Panel* m_shell = nullptr;                   // owned by the root, as the rest
        CheckBox* m_pick = nullptr;
        gui::Label* m_queryCount = nullptr;
        ListView* m_tree = nullptr;
        Panel* m_details = nullptr;
        FramesGraph* m_frames = nullptr;
        Array<TreeEntry> m_entries;   // the rows: the tree less its folded branches
        Array<const Node*> m_collapsed; // the folded branches (by identity; forgotten once gone)
        u64 m_signature = 0;
        u64 m_refreshes = 0;
        Node::ElementRef m_selected{};
        Node* m_selectedRaw = nullptr; // when the node has no element table to hold it weakly
        const Node* m_detailsFor = nullptr;
        bool m_selecting = false;
        bool m_picking = false;
        Array<Node*> m_hoverPath; // the node under the pointer, then what holds it, outward
        usize m_hoverLevel = 0;
    };
}
