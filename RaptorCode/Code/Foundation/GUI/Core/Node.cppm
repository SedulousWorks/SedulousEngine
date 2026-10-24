// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :node partition
//
// Node: the retained-mode scene-graph node - the tree content base (eepp Scene::Node).
// Ported from eepp include/eepp/scene/node.hpp, adapted to our Core: Object +
// Transformable bases (Cast<T> downcasts); the raw-pointer intrusive sibling list becomes
// an owning Array<RefPtr<Node>> children with a non-owning parent back-pointer. Draws its
// subtree through the DrawContext/VG seam (eepp's nodeDraw + matrix/clip, on VG).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:node;

import foundation.core; // Object, RefPtr, Array, Move, Float2
import foundation.script; // IScriptDelegate (the script surface's event handlers)
import foundation.vg;     // PathBuilder, ShapeBuilder (rounded clips), layers
import foundation.fonts;  // IFontService (what a rich text's runs ask, E4)
import :rect;
import :transform2d;
import :transformable;
import :event;
import :draw_context;
import :drawable;
import :action;
import :action_manager;
import :mutation_queue;
import :node_box;
import :reactive; // Effect, EffectScheduler (bindings)
import :data_model; // DataModel (BindData)
import :commands;   // CommandHandler, CommandPhase (G7)
import :css_values;  // LengthValue
import :style_value; // TransformFunction
import :thickness;
import :layout_style; // LayoutStyle, LayoutConstraints (E2)
import :resource_provider; // IResourceProvider (a rich text's icons, E4)
import :frame_stats;       // FrameStats (E8a)
import :debug_overlay;     // DebugOverlay (E8c)

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// What a focus scope does when navigation reaches its edge (G7 of Specs/vg-and-gui-lab.md):
    /// not a scope; pass to the neighbours outside it (the default for a scope); wrap around to its
    /// other side (menus, carousels); or contain focus (a dialog).
    enum class NavScope : u8
    {
        None,
        Pass,
        Wrap,
        Contain,
    };

    class EventDispatcher; // owned by the SceneRoot; reached via GetEventDispatcher()
    class Tween;           // a property moving on the GUI's clock (:tween, E14)
    class TweenGroup;      // tweens run as one (:tween)
    class ElementSet;      // what a GUI may create (:element_types); its SceneRoot holds one
    class SceneRoot;       // the root of a GUI (:scene_root)
    class GUIContext;      // the GUI a root is part of (:scene_root)
    class Node;

    /// One GUI's element table (G1 of Specs/vg-and-gui-lab.md): what a script's handle to a node
    /// resolves through, a slot and a generation, so the tree owns its nodes and a script only
    /// ever holds them weakly. Each GUIContext owns one, so two GUIs never share slots and a handle
    /// survives its node moving between roots. Handles retain the table (an anchored resolve-mode
    /// Variant): when its GUI goes, the table is closed and every handle into it reads as gone,
    /// never as freed memory.
    class ElementTable : public RefCounted
    {
    public:
        /// A slot for `node` (1-based), reusing a freed one under a new generation.
        u32 Take(Node& node)
        {
            u32 slot = 0;
            if (!m_free.IsEmpty())
            {
                slot = m_free.Back();
                m_free.PopBack();
            }
            else
            {
                m_slots.PushBack(Slot{});
                slot = static_cast<u32>(m_slots.Size());
            }
            m_slots[slot - 1].node = &node;
            return slot;
        }
        /// The node is gone: its handles stop resolving and the slot is free for another.
        void Free(u32 slot) noexcept
        {
            if (slot == 0 || slot > m_slots.Size())
                return;
            Slot& entry = m_slots[slot - 1];
            entry.node = nullptr;
            ++entry.generation;
            if (!m_closed)
                m_free.PushBack(slot);
        }
        /// The node in `slot` if `generation` is still its, else null.
        [[nodiscard]] Node* Resolve(u32 slot, u32 generation) const noexcept
        {
            if (m_closed || slot == 0 || slot > m_slots.Size())
                return nullptr;
            const Slot& entry = m_slots[slot - 1];
            return entry.generation == generation ? entry.node : nullptr;
        }
        [[nodiscard]] u32 Generation(u32 slot) const noexcept
        {
            return slot != 0 && slot <= m_slots.Size() ? m_slots[slot - 1].generation : 0;
        }
        /// The owning GUI is going: every handle into this table reads as gone from now on.
        void Close() noexcept { m_closed = true; }
        [[nodiscard]] bool IsClosed() const noexcept { return m_closed; }

    private:
        struct Slot
        {
            Node* node = nullptr;
            u32 generation = 1;
        };
        Array<Slot> m_slots;
        Array<u32> m_free;
        bool m_closed = false;
    };

    class Node : public Object, public Transformable
    {
        RTTI_OBJECT(Node, Object)
    public:
        static constexpr usize kInvalidIndex = static_cast<usize>(-1);

        /// Where a weak reference to a node resolves: its GUI's table, a slot and a generation.
        struct ElementRef
        {
            ElementTable* table = nullptr;
            u32 slot = 0;
            u32 generation = 0;
        };

        Node() = default;
        ~Node() override
        {
            // A child held elsewhere outlives its parent: it must not point at it after.
            for (const RefPtr<Node>& child : m_children)
                child->m_parent = nullptr;
            if (m_elementTable)
                m_elementTable->Free(m_elementSlot);
        }

        // === Tree query ===
        [[nodiscard]] Node* GetParent() const noexcept { return m_parent; }
        [[nodiscard]] usize ChildCount() const noexcept { return m_children.Size(); }
        [[nodiscard]] Node* GetChildAt(usize index) const
        {
            return index < m_children.Size() ? m_children[index].Get() : nullptr;
        }
        [[nodiscard]] Node* GetFirstChild() const
        {
            return m_children.Size() ? m_children[0].Get() : nullptr;
        }
        [[nodiscard]] Node* GetLastChild() const
        {
            return m_children.Size() ? m_children[m_children.Size() - 1].Get() : nullptr;
        }
        /// Its place among the children (kInvalidIndex when it is not one). Each child keeps its
        /// index until the children change, when the next ask numbers them all at once, so asking
        /// for each child in turn (siblings, :nth-child, `+` and `~`) costs one pass, not one each.
        [[nodiscard]] usize GetChildIndex(const Node* child) const
        {
            if (child == nullptr || child->m_parent != this)
                return kInvalidIndex;
            if (child->m_indexGeneration != m_childrenGeneration)
                for (usize i = 0; i < m_children.Size(); ++i)
                {
                    m_children[i]->m_indexInParent = i;
                    m_children[i]->m_indexGeneration = m_childrenGeneration;
                }
            return child->m_indexGeneration == m_childrenGeneration ? child->m_indexInParent : kInvalidIndex;
        }
        /// Counts changes to the children (added, removed, moved), for what is kept per arrangement.
        [[nodiscard]] u32 ChildrenGeneration() const noexcept { return m_childrenGeneration; }
        [[nodiscard]] bool HasChild(const Node* child) const
        {
            return GetChildIndex(child) != kInvalidIndex;
        }

        [[nodiscard]] Node* GetNextSibling() const
        {
            if (m_parent == nullptr)
                return nullptr;
            const usize i = m_parent->GetChildIndex(this);
            return (i != kInvalidIndex && i + 1 < m_parent->m_children.Size())
                       ? m_parent->m_children[i + 1].Get()
                       : nullptr;
        }
        [[nodiscard]] Node* GetPrevSibling() const
        {
            if (m_parent == nullptr)
                return nullptr;
            const usize i = m_parent->GetChildIndex(this);
            return (i != kInvalidIndex && i > 0) ? m_parent->m_children[i - 1].Get() : nullptr;
        }

        // === Tree mutation === (owning: the tree holds a RefPtr to each child)
        virtual Node* AddChild(Node* child)
        {
            if (child == nullptr || child == this || child->m_parent == this)
                return this;
            RefPtr<Node> keepAlive(child); // survive reparenting off the old parent
            if (child->m_parent != nullptr)
                child->m_parent->RemoveChild(child);
            child->m_parent = this;
            m_children.PushBack(core::Move(keepAlive));
            ChildrenRearranged(*child);
            child->MarkStyleDirty(true); // its selectors may match differently here
            ChildrenStyleChanged();
            child->HandleParentChange();
            OnChildrenChanged();
            RequestLayout(); // what it holds changed
            Invalidate();
            return this;
        }

        Node* AddChildAt(Node* child, usize index)
        {
            AddChild(child);
            SetChildIndex(child, index);
            return this;
        }

        void RemoveChild(Node* child)
        {
            if (GetChildIndex(child) == kInvalidIndex)
                return;
            // The dispatcher first drops its refs into the subtree (hover, press, focus, a popup):
            // the tree stops keeping those nodes alive. It may close a popup, which edits the
            // tree, so the index is found after.
            NotifyRemovingChild(*child);
            const usize index = GetChildIndex(child);
            if (index == kInvalidIndex)
                return;
            RefPtr<Node> keepAlive = m_children[index]; // hold across detach + callback
            child->NoteOldArea(nullptr); // where it showed is to be drawn again (E15)
            child->m_parent = nullptr;
            child->m_leaving = false; // out of its parent, it has left (K0): taken back, it is whole
            child->m_leaveQueued = false;
            child->m_enterPhase = 0;  // and its entrance is over (K5)
            m_children.RemoveAt(index);
            ChildrenRearranged(*child);
            ChildrenStyleChanged();
            child->HandleParentChange();
            OnChildrenChanged();
            RequestLayout();
            Invalidate();
        }

        void RemoveAllChildren()
        {
            while (m_children.Size() != 0)
                RemoveChild(m_children[m_children.Size() - 1].Get());
        }

        void RemoveFromParent()
        {
            if (m_parent != nullptr)
                m_parent->RemoveChild(this);
        }

        /// The root of the GUI this node is in, or null when it is in none (a detached subtree:
        /// GetRootNode gives its topmost node).
        [[nodiscard]] SceneRoot* GetSceneRoot();
        /// Its access key (E12 of Specs/gui-lab-evolution-2.md: the `F` of `&File`, lower case), or 0:
        /// Alt and the key focus and activate it in its window or menu.
        [[nodiscard]] virtual char32_t GetMnemonic() const { return 0; }
        /// Whether access keys are underlined now (while Alt is held, or always as its GUI says).
        [[nodiscard]] bool AreMnemonicsShown();
        /// The GUI this node is in, read as a binding's dependency: the binding reruns when the node
        /// joins or leaves one (a control bound to a command, made by markup before it is attached).
        [[nodiscard]] SceneRoot* ObserveSceneRoot()
        {
            m_sceneRootChanged.Track();
            return GetSceneRoot();
        }

        // The topmost ancestor (the SceneRoot, when the node is in a GUI).
        [[nodiscard]] Node* GetRootNode()
        {
            Node* n = this;
            while (n->m_parent != nullptr)
                n = n->m_parent;
            return n;
        }

        // === Z-order (draw/hit order = child index; last = topmost) ===
        void SetChildIndex(Node* child, usize newIndex)
        {
            const usize cur = GetChildIndex(child);
            if (cur == kInvalidIndex)
                return;
            if (newIndex >= m_children.Size())
                newIndex = m_children.Size() - 1;
            if (cur == newIndex)
                return;
            RefPtr<Node> ref = m_children[cur];
            m_children.RemoveAt(cur);
            m_children.Insert(newIndex, core::Move(ref));
            ChildrenRearranged(*child);
            ChildrenStyleChanged();
            RequestLayout(); // the flow follows the child order
            Invalidate();
        }
        void ToFront()
        {
            if (m_parent != nullptr)
                m_parent->SetChildIndex(this, m_parent->m_children.Size());
        }
        void ToBack()
        {
            if (m_parent != nullptr)
                m_parent->SetChildIndex(this, 0);
        }

        // === Size / bounds ===
        /// The node's size. From code, it is the node's width and height in pixels (inline `width`
        /// and `height`), kept by every layout; a layout placing the node (Arrange) sets it without.
        void SetSize(core::Float2 size)
        {
            bool styleChanged = false;
            if (!IsBeingPlaced())
            {
                PinStyle(SlotBit(SlotWidth) | SlotBit(SlotHeight));
                const LayoutLength w = LayoutLength::Px(size.x);
                const LayoutLength h = LayoutLength::Px(size.y);
                styleChanged = !(m_layoutStyle.Width == w) || !(m_layoutStyle.Height == h);
                m_layoutStyle.Width = w;
                m_layoutStyle.Height = h;
            }
            const bool changed = size != m_size;
            if (changed)
            {
                m_size = size;
                HandleSizeChange();
            }
            if (styleChanged || (changed && !IsBeingPlaced()))
                RequestBoxLayout();
        }
        [[nodiscard]] core::Float2 GetSize() const noexcept { return m_size; }
        [[nodiscard]] Rect GetLocalBounds() const noexcept
        {
            return Rect{0.0f, 0.0f, m_size.x, m_size.y};
        }

        // World transform accumulates the parent chain (parentWorld * local). A node in the top
        // layer (an open popup) sits in its root's space instead: its position is the root's.
        [[nodiscard]] Transform2D GetWorldTransform() const
        {
            if (m_topLayer)
            {
                const Node* root = this;
                while (root->m_parent != nullptr)
                    root = root->m_parent;
                return root->GetTransform() * GetTransform();
            }
            return m_parent != nullptr ? (m_parent->GetChildrenTransform() * GetTransform())
                                       : GetTransform();
        }
        /// Where this node's children sit in the world: its own world transform, moved by its
        /// scroll offset (a scroll container's content scrolls without being laid out again).
        [[nodiscard]] Transform2D GetChildrenTransform() const
        {
            Transform2D t = GetWorldTransform();
            if (m_scrollOffset.x != 0.0f || m_scrollOffset.y != 0.0f)
            {
                const core::Float2 shift = ScrollShift();
                t.Translate(-shift.x, -shift.y);
            }
            return t;
        }
        [[nodiscard]] core::Float2 ConvertToWorldSpace(core::Float2 nodePoint) const
        {
            return GetWorldTransform().TransformPoint(nodePoint);
        }
        [[nodiscard]] core::Float2 ConvertToNodeSpace(core::Float2 worldPoint) const
        {
            return GetWorldTransform().GetInverse().TransformPoint(worldPoint);
        }
        /// A point of this node in its root's own space, where a popup attached to the root is
        /// placed. The root's transform (its display scale) maps that space to device pixels, which
        /// is what world space is.
        [[nodiscard]] core::Float2 ConvertToRootSpace(core::Float2 nodePoint) const
        {
            const Node* root = this;
            while (root->m_parent != nullptr)
                root = root->m_parent;
            return root->ConvertToNodeSpace(ConvertToWorldSpace(nodePoint));
        }
        [[nodiscard]] core::Float2 GetScreenPosition() const
        {
            return ConvertToWorldSpace(core::Float2{0.0f, 0.0f});
        }
        [[nodiscard]] Rect GetScreenBounds() const
        {
            return GetWorldTransform().TransformRect(GetLocalBounds());
        }

        // === Visibility / enabled / alpha ===
        void SetVisible(bool visible)
        {
            PinStyle(SlotBit(SlotVisibility));
            if (visible == m_visible)
                return;
            m_visible = visible;
            HandleVisibilityChange();
        }
        /// Hidden (CSS `visibility: hidden`): not drawn and takes no input, but keeps its place in
        /// the layout. SetDisplayed(false) takes it out.
        [[nodiscard]] bool IsVisible() const noexcept { return m_visible; }
        [[nodiscard]] bool IsTreeVisible() const
        {
            return m_visible && IsDisplayed() && (m_parent == nullptr || m_parent->IsTreeVisible());
        }
        /// In the layout, or out of it with its subtree (CSS `display: none`): a page switched away,
        /// a panel collapsed. Shown again, it takes back the display kind it had.
        void SetDisplayed(bool displayed)
        {
            PinStyle(SlotBit(SlotDisplay));
            if (displayed == IsDisplayed())
                return;
            if (displayed)
                m_layoutStyle.Kind = m_displayBeforeNone;
            else
            {
                m_displayBeforeNone = m_layoutStyle.Kind;
                m_layoutStyle.Kind = Display::None;
            }
            RequestBoxLayout();
            Invalidate();
        }
        [[nodiscard]] bool IsDisplayed() const noexcept { return m_layoutStyle.Kind != Display::None; }
        void SetEnabled(bool enabled)
        {
            PinStyle(SlotBit(SlotEnabled));
            if (enabled == m_enabled)
                return;
            m_enabled = enabled;
            HandleEnabledChange();
        }
        [[nodiscard]] bool IsEnabled() const noexcept { return m_enabled; }
        /// Enabled itself and under enabled ancestors: a disabled panel disables what it holds.
        [[nodiscard]] bool IsTreeEnabled() const
        {
            return m_enabled && (m_parent == nullptr || m_parent->IsTreeEnabled());
        }
        void SetAlpha(f32 alpha)
        {
            PinStyle(SlotBit(SlotOpacity));
            m_alpha = alpha;
            Invalidate();
        }
        [[nodiscard]] f32 GetAlpha() const noexcept { return m_alpha; }

        // === Hit testing ===
        // When false, this node is transparent to the pointer: OverFind skips it (clicks fall
        // through to whatever is behind), though it still draws. Useful for decorative overlays
        // (a title-bar caption, an image over a draggable area). Children are still hit-tested.
        void SetHitTestVisible(bool visible) noexcept { m_hitTestVisible = visible; }
        [[nodiscard]] bool IsHitTestVisible() const noexcept { return m_hitTestVisible; }
        /// CSS `pointer-events`: `none` is SetHitTestVisible(false), `auto` the default.
        [[nodiscard]] core::String GetPointerEvents() const { return core::String(m_hitTestVisible ? u8"auto" : u8"none"); }
        void SetPointerEvents(const core::String& value) { SetHitTestVisible(value.AsView() != core::StringView(u8"none")); }
        /// The pointer's look over this node (CSS `cursor`); Auto takes its parent's.
        void SetCursor(Cursor cursor) noexcept { m_cursor = cursor; }
        [[nodiscard]] Cursor GetCursor() const noexcept { return m_cursor; }
        /// The look the pointer takes over it now: its `cursor`, unless what is under the pointer
        /// says otherwise (a rich text's link shows the pointer hand).
        [[nodiscard]] virtual Cursor GetCursorNow() const { return m_cursor; }
        [[nodiscard]] core::String GetCursorName() const { return core::String(CursorName(m_cursor)); }
        void SetCursorName(const core::String& name) { m_cursor = CursorNamed(name.AsView()); }
        /// What a finger over it may do that the GUI does itself (CSS `touch-action`, kTouch* bits,
        /// E17c); not inherited: an ancestor narrows it instead (EffectiveTouchActions).
        void SetTouchActions(u8 bits) noexcept { m_touchActions = static_cast<u8>(bits & kTouchAuto); }
        [[nodiscard]] u8 GetTouchActions() const noexcept { return m_touchActions; }
        /// Its own value narrowed by every ancestor's, as CSS intersects them.
        [[nodiscard]] u8 EffectiveTouchActions() const noexcept
        {
            u8 bits = kTouchAuto;
            for (const Node* n = this; n != nullptr; n = n->m_parent)
                bits &= n->m_touchActions;
            return bits;
        }
        [[nodiscard]] core::String GetTouchActionName() const { return TouchActionsName(m_touchActions); }
        /// A text it does not know is `auto`, its initial value, as a dropped declaration leaves it.
        void SetTouchActionName(const core::String& name) { m_touchActions = TouchActionsNamed(name.AsView()).ValueOr(kTouchAuto); }

        [[nodiscard]] virtual bool PointInside(core::Float2 worldPoint) const
        {
            if (!m_hitTestVisible)
                return false;
            return WithinBox(worldPoint);
        }
        /// Whether a world point lies in its box, whether or not it takes the pointer.
        [[nodiscard]] bool WithinBox(core::Float2 worldPoint) const
        {
            const core::Float2 p = ConvertToNodeSpace(worldPoint);
            return p.x >= 0.0f && p.x <= m_size.x && p.y >= 0.0f && p.y <= m_size.y;
        }
        /// Whether any child sets a z-index (else they paint and hit-test as they stand).
        [[nodiscard]] bool HasStackedChildren() const noexcept
        {
            // Kept until the children or one's z-index change: asked on every draw and hit test, it
            // read each child, which on a long column cost more than drawing what shows (E15).
            if (!m_stackedKnown)
            {
                m_stacked = false;
                for (const RefPtr<Node>& child : m_children)
                    m_stacked = m_stacked || child->m_layoutStyle.ZIndex != 0;
                m_stackedKnown = true;
            }
            return m_stacked;
        }
        /// Its children in paint order: by z-index (CSS's, among siblings), then as they stand.
        void ChildrenInPaintOrder(Array<Node*>& out) const
        {
            out.Clear();
            for (const RefPtr<Node>& child : m_children)
                out.PushBack(child.Get());
            for (usize i = 1; i < out.Size(); ++i) // insertion sort: stable, and sibling lists are short
                for (usize j = i; j > 0 && out[j]->m_layoutStyle.ZIndex < out[j - 1]->m_layoutStyle.ZIndex; --j)
                    core::Swap(out[j], out[j - 1]);
        }
        // Topmost visible descendant (or self) under a world point; nullptr if none.
        [[nodiscard]] virtual Node* OverFind(core::Float2 worldPoint)
        {
            if (!m_visible || !IsDisplayed() || m_leaving || m_inert) // a leaving or inert node takes no pointer (K0, K4)
                return nullptr;
            // A scroll container's bars lie over its content: a press on one is the container's.
            if (IsScrollContainer() && m_hitTestVisible)
            {
                const core::Float2 p = ConvertToNodeSpace(worldPoint);
                if (ScrollBarTrack(0).Contains(p) || ScrollBarTrack(1).Contains(p))
                    return this;
            }
            // What it clips is hit only where it shows: a row scrolled out of a list takes no press
            // over what lies beyond the list (navigation skips it likewise).
            if (!ClipsChildren() || WithinBox(worldPoint))
            {
                // The topmost first: the last drawn (z-index, then the order they stand in).
                Array<Node*> order;
                if (HasStackedChildren())
                    ChildrenInPaintOrder(order);
                else if (m_children.Size() >= kIndexedChildren)
                {
                    // Many children: those whose drawing holds the point, from the index (E15).
                    core::Float2 p = ConvertToNodeSpace(worldPoint);
                    if (m_scrollOffset.x != 0.0f || m_scrollOffset.y != 0.0f)
                    {
                        const core::Float2 shift = ScrollShift();
                        p = core::Float2{p.x + shift.x, p.y + shift.y};
                    }
                    ChildrenReaching(Rect{p.x, p.y, 0.0f, 0.0f}, order);
                    for (usize i = order.Size(); i-- > 0;)
                        if (!order[i]->m_topLayer)
                            if (Node* hit = order[i]->OverFind(worldPoint))
                                return hit;
                    return PointInside(worldPoint) ? this : nullptr;
                }
                const usize count = order.IsEmpty() ? m_children.Size() : order.Size();
                for (usize i = count; i-- > 0;)
                {
                    Node* child = order.IsEmpty() ? m_children[i].Get() : order[i];
                    if (!child->m_topLayer) // the top layer is hit-tested first, from the root
                        if (Node* hit = child->OverFind(worldPoint))
                            return hit;
                }
            }
            return PointInside(worldPoint) ? this : nullptr;
        }

        // === The top layer (E5) ===
        /// Open as a popup: drawn after the whole tree in its root's space, unclipped by its
        /// ancestors, hit-tested first, out of its parent's layout, while staying in its owner's
        /// subtree (its styles and its events' route). The dispatcher's popup stack sets it.
        [[nodiscard]] bool IsInTopLayer() const noexcept { return m_topLayer; }
        void SetInTopLayer(bool topLayer)
        {
            if (topLayer == m_topLayer)
                return;
            m_topLayer = topLayer;
            if (m_parent != nullptr)
                m_parent->RequestLayout(); // in or out of its parent's flow
            Invalidate();
        }
        /// Takes the GUI's "enter the menu bar" key (F10, the `menu.enter-bar` command): a menu bar
        /// focuses its first menu. False when it is not one to enter.
        virtual bool EnterFromKeyboard() { return false; }
        /// What a modal popup draws over the root under itself: a dim (a widget's `::backdrop` part).
        virtual void DrawBackdrop(DrawContext& ctx, const Rect& bounds) const
        {
            FilledBox(Color{0.0f, 0.0f, 0.0f, 0.45f}).DrawUnder(ctx, bounds);
        }
        /// Where an event's route ends (a modal popup: what is below it is inert, its owner too).
        [[nodiscard]] bool IsRouteStop() const noexcept { return m_routeStop; }
        void SetRouteStop(bool stop) noexcept { m_routeStop = stop; }

        // === Drawing === A node draws its box (SetBox, or a sheet's) under what it draws itself.
        void SetClipChildren(bool clip)
        {
            if (clip == m_clipChildren)
                return;
            m_clipChildren = clip;
            Invalidate();
        }
        /// Clips its children to its box: set so, or its overflow is not visible (hidden, scroll, auto).
        [[nodiscard]] bool ClipsChildren() const noexcept
        {
            return m_clipChildren || m_layoutStyle.OverflowX != Overflow::Visible || m_layoutStyle.OverflowY != Overflow::Visible;
        }

        // Draw this node and its subtree through the DrawContext, applying the node's
        // transform + opacity + optional child clip. Order: background -> OnDraw ->
        // children (back-to-front) -> foreground.
        void Draw(DrawContext& ctx)
        {
            if (!m_visible || !IsDisplayed())
                return;

            ctx.Save();
            ctx.ConcatTransform(GetTransform());
            // Nothing it or its subtree draws reaches the clip: none of it is drawn (E8b).
            if (!ctx.IsVisible(GetSubtreeInk()))
            {
                ctx.CountCulled();
                m_drawnAreaValid = false; // not on screen: nothing of it to draw again
                m_damageNoted = false;
                ctx.Restore();
                return;
            }
            // In view though fully transparent, it counts as drawn: a fade in from nothing is in
            // view, so its frames are asked for (not taken for a quiet animation out of sight).
            m_drawnFrame = ctx.Frame();
            if (m_alpha <= 0.0f)
            {
                m_drawnAreaValid = false; // shows nothing (a fade out noted where it showed)
                m_damageNoted = false;
                ctx.Restore();
                return;
            }
            // Damage (E15): where it covers now, when that is new, changed or moved, beside where
            // it covered before (noted when it changed).
            if (ctx.RecordsDamage())
            {
                const Rect area = ctx.DeviceRect(GetSubtreeInk());
                if (!m_drawnAreaValid || m_damageNoted || !(area == m_drawnArea))
                    ctx.RecordDamage(area);
                m_drawnArea = area;
                m_drawnAreaValid = true;
                m_damageNoted = false;
            }
            ctx.CountDrawn();
            if (m_invalidatedSelf && ctx.RecordsRedraws() && m_parent != nullptr) // the root would flash all
                ctx.RecordRedraw(GetScreenBounds());
            m_invalidatedSelf = false;
            if (m_box.TextEffectsSet != 0)
                ctx.VG().SetTextEffects(m_box.MergeTextEffects(ctx.VG().GetTextEffects()));
            // A node with children fades as one picture (CSS's opacity), as does one with a filter
            // or a blend: through a VG layer, composited once. A leaf's opacity multiplies into
            // what it draws (no offscreen target for a label).
            const bool layered = m_box.NeedsLayer() || (m_alpha < 1.0f && !m_children.IsEmpty());
            const bool pushedOpacity = !layered && m_alpha < 1.0f;
            // A backdrop blur is of what lies behind the node, so a node drawing through a layer
            // (where nothing lies behind) draws it first, onto the canvas behind, at its opacity, as
            // CSS composites it: frosted glass fading in blurs as it fades, rather than showing the
            // backdrop sharp until the fade ends and then the blur all at once.
            const bool backdropFirst = layered && m_box.BackdropBlur > 0.0f;
            if (backdropFirst)
            {
                ctx.PushOpacity(m_alpha);
                m_box.DrawBackdrop(ctx, GetLocalBounds());
                ctx.PopOpacity();
            }
            if (layered)
                ctx.VG().PushLayer(m_alpha, m_box.BlendMode, m_box.FilterBlur * ctx.DeviceScale());
            else if (pushedOpacity)
                ctx.PushOpacity(m_alpha);

            const Rect local = GetLocalBounds();

            m_box.DrawUnder(ctx, local, !backdropFirst);
            OnDraw(ctx, local);

            // Children clip to the box, its rounded corners included (a path clip; a host without
            // stencil fills gets the bounds' scissor).
            const bool clips = ClipsChildren();
            const bool roundedClip = clips && !m_box.Radii.IsZero();
            if (roundedClip)
            {
                vg::PathBuilder shape;
                vg::ShapeBuilder::BuildRoundedRect(local.ToRectangle(), m_box.Radii, shape);
                ctx.VG().PushClipPath(shape.ToPath());
            }
            else if (clips)
                ctx.PushClip(local);
            const bool scrolled = m_scrollOffset.x != 0.0f || m_scrollOffset.y != 0.0f;
            if (scrolled)
            {
                ctx.Save();
                const core::Float2 shift = ScrollShift();
                ctx.ConcatTransform(Transform2D{}.Translate(-shift.x, -shift.y));
            }
            Rect view;
            if (!HasStackedChildren() && m_children.Size() >= kIndexedChildren && ctx.GetVisibleBounds(view))
            {
                // Many children under a clip: those that can reach it, from the index, rather than
                // each asked in turn (E15: a long column visited thousands only to cull them).
                Array<Node*> shown;
                ChildrenReaching(view, shown);
                for (Node* child : shown)
                    if (!child->m_topLayer)
                        child->Draw(ctx);
            }
            else if (!HasStackedChildren())
            {
                for (const RefPtr<Node>& child : m_children)
                    if (!child->m_topLayer) // drawn by the root's top layer, after the tree
                        child->Draw(ctx);
            }
            else
            {
                Array<Node*> order;
                ChildrenInPaintOrder(order);
                for (Node* child : order)
                    if (!child->m_topLayer)
                        child->Draw(ctx);
            }
            if (scrolled)
                ctx.Restore();
            if (roundedClip)
                ctx.VG().PopClipPath();
            else if (clips)
                ctx.PopClip();

            if (IsScrollContainer())
                DrawScrollBars(ctx);

            if (layered)
                ctx.VG().PopLayer();
            else if (pushedOpacity)
                ctx.PopOpacity();
            OnDrawAbove(ctx);
            ctx.Restore();
            m_needsRedraw = false; // drawn: clean until something invalidates it again
        }

        /// A node with this many children keeps an index of where each one's drawing reaches
        /// (E15), so drawing and hit testing visit those that can matter, not every one.
        static constexpr usize kIndexedChildren = 32;

        /// Its children whose drawing can reach `area` (in their parent's space, past its scroll),
        /// in their order, from its index of them. The index is checked against the children once
        /// something under it changed, and built again only when a child's reach moved: a colour
        /// animating in a row costs no rebuild, a row resized does.
        void ChildrenReaching(const Rect& area, Array<Node*>& out)
        {
            RefreshChildIndex();
            const ChildIndex& index = *m_childIndex;
            const bool vertical = index.Vertical;
            const f32 lo = vertical ? area.y : area.x;
            const f32 hi = vertical ? area.Bottom() : area.Right();
            const usize n = index.Order.Size();
            // Those starting at or before the area's far edge: a prefix of the order.
            usize first = 0, last = n;
            {
                usize a = 0, b = n;
                while (a < b)
                {
                    const usize mid = (a + b) / 2;
                    const Rect& r = index.Rects[index.Order[mid]];
                    if ((vertical ? r.y : r.x) <= hi)
                        a = mid + 1;
                    else
                        b = mid;
                }
                last = a;
            }
            // And of those, the ones from where the farthest reach so far gets to the near edge.
            {
                usize a = 0, b = last;
                while (a < b)
                {
                    const usize mid = (a + b) / 2;
                    if (index.Reach[mid] < lo)
                        a = mid + 1;
                    else
                        b = mid;
                }
                first = a;
            }
            Array<u32> picked;
            for (usize j = first; j < last; ++j)
            {
                const u32 i = index.Order[j];
                const Rect& r = index.Rects[i];
                if (r.x <= area.Right() && area.x <= r.Right() && r.y <= area.Bottom() && area.y <= r.Bottom())
                    picked.PushBack(i);
            }
            picked.Sort([](u32 a, u32 b) { return a < b; }); // few, and nearly in order already
            for (const u32 i : picked)
                out.PushBack(m_children[i].Get());
        }
        /// How many times its index of its children was built (tests, the inspector): once, then
        /// again only when a child's reach moved.
        [[nodiscard]] u32 GetChildIndexBuilds() const noexcept { return m_childIndexBuilds; }

        /// What it draws itself, in its own space: its box grown by its outer shadows (three sigma
        /// of their blur past their spread and offset). A widget drawing past its box adds that (a
        /// label's overflowing text); a filter's blur is added over the whole subtree.
        [[nodiscard]] virtual Rect GetInkBounds() const
        {
            Rect ink = GetLocalBounds();
            for (const BoxShadow& shadow : m_box.Shadows)
            {
                if (shadow.Inset)
                    continue;
                const f32 reach = shadow.Spread + 1.5f * shadow.Blur; // the blur is CSS's: sigma is half
                ink = Rect::Union(ink, Rect{shadow.Offset.x - reach, shadow.Offset.y - reach,
                                            m_size.x + 2.0f * reach, m_size.y + 2.0f * reach});
            }
            return ink;
        }
        /// What it and its subtree draw, in its own space: its ink and its shown children's (within
        /// its box when it clips them), grown by its filter's blur. Kept until it or something in
        /// it invalidates, which reaches every ancestor of what changed.
        [[nodiscard]] const Rect& GetSubtreeInk() const
        {
            if (m_subtreeInkValid)
                return m_subtreeInk;
            Rect ink = GetInkBounds();
            if (!ClipsChildren() && m_children.Size() >= kIndexedChildren)
            {
                // Many children: what the index holds of their reach (E15), not each asked again. It
                // counts hidden ones too, so it is never smaller than what they draw.
                RefreshChildIndex();
                if (!m_children.IsEmpty())
                    ink = Rect::Union(ink, m_childIndex->Bounds);
            }
            else if (!ClipsChildren())
                for (const RefPtr<Node>& child : m_children)
                {
                    const Node& c = *child;
                    if (c.m_topLayer || !c.m_visible || c.m_alpha <= 0.0f || !c.IsDisplayed())
                        continue;
                    ink = Rect::Union(ink, c.GetTransform().TransformRect(c.GetSubtreeInk()));
                }
            if (m_box.FilterBlur > 0.0f)
            {
                const f32 reach = 3.0f * m_box.FilterBlur; // a sigma
                ink = Rect{ink.x - reach, ink.y - reach, ink.width + 2.0f * reach, ink.height + 2.0f * reach};
            }
            m_subtreeInk = ink;
            m_subtreeInkValid = true;
            return m_subtreeInk;
        }

        /// The host's frame it was last drawn in (0: none yet); one hidden or culled keeps an older one.
        [[nodiscard]] u32 GetDrawnFrame() const noexcept { return m_drawnFrame; }
        /// The host's last drawn frame, as its root counts them (0 outside a GUI or before one).
        [[nodiscard]] virtual u32 GetLastDrawnFrame() const { return m_parent != nullptr ? m_parent->GetLastDrawnFrame() : 0u; }
        /// Not drawn in the host's last frame: hidden, culled, or under something culled.
        [[nodiscard]] bool WasOutOfView() const
        {
            const u32 last = GetLastDrawnFrame();
            return last != 0 && m_drawnFrame != last;
        }
        /// Between these, its invalidations mark it alone, as a hidden node's do: a change that only
        /// paints it differently, made while it is out of view, asks for no frame (it shows when
        /// something brings it into view, which redraws on its own).
        void BeginQuietInvalidation() noexcept { ++m_quietInvalidations; }
        void EndQuietInvalidation() noexcept { --m_quietInvalidations; }

        // === What a frame must redo (only what changed: a clean subtree costs nothing) ===

        /// This node must be restyled (with its subtree when `withDescendants`: a selector with a
        /// combinator may match them differently): a class, id, tag or state changed, or it joined
        /// a tree. Its ancestors learn a descendant waits, so the style pass finds it.
        void MarkStyleDirty(bool withDescendants)
        {
            m_styleDirty = true;
            m_styleSubtreeDirty = m_styleSubtreeDirty || withDescendants;
            for (Node* p = m_parent; p != nullptr && !p->m_childStyleDirty; p = p->m_parent)
                p->m_childStyleDirty = true;
        }
        /// What a tween moves changed (E14): the style pass applies the style it has with the
        /// node's animated layer over it again, without resolving the cascade anew.
        void MarkStyleMotionDirty()
        {
            m_styleMotionDirty = true;
            for (Node* p = m_parent; p != nullptr && !p->m_childStyleDirty; p = p->m_parent)
                p->m_childStyleDirty = true;
        }
        [[nodiscard]] bool IsStyleMotionDirty() const noexcept { return m_styleMotionDirty; }
        /// The states a selector reads (E3), one bit each: a node whose state changed restyles
        /// alone, or with its subtree or its later siblings when a sheet reads that state through
        /// an ancestor or a sibling (the style pass decides; StyleManager knows its sheets).
        enum StyleState : u32
        {
            StateHover = 1u << 0,
            StateFocus = 1u << 1,
            StateActive = 1u << 2,
            StateDisabled = 1u << 3,
            StateFocusVisible = 1u << 4,
            StateEnabled = 1u << 5,
            StateFocusWithin = 1u << 6,
            StateChecked = 1u << 7,
            StateIndeterminate = 1u << 8,
            StateReadOnly = 1u << 9,
            StateReadWrite = 1u << 10,
            StatePlaceholderShown = 1u << 11,
            StateSelected = 1u << 18, // after the selector's own flags (12 to 17)
            StateDropTarget = 1u << 19,
            StateDragSource = 1u << 20,
            StateLeaving = 1u << 22, // after :root (21)
            StateEntering = 1u << 23,
        };
        /// `states` changed on this node: it restyles (its subtree too when the sheets read them
        /// through it).
        void MarkStyleStateDirty(u32 states)
        {
            m_changedStyleStates |= states;
            MarkStyleDirty(false);
        }
        [[nodiscard]] u32 GetChangedStyleStates() const noexcept { return m_changedStyleStates; }
        /// States the style pass reads as set whatever the node's own (E8d: the inspector forcing
        /// :hover, :active, :focus, :focus-visible, :checked or :disabled to see their rules).
        void SetForcedStyleStates(u32 states)
        {
            const u32 changed = states ^ m_forcedStyleStates;
            if (changed == 0)
                return;
            m_forcedStyleStates = states;
            // What a forced state turns with it: disabled is not enabled, focus-visible is focus.
            u32 marks = changed;
            if ((changed & StateDisabled) != 0)
                marks |= StateEnabled;
            if ((changed & StateFocusVisible) != 0)
                marks |= StateFocus;
            MarkStyleStateDirty(marks);
        }
        [[nodiscard]] u32 GetForcedStyleStates() const noexcept { return m_forcedStyleStates; }

        /// The children changed (one joined, left or moved): what matches by position or by
        /// sibling (:first-child, :nth-child(), `+`, `~`) may change for each, and :empty for this
        /// node.
        // The children changed: every kept index is stale, and `moved`'s from another parent too.
        void ChildrenRearranged(Node& moved) noexcept
        {
            if (++m_childrenGeneration == kNoGeneration) // never the mark of "none"
                m_childrenGeneration = 0;
            moved.m_indexGeneration = kNoGeneration;
        }
        // Its children's arrangement changed: a selector reading siblings (:nth-child, `+`, `~`)
        // may match them differently. The style pass decides once whether they restyle (it knows
        // its sheets); marking each child here made building a long list quadratic.
        void ChildrenStyleChanged()
        {
            m_childIndexAll = true; // its index of its children is of others (E15)
            m_stackedKnown = false;
            m_changedChildren.Clear();
            MarkAccessDirty(); // its accessibility node's children changed (E9d)
            m_childrenArrangementChanged = true;
            MarkStyleDirty(false);
        }
        /// Its children were added, removed or moved since its last restyle.
        [[nodiscard]] bool ChildrenArrangementChanged() const noexcept { return m_childrenArrangementChanged; }
        [[nodiscard]] bool IsStyleDirty() const noexcept { return m_styleDirty; }
        [[nodiscard]] bool IsStyleSubtreeDirty() const noexcept { return m_styleSubtreeDirty; }
        [[nodiscard]] bool HasStyleDirtyDescendant() const noexcept { return m_childStyleDirty; }
        void ClearStyleDirty() noexcept
        {
            m_styleDirty = false;
            m_styleMotionDirty = false;
            m_styleSubtreeDirty = false;
            m_childStyleDirty = false;
            m_childrenArrangementChanged = false;
            m_changedStyleStates = 0;
        }

        // === Layout (E2 of Specs/gui-lab-evolution.md) ===
        // A node asks for a size within constraints (Measure: the size its style and content want,
        // cached until either changes) and is placed by its container (Arrange), which lays out its
        // own children when its size changed or they did (OnLayout: by its display kind, or a
        // composite widget's own arrangement).

        // === Code over the sheet (E3) ===
        // A property a sheet sets through a setter (opacity, padding, the layout properties,
        // enabled, visibility, the text properties) is code's once code sets it, as CSS's inline
        // style: the setter pins it and the sheet leaves it be. What no rule sets returns to the
        // node's own value: its default, or what code set before a sheet first styled it.

        /// The node's own values, captured when a sheet first styles it.
        struct UnstyledValues
        {
            bool Captured = false;
            f32 Alpha = 1.0f;
            Thickness Padding{};
            LayoutStyle Layout{};
            bool Visible = true;
            bool Enabled = true;
            bool ClipChildren = false;
        };
        /// While one lives, the node's setters write without pinning: what a sheet applies, and a
        /// widget's defaults (set in its constructor, the values a sheet returns to).
        class StyleWriteScope
        {
        public:
            explicit StyleWriteScope(Node& node) noexcept : m_node(node), m_was(node.m_styleWriting) { node.m_styleWriting = true; }
            ~StyleWriteScope() { m_node.m_styleWriting = m_was; }
            StyleWriteScope(const StyleWriteScope&) = delete;
            StyleWriteScope& operator=(const StyleWriteScope&) = delete;

        private:
            Node& m_node;
            bool m_was;
        };
        /// Pins `slots` as code's (no-op while a StyleWriteScope lives).
        void PinStyle(StyleSlotSet slots) noexcept
        {
            if (!m_styleWriting)
                m_stylePins |= slots;
        }
        /// Gives `slots` back to the sheet: the next restyle sets them, or returns them to the node's own value.
        void UnpinStyle(StyleSlotSet slots) noexcept
        {
            m_stylePins &= ~slots;
            MarkStyleDirty(false);
        }
        [[nodiscard]] bool IsStylePinned(StyleSlot slot) const noexcept { return m_stylePins.Has(slot); }
        [[nodiscard]] StyleSlotSet GetStylePins() const noexcept { return m_stylePins; }
        /// A StyleWriteScope lives (a sheet or a widget's defaults are writing).
        [[nodiscard]] bool IsStyleWriting() const noexcept { return m_styleWriting; }
        /// Its own values, captured now unless they were already.
        const UnstyledValues& CaptureUnstyledValues()
        {
            if (!m_unstyled.Captured)
            {
                m_unstyled.Captured = true;
                m_unstyled.Alpha = m_alpha;
                m_unstyled.Padding = m_padding;
                m_unstyled.Layout = m_layoutStyle;
                m_unstyled.Visible = m_visible;
                m_unstyled.Enabled = m_enabled;
                m_unstyled.ClipChildren = m_clipChildren;
            }
            return m_unstyled;
        }

        [[nodiscard]] const LayoutStyle& GetLayoutStyle() const noexcept { return m_layoutStyle; }
        /// The layout style as a whole (a sheet's, or code's); lays out again.
        void SetLayoutStyle(const LayoutStyle& style)
        {
            PinStyle(ChangedLayoutSlots(m_layoutStyle, style)); // from code: what it changed is its own
            if (style.ZIndex != m_layoutStyle.ZIndex && m_parent != nullptr)
                m_parent->m_stackedKnown = false; // its parent paints its children in another order
            m_layoutStyle = style;
            RequestBoxLayout();
        }
        /// Edits the layout style in place (`edit(LayoutStyle&)`), then lays out again.
        template <typename F>
        void EditLayoutStyle(F&& edit)
        {
            LayoutStyle edited = m_layoutStyle;
            edit(edited);
            SetLayoutStyle(edited);
        }

        /// The space inside the border the content starts from.
        void SetPadding(Thickness padding)
        {
            PinStyle(SlotBit(SlotPaddingTop) | SlotBit(SlotPaddingRight) | SlotBit(SlotPaddingBottom) | SlotBit(SlotPaddingLeft));
            m_padding = padding;
            m_paddingPercent = Thickness{};
            RequestLayout();
            Invalidate();
        }
        /// Padding in percentages of the containing box's width beside the lengths (CSS's
        /// `padding: 5%`; the style pass sets it), resolved against the width it was last measured in.
        void SetPaddingPercent(Thickness percent)
        {
            if (percent == m_paddingPercent)
                return;
            m_paddingPercent = percent;
            RequestLayout();
            Invalidate();
        }
        [[nodiscard]] Thickness GetPaddingPercent() const noexcept { return m_paddingPercent; }
        [[nodiscard]] Thickness GetPadding() const noexcept
        {
            if (m_paddingPercent == Thickness{} || m_percentWidth <= 0.0f)
                return m_padding;
            const f32 k = m_percentWidth * 0.01f;
            return Thickness{m_padding.Left + m_paddingPercent.Left * k, m_padding.Top + m_paddingPercent.Top * k,
                             m_padding.Right + m_paddingPercent.Right * k, m_padding.Bottom + m_paddingPercent.Bottom * k};
        }
        /// Its padding as set, without the percentages.
        [[nodiscard]] Thickness GetPaddingLengths() const noexcept { return m_padding; }
        /// The space outside the border its container keeps clear.
        void SetMargin(Thickness margin)
        {
            PinStyle(SlotBit(SlotMarginTop) | SlotBit(SlotMarginRight) | SlotBit(SlotMarginBottom) | SlotBit(SlotMarginLeft));
            m_layoutStyle.Margin = margin;
            m_layoutStyle.MarginPercent = Thickness{}; // code gives lengths
            RequestBoxLayout();
        }
        [[nodiscard]] Thickness GetMargin() const noexcept { return m_layoutStyle.Margin; }
        /// Its margin within a containing box `width` wide: its lengths and its percentages of
        /// that width (none when the width is not known, below 0).
        [[nodiscard]] Thickness GetMarginWithin(f32 width) const noexcept
        {
            const Thickness& p = m_layoutStyle.MarginPercent;
            if (width <= 0.0f || p == Thickness{})
                return m_layoutStyle.Margin;
            const f32 k = width * 0.01f;
            const Thickness& m = m_layoutStyle.Margin;
            return Thickness{m.Left + p.Left * k, m.Top + p.Top * k, m.Right + p.Right * k, m.Bottom + p.Bottom * k};
        }
        /// The box's border widths (its NodeBox's), the part of its chrome a sheet's border gives.
        [[nodiscard]] Thickness GetBorderThickness() const noexcept
        {
            const vg::BorderWidths& w = m_box.BorderWidths;
            return Thickness{w.left, w.top, w.right, w.bottom};
        }
        /// Padding and border: what lies between the box's edge and its content.
        [[nodiscard]] Thickness GetChrome() const noexcept
        {
            const Thickness b = GetBorderThickness();
            const Thickness p = GetPadding();
            return Thickness{p.Left + b.Left, p.Top + b.Top, p.Right + b.Right, p.Bottom + b.Bottom};
        }
        /// The local bounds inset by the padding and border: where content and children go.
        [[nodiscard]] Rect GetContentBounds() const
        {
            const Thickness c = GetChrome();
            return Rect{c.Left, c.Top, core::Max(0.0f, m_size.x - c.TotalHorizontal()),
                        core::Max(0.0f, m_size.y - c.TotalVertical())};
        }

        /// The border-box size this node wants within `constraints`: its width and height where
        /// its style gives them (a length, or a percentage of the constraints' base), its content's
        /// (MeasureContent) plus its chrome where they are auto, then kept within its min and max
        /// and the constraints. Cached until its style, content or children change.
        core::Float2 Measure(const LayoutConstraints& constraints);
        /// The size of what is inside the chrome, given the space `available` there (kUnbounded on
        /// an axis with no limit). A widget with content of its own (text, an image) answers it;
        /// the default measures the children by the display kind.
        [[nodiscard]] virtual core::Float2 MeasureContent(core::Float2 available);
        /// Where this node's baseline sits, down from its top, when its border box is `size`: what
        /// a flex row with `align-items: baseline` lines up. A widget showing text answers its
        /// first line's; any other node the bottom of its content box.
        [[nodiscard]] virtual f32 BaselineAt(core::Float2 size) const { return size.y - GetChrome().Bottom; }
        /// Its baseline at the size it has.
        [[nodiscard]] f32 GetBaseline() const { return BaselineAt(m_size); }
        /// Places this node at `rect` (its border box, in its parent's space) and lays out its
        /// children when its size changed or they need it.
        void Arrange(const Rect& rect);
        /// Lays out the children again where something in this subtree asked (the pass a GUI runs
        /// each frame), keeping this node where it is.
        void ArrangeAgain() { Arrange(Rect{GetPosition().x, GetPosition().y, m_size.x, m_size.y}); }

        /// This node's content or children changed: it measures and lays out again, and so do the
        /// containers above it whose size follows it, at the next layout pass (a GUI runs one each
        /// frame, so a burst of changes costs one layout).
        void RequestLayout();
        /// This node and everything under it measure and lay out again: for a change every node's
        /// layout reads (the display scale its edges round to).
        void RequestLayoutTree();
        /// Device pixels per logical unit where this node was last laid out (its GUI's display
        /// scale; 1 in a tree with no GUI). Layout rounds every arranged edge to that grid, so
        /// borders and backgrounds land on whole device pixels at any scale.
        [[nodiscard]] f32 GetPixelScale() const noexcept { return m_pixelScale; }
        /// The layout pass for the tree this node tops: lays out what asked, a few rounds while
        /// layouts resize what they hold. A GUI runs it each frame; a tree in no GUI when its
        /// owner wants its geometry. How many containers laid out.
        u32 UpdateLayout();
        /// Its own box changed (its size, margin, display, position): its container lays out again too.
        void RequestBoxLayout()
        {
            RequestLayout();
            if (m_parent != nullptr)
                m_parent->RequestLayout();
        }
        [[nodiscard]] bool IsLayoutDirty() const noexcept { return m_layoutDirty; }
        [[nodiscard]] bool HasLayoutDirtyDescendant() const noexcept { return m_childLayoutDirty; }
        /// Inside this node's own placement or its parent's layout: a size or a position set now is
        /// the layout's, not code's.
        [[nodiscard]] bool IsBeingPlaced() const noexcept { return m_placing || (m_parent != nullptr && m_parent->m_layingOut); }

        // === Scrolling (overflow: scroll or auto) ===
        /// Whether this node scrolls its content on either axis.
        [[nodiscard]] bool IsScrollContainer() const noexcept
        {
            const auto scrolls = [](Overflow o) { return o == Overflow::Scroll || o == Overflow::Auto; };
            return scrolls(m_layoutStyle.OverflowX) || scrolls(m_layoutStyle.OverflowY);
        }
        /// How far the content is scrolled (its children move by minus this).
        [[nodiscard]] core::Float2 GetScrollOffset() const noexcept { return m_scrollOffset; }
        /// Scrolls to `offset` at once (ending a smooth scroll), kept within the range on the axes
        /// that scroll (with a layout pending, kept as asked until the layout knows the content's
        /// extent and clamps it).
        void SetScrollOffset(core::Float2 offset)
        {
            m_smoothScrolling = false;
            m_flinging = false;
            ApplyScrollOffset(offset);
        }
        /// Flings it at `velocity` (offset units a second, as a finger left it): it glides on,
        /// slowing by e^(-t/tau) whatever the frame rate, until it nearly stops or meets an end.
        void Fling(core::Float2 velocity); // LayoutImpl.cpp, which sees :actions
        void StopFling() noexcept { m_flinging = false; }
        [[nodiscard]] bool IsFlinging() const noexcept { return m_flinging; }
        /// Scrolls to `offset`, at once or easing there (Auto: as the node's `scroll-behavior` says).
        void ScrollTo(core::Float2 offset, ScrollBehavior behavior = ScrollBehavior::Auto);
        /// Scrolls to the end of its content (the bottom; a horizontal-only scroller's inline end).
        void ScrollToEnd(ScrollBehavior behavior = ScrollBehavior::Auto);
        /// Where the end of its content is (ScrollToEnd's offset), from `from` on the other axis.
        [[nodiscard]] core::Float2 ScrollEnd(core::Float2 from) const; // LayoutImpl.cpp
        /// Keeps it at the end of its content as the content grows (a log, a chat), while it is at
        /// the end: scrolled away it lets go, and back at the end it holds again (AUI's way).
        void SetStickToEnd(bool stick)
        {
            m_stickToEnd = stick;
            m_latchedToEnd = stick && IsAtScrollEnd();
        }
        [[nodiscard]] bool IsStickToEnd() const noexcept { return m_stickToEnd; }
        /// Held at the end now (stick-to-end and at the end).
        [[nodiscard]] bool IsLatchedToEnd() const noexcept { return m_stickToEnd && m_latchedToEnd; }
        /// At the end of its content on the axis ScrollToEnd moves (within half a pixel).
        [[nodiscard]] bool IsAtScrollEnd() const
        {
            const core::Float2 range = GetScrollRange();
            if (range.y > 0.0f || range.x <= 0.0f)
                return m_scrollOffset.y >= range.y - 0.5f;
            return ScrollsFromRight() ? m_scrollOffset.x <= GetScrollMin().x + 0.5f : m_scrollOffset.x >= range.x - 0.5f;
        }
        /// Where a smooth scroll is going (the offset itself when none runs).
        [[nodiscard]] core::Float2 GetScrollTarget() const noexcept { return m_smoothScrolling ? m_scrollTarget : m_scrollOffset; }
        [[nodiscard]] bool IsSmoothScrolling() const noexcept { return m_smoothScrolling; }
        /// Scrolls by `delta` from where it is going, at once or easing (Auto: the node's own way).
        void ScrollBy(core::Float2 delta, ScrollBehavior behavior = ScrollBehavior::Instant)
        {
            const core::Float2 from = GetScrollTarget();
            ScrollTo(core::Float2{from.x + delta.x, from.y + delta.y}, behavior);
        }
        /// The scroll offset as the children move by it: on the device grid, as their edges are.
        [[nodiscard]] core::Float2 ScrollShift() const noexcept
        {
            return core::Float2{core::Round(m_scrollOffset.x * m_pixelScale) / m_pixelScale,
                                core::Round(m_scrollOffset.y * m_pixelScale) / m_pixelScale};
        }
        /// How far the content can scroll on each axis that scrolls (0 on one that does not).
        [[nodiscard]] core::Float2 GetScrollRange() const
        {
            const Rect box = GetContentBounds();
            const auto scrolls = [](Overflow o) { return o == Overflow::Scroll || o == Overflow::Auto; };
            return core::Float2{scrolls(m_layoutStyle.OverflowX) ? core::Max(0.0f, m_contentExtent.x - box.width) : 0.0f,
                                scrolls(m_layoutStyle.OverflowY) ? core::Max(0.0f, m_contentExtent.y - box.height) : 0.0f};
        }
        /// Where the offset may go on each axis (E17a, CSS's scroll positions): from 0 at the content's
        /// start to its range, except across a right-to-left scroller, whose start is its right, so
        /// it goes from minus its range at the left to 0 there.
        [[nodiscard]] core::Float2 GetScrollMin() const
        {
            return core::Float2{ScrollsFromRight() ? -GetScrollRange().x : 0.0f, 0.0f};
        }
        [[nodiscard]] core::Float2 GetScrollMax() const
        {
            const core::Float2 range = GetScrollRange();
            return core::Float2{ScrollsFromRight() ? 0.0f : range.x, range.y};
        }
        /// Its content starts at its right and overflows to the left: it scrolls across, its flow
        /// running right to left (a dock's sides stay where they say).
        [[nodiscard]] bool ScrollsFromRight() const
        {
            const bool across = m_layoutStyle.OverflowX == Overflow::Scroll || m_layoutStyle.OverflowX == Overflow::Auto;
            return across && m_layoutStyle.Kind != Display::Dock && m_layoutStyle.Kind != Display::None && IsRightToLeft();
        }
        /// The content's size as last laid out: what a scroll container scrolls over.
        [[nodiscard]] core::Float2 GetContentExtent() const noexcept { return m_contentExtent; }
        /// Sets what a scroll container scrolls over, as laying out its children does (the
        /// offset kept within it, held at the end while latched): a container that places its
        /// children itself (an item view, which realises only some of them) says how far its
        /// content reaches.
        void SetScrollExtent(core::Float2 extent); // LayoutImpl.cpp
        /// How far the wheel scrolls per notch, and the arrow keys per press.
        void SetScrollStep(f32 step) noexcept { m_scrollStep = step; }
        /// Whether, focused, the arrows, Page Up and Down, Home and End scroll it (true): a scroller
        /// whose keys are its own (a code editor's caret moves) says false, the keymap then hearing
        /// them; the wheel and the bars scroll it still.
        void SetScrollsByKeys(bool scrolls) noexcept { m_scrollsByKeys = scrolls; }
        [[nodiscard]] bool GetScrollsByKeys() const noexcept { return m_scrollsByKeys; }
        [[nodiscard]] f32 GetScrollStep() const noexcept { return m_scrollStep; }
        /// A part's own states (`::scrollbar-thumb:hover` matches through them): a scroller's bar
        /// hovered, its thumb hovered or dragged. A widget with parts of its own adds theirs.
        [[nodiscard]] virtual u32 GetPartStates(core::StringView part) const
        {
            if (part == core::StringView(u8"scrollbar-thumb"))
                return (m_scrollHover == 2 ? StateHover : 0u) | (m_scrollDragAxis <= 1 ? StateActive : 0u);
            if (part == core::StringView(u8"scrollbar"))
                return m_scrollHover != 0 || m_scrollDragAxis <= 1 ? StateHover : 0u;
            return 0u;
        }
        /// A part's style as the sheet set it (a UINode's; null for a bare node).
        [[nodiscard]] virtual const PartStyle* FindPartStyle(core::StringView part) const
        {
            (void)part;
            return nullptr;
        }
        /// How visible an overlay scroller's bars are now, 0 to 1 (1 for bars that stay).
        [[nodiscard]] f32 GetScrollbarOpacity() const noexcept
        {
            return m_layoutStyle.BarVisibility == ScrollbarVisibility::Overlay ? m_scrollbarAlpha : 1.0f;
        }
        /// Where a scroll container's bar and thumb are on an axis (0 horizontal, 1 vertical), in
        /// local space; empty rects when it shows none.
        [[nodiscard]] Rect ScrollBarTrack(u32 axis) const;
        [[nodiscard]] Rect ScrollBarThumb(u32 axis) const;
        /// How many containers laid out on this thread (a GUI's pass reads the difference).
        static u32& LayoutRunCounter() noexcept;

        // === The box (G2 of Specs/vg-and-gui-lab.md) ===
        // Background colour and layers, a border per side, radii and shadows, drawn under the
        // node's content. A sheet sets it (fromStyle: the next restyle replaces or clears it);
        // native code may set it directly.
        void SetBox(NodeBox box, bool fromStyle = false)
        {
            m_box = core::Move(box);
            m_boxFromStyle = fromStyle;
            Invalidate();
        }
        [[nodiscard]] const NodeBox& GetBox() const noexcept { return m_box; }
        /// Whether its box paints a fill of its own (a background colour, a layer, a border image):
        /// a widget's default face then gives way to it (a theme's, E13).
        [[nodiscard]] bool BoxFills() const noexcept
        {
            return m_box.BackgroundColor.a > 0.0f || !m_box.Layers.IsEmpty() || m_box.Skin.HasPicture();
        }
        [[nodiscard]] bool IsBoxFromStyle() const noexcept { return m_boxFromStyle; }

        /// CSS's `transform` about `transform-origin`: functions applied left to right after the
        /// node's own position, scale and rotation; translations and the origin in percentages
        /// resolve against the node's size, now and whenever it changes.
        void SetStyleTransform(Array<TransformFunction> functions, LengthValue originX, LengthValue originY,
                               bool fromStyle = true)
        {
            m_styleTransforms = core::Move(functions);
            m_transformOriginX = originX;
            m_transformOriginY = originY;
            m_transformFromStyle = fromStyle;
            UpdateStyleTransform();
        }
        [[nodiscard]] bool IsTransformFromStyle() const noexcept { return m_transformFromStyle; }
        [[nodiscard]] const Array<TransformFunction>& GetStyleTransforms() const noexcept { return m_styleTransforms; }

        void DrawScrollBars(DrawContext& ctx) const;
        /// Draws `what` of the layout overlay for this node and its displayed subtree, in this
        /// node's space (clipped where its children are).
        void DrawLayoutOverlay(DrawContext& ctx, const DebugOverlay& what) const;
        /// Places the children in the content box (Arrange calls it when needed). The default lays
        /// them out by the display kind (LayoutChildren); a composite widget arranges its own.
        virtual void OnLayout() { LayoutChildren(); }
        /// Lays out the children by this node's display kind, the out-of-flow ones by their insets,
        /// and records the content's extent (what a scroll container scrolls over).
        void LayoutChildren();

        // Subclass-drawn content, between background and children.
        virtual void OnDraw(DrawContext& ctx, const Rect& localBounds)
        {
            (void)ctx;
            (void)localBounds;
        }

        // === Coordinator lookup + lifecycle ===
        // The SceneRoot's ActionManager / MutationQueue, found by walking to the root.
        // Base returns the parent's; SceneRoot overrides to return its own. Null if the
        // node is not yet attached under a SceneRoot.
        /// Where children given to this node by markup or a script go: the node itself, or, for a
        /// widget built of parts (a scroller, a window), the part that holds its content.
        [[nodiscard]] virtual Node* GetChildHost() { return this; }

        /// The GUI this node is in (its root's context), or null outside one.
        [[nodiscard]] virtual GUIContext* GetGUIContext() { return m_parent ? m_parent->GetGUIContext() : nullptr; }
        /// Where this node's bindings wait for the frame: its SceneRoot's scheduler, or none
        /// outside a scene (a binding then runs at once).
        [[nodiscard]] virtual EffectScheduler* GetEffectScheduler()
        {
            return m_parent ? m_parent->GetEffectScheduler() : nullptr;
        }
        [[nodiscard]] virtual ActionManager* GetActionManager()
        {
            return m_parent ? m_parent->GetActionManager() : nullptr;
        }
        [[nodiscard]] virtual MutationQueue* GetMutationQueue()
        {
            return m_parent ? m_parent->GetMutationQueue() : nullptr;
        }
        // The SceneRoot's EventDispatcher (pointer walk to the root; SceneRoot returns its own).
        /// What the GUI this node is in may create (its SceneRoot's set), or null when detached.
        [[nodiscard]] virtual const ElementSet* GetElementSet() const
        {
            return m_parent ? m_parent->GetElementSet() : nullptr;
        }
        /// The element table of the GUI this node is in (its SceneRoot's), or null when detached.
        [[nodiscard]] virtual ElementTable* GetElementTable()
        {
            return m_parent ? m_parent->GetElementTable() : nullptr;
        }
        [[nodiscard]] virtual EventDispatcher* GetEventDispatcher()
        {
            return m_parent ? m_parent->GetEventDispatcher() : nullptr;
        }
        /// What the last frame of the GUI this node is in cost (its SceneRoot's), or null when
        /// detached (E8a): the phases write it as they run.
        [[nodiscard]] virtual FrameStats* GetFrameStats()
        {
            return m_parent ? m_parent->GetFrameStats() : nullptr;
        }
        /// A short name for diagnostics: its type (a widget adds its id).
        [[nodiscard]] virtual core::String DebugName() const
        {
            const core::TypeInfo* type = GetType();
            return core::String(type != nullptr ? core::StringView(reinterpret_cast<const char8_t*>(type->name)) : core::StringView(u8"Node"));
        }
        [[nodiscard]] const EventDispatcher* GetEventDispatcher() const
        {
            return const_cast<Node*>(this)->GetEventDispatcher(); // a read: which dispatcher, not a change
        }
        /// The font service of the GUI this node is in (its SceneRoot's context's), or null: what a
        /// rich text's runs that set a font of their own ask.
        [[nodiscard]] virtual fonts::IFontService* GetFontService()
        {
            return m_parent ? m_parent->GetFontService() : nullptr;
        }
        /// The resources of the GUI this node is in, or null: what loads a rich text's icons.
        [[nodiscard]] virtual IResourceProvider* GetResourceProvider()
        {
            return m_parent ? m_parent->GetResourceProvider() : nullptr;
        }

        // Programmatic focus (routes through the dispatcher; defined in the impl unit).
        void RequestFocus();
        void ReleaseFocus();

        /// Moves `property` to `to` over `seconds` on the GUI's clock (E14), eased as `easing` names
        /// (a CSS easing or a named curve). The property is named as a sheet names it, and composes
        /// over the cascade, holding its end until stopped; a name no sheet knows is a reflected
        /// property (`value`, `x`, `textColor`). A tween of the same property replaces the running
        /// one, from the value showing. The tween, to shape further (a start value, a delay,
        /// repeats); inert on a node in no GUI. Defined in Styling/TweenImpl.cpp.
        RefPtr<Tween> Animate(core::StringView property, core::StringView to, f32 seconds,
                              core::StringView easing = core::StringView(u8"ease"));
        /// Moves `property` toward `to` as a damped spring (E14, Tween::Spring): a spring already
        /// moving it turns toward the new end from where it is, at the speed it has, rather than
        /// starting again. The spring, running.
        RefPtr<Tween> SpringTo(core::StringView property, core::StringView to, f32 stiffness = 170.0f, f32 damping = 26.0f,
                               f32 mass = 1.0f);
        /// Runs `group` on this node's GUI clock (a script's RunAction for a group, E14).
        void Play(RefPtr<TweenGroup> group);
        /// A tween of this node as Animate makes one, not yet running: a step for a group (E14).
        RefPtr<Tween> CreateTween(core::StringView property, core::StringView to, f32 seconds,
                                  core::StringView easing = core::StringView(u8"ease"));
        /// Stops what moves `property` and gives it back to the sheet (a tween that ended holds
        /// its end until this); false when nothing moved it.
        bool StopAnimation(core::StringView property);

        // Run an action on this node (targets it, hands it to the SceneRoot's manager).
        // No-op (the action is dropped) if the node is not attached under a SceneRoot.
        void RunAction(RefPtr<Action> action)
        {
            if (!action)
                return;
            TargetAction(*action);
            if (ActionManager* manager = GetActionManager())
                manager->AddAction(core::Move(action));
        }

        /// Makes this node `action`'s target, held weakly too: a node destroyed mid-animation takes
        /// its actions with it. RunAction does it; a step of a group (E14) is targeted so, then run
        /// by its group.
        void TargetAction(Action& action)
        {
            action.SetTarget(this);
            if (const ElementRef ref = TakeElementRef(); ref.table != nullptr)
                action.SetWeakTarget(Action::WeakTarget{ref.table, ref.slot, ref.generation, &ResolveActionTarget});
        }

        [[nodiscard]] static Node* ResolveActionTarget(const Action::WeakTarget& weak)
        {
            return static_cast<const ElementTable*>(weak.table)->Resolve(weak.slot, weak.generation);
        }

        // === Weak references and the script surface (G1 of Specs/vg-and-gui-lab.md) ===
        // The tree owns its nodes. Anything else holds one weakly: a slot and a generation in its
        // GUI's element table, resolved on every use (Element<T> natively, a handle in a script),
        // reading as gone once the node is destroyed. Reflected in GUIReflectionImpl.cpp.

        /// This node's place in its GUI's element table, taking a slot the first time; an empty
        /// ref (null table) for a node in no GUI.
        [[nodiscard]] ElementRef TakeElementRef();

        /// A handle to this node typed as `type` (this node's type or a base of it); empty when the
        /// node is in no GUI (a detached element has no owner a handle could resolve through).
        [[nodiscard]] Variant HandleAs(const TypeInfo& type);
        /// The node a handle resolves to now, or null (gone, or not a node's handle).
        [[nodiscard]] static Node* FromHandle(const Variant& handle);
        /// Creates the element `tag` names in this GUI's element set as this node's last child,
        /// from this node's allocator; its handle, or empty when the set does not allow `tag`.
        Variant AddElement(core::StringView tag);
        /// The first widget in this subtree (depth first, this node first) whose id is `id`.
        [[nodiscard]] Variant FindElement(core::StringView id);
        [[nodiscard]] Variant ParentElement();
        [[nodiscard]] Variant ChildElement(i32 index);
        [[nodiscard]] i32 ElementChildCount() const noexcept { return static_cast<i32>(m_children.Size()); }
        /// Calls `handler` on each event named `eventName` (click, mousedown, mouseup,
        /// mouseenter, mouseleave, mousemove, wheel, keydown, keyup, textinput, focus, blur, and the
        /// rest of the core's), or of a name a library sends (SendNamedEvent: a screen's
        /// `screenenter`). A token for Off (0 for an empty name).
        i32 On(core::StringView eventName, RefPtr<foundation::script::IScriptDelegate> handler);
        /// Opens `content` (a node's handle) as a popup below this node (E16): closed by a press
        /// outside it or Escape, focus going into it and back; whether it opened.
        [[nodiscard]] core::Variant OpenPopupScript(core::Variant content);
        /// Closes this node where it is open as a popup (a script's popup, menu or window); false
        /// when it is not one.
        bool ClosePopupScript();
        /// Stops what On or OnCommandScript started (E16), from inside that handler too; false when
        /// the token is none of this node's.
        bool Off(i32 token)
        {
            const u32 id = static_cast<u32>(token);
            return token > 0 && (RemoveEventListener(id) || RemoveCommandHandler(id));
        }
        /// Binds `property` to what `expression` returns, run again whenever what it read changed
        /// (gui.getNumber and the rest, widget properties). False when no such property.
        bool BindScript(core::StringView property, RefPtr<foundation::script::IScriptDelegate> expression);
        /// Binds `property` to this GUI's data value `key` (BindData with its scene's model); false
        /// outside a scene or with no such property.
        bool BindSceneData(core::StringView property, core::StringView key);
        /// Focuses this widget, or, for a container (a page, a dialog), its entry: what was last
        /// focused in it, else its default focus (nav-default), else its first focusable widget.
        /// False when there is nothing to focus.
        bool FocusElement();
        /// Handles command `id` with a script function, in the bubble phase; the function returning
        /// true lets the command go on up the focus path.
        i32 OnCommandScript(core::StringView id, RefPtr<foundation::script::IScriptDelegate> handler);
        /// Removes this node from its tree at the end of the UI's update (Close): never under a
        /// running handler.
        void Destroy() { Close(); }

        [[nodiscard]] f32 GetWidth() const noexcept { return m_size.x; }
        void SetWidth(f32 width) { SetSize(core::Float2{width, m_size.y}); }
        [[nodiscard]] f32 GetHeight() const noexcept { return m_size.y; }
        void SetHeight(f32 height) { SetSize(core::Float2{m_size.x, height}); }
        [[nodiscard]] f32 GetX() const noexcept { return GetPosition().x; }
        void SetX(f32 x) { SetPosition(core::Float2{x, GetPosition().y}); }
        [[nodiscard]] f32 GetY() const noexcept { return GetPosition().y; }
        void SetY(f32 y) { SetPosition(core::Float2{GetPosition().x, y}); }

        // Detach this node from its tree at the next safe sync point (SceneRoot drain).
        // Falls back to immediate removal if there is no coordinator.
        void Close()
        {
            if (MutationQueue* queue = GetMutationQueue())
            {
                RefPtr<Node> self(this); // keep alive until the deferred op runs
                queue->Enqueue([self]() { self.Get()->RemoveFromParent(); });
            }
            else
            {
                RemoveFromParent();
            }
        }

        // === Input routing === (the EventDispatcher starts a route; RouteEvent walks it)
        /// Sends an input event (pointer, wheel, key, text) along its route to this node: down
        /// from the root through the capture listeners, at this node, and back up through each
        /// node's own handler (OnMouseDown and the rest) and its bubble listeners; a handler
        /// marking it Handled ends the route once that node is done. The path is held for the
        /// walk, so a handler may remove nodes on it (one that left the tree is skipped). True
        /// when it was handled.
        bool RouteEvent(Event& event);
        /// One step of a route, at this node, in `event.Phase`: the capture listeners in the
        /// capture and target phases; this node's handler and its bubble listeners in the target
        /// and bubble phases. Everything at a node runs; marking the event Handled ends the
        /// route after it (as the DOM's stopPropagation does). A node given an event outside a
        /// route (an enter or a leave) is given it at the target. `ownHandler` false: its
        /// listeners hear it, its own handler does not (an event from a popup it holds, E5: a click
        /// in a menu is not a click on the button that opened it).
        void DeliverRouted(Event& event, bool ownHandler = true)
        {
            event.CurrentTarget = this;
            if (event.Phase != EventPhase::Bubble)
                RunListeners(event, true);
            if (event.Phase != EventPhase::Capture)
            {
                if (ownHandler)
                    InvokeInputHandler(event);
                RunListeners(event, false);
            }
        }
        /// Under the pointer: this node or one inside it (the dispatcher's hover path); `:hover`.
        [[nodiscard]] bool IsHovered() const noexcept { return m_hovered; }
        /// Pressed: a press on this node or one inside it, not yet released; `:active`.
        [[nodiscard]] bool IsPressed() const noexcept { return m_pressed; }
        /// Set by the dispatcher as the hover and press paths change.
        void SetHovered(bool hovered)
        {
            if (hovered == m_hovered)
                return;
            m_hovered = hovered;
            OnPointerStateChange();
        }
        void SetPressed(bool pressed)
        {
            if (pressed == m_pressed)
                return;
            m_pressed = pressed;
            OnPointerStateChange();
        }
        bool HandleActivate() { return OnActivate(); }
        void HandleFocusGained()
        {
            m_focused = true;
            MarkStyleStateDirty(StateFocus | StateFocusVisible | StateFocusWithin);
            for (Node* p = m_parent; p != nullptr; p = p->m_parent)
            {
                ++p->m_focusWithin;
                p->MarkStyleStateDirty(StateFocusWithin);
            }
            OnFocusGained();
            SendEvent(Event(EventType::FocusGained, this));
        }
        void HandleFocusLost()
        {
            m_focused = false;
            MarkStyleStateDirty(StateFocus | StateFocusVisible | StateFocusWithin);
            for (Node* p = m_parent; p != nullptr; p = p->m_parent)
            {
                if (p->m_focusWithin > 0)
                    --p->m_focusWithin;
                p->MarkStyleStateDirty(StateFocusWithin);
            }
            OnFocusLost();
            SendEvent(Event(EventType::FocusLost, this));
        }

        [[nodiscard]] bool IsFocused() const noexcept { return m_focused; }
        /// Focused, or holding the focused node (CSS's :focus-within).
        [[nodiscard]] bool IsFocusWithin() const noexcept { return m_focused || m_focusWithin > 0; }
        /// Focused, and by the keyboard or a gamepad (CSS's :focus-visible): the focus ring shows
        /// in that use only, not after a click.
        [[nodiscard]] bool IsFocusVisible() const noexcept { return m_focused && m_focusVisible; }
        void SetFocusVisible(bool visible)
        {
            if (visible == m_focusVisible)
                return;
            m_focusVisible = visible;
            if (m_focused)
                MarkStyleStateDirty(StateFocusVisible);
        }
        /// A widget under this node took focus (G7): a scroller brings it into view.
        /// A scroll container scrolls by the least that shows it.
        virtual void OnDescendantFocused(Node& focused) { ScrollIntoView(focused); }
        /// Whether this node brings a focused descendant into view, so a widget its clip hides is
        /// still one navigation reaches (a scroller).
        [[nodiscard]] virtual bool ScrollsDescendantsIntoView() const { return IsScrollContainer(); }
        /// Scrolls (a scroll container) to show `descendant` in the content box: by the least that
        /// shows it, or with its start, centre or end at the box's.
        void ScrollIntoView(Node& descendant, ScrollAlign align = ScrollAlign::Nearest, ScrollBehavior behavior = ScrollBehavior::Auto)
        {
            ScrollIntoView(descendant, descendant.GetLocalBounds(), align, behavior);
        }
        /// The part of it the scrollers round it keep in view while it has focus (a text field's
        /// caret, in its own space), as it moves and as their content grows; false: none.
        [[nodiscard]] virtual bool GetFocusArea(Rect& out) const
        {
            (void)out;
            return false;
        }
        /// Scrolls to show `area` of `descendant` (in its own space): a text field's caret.
        void ScrollIntoView(Node& descendant, const Rect& area, ScrollAlign align = ScrollAlign::Nearest,
                            ScrollBehavior behavior = ScrollBehavior::Auto);

        // === Drag and drop (E7) ===
        // A press that moves past the GUI's threshold offers a drag to the pressed node and then
        // up its ancestors: the first that fills the request starts it, and one that owns its
        // press (a slider, a scroll bar's thumb, a field selecting) ends the walk. While it goes,
        // the node under the pointer and up its ancestors are asked what a drop would do; the
        // first that takes it is the target (`:drop-target`). The source shows `:drag-source` and
        // is told how it ended.

        /// Gives what a press on it drags (an alternative to overriding OnDragRequested).
        void SetDragSource(core::Function<bool(DragRequest&)> source) { m_dragSource = core::Move(source); }
        /// Takes drops of these types (markup's `drop-types`, space-separated) with the source's
        /// preferred effect; an alternative to overriding OnDragQuery or SetOnDragQuery.
        void SetDropTypes(const core::String& types) { m_dropTypes = types; }
        [[nodiscard]] core::String GetDropTypes() const { return m_dropTypes; }
        /// Answers each drop query here (after OnDragQuery leaves it undecided).
        void SetOnDragQuery(core::Function<void(DropQuery&)> query) { m_dropQuery = core::Move(query); }
        /// How a drag from here ended.
        void SetOnDragEnd(core::Function<void(const DragResult&)> callback) { m_dragEnd = core::Move(callback); }

        /// Whether it takes drops of a type, by its drop types.
        [[nodiscard]] bool TakesDropType(core::StringView type) const
        {
            core::StringView rest = core::Trim(m_dropTypes.AsView());
            while (rest.Size() != 0)
            {
                usize end = 0;
                while (end < rest.Size() && rest[end] != u8' ')
                    ++end;
                if (rest.SubStr(0, end) == type)
                    return true;
                rest = core::Trim(rest.SubStr(end, rest.Size() - end));
            }
            return false;
        }

        // The dispatcher's calls (each runs the virtual, then the callbacks, then the listeners).
        bool HandleDragRequested(DragRequest& request)
        {
            if (OnDragRequested(request))
                return true;
            return m_dragSource && m_dragSource(request);
        }
        void HandleDragQuery(DropQuery& query)
        {
            OnDragQuery(query);
            // A listener (a script's `dragquery`) that takes the event takes the drop.
            if (query.Effect == DropEffect::None && !query.Refused && HasListener(EventType::DragQuery))
            {
                DragEvent asked(EventType::DragQuery, this, query.Payload);
                asked.Effect = query.Preferred;
                asked.Modifiers = query.Modifiers;
                SendEvent(asked);
                if (asked.Handled)
                    query.Accept();
            }
            if (query.Effect == DropEffect::None && !query.Refused && m_dropQuery)
                m_dropQuery(query);
            if (query.Effect == DropEffect::None && !query.Refused && TakesDropType(query.Payload.Type.AsView()))
                query.Accept();
        }
        void HandleDragEvent(const DragEvent& event)
        {
            switch (event.Type)
            {
            case EventType::DragEnter: OnDragEnter(event); break;
            case EventType::DragOver: OnDragOver(event); break;
            case EventType::DragLeave: OnDragLeave(event); break;
            case EventType::Drop: OnDrop(event); break;
            default: break;
            }
            SendEvent(event);
        }
        bool HandleDragHoverOpen(core::Float2 local) { return OnDragHoverOpen(local); }
        void HandleDragEnd(const DragResult& result, const DragEvent& event)
        {
            OnDragEnd(result);
            if (m_dragEnd)
                m_dragEnd(result);
            SendEvent(event);
        }
        /// The dispatcher's: whether it is the drag's target now (`:drop-target`), or its source
        /// (`:drag-source`).
        void SetDropTargetState(bool target)
        {
            if (target == m_dropTargetState)
                return;
            m_dropTargetState = target;
            MarkStyleStateDirty(StateDropTarget);
            Invalidate();
        }
        [[nodiscard]] bool IsDropTarget() const noexcept { return m_dropTargetState; }
        void SetDragSourceState(bool source)
        {
            if (source == m_dragSourceState)
                return;
            m_dragSourceState = source;
            MarkStyleStateDirty(StateDragSource);
            Invalidate();
        }
        [[nodiscard]] bool IsDragSource() const noexcept { return m_dragSourceState; }

        // === Leaving (K0 of Specs/gui-lab-evolution-3.md) ===
        // A node that goes plays its way out first: Leave puts it in `:leaving`, where the sheet's
        // exit transition or animation runs, takes it out of the pointer, focus and navigation at
        // once, and the style pass removes it from its parent when what the sheet started on it
        // has ended (the next frame when nothing moves it; an infinite or paused animation is not
        // waited for). Leaving ends when it leaves its parent, by this or any other removal, so a
        // node taken back is whole again. Defined in Scene/GUIClusterImpl.cpp.

        /// Leaves its parent after its exit plays: at the GUI's next update when nothing plays one (no
        /// style pass, or a node no sheet styles), at once in no GUI.
        void Leave();
        /// Whether it is leaving (`:leaving`).
        [[nodiscard]] bool IsLeaving() const noexcept { return m_leaving; }
        /// Whether it or an ancestor is leaving.
        [[nodiscard]] bool IsTreeLeaving() const noexcept
        {
            for (const Node* n = this; n != nullptr; n = n->m_parent)
                if (n->m_leaving)
                    return true;
            return false;
        }

        // === Inert (K4 of Specs/gui-lab-evolution-3.md, HTML's `inert`) ===
        /// An inert node and what it holds take no pointer, focus, navigation, keys or commands,
        /// and still draw (a game's screen under a blocking one). Made inert, what the dispatcher
        /// held in it lets go, as of a removed subtree: a press held, the hover, the focus, its
        /// popups. Defined in Scene/GUIClusterImpl.cpp.
        void SetInert(bool inert);
        [[nodiscard]] bool IsInert() const noexcept { return m_inert; }
        /// Whether it or an ancestor is inert or leaving: it takes no input.
        [[nodiscard]] bool IsTreeInert() const noexcept
        {
            for (const Node* n = this; n != nullptr; n = n->m_parent)
                if (n->m_leaving || n->m_inert)
                    return true;
            return false;
        }
        /// The style pass's: what moves it has ended, so it goes (at the next safe point, once).
        void FinishLeaving();

        // === Entering (K5 of Specs/gui-lab-evolution-3.md) ===
        // A node that arrives plays its way in: Enter puts it in `:entering`, where the sheet's
        // entrance runs (a keyframe animation, or values it starts from, as CSS's @starting-style),
        // until what that started has ended; then `:entering` goes, the node moves to its own style
        // (through its transitions), and once that has settled it hears `entered`. Leave cuts an
        // entrance short, leaving from where it is. In no GUI, in one no style pass runs over, or
        // not styled, it has no entrance and hears `entered` at once. Defined in Scene/GUIClusterImpl.cpp.

        void Enter();
        /// In `:entering`, its entrance's first half.
        [[nodiscard]] bool IsEntering() const noexcept { return m_enterPhase == 1; }
        /// Entering, or moving to its own style after: `entered` is still to come.
        [[nodiscard]] bool IsArriving() const noexcept { return m_enterPhase != 0; }
        /// Whether the style pass tells it when what moves it settles (MotionSettled): leaving or arriving.
        [[nodiscard]] bool WatchesMotion() const noexcept { return m_leaving || m_enterPhase != 0; }
        /// The style pass's: nothing the sheet started on it waits now. A leaving node goes; an
        /// arriving one takes its entrance's next step (at the GUI's next drain).
        void MotionSettled();
        /// A style pass ran over the tree this node tops (StyleManager::ApplyTree says so): a node
        /// leaving it waits for the sheet's exit.
        void NoteStylePass() noexcept { m_styledTree = true; }
        [[nodiscard]] bool HasStylePass() const noexcept { return m_styledTree; }
        /// It owns a press at `local` for a drag of its own (a slider's thumb, a scroll bar, a
        /// field selecting): a drag from an ancestor is not offered.
        [[nodiscard]] virtual bool OwnsPressDrag(core::Float2 local) const
        {
            // A scroll container's bars are its own.
            return IsScrollContainer() && (ScrollBarTrack(0).Contains(local) || ScrollBarTrack(1).Contains(local));
        }
        /// The preview a drag shows when its source gives none (GUIClusterImpl.cpp: a label of
        /// the payload's label), and the hint beside the pointer with a target's reason.
        [[nodiscard]] virtual core::RefPtr<Node> CreateDragPreview(const DragPayload& payload);
        [[nodiscard]] virtual core::RefPtr<Node> CreateDropHint(core::StringView reason, bool refused);
        /// A preview hears the effect a drop would have now (a default preview shows a badge).
        virtual void OnDragPreviewEffect(DropEffect) {}

        // True if this node edits text and wants the platform's text-input (IME) enabled
        // while it holds focus. The gui.shell bridge reads the focused node's answer and
        // drives the window's StartTextInput/StopTextInput accordingly. Default: false.
        [[nodiscard]] virtual bool WantsTextInput() const { return false; }
        /// Whether what it takes is secret (a password): the platform's IME keeps out of it.
        [[nodiscard]] virtual bool IsTextInputSecret() const { return false; }
        /// Where text is typed in this node, in its own space, and the caret's x there: the IME
        /// places its candidate list beside it. False when it types no text.
        [[nodiscard]] virtual bool GetTextInputArea(Rect& area, f32& caretX) const
        {
            (void)area;
            (void)caretX;
            return false;
        }

        /// Whether the pointer over this node is the GUI's, so a game host leaves a click there
        /// alone: a node that paints a background, takes focus, or listens for the pointer.
        /// A plain layout container lets the pointer through to the game.
        [[nodiscard]] virtual bool TakesPointer() const
        {
            if (m_box.BackgroundColor.a > 0.0f || !m_box.Layers.IsEmpty() || IsTabFocusable())
                return true;
            for (usize i = 0; i < m_listeners.Size(); ++i)
                if (!m_listeners[i].Removed)
                    switch (m_listeners[i].Type)
                    {
                    case EventType::MouseDown:
                    case EventType::MouseUp:
                    case EventType::MouseClick:
                    case EventType::MouseWheel: return true;
                    default: break;
                    }
            return false;
        }

        // Optional hover-tooltip text: the dispatcher shows the nearest one up the parent chain
        // from the hovered node, after a delay (E5). Empty (the default) means none here.
        [[nodiscard]] virtual core::StringView GetTooltipText() const { return {}; }
        /// Its tooltip takes the pointer (E16): it holds while the pointer crosses into it, and a
        /// press inside it does not close it (a tooltip with a link or a button).
        [[nodiscard]] virtual bool IsTooltipInteractive() const { return false; }
        /// What its tooltip shows for `text` (E5): a Tooltip label by default (defined where the
        /// widgets are); any node, for a richer one. Null: no tooltip.
        [[nodiscard]] virtual core::RefPtr<Node> CreateTooltipContent(core::StringView text);

        // Tab-navigation: whether Tab / Shift+Tab focus traversal can land on this node
        // (distinct from click focus, which targets whatever is hit). Interactive widgets
        // opt in; static nodes (labels, layouts) stay false. Modeled on eepp's
        // UI_TAB_FOCUSABLE flag.
        void SetTabFocusable(bool focusable) noexcept { m_tabFocusable = focusable; }
        [[nodiscard]] bool IsTabFocusable() const noexcept { return m_tabFocusable; }
        /// Where Tab reaches it (CSS's and HTML's `tab-index`, E12 of Specs/gui-lab-evolution-2.md):
        /// a positive index before the rest, lowest first (a tie in tree order); 0, in tree order
        /// (the default); below 0, never by Tab, though a click, an arrow or code still focuses it.
        void SetTabIndex(i32 index) noexcept { m_tabIndex = index; }
        /// Tab and Shift+Tab reach it as keys rather than moving focus (CSS-like `tab-captures`, E12:
        /// a code editor, a terminal); Ctrl+Tab and Ctrl+Shift+Tab move focus from it instead.
        void SetTabCaptures(bool captures) noexcept { m_tabCaptures = captures; }
        /// A press in it leaves the focus where it is, rather than moving it to what was pressed or
        /// clearing it (the web's prevented `mousedown`): a code editor's completion list, whose
        /// row a click picks while the editor keeps the keys. A focusable widget inside it still
        /// takes the focus.
        void SetKeepsFocus(bool keeps) noexcept { m_keepsFocus = keeps; }
        [[nodiscard]] bool GetKeepsFocus() const noexcept { return m_keepsFocus; }
        [[nodiscard]] bool GetTabCaptures() const noexcept { return m_tabCaptures; }
        [[nodiscard]] i32 GetTabIndex() const noexcept { return m_tabIndex; }

        // === Focus scopes (G7) ===
        // A scope groups what directional and tab navigation move between: it says what happens
        // at its edge, remembers what was last focused inside it (so coming back returns there),
        // and may name the widget focus starts on (its id).
        void SetNavScope(NavScope scope) noexcept { m_navScope = scope; }
        /// Its scope's kind: as set, or, for a focus group that sets none, wrap.
        [[nodiscard]] NavScope GetNavScope() const noexcept
        {
            return m_navScope == NavScope::None && m_focusGroup ? NavScope::Wrap : m_navScope;
        }
        /// A focus group (E12 of Specs/gui-lab-evolution-2.md: a radio group, a tab strip, a
        /// toolbar): one Tab stop however many it holds, the member focused there last (else its
        /// `nav-default`, else its current one, else the first); the arrows move inside it, wrapping
        /// unless its `nav-scope` says otherwise. Reflected as `focus-group`.
        void SetFocusGroup(bool group) noexcept { m_focusGroup = group; }
        [[nodiscard]] bool IsFocusGroup() const noexcept { return m_focusGroup; }
        /// Whether it is its group's current member (a checked radio, the selected tab): where Tab
        /// enters a focus group no one has focused in yet.
        [[nodiscard]] virtual bool IsCurrentInGroup() const { return false; }
        void SetDefaultFocusId(core::StringView id) { m_defaultFocusId = core::String(id); }
        [[nodiscard]] core::StringView GetDefaultFocusId() const noexcept { return m_defaultFocusId.AsView(); }
        /// What was last focused inside this scope (weakly: null once it is gone).
        [[nodiscard]] Node* GetRememberedFocus() const noexcept
        {
            return m_rememberedFocus.table != nullptr
                       ? m_rememberedFocus.table->Resolve(m_rememberedFocus.slot, m_rememberedFocus.generation)
                       : nullptr;
        }
        void RememberFocus(Node& focused) { m_rememberedFocus = focused.TakeElementRef(); }

        // Overrides where the geometry is wrong (`nav-up`, `nav-down`, `nav-left`, `nav-right`,
        // `nav-next`, `nav-prev`): a widget's id to go to, `none` to stop, or `auto` (or empty) for
        // the picker or the tab order. Reflected with their CSS names, so sheets, markup and
        // scripts set them alike; a scope's kind (`nav-scope`: pass, wrap, contain, none) and default
        // focus (`nav-default`) likewise.
        enum NavOverride : u8
        {
            NavOverrideUp,
            NavOverrideDown,
            NavOverrideLeft,
            NavOverrideRight,
            NavOverrideNext,
            NavOverridePrevious,
            NavOverrideCount,
        };
        [[nodiscard]] core::StringView GetNavOverride(NavOverride which) const noexcept { return m_navOverrides[which].AsView(); }
        void SetNavOverride(NavOverride which, core::StringView target) { m_navOverrides[which] = core::String(target); }
        [[nodiscard]] core::StringView GetNavUp() const noexcept { return GetNavOverride(NavOverrideUp); }
        void SetNavUp(core::StringView v) { SetNavOverride(NavOverrideUp, v); }
        [[nodiscard]] core::StringView GetNavDown() const noexcept { return GetNavOverride(NavOverrideDown); }
        void SetNavDown(core::StringView v) { SetNavOverride(NavOverrideDown, v); }
        [[nodiscard]] core::StringView GetNavLeft() const noexcept { return GetNavOverride(NavOverrideLeft); }
        void SetNavLeft(core::StringView v) { SetNavOverride(NavOverrideLeft, v); }
        [[nodiscard]] core::StringView GetNavRight() const noexcept { return GetNavOverride(NavOverrideRight); }
        void SetNavRight(core::StringView v) { SetNavOverride(NavOverrideRight, v); }
        [[nodiscard]] core::StringView GetNavNext() const noexcept { return GetNavOverride(NavOverrideNext); }
        void SetNavNext(core::StringView v) { SetNavOverride(NavOverrideNext, v); }
        [[nodiscard]] core::StringView GetNavPrevious() const noexcept { return GetNavOverride(NavOverridePrevious); }
        void SetNavPrevious(core::StringView v) { SetNavOverride(NavOverridePrevious, v); }
        [[nodiscard]] core::StringView GetNavScopeName() const noexcept
        {
            switch (m_navScope)
            {
            case NavScope::Pass: return core::StringView(u8"pass");
            case NavScope::Wrap: return core::StringView(u8"wrap");
            case NavScope::Contain: return core::StringView(u8"contain");
            case NavScope::None: break;
            }
            return core::StringView(u8"none");
        }
        /// The key context this node declares for bindings (G7: "menu", "editor mode=insert"):
        /// a binding's context predicate is matched against these along the focus path. Reflected
        /// with its CSS name (`key-context`).
        [[nodiscard]] core::StringView GetKeyContext() const noexcept { return m_keyContext.AsView(); }
        void SetKeyContext(core::StringView context) { m_keyContext = core::String(context); }
        void SetNavScopeName(core::StringView name)
        {
            m_navScope = name == core::StringView(u8"pass")      ? NavScope::Pass
                         : name == core::StringView(u8"wrap")    ? NavScope::Wrap
                         : name == core::StringView(u8"contain") ? NavScope::Contain
                                                                 : NavScope::None;
        }

        // === Invalidation === (marks self and every ancestor up to the root)
        // Not stopping at an ancestor already marked: one marked after it was drawn in a frame (a
        // later node's drawing touched it) or never drawn (hidden) keeps its mark while the root's
        // is cleared, and a change under it would never reach the root; a skipped frame then hid
        // it (a list's rows, a field's committed value, a selection showed only once something
        // else redrew).
        // A node not shown (hidden, or under a node not displayed) marks itself alone: nothing on
        // screen changes (an animation running on a page out of view asks for no frames), and it
        // reaches the root again once shown (showing it invalidates, or lays out).
        void Invalidate()
        {
            MarkAccessDirty(); // what shows differently may read differently (E9d)
            m_needsRedraw = true;
            m_invalidatedSelf = true;
            m_subtreeInkValid = false;
            if (!IsTreeVisible() || m_quietInvalidations != 0)
            {
                NoteOldArea(nullptr); // hidden: where it showed is to be drawn again
                return;
            }
            NoteOldArea(MarkAncestorsForRedraw()); // the topmost: its root
        }
        /// Its ancestors draw again (what holds it changed), up to its root, which it returns: what
        /// Invalidate does above the node, without the node's own area counting as changed.
        Node* MarkAncestorsForRedraw()
        {
            Node* through = this; // the child of each ancestor the change came up through
            for (Node* p = m_parent; p != nullptr; p = p->m_parent)
            {
                p->m_needsRedraw = true;
                p->m_subtreeInkValid = false; // what it holds may reach elsewhere now
                p->NoteChildChanged(*through); // and that child's reach may have moved (E15)
                through = p;
            }
            return through;
        }
        /// A frame's damage (E15): the root collects the areas, in device pixels, that changed
        /// since its last frame (where a node was, before it changed, moved, hid or went). Nodes
        /// other than a root keep none.
        virtual void AddDamage(const Rect& device) { (void)device; }

    private:
        // What it covered when last drawn is to be drawn again: told to its root, once a frame.
        void NoteOldArea(Node* root)
        {
            if (!m_drawnAreaValid || m_damageNoted)
                return;
            m_damageNoted = true;
            if (root == nullptr)
                root = GetRootNode();
            if (root != nullptr)
                root->AddDamage(m_drawnArea);
        }

    public:
        [[nodiscard]] bool NeedsRedraw() const noexcept { return m_needsRedraw; }

        /// Its accessibility node may read differently (E9d): the next update sends it, and its
        /// ancestors learn something below waits, so the walk finds it. A node starts marked.
        void MarkAccessDirty() noexcept
        {
            m_accessDirty = true;
            for (Node* p = m_parent; p != nullptr && !p->m_accessChildDirty; p = p->m_parent)
                p->m_accessChildDirty = true;
        }
        [[nodiscard]] bool IsAccessDirty() const noexcept { return m_accessDirty; }
        /// A hash of what was last sent of it to the bridge: marked again (an animation's frames),
        /// it is sent only when what it reads changed.
        [[nodiscard]] u64 GetAccessSent() const noexcept { return m_accessSent; }
        /// Whether code placed it (SetPosition): its insets are a place in its parent's box, not a
        /// sheet's insets from inside the parent's border.
        [[nodiscard]] bool IsPlacedByCode() const noexcept { return m_placedByCode; }
        void SetAccessSent(u64 hash) noexcept { m_accessSent = hash; }
        [[nodiscard]] bool HasAccessDirtyDescendant() const noexcept { return m_accessChildDirty; }
        void ClearAccessDirty() noexcept
        {
            m_accessDirty = false;
            m_accessChildDirty = false;
        }
        void ClearNeedsRedraw() noexcept { m_needsRedraw = false; }

        // === Transformable overrides: geometry changes invalidate + notify ===
        // An unchanged value is no change: hosts and layouts set geometry every pass, and an idle
        // frame must find nothing to redraw.
        /// The node's place in its parent. From code (not a layout placing it), it takes the node
        /// out of its container's flow to that place, as `position: absolute` with `left` and `top`
        /// does; every layout keeps it there.
        void SetPosition(core::Float2 position) override
        {
            if (!IsBeingPlaced())
            {
                PinStyle(SlotBit(SlotPosition) | SlotBit(SlotLeft) | SlotBit(SlotTop) | SlotBit(SlotRight) | SlotBit(SlotBottom));
                const bool wasInFlow = m_layoutStyle.Placement != Position::Absolute;
                m_layoutStyle.Placement = Position::Absolute;
                m_placedByCode = true; // at this place in its parent's box, not inside its border
                m_layoutStyle.Left = LayoutLength::Px(position.x);
                m_layoutStyle.Top = LayoutLength::Px(position.y);
                m_layoutStyle.Right = LayoutLength{};
                m_layoutStyle.Bottom = LayoutLength{};
                if (wasInFlow && m_parent != nullptr)
                    m_parent->RequestLayout(); // its siblings close the gap
            }
            if (position == GetPosition())
                return;
            Transformable::SetPosition(position);
            HandlePositionChange();
        }
        void SetRotation(f32 radians) override
        {
            if (radians == GetRotation())
                return;
            Transformable::SetRotation(radians);
            Invalidate();
        }
        void SetScale(core::Float2 factors) override
        {
            if (factors == GetScale())
                return;
            Transformable::SetScale(factors);
            Invalidate();
        }

        // === Direction (E9b of Specs/gui-lab-evolution.md) ===

        /// Which way its content runs: as what holds it does (the top of a GUI: its language's,
        /// as the Localization's tables say), left to right, or right to left (CSS's `direction`).
        /// Auto (HTML's dir="auto", E11 of Specs/gui-lab-evolution-2.md): its text's paragraphs
        /// each run as their first strong character reads, typed or translated; its boxes run as
        /// what holds it does.
        enum class LayoutDirection : u8
        {
            Inherit,
            LeftToRight,
            RightToLeft,
            Auto,
        };
        void SetLayoutDirection(LayoutDirection direction)
        {
            PinStyle(SlotBit(SlotDirection));
            if (direction == m_direction)
                return;
            m_direction = direction;
            DirectionChanged();
        }
        [[nodiscard]] LayoutDirection GetLayoutDirection() const noexcept { return m_direction; }
        /// It places its children itself, at points of its own rather than in a flow (a canvas:
        /// a node graph's nodes), so right to left does not move them; what is inside each child
        /// still runs as its direction says.
        void SetPlacesChildren(bool places) noexcept { m_placesChildren = places; }
        [[nodiscard]] bool GetPlacesChildren() const noexcept { return m_placesChildren; }
        void SetDirectionName(const core::String& name)
        {
            SetLayoutDirection(name == core::StringView(u8"rtl")    ? LayoutDirection::RightToLeft
                               : name == core::StringView(u8"ltr")  ? LayoutDirection::LeftToRight
                               : name == core::StringView(u8"auto") ? LayoutDirection::Auto
                                                                    : LayoutDirection::Inherit);
        }
        [[nodiscard]] core::String GetDirectionName() const
        {
            return core::String(m_direction == LayoutDirection::RightToLeft   ? core::StringView(u8"rtl")
                                : m_direction == LayoutDirection::LeftToRight ? core::StringView(u8"ltr")
                                : m_direction == LayoutDirection::Auto        ? core::StringView(u8"auto")
                                                                              : core::StringView(u8"inherit"));
        }
        /// Whether its content runs right to left (the first ancestor not inheriting says, else
        /// the GUI's language).
        [[nodiscard]] bool IsRightToLeft() const
        {
            for (const Node* n = this; n != nullptr; n = n->m_parent)
            {
                if (n->m_direction == LayoutDirection::LeftToRight || n->m_direction == LayoutDirection::RightToLeft)
                    return n->m_direction == LayoutDirection::RightToLeft;
                if (n->m_parent == nullptr)
                    return n->ContextRightToLeft();
            }
            return false;
        }
        /// Which way an arrow key goes along the line (E17a): +1 toward the inline end (Right, or
        /// Left in right to left), -1 toward its start, 0 for any other key.
        [[nodiscard]] i32 InlineStep(KeyCode key) const
        {
            if (key != KeyCode::Left && key != KeyCode::Right)
                return 0;
            return (key == KeyCode::Right) != IsRightToLeft() ? 1 : -1;
        }
        /// Whether its drawing (with what it holds) flips left for right in right to left: an
        /// arrow or icon that points along the line (CSS has none; the GUI's `mirror-on-rtl`).
        void SetMirrorOnRtl(bool mirror)
        {
            if (mirror == m_mirrorOnRtl)
                return;
            m_mirrorOnRtl = mirror;
            RefreshMirror();
        }
        [[nodiscard]] bool GetMirrorOnRtl() const noexcept { return m_mirrorOnRtl; }
        /// Whether it is drawn flipped now.
        [[nodiscard]] bool IsMirrored() const noexcept { return m_mirrored; }
        void RefreshMirror()
        {
            const bool mirrored = m_mirrorOnRtl && IsRightToLeft();
            if (mirrored == m_mirrored)
                return;
            m_mirrored = mirrored;
            UpdateStyleTransform();
        }
        /// Tells it and what it holds that the way they run may have changed (stopping below at a
        /// node that sets its own): text takes its paragraphs' direction from it (E9c).
        void NotifyDirectionChange()
        {
            OnDirectionChange();
            for (usize i = 0; i < m_children.Size(); ++i)
                if (Node* child = m_children[i].Get(); child != nullptr && child->FollowsParentDirection())
                    child->NotifyDirectionChange();
        }
        /// Whether its text's paragraphs take their direction from their content: the first node up
        /// from it that sets a direction sets auto.
        [[nodiscard]] bool IsDirectionAuto() const
        {
            for (const Node* n = this; n != nullptr; n = n->m_parent)
                if (n->m_direction != LayoutDirection::Inherit)
                    return n->m_direction == LayoutDirection::Auto;
            return false;
        }
        /// Its boxes run as its parent's do (inherited, or auto, whose boxes follow the parent).
        [[nodiscard]] bool FollowsParentDirection() const noexcept
        {
            return m_direction == LayoutDirection::Inherit || m_direction == LayoutDirection::Auto;
        }
        /// The way it runs may have changed (its own direction, an ancestor's, or a new parent).
        virtual void OnDirectionChange() {}
        /// The direction changed here or above: the subtree lays out again (its rows run the other
        /// way) and restyles (text-align's start and end follow it).
        void DirectionChanged()
        {
            RequestLayoutTree();
            NotifyDirectionChange();
            if (m_styleWriting) // the style pass applies it before its text: only what it holds waits
            {
                for (usize i = 0; i < m_children.Size(); ++i)
                    if (Node* child = m_children[i].Get())
                        child->MarkStyleDirty(true);
            }
            else
                MarkStyleDirty(true);
            Invalidate();
        }

        // === Translation (E9a of Specs/gui-lab-evolution.md) ===

        /// Whether its translated properties resolve their keys: as what holds it does (the root
        /// does), always, or never (a key then shows as written).
        enum class AutoTranslate : u8
        {
            Inherit,
            Always,
            Off,
        };
        void SetAutoTranslate(AutoTranslate mode)
        {
            if (mode == m_autoTranslate)
                return;
            m_autoTranslate = mode;
            m_translationChanged.Notify();
        }
        [[nodiscard]] AutoTranslate GetAutoTranslate() const noexcept { return m_autoTranslate; }
        void SetAutoTranslateName(const core::String& name)
        {
            SetAutoTranslate(name == core::StringView(u8"always") ? AutoTranslate::Always
                             : name == core::StringView(u8"off")  ? AutoTranslate::Off
                                                                  : AutoTranslate::Inherit);
        }
        [[nodiscard]] core::String GetAutoTranslateName() const
        {
            return core::String(m_autoTranslate == AutoTranslate::Always ? core::StringView(u8"always")
                                : m_autoTranslate == AutoTranslate::Off  ? core::StringView(u8"off")
                                                                         : core::StringView(u8"inherit"));
        }
        /// Whether its translated properties resolve now (the first ancestor not inheriting says;
        /// the top of a tree does). Read by a translated binding, which follows a change above.
        [[nodiscard]] bool IsAutoTranslating() const
        {
            for (const Node* n = this; n != nullptr; n = n->m_parent)
            {
                n->m_translationChanged.Track();
                if (n->m_autoTranslate != AutoTranslate::Inherit)
                    return n->m_autoTranslate == AutoTranslate::Always;
            }
            return true;
        }

        /// The language it speaks (`lang`, as markup's attribute; inherited: empty takes what holds
        /// it speaks, the top of a GUI its Localization's). `:lang()` matches it.
        void SetLang(const core::String& lang)
        {
            if (lang == m_lang)
                return;
            m_lang = lang;
            MarkStyleDirty(true); // what :lang matches here and below may differ
        }
        [[nodiscard]] core::String GetLang() const { return m_lang; }
        [[nodiscard]] core::String Language() const
        {
            for (const Node* n = this; n != nullptr; n = n->m_parent)
            {
                if (!n->m_lang.IsEmpty())
                    return n->m_lang;
                if (n->m_parent == nullptr)
                    return n->ContextLanguage();
            }
            return {};
        }

        /// One argument of a translated text: a literal, or a value of the GUI's data by name.
        struct TranslationArgument
        {
            core::String Text;
            bool IsName = false;
        };
        /// Binds reflected property `property` (one marked `translatable`) to the text of `key` in
        /// the GUI's Localization: resolved now and again when the language changes, the node joins
        /// a GUI, or a named argument changes. With a count, the key's plural form for it, `{0}`
        /// the count and `args` from `{1}`; else `args` from `{0}`. A key shows as written while no
        /// Localization is set or auto-translation is off. False when the property is none such.
        /// `fallback` shows where no table has the key, or the GUI has no Localization (a widget's own
        /// label, "OK", over "gui.ok"); empty: the key shows, as for markup's @key.
        bool BindTranslation(core::StringView property, core::StringView key, RefPtr<DataModel> data = {},
                             Optional<TranslationArgument> count = {}, Array<TranslationArgument> args = {},
                             core::StringView fallback = {}); // GUIReflectionImpl.cpp
        /// The key a translated property resolves (null when it is not translated).
        [[nodiscard]] const core::String* TranslationKey(core::StringView property) const
        {
            for (const TranslatedProperty& t : m_translations)
                if (t.Property.AsView() == property)
                    return &t.Key;
            return nullptr;
        }

        // === Bindings (G5 of Specs/vg-and-gui-lab.md) ===

        /// Runs `body` now, and again on this GUI's frame whenever something it read changed (at
        /// once outside a scene). The node owns it: it ends with the node, or at ClearBindings.
        Effect& Bind(core::Function<void()> body)
        {
            m_bindings.PushBack(
                MakeUnique<Effect>(MemoryAllocator(), core::Move(body), [this]() { return GetEffectScheduler(); }));
            return *m_bindings[m_bindings.Size() - 1];
        }
        /// Binds the reflected property named `name` (this node's type's or a base's) to
        /// `expression`'s value, converted to the property's type: native code, markup and scripts
        /// bind any widget's properties this way, a library's included. False when the node has no
        /// such writable property.
        bool BindProperty(core::StringView name, core::Function<Variant()> expression);
        /// The reverse: `write` takes the property's value now and whenever it changes (the user
        /// moved a slider, typed). Only for the properties a widget's user changes (the `twoWay`
        /// property attribute); false for any other.
        bool BindPropertyBack(core::StringView name, core::Function<void(const Variant&)> write);
        /// Binds `property` to `model`'s value `key`, as markup's `{{key}}` does: it follows the
        /// value, and writes it back when the property is one the user changes. False when the node
        /// has no such writable property.
        bool BindData(core::StringView property, RefPtr<DataModel> model, core::StringView key)
        {
            const core::String name(key);
            if (!BindProperty(property, [model, name] { return model->Get(name.AsView()); }))
                return false;
            (void)BindPropertyBack(property, [model, name](const Variant& v) { model->Set(name.AsView(), v); });
            return true;
        }
        void ClearBindings()
        {
            m_bindings.Clear();
            m_propertyBindings.Clear();
        }
        /// Bind for one reflected property (`back`: the write-back from it): binding the property
        /// again replaces the binding, rather than leaving the old one running beside it.
        Effect& BindFor(const void* property, bool back, core::Function<void()> body)
        {
            for (usize i = 0; i < m_propertyBindings.Size(); ++i)
                if (m_propertyBindings[i].Property == property && m_propertyBindings[i].Back == back)
                {
                    for (usize b = 0; b < m_bindings.Size(); ++b)
                        if (m_bindings[b].Get() == m_propertyBindings[i].Bound)
                        {
                            m_bindings.RemoveAt(b);
                            break;
                        }
                    m_propertyBindings.RemoveAt(i);
                    break;
                }
            Effect& bound = Bind(core::Move(body));
            m_propertyBindings.PushBack(PropertyBinding{property, back, &bound});
            return bound;
        }
        [[nodiscard]] usize BindingCount() const noexcept { return m_bindings.Size(); }
        /// Calls `f(id, phase)` for each command it handles (the inspector lists them).
        template <typename F>
        void ForEachCommandHandler(F&& f) const
        {
            for (const CommandHandlerEntry& entry : m_commandHandlers)
                f(entry.Id.AsView(), entry.Phase);
        }
        /// Calls `f(type, capture)` for each event listener on it (the inspector lists them).
        template <typename F>
        void ForEachListener(F&& f) const
        {
            for (const Listener& listener : m_listeners)
                if (!listener.Removed)
                    f(listener.Type, listener.Capture);
        }

        // === Command handlers (G7 of Specs/vg-and-gui-lab.md) ===
        // A node handles commands by id: running one walks the focus path (capture from the root
        // down, then bubble from the focused widget up), and a command is available while a handler
        // for it is on that path. A screen's commands live on the screen; the GUI's own on its root.

        /// Handles command `id` in `phase`; a token for RemoveCommandHandler.
        u32 OnCommand(core::StringView id, CommandHandler handler, CommandPhase phase = CommandPhase::Bubble)
        {
            CommandHandlerEntry entry{core::String(id), phase, core::Move(handler), ++m_nextListenerId};
            if (m_dispatching != 0)
                m_pendingCommandHandlers.PushBack(core::Move(entry)); // joins once the running ones return
            else
                m_commandHandlers.PushBack(core::Move(entry));
            NotifyCommandsChanged();
            return m_nextListenerId;
        }
        /// Removes a handler; one removed while handlers run (its own, from inside it) is marked and
        /// goes once they return, never destroyed while it runs. False when the token is none of its.
        bool RemoveCommandHandler(u32 token)
        {
            for (usize i = 0; i < m_commandHandlers.Size(); ++i)
                if (m_commandHandlers[i].Token == token && !m_commandHandlers[i].Removed)
                {
                    if (m_dispatching != 0)
                        m_commandHandlers[i].Removed = true;
                    else
                        m_commandHandlers.RemoveAt(i);
                    NotifyCommandsChanged();
                    return true;
                }
            for (usize i = 0; i < m_pendingCommandHandlers.Size(); ++i)
                if (m_pendingCommandHandlers[i].Token == token)
                {
                    m_pendingCommandHandlers.RemoveAt(i);
                    NotifyCommandsChanged();
                    return true;
                }
            return false;
        }
        [[nodiscard]] bool HandlesCommand(core::StringView id) const
        {
            for (const CommandHandlerEntry& entry : m_commandHandlers)
                if (!entry.Removed && entry.Id.AsView() == id)
                    return true;
            return false;
        }
        /// Binds this control to command `id` (empty: none): it is enabled while the command is
        /// available and shows its checked state (OnBoundCommandState), and runs it when used
        /// (RunBoundCommand, from the widget's click). Reflected as `command`, so markup and sheets
        /// set it too.
        void SetCommand(core::StringView id);
        [[nodiscard]] core::StringView GetCommand() const noexcept { return m_command.Peek().AsView(); }
        [[nodiscard]] bool HasCommand() const noexcept { return m_command.Peek().Size() != 0; }
        /// Runs the bound command along the focus path; false with none, or none ran.
        bool RunBoundCommand();
        /// The bound command's state reached the control: enabled by availability; a checkable
        /// control shows its checked state too, and one with a tooltip the reason.
        virtual void OnBoundCommandState(const BoundCommandState& state) { SetEnabled(state.Available); }
        /// What the bound command shows reached the control (E5): its label, its icon (an image
        /// path) and its keys as text ("Ctrl+S"), each followed as it changes. A button or a menu
        /// item with no text of its own takes the label; a menu item, the keys and the icon.
        virtual void OnBoundCommandText(core::StringView label, core::StringView icon, core::StringView shortcut)
        {
            (void)label;
            (void)icon;
            (void)shortcut;
        }

        /// Runs this node's handlers for `event` in its phase; whether any ran.
        bool RunCommandHandlers(CommandEvent& event)
        {
            bool ran = false;
            DispatchScope scope(*this);
            for (usize i = 0; i < m_commandHandlers.Size(); ++i)
            {
                CommandHandlerEntry& entry = m_commandHandlers[i];
                if (entry.Removed || entry.Phase != event.Phase || entry.Id.AsView() != event.Id)
                    continue;
                entry.Handler(event);
                ran = true;
            }
            return ran;
        }

        // === Event listeners ===
        /// Listens for `type`. An input event reaches a `capture` listener on its way down from
        /// the root (before the target's own handling), any other on its way back up.
        u32 AddEventListener(EventType type, EventCallback callback, bool capture = false)
        {
            const u32 id = ++m_nextListenerId;
            if (m_dispatching != 0)
                m_pendingListeners.PushBack(Listener{id, type, core::Move(callback), capture}); // after the running ones
            else
                m_listeners.PushBack(Listener{id, type, core::Move(callback), capture});
            return id;
        }
        [[nodiscard]] bool HasListener(EventType type) const
        {
            for (const Listener& l : m_listeners)
                if (l.Type == type && !l.Removed)
                    return true;
            for (const Listener& l : m_pendingListeners)
                if (l.Type == type)
                    return true;
            return false;
        }
        /// Removes a listener; one removed while listeners run (its own, from inside it) is marked
        /// and goes once they return, never destroyed while it runs. False when the id is none of its.
        bool RemoveEventListener(u32 id)
        {
            for (usize i = 0; i < m_listeners.Size(); ++i)
                if (m_listeners[i].Id == id && !m_listeners[i].Removed)
                {
                    if (m_dispatching != 0)
                        m_listeners[i].Removed = true;
                    else
                        m_listeners.RemoveAt(i);
                    return true;
                }
            for (usize i = 0; i < m_pendingListeners.Size(); ++i)
                if (m_pendingListeners[i].Id == id)
                {
                    m_pendingListeners.RemoveAt(i);
                    return true;
                }
            return false;
        }
        /// Tells this node's listeners of the event a library names `name` (EventType::Named),
        /// with a detail as text.
        void SendNamedEvent(core::StringView name, core::StringView detail = {}) { SendEvent(NamedEvent(this, name, detail)); }
        /// Calls `callback` on each event named `name` this node is told (SendNamedEvent); a token
        /// for RemoveEventListener.
        u32 AddNamedListener(core::StringView name, EventCallback callback)
        {
            return AddEventListener(EventType::Named, [name = core::String(name), callback = core::Move(callback)](const Event& event)
                                    {
                                        if (static_cast<const NamedEvent&>(event).Name == name.AsView())
                                            callback(event);
                                    });
        }
        /// Tells this node's listeners of an event about it (not routed: geometry, focus, change).
        void SendEvent(const Event& event)
        {
            DispatchScope scope(*this);
            for (usize i = 0; i < m_listeners.Size(); ++i)
                if (!m_listeners[i].Removed && m_listeners[i].Type == event.Type)
                    m_listeners[i].Callback(event);
        }

        // === Change hooks (subclass overrides; the Handle* wrappers fire the event too) ===
        virtual void OnPositionChange() {}
        virtual void OnSizeChange() {}
        virtual void OnVisibilityChange() {}
        virtual void OnEnabledChange() {}
        virtual void OnParentChange() {}
        // Called on this node after a child is added or removed (containers re-layout here).
        virtual void OnChildrenChanged() {}
        /// Its scroll offset moved (a container realising what is in view follows it here).
        virtual void OnScrollChange() {}

    protected:
        /// The device pixels per logical unit the top of a tree lays out on (its children take
        /// theirs from it): 1, or a GUI root's display scale.
        [[nodiscard]] virtual f32 TopPixelScale() const { return 1.0f; }
        /// The language of a tree with no `lang` on it: none, or a GUI root's Localization's.
        [[nodiscard]] virtual core::String ContextLanguage() const { return {}; }
        /// The direction of a tree with no `direction` on it: left to right, or as a GUI root's
        /// Localization's language is written.
        [[nodiscard]] virtual bool ContextRightToLeft() const { return false; }
        /// Draws over this node and everything under it, after them, in its space and at full
        /// opacity: what a GUI root puts over its tree (the layout overlay).
        virtual void OnDrawAbove(DrawContext&) {}

        // Input handler hooks (override in subclasses; the Handle* wrappers call these).
        virtual void OnMouseEnter(const MouseEvent&) {}
        virtual void OnMouseLeave(const MouseEvent&) {}
        virtual void OnMouseMove(const MouseEvent&) {}
        virtual void OnMouseDown(const MouseEvent&) {}
        virtual void OnMouseUp(const MouseEvent&) {}
        virtual void OnMouseClick(const MouseEvent&) {}
        virtual void OnMouseWheel(const WheelEvent&) {}
        virtual void OnKeyDown(const KeyEvent&) {}
        /// Return or Space (a gamepad's South) on the focused widget, when it used neither: what a
        /// click does, for the widgets a click acts on. True when it did something.
        virtual bool OnActivate() { return false; }

        // A click at the centre, as activation delivers it (listeners see a click, as with a mouse).
        bool ActivateAsClick()
        {
            MouseEvent click(EventType::MouseClick, this, ConvertToWorldSpace(core::Float2{m_size.x * 0.5f, m_size.y * 0.5f}));
            (void)RouteEvent(click);
            return true;
        }
        virtual void OnKeyUp(const KeyEvent&) {}
        virtual void OnTextInput(const TextInputEvent&) {}
        virtual void OnComposition(const CompositionEvent&) {}
        /// A context menu asked for at the event's position (a right release, a long press,
        /// Shift+F10): open one and mark it Handled; unhandled, it bubbles up.
        virtual void OnContextMenu(const MouseEvent&) {}
        virtual void OnFocusGained() {}
        virtual void OnFocusLost() {}
        /// Hovered or pressed changed: restyles the node (`:hover`, `:active`; its subtree when a
        /// sheet reads them through it) and redraws it.
        virtual void OnPointerStateChange()
        {
            MarkStyleStateDirty(StateHover | StateActive);
            Invalidate();
        }
        /// The pointer this node captured was taken away or released.
        virtual void OnPointerCaptureLost() {}
        /// The press on this node (or inside it) was cancelled: no release or click follows.
        virtual void OnPointerCancel(const MouseEvent&) {}
        /// A source's answer to a drag offered by a press on it or inside it: fill the request's
        /// payload (and a preview) and return true to start it.
        virtual bool OnDragRequested(DragRequest&) { return false; }
        /// A target's answer: what a drop here would do (DropQuery::Accept, Refuse).
        virtual void OnDragQuery(DropQuery&) {}
        virtual void OnDragEnter(const DragEvent&) {}
        virtual void OnDragOver(const DragEvent&) {}
        virtual void OnDragLeave(const DragEvent&) {}
        virtual void OnDrop(const DragEvent&) {}
        /// A source hears how its drag ended (a move removes what was moved).
        virtual void OnDragEnd(const DragResult&) {}
        /// A drag rested on it a moment (at `local`): a closed tree node opens, an expander opens,
        /// a tab is selected. True when it did something (and the drag is asked again).
        virtual bool OnDragHoverOpen(core::Float2 local)
        {
            (void)local;
            return false;
        }

        void HandlePositionChange()
        {
            OnPositionChange();
            Invalidate();
            SendEvent(Event(EventType::PositionChanged, this));
        }
        void HandleSizeChange()
        {
            if (!m_styleTransforms.IsEmpty() || m_mirrored)
                UpdateStyleTransform();
            OnSizeChange();
            Invalidate();
            SendEvent(Event(EventType::SizeChanged, this));
        }
        void HandleVisibilityChange()
        {
            OnVisibilityChange();
            Invalidate();
            if (!m_visible)
                (void)MarkAncestorsForRedraw(); // hidden, it marks itself alone: what drew it must draw again
            SendEvent(Event(EventType::VisibilityChanged, this)); // hidden keeps its place: no layout
        }
        void HandleEnabledChange()
        {
            OnEnabledChange();
            MarkStyleStateDirty(StateDisabled | StateEnabled);
            Invalidate();
            SendEvent(Event(EventType::EnabledChanged, this));
        }
        void HandleParentChange()
        {
            OnParentChange();
            if (FollowsParentDirection())
                NotifyDirectionChange(); // it may run another way under its new parent
            Invalidate();
            SendEvent(Event(EventType::ParentChanged, this));
            NotifySceneRootChanged(); // the subtree may have joined or left a GUI
        }
        // Tells the bindings that read which GUI this subtree is in (ObserveSceneRoot); a node with
        // none costs a visit.
        void NotifySceneRootChanged()
        {
            m_sceneRootChanged.Notify();
            for (const RefPtr<Node>& child : m_children)
                child->NotifySceneRootChanged();
        }

        struct Listener
        {
            u32 Id;
            EventType Type;
            EventCallback Callback;
            bool Capture = false;
            bool Removed = false; // while listeners run: goes once they return
        };
        // The listeners of one kind (capture or bubble) for an input event. By index: a listener
        // may add another.
        void RunListeners(const Event& event, bool capture)
        {
            DispatchScope scope(*this);
            for (usize i = 0; i < m_listeners.Size(); ++i)
                if (!m_listeners[i].Removed && m_listeners[i].Type == event.Type && m_listeners[i].Capture == capture)
                    m_listeners[i].Callback(event);
        }
        // While its listeners or handlers run, the lists hold still: one removed is marked, one added
        // waits; both settle when the outermost run returns (a script's `off` from inside its own
        // handler would otherwise free the function running).
        struct DispatchScope
        {
            Node& Owner;
            explicit DispatchScope(Node& owner) noexcept : Owner(owner) { ++Owner.m_dispatching; }
            ~DispatchScope()
            {
                if (--Owner.m_dispatching == 0)
                    Owner.SettleHandlers();
            }
        };
        void SettleHandlers()
        {
            for (usize i = 0; i < m_listeners.Size();)
                if (m_listeners[i].Removed)
                    m_listeners.RemoveAt(i);
                else
                    ++i;
            for (Listener& l : m_pendingListeners)
                m_listeners.PushBack(core::Move(l));
            m_pendingListeners.Clear();
            for (usize i = 0; i < m_commandHandlers.Size();)
                if (m_commandHandlers[i].Removed)
                    m_commandHandlers.RemoveAt(i);
                else
                    ++i;
            for (CommandHandlerEntry& e : m_pendingCommandHandlers)
                m_commandHandlers.PushBack(core::Move(e));
            m_pendingCommandHandlers.Clear();
        }
        // The widget's own handler for an input event.
        void InvokeInputHandler(const Event& event)
        {
            switch (event.Type)
            {
            case EventType::MouseDown: OnMouseDown(static_cast<const MouseEvent&>(event)); break;
            case EventType::MouseUp: OnMouseUp(static_cast<const MouseEvent&>(event)); break;
            case EventType::MouseMove: OnMouseMove(static_cast<const MouseEvent&>(event)); break;
            case EventType::MouseClick: OnMouseClick(static_cast<const MouseEvent&>(event)); break;
            case EventType::MouseEnter: OnMouseEnter(static_cast<const MouseEvent&>(event)); break;
            case EventType::MouseLeave: OnMouseLeave(static_cast<const MouseEvent&>(event)); break;
            case EventType::MouseWheel: OnMouseWheel(static_cast<const WheelEvent&>(event)); break;
            case EventType::KeyDown: OnKeyDown(static_cast<const KeyEvent&>(event)); break;
            case EventType::KeyUp: OnKeyUp(static_cast<const KeyEvent&>(event)); break;
            case EventType::TextInput: OnTextInput(static_cast<const TextInputEvent&>(event)); break;
            case EventType::Composition: OnComposition(static_cast<const CompositionEvent&>(event)); break;
            case EventType::ContextMenu: OnContextMenu(static_cast<const MouseEvent&>(event)); break;
            case EventType::PointerCaptureLost: OnPointerCaptureLost(); break;
            case EventType::PointerCancel: OnPointerCancel(static_cast<const MouseEvent&>(event)); break;
            default: break;
            }
            if (!event.Handled && IsScrollContainer())
                ScrollDefaultAction(event);
        }
        // A scroll container's own handling, after its widget's: the wheel (taken when it moved),
        // the keys while it is focused, and its bars (a press on one drags its thumb or pages).
        void ScrollDefaultAction(const Event& event);
        /// Moves the offset (clamped as SetScrollOffset says) and reports the scroll; a smooth
        /// scroll's steps come here without ending it.
        void ApplyScrollOffset(core::Float2 offset)
        {
            const core::Float2 clamped = ClampScroll(offset);
            if (clamped == m_scrollOffset)
                return;
            m_scrollOffset = clamped;
            Invalidate();
            if (m_stickToEnd)
                m_latchedToEnd = IsAtScrollEnd(); // scrolled away it lets go; back at the end it holds
            if (m_layoutStyle.BarVisibility == ScrollbarVisibility::Overlay)
                ShowOverlayScrollbars();
            OnScrollChange();
            SendEvent(Event(EventType::Scroll, this));
        }
        /// `offset` within where it may go (with a layout pending, as asked: the layout clamps it).
        [[nodiscard]] core::Float2 ClampScroll(core::Float2 offset) const
        {
            if (m_layoutDirty || m_childLayoutDirty)
                return offset;
            const core::Float2 low = GetScrollMin(), high = GetScrollMax();
            return core::Float2{core::Clamp(offset.x, low.x, high.x), core::Clamp(offset.y, low.y, high.y)};
        }
        /// Eases toward m_scrollTarget on the GUI's clock (LayoutImpl.cpp, which sees :actions).
        void StartSmoothScroll();
        /// An overlay scroller's bars are wanted (it scrolled, or the pointer is over it): shown,
        /// then fading once let be.
        void ShowOverlayScrollbars();
        /// Which bar part is under `p` (local): 0 none, 1 a track, 2 a thumb; the part states follow.
        void SetScrollHover(u8 part);

        // Tells this GUI's dispatcher a child's subtree is leaving (GUIClusterImpl.cpp, which
        // sees :event_dispatcher).
        void NotifyRemovingChild(Node& child);

        Cursor m_cursor = Cursor::Auto;
        u8 m_touchActions = kTouchAuto; // touch-action
        bool m_hovered = false; // on the dispatcher's hover path
        bool m_pressed = false; // on its press path
        Node* m_parent = nullptr;       // non-owning back-pointer
        static constexpr u32 kNoGeneration = ~0u;
        u32 m_childrenGeneration = 0;                     // bumped when the children change
        mutable usize m_indexInParent = 0;                // its index, while
        mutable u32 m_indexGeneration = kNoGeneration;    // this is its parent's generation
        Array<RefPtr<Node>> m_children; // owning
        // Where each child's drawing reaches, in this node's children's space, ordered along the
        // axis they spread on, with the farthest reach so far at each place (E15).
        struct ChildIndex
        {
            Array<Rect> Rects;  // by child
            Array<u32> Order;   // children by where they start along the axis
            Array<f32> Reach;   // the farthest end along the axis of Order[0..i]
            Rect Bounds;        // around every child's reach
            bool Vertical = true;
            bool Built = false;
        };
        // Mutable: kept by the const reads of what it draws (GetSubtreeInk), as the ink is.
        mutable UniquePtr<ChildIndex> m_childIndex; // made for a node with many children
        mutable bool m_childIndexAll = true;        // every child's reach to be read again
        mutable Array<Node*> m_changedChildren;     // children something under changed in, since the index was checked
        mutable u32 m_childIndexBuilds = 0;
        mutable bool m_stackedKnown = false; // whether m_stacked holds HasStackedChildren's answer
        Rect m_drawnArea;              // what its subtree covered when last drawn, in device pixels (E15)
        bool m_drawnAreaValid = false; // drawn, and on screen
        bool m_damageNoted = false;    // its old area went to its root since it was drawn
        mutable bool m_stacked = false;

        // Something changed under `child`: its reach is read again at the next check (all of them,
        // once that is most of them). Cleared with the children, so it never holds one gone.
        void NoteChildChanged(Node& child)
        {
            if (!m_childIndex || m_childIndexAll)
                return;
            if (m_changedChildren.Size() > m_children.Size() / 4 + 8)
            {
                m_childIndexAll = true;
                m_changedChildren.Clear();
                return;
            }
            m_changedChildren.PushBack(&child);
        }

        // Checks the index against the children (those something changed under, or all when the
        // children changed), building it again when a reach moved.
        void RefreshChildIndex() const
        {
            if (!m_childIndex)
                m_childIndex = MakeUnique<ChildIndex>(MemoryAllocator());
            ChildIndex& index = *m_childIndex;
            const usize n = m_children.Size();
            const auto reachOf = [](const Node& c) { return c.GetTransform().TransformRect(c.GetSubtreeInk()); };
            bool moved = false;
            if (!index.Built || m_childIndexAll || index.Rects.Size() != n)
            {
                moved = !index.Built || index.Rects.Size() != n;
                index.Rects.Resize(n);
                for (usize i = 0; i < n; ++i)
                {
                    const Rect r = reachOf(*m_children[i]);
                    moved = moved || !(index.Rects[i] == r);
                    index.Rects[i] = r;
                }
            }
            else
            {
                for (Node* child : m_changedChildren)
                {
                    const usize i = GetChildIndex(child);
                    if (i == kInvalidIndex)
                        continue;
                    const Rect r = reachOf(*child);
                    moved = moved || !(index.Rects[i] == r);
                    index.Rects[i] = r;
                }
            }
            m_childIndexAll = false;
            m_changedChildren.Clear();
            if (!moved)
                return;
            // The axis they spread along more: a column's, or a row's; and the bounds of them all.
            f32 minX = 0.0f, maxX = 0.0f, minY = 0.0f, maxY = 0.0f;
            for (usize i = 0; i < n; ++i)
            {
                const Rect& r = index.Rects[i];
                minX = i == 0 ? r.x : core::Min(minX, r.x);
                maxX = i == 0 ? r.x : core::Max(maxX, r.x);
                minY = i == 0 ? r.y : core::Min(minY, r.y);
                maxY = i == 0 ? r.y : core::Max(maxY, r.y);
                index.Bounds = i == 0 ? r : Rect::Union(index.Bounds, r);
            }
            index.Vertical = maxY - minY >= maxX - minX;
            const bool vertical = index.Vertical;
            const auto start = [&](u32 i) { return vertical ? index.Rects[i].y : index.Rects[i].x; };
            // Ordered by start: a merge sort, as children placed anywhere may come in any order.
            index.Order.Resize(n);
            for (usize i = 0; i < n; ++i)
                index.Order[i] = static_cast<u32>(i);
            Array<u32> scratch;
            scratch.Resize(n);
            for (usize width = 1; width < n; width *= 2)
            {
                for (usize lo = 0; lo < n; lo += 2 * width)
                {
                    const usize mid = core::Min(lo + width, n), hi = core::Min(lo + 2 * width, n);
                    usize a = lo, b = mid, k = lo;
                    while (a < mid && b < hi)
                        scratch[k++] = start(index.Order[b]) < start(index.Order[a]) ? index.Order[b++] : index.Order[a++];
                    while (a < mid)
                        scratch[k++] = index.Order[a++];
                    while (b < hi)
                        scratch[k++] = index.Order[b++];
                }
                core::Swap(index.Order, scratch);
            }
            index.Reach.Resize(n);
            f32 reach = 0.0f;
            for (usize j = 0; j < n; ++j)
            {
                const Rect& r = index.Rects[index.Order[j]];
                const f32 end = vertical ? r.Bottom() : r.Right();
                reach = j == 0 ? end : core::Max(reach, end);
                index.Reach[j] = reach;
            }
            index.Built = true;
            ++m_childIndexBuilds;
        }
        Array<Listener> m_listeners;
        Array<UniquePtr<Effect>> m_bindings; // this node's bindings (Bind, BindProperty)
        struct PropertyBinding
        {
            const void* Property; // its PropertyInfo
            bool Back;            // the write-back from it (BindPropertyBack)
            Effect* Bound;        // one of m_bindings
        };
        Array<PropertyBinding> m_propertyBindings; // which binding is each property's
        Observable m_sceneRootChanged;       // told when this subtree joins or leaves a GUI
        struct CommandHandlerEntry
        {
            core::String Id;
            CommandPhase Phase;
            CommandHandler Handler;
            u32 Token;
            bool Removed = false; // while handlers run: goes once they return
        };
        Array<CommandHandlerEntry> m_commandHandlers;
        Array<CommandHandlerEntry> m_pendingCommandHandlers; // added while handlers ran
        Array<Listener> m_pendingListeners;                  // added while listeners ran
        u16 m_dispatching = 0;                               // runs of its listeners or handlers in progress
        Property<core::String> m_command; // the bound command's id (SetCommand)
        bool m_commandBound = false;      // its binding made (once)
        // Tells this GUI's commands that what decides availability changed (GUIClusterImpl.cpp).
        void NotifyCommandsChanged();
        core::Function<bool(DragRequest&)> m_dragSource;
        core::Function<void(DropQuery&)> m_dropQuery;
        core::Function<void(const DragResult&)> m_dragEnd;
        core::String m_dropTypes;
        bool m_dropTargetState = false;
        bool m_dragSourceState = false;
        bool m_leaving = false;     // Leave was called; it goes when its exit ends (K0)
        bool m_inert = false;       // takes no input (K4)
        bool m_leaveQueued = false; // its removal waits in the mutation queue
        u8 m_enterPhase = 0;        // K5: 1 in :entering, 2 moving to its own style, 0 arrived
        bool m_enterQueued = false; // its entrance's next step waits in the mutation queue
        bool m_styledTree = false;  // the top of a tree a style pass ran over
        core::Float2 m_size{0.0f, 0.0f};
        LayoutStyle m_layoutStyle;              // what it asks of layout (E2)
        Display m_displayBeforeNone = Display::Flex; // what SetDisplayed(true) gives back
        Thickness m_padding{};
        Thickness m_paddingPercent{}; // of the containing box's width (CSS's padding percentages)
        f32 m_percentWidth = -1.0f;   // the containing box's width it was last measured in (-1: unknown)
        core::Float2 m_scrollOffset{0.0f, 0.0f}; // a scroll container's (its children move by minus it)
        f32 m_pixelScale = 1.0f; // device pixels per unit at its last arrange (its edges round to them)
        core::Float2 m_contentExtent{0.0f, 0.0f}; // the children's extent as last laid out
        // The last few measures, by the constraints each was for. One slot is not enough: a flex
        // item is measured for its base size and again at its resolved size, and with one slot
        // each level of nesting would measure what it holds twice (2^depth).
        struct MeasureEntry
        {
            LayoutConstraints Key{};
            core::Float2 Size{0.0f, 0.0f};
        };
        static constexpr u8 kMeasureSlots = 4;
        MeasureEntry m_measures[kMeasureSlots]{};
        u8 m_measureCount = 0; // slots in use (0: nothing cached)
        u8 m_measureNext = 0;  // the slot the next measure replaces once all are in use
        bool m_placing = false;                  // inside Arrange: the size and place set are the layout's
        f32 m_scrollStep = 40.0f;                // the wheel's notch and an arrow key's step
        bool m_scrollsByKeys = true;             // focused, the arrow and page keys scroll it
        core::Float2 m_scrollTarget{0.0f, 0.0f}; // where a smooth scroll is going
        bool m_smoothScrolling = false;          // a smooth scroll is easing toward m_scrollTarget
        bool m_smoothTicking = false;            // its tick runs on the GUI's clock
        u8 m_scrollHover = 0;                    // the pointer over a bar: 0 none, 1 its track, 2 its thumb
        f32 m_scrollbarAlpha = 0.0f;             // an overlay's bars: shown while scrolling or hovered, then fading
        f32 m_scrollbarIdle = 0.0f;              // seconds since an overlay's bars were last wanted
        bool m_scrollbarFading = false;          // the overlay's tick runs
        bool m_stickToEnd = false;               // held at the end as the content grows
        bool m_latchedToEnd = false;             // at the end, so held there
        bool m_flinging = false;                 // a fling is gliding
        bool m_flingTicking = false;             // its tick runs
        core::Float2 m_flingVelocity{0.0f, 0.0f}; // as it was let go
        core::Float2 m_flingStart{0.0f, 0.0f};   // the offset it was let go at
        f32 m_flingTime = 0.0f;                  // seconds since
        u32 m_scrollDragAxis = 2;                // a bar being dragged (0, 1), 2 for none
        f32 m_scrollDragGrab = 0.0f;             // where on the thumb it was taken
        f32 m_alpha = 1.0f;
        bool m_visible = true;
        bool m_enabled = true;
        bool m_needsRedraw = true;
        mutable bool m_subtreeInkValid = false; // m_subtreeInk holds what it and its subtree draw
        u32 m_drawnFrame = 0;                   // the host's frame it was last drawn in
        u32 m_forcedStyleStates = 0;            // StyleState bits the style pass reads as set
        bool m_invalidatedSelf = true;          // invalidated itself (not through a descendant) since drawn
        u8 m_quietInvalidations = 0;            // inside BeginQuietInvalidation's
        AutoTranslate m_autoTranslate = AutoTranslate::Inherit;
        LayoutDirection m_direction = LayoutDirection::Inherit;
        bool m_placesChildren = false; // its children at points of its own, not mirrored
        bool m_mirrorOnRtl = false;
        bool m_accessDirty = true;       // its accessibility node waits to be sent (E9d)
        bool m_accessChildDirty = false; // some descendant's does
        u64 m_accessSent = 0;            // a hash of its node as last sent (0: never)
        bool m_placedByCode = false;     // SetPosition put it where it is (its insets are in the parent's box)
        bool m_mirrored = false; // mirror-on-rtl, and it runs right to left: flipped about its centre
        mutable Observable m_translationChanged; // its auto-translation changed (its translated bindings follow)
        core::String m_lang;                     // its language, empty: inherited
        struct TranslatedProperty
        {
            core::String Property;
            core::String Key;
        };
        Array<TranslatedProperty> m_translations; // what BindTranslation bound (the inspector reads it)
        mutable Rect m_subtreeInk{};
        bool m_styleDirty = true;          // restyle this node
        bool m_styleSubtreeDirty = true;   // ... and every descendant
        bool m_childStyleDirty = false;    // some descendant waits for a restyle
        bool m_styleMotionDirty = false;   // a tween moved: apply again, the cascade as it was
        bool m_childrenArrangementChanged = false; // its children were added, removed or moved
        bool m_layoutDirty = false;        // this container's layout must run
        bool m_childLayoutDirty = false;   // some descendant's must
        bool m_layingOut = false;          // inside OnLayout: the sizes it sets are its own
        bool m_clipChildren = false;
        bool m_topLayer = false;  // open as a popup (SetInTopLayer)
        bool m_routeStop = false; // an event's route ends here (a modal popup)
        NavScope m_navScope = NavScope::None;
        bool m_focusGroup = false; // one Tab stop; its arrows move inside it
        core::String m_defaultFocusId;
        ElementRef m_rememberedFocus{}; // weak: resolved through the GUI's element table
        core::String m_navOverrides[NavOverrideCount]; // nav-up and the rest: an id, none, or auto
        core::String m_keyContext;                     // for bindings (key-context)
        bool m_focused = false;
        bool m_styleWriting = false; // a StyleWriteScope lives: setters do not pin
        StyleSlotSet m_stylePins;    // the StyleSlots code set (they are its, over the sheet's)
        UnstyledValues m_unstyled;
        u32 m_focusWithin = 0;
        u32 m_changedStyleStates = 0; // the StyleStates that changed since the last style pass // focused descendants (one at most; a count survives odd orders)
        bool m_focusVisible = false; // focused by the keyboard or a gamepad
        bool m_tabFocusable = false;
        bool m_keepsFocus = false; // a press in it leaves the focus where it is
        i32 m_tabIndex = 0; // where Tab reaches it: positive first, 0 in tree order, below 0 never
        bool m_tabCaptures = false; // Tab is its key, not focus's
        bool m_hitTestVisible = true;
        u32 m_nextListenerId = 0;
        // The style transform's matrix and origin in local units, from the functions and the size.
        // Mirrored (E9b), flipped about its centre first, wherever the origin is.
        void UpdateStyleTransform()
        {
            const core::Float2 origin{ResolveAgainst(m_transformOriginX, m_size.x), ResolveAgainst(m_transformOriginY, m_size.y)};
            Transform2D transform = ComposeTransforms(m_styleTransforms, m_size);
            if (m_mirrored)
            {
                Transform2D flip = Transform2D::Identity();
                flip.Scale(-1.0f, 1.0f, m_size.x * 0.5f - origin.x, 0.0f);
                transform = transform * flip;
            }
            SetExtraTransform(transform, origin);
            Invalidate();
        }

        NodeBox m_box;
        bool m_boxFromStyle = false;
        Array<TransformFunction> m_styleTransforms;
        LengthValue m_transformOriginX{50.0f, LengthUnit::Percent};
        LengthValue m_transformOriginY{50.0f, LengthUnit::Percent};
        bool m_transformFromStyle = false;
        RefPtr<ElementTable> m_elementTable; // the table a handle took a slot in (null: none yet)
        u32 m_elementSlot = 0;
    };
}
