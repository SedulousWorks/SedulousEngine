// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_manager partition
//
// StyleManager: the glue that makes a StyleSheet live on a widget tree. It resolves each
// UIWidget against the sheet (+ MediaContext), applies the result, and - by caching the
// last-applied ResolvedStyle per widget - animates transitioned changes on the next apply.
// Re-applying after a state change (e.g. :hover) therefore drives CSS transitions live.
//
// The per-widget cache lives here (not on UIWidget) to avoid a :ui_widget <-> :style_sheet
// partition cycle. ApplyTree re-resolves only what changed: the widgets a state, class, tag, id
// or parent change marked (Node::MarkStyleDirty), with their subtrees or later siblings when a
// sheet reads that state through them, the children of a widget whose children were rearranged
// when a sheet reads siblings, the children of one whose custom properties changed, and
// everything after a new sheet, media or fonts. Cache entries are keyed by the widget's address
// and checked against its place in its GUI's element table, so a destroyed widget's entries are
// never taken for a new one's at the same address, and a sweep drops them as the caches grow;
// Forget() or Clear() drops them at once.

module;
#include "Core/Prelude.h"
#include "Profiler/Profiler.h" // PROFILE_SCOPE

export module foundation.gui:style_manager;

import foundation.core;  // HashMap, Cast, Move, Array, StringView, Float2, Duration, MakeRef
import foundation.fonts; // IFontService
import foundation.profiler;
import :node;
import :frame_stats;
import :ui_node;
import :ui_widget;
import :style_rule; // StyleProperty
import :style_sheet;
import :media_query;
import :style_applier;
import :style_animation;
import :style_interpolation; // StyleInterpolationContext (E14)
import :resource_provider;
import :css_values; // ParseLength
import :css_parser; // an @import's sheet

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    /// Where a node's value of a property came from (E8d, for the inspector).
    enum class StyleOrigin : u8
    {
        Sheet,     ///< a rule of a sheet
        Inline,    ///< the node's inline style (markup's attributes, a script's style)
        Inherited, ///< an ancestor's (an inherited property no rule here set)
        Code,      ///< a setter called from code: the sheet leaves it be
        Own,       ///< nothing set it: the node's own value
    };
    /// One declaration of a property: where it was written and what it said.
    struct StyleDeclarationSource
    {
        core::String Sheet;    ///< its sheet's name ("inline" for the inline style)
        u32 Line = 0;          ///< its rule's line in that sheet (0: unknown)
        core::String Selector; ///< its rule's selector as written
        core::String Value;    ///< as written
        bool Important = false;
        bool Inline = false;
        const StyleRule* Rule = nullptr; ///< its rule (null for the inline style), for EditDeclaration
    };
    /// A property of a node, its value and where the value came from.
    struct StyleExplanation
    {
        core::String Property;
        StyleOrigin Origin = StyleOrigin::Own;
        core::String Value; ///< the cascade's (the ancestor's when inherited; empty for code's or its own)
        /// This node's declarations of it, the winner first (all overridden when code set it).
        Array<StyleDeclarationSource> Declarations;
        const UIWidget* InheritedFrom = nullptr; ///< the ancestor whose value it is
        bool Animated = false;                   ///< a transition or an animation moves it now
    };

    class StyleManager
    {
    public:
        StyleManager() = default;
        explicit StyleManager(StyleSheet sheet) : m_sheet(core::Move(sheet)) {}

        /// The GUI's sheet (the author origin): over the user agent's, under a subtree's and inline.
        void SetStyleSheet(StyleSheet sheet)
        {
            m_sheet = core::Move(sheet);
            m_cache = {};
            m_allDirty = true; // hot-reload: every widget restyles
            m_relationsKnown = false;
            m_fontFacesLoaded = false;
            m_importsExpanded = false;
        }
        [[nodiscard]] const StyleSheet& GetStyleSheet() const noexcept { return m_sheet; }

        /// The user agent's sheet, the lowest origin: the built-in theme, what every rule of the
        /// GUI's own sheets overrides.
        void SetUserAgentSheet(StyleSheet sheet)
        {
            m_userAgent = core::Move(sheet);
            m_cache = {};
            m_allDirty = true;
            m_relationsKnown = false;
            m_fontFacesLoaded = false;
            m_importsExpanded = false; // its sprites, as the author sheet's
        }
        [[nodiscard]] const StyleSheet& GetUserAgentSheet() const noexcept { return m_userAgent; }

        /// A sheet for `root` and what is under it alone (a page's own .css): over the GUI's
        /// sheet, under inline; a subtree inside another's outranks it. The root must be in a GUI
        /// (it is held weakly, through its GUI's element table); false when it is in none.
        bool SetSubtreeSheet(Node& root, StyleSheet sheet)
        {
            const Node::ElementRef ref = root.TakeElementRef();
            if (ref.table == nullptr)
                return false;
            RemoveSubtreeSheet(root);
            m_subtrees.PushBack(SubtreeSheet{ref, core::Move(sheet)});
            root.MarkStyleDirty(true);
            m_relationsKnown = false;
            return true;
        }
        void RemoveSubtreeSheet(Node& root)
        {
            for (usize i = 0; i < m_subtrees.Size(); ++i)
                if (RootOf(m_subtrees[i]) == &root)
                {
                    m_subtrees.RemoveAt(i);
                    root.MarkStyleDirty(true);
                    m_relationsKnown = false;
                    return;
                }
        }

        void SetMediaContext(const MediaContext& context)
        {
            if (context == m_context)
                return; // unchanged: nothing to restyle (a host may set it every frame)
            const MediaContext before = m_context;
            m_context = context;
            // The viewport's size alone (a window resized: each frame of the drag) restyles
            // everything only when a sheet reads it, through vw or vh or a size query that now
            // answers differently; else only the widgets whose own inline style reads it. The
            // input kind alone (K2b: a mouse bumped while a pad plays) restyles only when a query
            // answers differently.
            MediaContext moved = before;
            moved.Width = context.Width;
            moved.Height = context.Height;
            moved.Input = context.Input;
            if (moved == context && m_importsExpanded)
            {
                if (!m_relationsKnown)
                    LearnRelations();
                const bool resized = before.Width != context.Width || before.Height != context.Height;
                bool flips = resized && m_sheetsReadViewport;
                for (usize i = 0; !flips && i < m_sizeQueries.Size(); ++i)
                    flips = m_sizeQueries[i]->Evaluate(before) != m_sizeQueries[i]->Evaluate(context);
                if (!flips)
                {
                    m_viewportResized = m_viewportResized || resized;
                    return;
                }
            }
            m_allDirty = true;
        }
        [[nodiscard]] const MediaContext& GetMediaContext() const noexcept { return m_context; }

        // Root font size for CSS `rem` units (default 16px).
        void SetRootFontSize(f32 pixels) noexcept
        {
            m_allDirty = m_allDirty || pixels != m_rootFontSize;
            m_rootFontSize = pixels;
        }
        [[nodiscard]] f32 GetRootFontSize() const noexcept { return m_rootFontSize; }

        // Loads background-image assets referenced by the sheet. Null = background-image skipped.
        void SetResourceProvider(IResourceProvider* resources) noexcept
        {
            m_allDirty = m_allDirty || resources != m_resources;
            m_importsExpanded = m_importsExpanded && resources == m_resources;
            m_resources = resources;
        }
        [[nodiscard]] IResourceProvider* GetResourceProvider() const noexcept
        {
            return m_resources;
        }

        // Resolves font-family/-size in the sheet (the app's font service - VFS-backed or not;
        // the GUI is agnostic). Null = font-family skipped.
        void SetFontService(fonts::IFontService* fontService) noexcept
        {
            m_allDirty = m_allDirty || fontService != m_fontService;
            m_fontFacesLoaded = m_fontFacesLoaded && fontService == m_fontService; // a new service lacks the faces
            m_fontService = fontService;
        }
        [[nodiscard]] fonts::IFontService* GetFontService() const noexcept { return m_fontService; }

        /// Loads a sheet's @font-face (E11): the host puts the file at `source` (a path as the
        /// sheet wrote it) into its font service under `face`, the name the face is chosen by
        /// ("Family", "Family Bold", "Family Light Italic"), and says whether it did. Each face is
        /// asked for once per sheet, before the restyle that may draw in it; one the service
        /// already has is not asked for. Null: @font-face is skipped.
        void SetFontFaceLoader(Function<bool(core::StringView face, core::StringView source)> loader)
        {
            m_fontFaceLoader = core::Move(loader);
            m_fontFacesLoaded = false;
            m_allDirty = true;
        }

        // Resolve + apply one widget. A property that changed and has a `transition` moves from
        // the value showing toward its new one, an `animation` runs its @keyframes, both through
        // the widget's StyleAnimation on its GUI's clock; otherwise the style applies at once.
        void ApplyTo(UIWidget& widget)
        {
            const bool filtering = m_filtering; // the walk's filter is not this widget's ancestors
            m_filtering = false;
            (void)ApplyOne(widget);
            m_filtering = filtering;
        }

        /// Restyles what changed in the subtree (only what changed: a widget whose class, id, tag
        /// or state changed, or that joined the tree, with its descendants; the children of one
        /// whose custom properties changed; everything after the sheet, the media, the fonts or
        /// the resources changed). A clean subtree is not visited.
        void ApplyTree(Node& root)
        {
            PROFILE_SCOPE("GUI.Style");
            const core::Stopwatch watch = core::Stopwatch::StartNew();
            m_lastRestyleCount = 0;
            if (!m_relationsKnown)
                LearnRelations();
            if (!m_importsExpanded)
                ExpandImports();
            if (!m_fontFacesLoaded)
                LoadFontFaces();
            const bool all = m_allDirty;
            m_allDirty = false;
            if (m_viewportResized && !all)
                MarkViewportReaders(root);
            m_viewportResized = false;
            // The names above what is styled, from the walk's start up (E8): pushed on the way down.
            m_ancestors.Clear();
            for (const Node* n = root.GetParent(); n != nullptr; n = n->GetParent())
                if (const UIWidget* w = core::Cast<UIWidget>(n))
                    m_ancestors.Push(*w);
            root.GetRootNode()->NoteStylePass(); // a node leaving this tree waits for its exit (K0)
            m_filtering = true;
            Visit(root, all, false);
            m_filtering = false;
            if (m_owners.Size() > m_sweepAt)
                SweepGone();
            if (FrameStats* stats = root.GetFrameStats()) // the GUI's frame stats (E8a)
            {
                stats->StyleMs += watch.Elapsed().AsMilliseconds();
                stats->Restyled += m_lastRestyleCount;
            }
        }

        /// How many widgets the last ApplyTree restyled (none in a frame where nothing changed).
        [[nodiscard]] u32 LastRestyleCount() const noexcept { return m_lastRestyleCount; }
        /// How many widgets it keeps a style for (a destroyed one's go at the next sweep).
        [[nodiscard]] usize CachedWidgetCount() const noexcept { return m_cache.Size(); }

    private:
        void Visit(Node& node, bool forceSubtree, bool forceSelf)
        {
            // A state a rule reads through this node (as an ancestor's, or an earlier sibling's)
            // restyles what it reaches; any other state change restyles the node alone.
            const u32 states = node.GetChangedStyleStates();
            if ((states & m_siblingStates) != 0)
                if (Node* parent = node.GetParent())
                    for (usize i = parent->GetChildIndex(&node) + 1; i < parent->ChildCount(); ++i)
                        parent->GetChildAt(i)->MarkStyleDirty(true);
            const bool self = forceSubtree || forceSelf || node.IsStyleDirty();
            const bool subtree = forceSubtree || node.IsStyleSubtreeDirty() || (states & m_ancestorStates) != 0;
            // Its children came, went or moved: when a sheet reads siblings, each may match
            // differently, and what each holds only when a rule reads them through an ancestor;
            // else only the new ones restyle (marked so). (Restyling every child's subtree made each
            // popup or tooltip joining the root restyle the whole page: a second in Debug.)
            const bool rearranged = m_readsSiblings && node.ChildrenArrangementChanged();
            bool descend = subtree || rearranged || node.HasStyleDirtyDescendant();
            const bool moved = node.IsStyleMotionDirty();
            node.ClearStyleDirty();
            bool customsChanged = false;
            if (self)
            {
                if (UIWidget* widget = core::Cast<UIWidget>(&node))
                {
                    customsChanged = ApplyOne(*widget);
                    ++m_lastRestyleCount;
                }
            }
            else if (moved)
            {
                if (UIWidget* widget = core::Cast<UIWidget>(&node))
                    ApplyMotion(*widget);
            }
            // Applying it may have marked what it holds (a direction it now runs in, E9b).
            descend = descend || node.HasStyleDirtyDescendant();
            if (!descend && !customsChanged)
                return;
            const UIWidget* above = core::Cast<UIWidget>(&node);
            if (above != nullptr)
                m_ancestors.Push(*above);
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (Node* child = node.GetChildAt(i))
                    Visit(*child, subtree || (rearranged && HoldsSiblingReads(*child)), customsChanged || rearranged);
            if (above != nullptr)
                m_ancestors.Pop();
        }

        // Whether a rearrangement of `child`'s siblings can change what matches inside it: a rule
        // reads siblings in a compound `child` could match, with a step below it.
        [[nodiscard]] bool HoldsSiblingReads(const Node& child) const
        {
            const UIWidget* widget = core::Cast<UIWidget>(&child);
            if (widget == nullptr)
                return !m_siblingReadsAbove.IsEmpty();
            for (const StyleSelectorRule& compound : m_siblingReadsAbove)
                if (compound.MatchesIdentity(*widget))
                    return true;
            return false;
        }

        [[nodiscard]] static bool SameCustomProperties(const ResolvedStyle& a, const ResolvedStyle& b)
        {
            const auto contains = [](const ResolvedStyle& in, const ResolvedProperty& p)
            { return in.Get(p.Name.AsView()) == p.Value.AsView() && in.Has(p.Name.AsView()); };
            for (const ResolvedProperty& p : a.Properties())
                if (ResolvedStyle::IsCustomProperty(p.Name.AsView()) && !contains(b, p))
                    return false;
            for (const ResolvedProperty& p : b.Properties())
                if (ResolvedStyle::IsCustomProperty(p.Name.AsView()) && !contains(a, p))
                    return false;
            return true;
        }

        // What applying `resolved` to `widget` needs: the length-resolution context (the viewport
        // from the media context, the root font size configurable, the element's font size from
        // its resolved font-size, for em), the resources and the fonts.
        [[nodiscard]] StyleApplyContext ApplyContextFor(const UIWidget& widget, const ResolvedStyle& resolved) const
        {
            StyleApplyContext context;
            context.Resources = m_resources;
            context.FontService = m_fontService;
            context.Lengths.RootFontSize = m_rootFontSize;
            context.Lengths.ViewportWidth = m_context.Width;
            context.Lengths.ViewportHeight = m_context.Height;
            // The element's font size, what its em lengths measure by: its own font-size resolved
            // against its parent's (em and percentages of the parent's, rem of the root's), else
            // the parent's as it inherits.
            const UINode* parentNode = core::Cast<UINode>(widget.GetParent());
            const f32 parentSize =
                parentNode != nullptr && parentNode->GetTextStyle().FontSize > 0.0f ? parentNode->GetTextStyle().FontSize : m_rootFontSize;
            LengthContext parentLengths = context.Lengths;
            parentLengths.ElementFontSize = parentSize;
            const core::StringView fontSize = resolved.Get(core::StringView(u8"font-size"), core::StringView(u8""));
            context.Lengths.ElementFontSize =
                fontSize.Size() != 0 ? ResolveLength(fontSize, parentLengths, parentSize).ValueOr(parentSize) : parentSize;
            return context;
        }

        // A tween moved (E14) and nothing else changed: the style it has, with the animated layer
        // over it, applied again (through its transitions and animations when they run).
        void ApplyMotion(UIWidget& widget)
        {
            if (!IsOwn(widget))
            {
                (void)ApplyOne(widget); // entries at its address were another's: from scratch
                return;
            }
            if (const RefPtr<StyleAnimation>* running = m_animations.Find(&widget); running != nullptr && *running && !(*running)->IsDone())
            {
                (*running)->ApplyNow();
                return;
            }
            const ResolvedStyle* cached = m_cache.Find(&widget);
            if (cached == nullptr)
            {
                (void)ApplyOne(widget);
                return;
            }
            ResolvedStyle effective = *cached;
            const StyleApplyContext context = ApplyContextFor(widget, effective);
            StyleInterpolationContext lengths;
            lengths.Lengths = context.Lengths;
            lengths.BoxSize = widget.GetSize();
            OverlayMotion(widget, effective, &lengths);
            ApplyStyle(widget, effective, context.Resources, context.FontService, context.Lengths);
        }

        // Restyles one widget; whether its custom properties changed (its children then restyle,
        // as they inherit them).
        bool ApplyOne(UIWidget& widget)
        {
            Claim(widget);
            // Custom properties inherit: the nearest styled ancestor's resolved style gives those
            // this widget does not set (ApplyTree styles parents first, so theirs are current).
            const ResolvedStyle* inherited = nullptr;
            for (Node* ancestor = widget.GetParent(); ancestor != nullptr && inherited == nullptr;
                 ancestor = ancestor->GetParent())
                inherited = m_cache.Find(ancestor);
            const Array<const StyleSheet*> subtrees = SubtreeSheetsOver(widget);
            ResolvedStyle resolved = ResolveFor(widget, subtrees, {}, inherited);
            resolved.SettleKeywords(inherited);
            const UINode::TextStyle textBefore = widget.GetTextStyle();

            const StyleApplyContext context = ApplyContextFor(widget, resolved);

            RefPtr<StyleAnimation>* running = m_animations.Find(&widget);
            if (running != nullptr && (*running)->IsDone())
            {
                m_animations.Remove(&widget);
                running = nullptr;
            }
            RefPtr<StyleAnimation> animation = running != nullptr ? *running : RefPtr<StyleAnimation>{};
            bool created = false;
            const auto ensure = [&]()
            {
                if (!animation && widget.GetActionManager() != nullptr)
                {
                    animation = core::MakeRef<StyleAnimation>(widget.MemoryAllocator(), widget);
                    animation->SetTargetStyle(resolved, context);
                    created = true;
                }
                return animation.Get() != nullptr;
            };

            // Transitions: each property that changed since the last apply and a `transition`
            // entry covers, from what shows now.
            if (const ResolvedStyle* previous = m_cache.Find(&widget))
            {
                const Array<TransitionSpec> transitions =
                    ComposeTransitions(resolved.Get(u8"transition-property"), resolved.Get(u8"transition-duration"),
                                       resolved.Get(u8"transition-timing-function"), resolved.Get(u8"transition-delay"));
                if (!transitions.IsEmpty())
                    StartTransitions(transitions, *previous, resolved, animation, ensure);
            }

            // Keyframe animations: start those newly named (once: one that has ended stays ended
            // while it is named), stop those no longer named.
            const Array<AnimationSpec> animations = ComposeAnimations(
                resolved.Get(u8"animation-name"), resolved.Get(u8"animation-duration"),
                resolved.Get(u8"animation-timing-function"), resolved.Get(u8"animation-delay"),
                resolved.Get(u8"animation-iteration-count"), resolved.Get(u8"animation-direction"),
                resolved.Get(u8"animation-fill-mode"), resolved.Get(u8"animation-play-state"));
            Array<core::String>* startedSlot = m_startedAnimations.Find(&widget);
            Array<core::String>& started =
                startedSlot != nullptr ? *startedSlot : m_startedAnimations.InsertOrAssign(&widget, Array<core::String>{});
            for (usize i = 0; i < started.Size();)
            {
                bool named = false;
                for (const AnimationSpec& spec : animations)
                    named = named || spec.Name.AsView() == started[i].AsView();
                if (named)
                {
                    ++i;
                    continue;
                }
                if (animation)
                    animation->StopKeyframes(started[i].AsView());
                started.RemoveAt(i);
            }
            for (const AnimationSpec& spec : animations)
            {
                bool already = false;
                for (const core::String& name : started)
                    already = already || name.AsView() == spec.Name.AsView();
                if (already && animation)
                    animation->SetPaused(spec.Name.AsView(), spec.Paused);
                const Keyframes* keyframes = FindKeyframes(subtrees, spec.Name.AsView());
                if (already || keyframes == nullptr)
                    continue;
                if (ensure())
                {
                    animation->SetTargetStyle(resolved, context);
                    animation->StartKeyframes(spec, *keyframes);
                    started.PushBack(spec.Name);
                }
            }

            if (animation && animation->TrackCount() > 0)
            {
                animation->SetTargetStyle(resolved, context);
                if (created)
                {
                    m_animations.InsertOrAssign(&widget, animation);
                    widget.RunAction(animation); // Start applies it now
                }
                else
                {
                    animation->ApplyNow();
                }
            }
            else
            {
                if (animation)
                {
                    // Nothing moves any more: the target, with what the stopped tracks moved
                    // returned to it (or to its initial value).
                    animation->SetTargetStyle(resolved, context);
                    animation->ApplyNow();
                    animation->Stop();
                    m_animations.Remove(&widget);
                }
                else if (widget.HasMotion())
                {
                    // Tweens over it (E14); the cache keeps the cascade alone.
                    ResolvedStyle effective = resolved;
                    StyleInterpolationContext lengths;
                    lengths.Lengths = context.Lengths;
                    lengths.BoxSize = widget.GetSize();
                    OverlayMotion(widget, effective, &lengths);
                    ApplyStyle(widget, effective, context.Resources, context.FontService, context.Lengths);
                }
                else
                {
                    ApplyStyle(widget, resolved, context.Resources, context.FontService, context.Lengths);
                }
            }
            // Leaving (K0), with nothing the sheet started that will end: it goes (at the GUI's next
            // drain, not inside this walk); else its animation lets it go when that ends.
            if (widget.WatchesMotion() && !(animation && !animation->IsDone() && animation->WaitsForEnd()))
                widget.MotionSettled(); // a leaving node goes, an arriving one takes its next step (K0, K5)
            const ResolvedStyle* before = m_cache.Find(&widget);
            // Its children restyle when what they inherit changed: a custom property, or its text style.
            const bool customsChanged = before == nullptr || !SameCustomProperties(*before, resolved) ||
                                        !(textBefore == widget.GetTextStyle());
            m_cache.InsertOrAssign(&widget, core::Move(resolved));

            // Pseudo-element parts (tag::part): resolve + apply each part the widget declares.
            Array<core::StringView> parts;
            widget.CollectStyleParts(parts);
            if (widget.IsScrollContainer()) // any node that scrolls has its bars' parts
            {
                parts.PushBack(core::StringView(u8"scrollbar"));
                parts.PushBack(core::StringView(u8"scrollbar-thumb"));
            }
            // A part inherits from its widget, as CSS's pseudo-elements do: its custom properties
            // (a theme's tokens, E13) and currentColor reach it.
            const ResolvedStyle* widgetStyle = m_cache.Find(&widget);
            for (const core::StringView part : parts)
            {
                const ResolvedStyle partStyle = ResolveFor(widget, subtrees, part, widgetStyle, widget.GetPartStates(part));
                ApplyPartStyle(widget, part, partStyle, context.Resources, context.Lengths);
            }
            return customsChanged;
        }

    public:
        /// Every property something sets on `widget`, each with its value and where it came from:
        /// its cascade's longhands (each declaration, the winner first), what code pinned, and the
        /// inherited properties an ancestor's rules set (E8d). For the inspector, not the frame.
        [[nodiscard]] Array<StyleExplanation> ExplainStyle(const UIWidget& widget) const
        {
            const Array<const StyleSheet*> subtrees = SubtreeSheetsOver(widget);
            Array<StyleRuleMatch> matches;
            Collect(widget, subtrees, {}, 0, nullptr, matches);
            const Array<LonghandTrace> traces = StyleSheet::Trace(matches, widget.GetInlineStyle());
            Array<StyleExplanation> out;
            const auto listed = [&out](core::StringView name)
            {
                for (const StyleExplanation& e : out)
                    if (e.Property.AsView() == name)
                        return true;
                return false;
            };
            for (const LonghandTrace& trace : traces)
                out.PushBack(Explain(widget, trace.Name.AsView(), &trace, subtrees));
            for (u32 slot = 0; slot < SlotCount; ++slot)
            {
                const core::StringView name(StyleSlotProperty(static_cast<StyleSlot>(slot)));
                if (widget.IsStylePinned(static_cast<StyleSlot>(slot)) && !listed(name))
                    out.PushBack(Explain(widget, name, nullptr, subtrees));
            }
            for (const StylePropertySpec& spec : AllStyleProperties())
            {
                const core::StringView name(spec.Name);
                if (spec.Inherited && !listed(name) && InheritedFrom(widget, name) != nullptr)
                    out.PushBack(Explain(widget, name, nullptr, subtrees));
            }
            return out;
        }
        /// Sets `property` to `value` in `rule` (one of its sheets'), as an inspector edits a rule:
        /// every node it matches restyles. A longhand set in a rule written with its shorthand
        /// comes after it there, so it wins for that side alone. False when the rule is none of
        /// its sheets' (it is only compared, so one from a sheet replaced since is safe to pass).
        bool EditDeclaration(const StyleRule* rule, core::StringView property, core::StringView value)
        {
            StyleRule* editable = m_userAgent.MutableRule(rule);
            if (editable == nullptr)
                editable = m_sheet.MutableRule(rule);
            for (usize i = 0; editable == nullptr && i < m_subtrees.Size(); ++i)
                editable = m_subtrees[i].Sheet.MutableRule(rule);
            if (editable == nullptr)
                return false;
            editable->SetProperty(property, value);
            m_allDirty = true;
            return true;
        }

        /// One property of `widget`, as ExplainStyle gives it (its own value when nothing sets it).
        [[nodiscard]] StyleExplanation ExplainProperty(const UIWidget& widget, core::StringView property) const
        {
            for (StyleExplanation& e : ExplainStyle(widget))
                if (e.Property.AsView() == property)
                    return core::Move(e);
            StyleExplanation own;
            own.Property = core::String(property);
            return own;
        }

        // Drop a widget's cached style (a destroyed one's go by themselves, at the next sweep).
        void Forget(Node* widget)
        {
            m_cache.Remove(widget);
            m_animations.Remove(widget);
            m_startedAnimations.Remove(widget);
            m_owners.Remove(widget);
        }
        void Clear()
        {
            m_cache = {};
            m_animations = {};
            m_startedAnimations = {};
            m_owners = {};
        }

    private:
        struct SubtreeSheet
        {
            Node::ElementRef Root;
            StyleSheet Sheet;
        };
        [[nodiscard]] static Node* RootOf(const SubtreeSheet& s)
        {
            return s.Root.table != nullptr ? s.Root.table->Resolve(s.Root.slot, s.Root.generation) : nullptr;
        }

        // The subtree sheets whose root is `widget` or holds it, the outermost first.
        [[nodiscard]] Array<const StyleSheet*> SubtreeSheetsOver(const Node& widget) const
        {
            Array<const StyleSheet*> out;
            if (m_subtrees.IsEmpty())
                return out;
            for (const Node* n = &widget; n != nullptr; n = n->GetParent())
                for (const SubtreeSheet& s : m_subtrees)
                    if (RootOf(s) == n)
                        out.PushBack(&s.Sheet);
            for (usize a = 0, b = out.Size(); a + 1 < b; ++a, --b) // innermost first, so reverse
                core::Swap(out[a], out[b - 1]);
            return out;
        }

        // The rules matching `widget` (or its `part`) over every origin: the user agent's sheet, the
        // GUI's, the subtrees' (outermost first).
        void Collect(const UIWidget& widget, const Array<const StyleSheet*>& subtrees, core::StringView part, u32 partStates,
                     const AncestorFilter* ancestors, Array<StyleRuleMatch>& matches) const
        {
            m_userAgent.CollectMatches(widget, m_context, true, part, 0, matches, partStates, ancestors);
            m_sheet.CollectMatches(widget, m_context, true, part, 1, matches, partStates, ancestors);
            u32 origin = 2;
            for (const StyleSheet* sheet : subtrees)
                sheet->CollectMatches(widget, m_context, true, part, origin++, matches, partStates, ancestors);
        }
        // The sheet at a match's origin.
        [[nodiscard]] const StyleSheet& SheetAt(u32 origin, const Array<const StyleSheet*>& subtrees) const
        {
            return origin == 0 ? m_userAgent : origin == 1 ? m_sheet : *subtrees[origin - 2];
        }
        // The nearest ancestor whose cascade set `property`.
        [[nodiscard]] const UIWidget* InheritedFrom(const UIWidget& widget, core::StringView property) const
        {
            for (Node* n = widget.GetParent(); n != nullptr; n = n->GetParent())
                if (const ResolvedStyle* style = m_cache.Find(n); style != nullptr && style->Has(property))
                    return core::Cast<UIWidget>(n);
            return nullptr;
        }
        [[nodiscard]] StyleExplanation Explain(const UIWidget& widget, core::StringView property, const LonghandTrace* trace,
                                               const Array<const StyleSheet*>& subtrees) const
        {
            StyleExplanation e;
            e.Property = core::String(property);
            if (trace != nullptr)
                for (const DeclarationTrace& d : trace->Declarations)
                {
                    StyleDeclarationSource source;
                    source.Value = d.Value;
                    source.Important = d.Important;
                    if (d.Rule == nullptr)
                    {
                        source.Sheet = core::String(core::StringView(u8"inline"));
                        source.Inline = true;
                    }
                    else
                    {
                        source.Rule = d.Rule;
                        source.Sheet = core::String(SheetAt(d.Origin, subtrees).Name());
                        source.Line = d.Rule->Line();
                        source.Selector = core::String(d.Rule->SelectorText());
                    }
                    e.Declarations.PushBack(core::Move(source));
                }
            bool pinned = false;
            for (u32 slot = 0; slot < SlotCount; ++slot)
                if (core::StringView(StyleSlotProperty(static_cast<StyleSlot>(slot))) == property)
                    pinned = widget.IsStylePinned(static_cast<StyleSlot>(slot));
            if (pinned)
                e.Origin = StyleOrigin::Code;
            else if (!e.Declarations.IsEmpty())
            {
                e.Origin = e.Declarations[0].Inline ? StyleOrigin::Inline : StyleOrigin::Sheet;
                const ResolvedStyle* style = m_cache.Find(const_cast<UIWidget*>(&widget));
                e.Value = style != nullptr && style->Has(property) ? core::String(style->Get(property)) : e.Declarations[0].Value;
            }
            else if (const StylePropertySpec* spec = FindStyleProperty(property); spec != nullptr && spec->Inherited)
                if (const UIWidget* from = InheritedFrom(widget, property))
                {
                    e.Origin = StyleOrigin::Inherited;
                    e.InheritedFrom = from;
                    e.Value = core::String(m_cache.Find(const_cast<UIWidget*>(from))->Get(property));
                }
            if (const RefPtr<StyleAnimation>* animation = m_animations.Find(const_cast<UIWidget*>(&widget)); animation != nullptr && *animation)
            {
                StyleValue now;
                e.Animated = (*animation)->TrackValue(property, now);
            }
            return e;
        }

        // The cascade for `widget` (or its `part`) over every origin: the user agent's sheet, the
        // GUI's, the subtrees' (outermost first), then the widget's inline style.
        [[nodiscard]] ResolvedStyle ResolveFor(const UIWidget& widget, const Array<const StyleSheet*>& subtrees,
                                               core::StringView part, const ResolvedStyle* inherited, u32 partStates = 0) const
        {
            Array<StyleRuleMatch> matches;
            Collect(widget, subtrees, part, partStates, m_filtering ? &m_ancestors : nullptr, matches); // the filter only inside ApplyTree's walk
            return StyleSheet::Cascade(matches, inherited,
                                       part.Size() == 0 ? widget.GetInlineStyle() : core::Span<const InlineStyleDeclaration>{});
        }

        // The sheet's @import, through the resource provider (E13): each imported sheet (its own
        // imports first) before what imported it; a chain that comes back to a sheet stops there.
        void ExpandImports()
        {
            m_importsExpanded = true;
            ExpandSheetImports();
            // Sprites (E13): a url() naming one, in either sheet, as its image and region.
            Array<Spritesheet> sprites;
            for (const Spritesheet& s : m_userAgent.Spritesheets())
                sprites.PushBack(s);
            for (const Spritesheet& s : m_sheet.Spritesheets())
                sprites.PushBack(s);
            if (sprites.IsEmpty())
                return;
            m_userAgent.ResolveSprites(sprites.AsSpan());
            m_sheet.ResolveSprites(sprites.AsSpan());
            m_cache = {};
            m_allDirty = true;
        }
        void ExpandSheetImports()
        {
            if (m_resources == nullptr || m_sheet.Imports().IsEmpty())
                return;
            Array<core::String> chain;
            chain.PushBack(core::String(m_sheet.Name()));
            ExpandImportsOf(m_sheet, chain);
            m_cache = {};
            m_allDirty = true;
            m_relationsKnown = false;
        }
        void ExpandImportsOf(StyleSheet& sheet, Array<core::String>& chain)
        {
            const Array<core::String> imports = sheet.Imports();
            for (usize i = imports.Size(); i-- > 0;) // the last first: each goes in front of the rest
            {
                bool cycle = false;
                for (const core::String& seen : chain)
                    cycle = cycle || seen.AsView() == imports[i].AsView();
                core::String text;
                if (cycle || !m_resources->LoadText(imports[i].AsView(), text))
                    continue;
                StyleSheet imported = CSSParser::Parse(text.AsView(), imports[i].AsView());
                chain.PushBack(imports[i]);
                ExpandImportsOf(imported, chain);
                chain.PopBack();
                sheet.PrependImported(core::Move(imported));
            }
        }

        // The sheets' @font-face, through the host's loader: each under the name ChooseFace looks
        // for (the family, its weight's name, " Italic").
        void LoadFontFaces()
        {
            m_fontFacesLoaded = true;
            if (!m_fontFaceLoader)
                return;
            const StyleSheet* const sheets[] = {&m_userAgent, &m_sheet};
            for (const StyleSheet* sheet : sheets)
                for (const FontFaceRule& rule : sheet->FontFaces())
                {
                    core::String face = detail::WithSuffix(rule.Family.AsView(), detail::WeightSuffix(rule.Weight));
                    if (rule.Italic)
                        face.Append(core::StringView(u8" Italic"));
                    if (m_fontService != nullptr && m_fontService->HasFamily(face.AsView()))
                        continue;
                    (void)m_fontFaceLoader(face.AsView(), rule.Source.AsView());
                }
        }

        // A @keyframes by name: the innermost subtree's, then the GUI's, then the user agent's.
        [[nodiscard]] const Keyframes* FindKeyframes(const Array<const StyleSheet*>& subtrees, core::StringView name) const
        {
            for (usize i = subtrees.Size(); i > 0; --i)
                if (const Keyframes* k = subtrees[i - 1]->FindKeyframes(name))
                    return k;
            if (const Keyframes* k = m_sheet.FindKeyframes(name))
                return k;
            return m_userAgent.FindKeyframes(name);
        }

        // A transition for each property that changed between `previous` and `resolved` and an
        // entry covers (its own name, or `all` for the transitionable ones; the last entry naming
        // a property wins), from the value showing now toward the new one.
        template <typename Ensure>
        static void StartTransitions(const Array<TransitionSpec>& transitions, const ResolvedStyle& previous,
                                     const ResolvedStyle& resolved, RefPtr<StyleAnimation>& animation, Ensure&& ensure)
        {
            for (const ResolvedProperty& p : resolved.Properties())
            {
                const core::StringView name = p.Name.AsView();
                if (ResolvedStyle::IsCustomProperty(name) || p.Typed.Kind == StyleValueKind::None)
                    continue;
                const TransitionSpec* spec = nullptr;
                for (const TransitionSpec& t : transitions)
                    if (t.Property.AsView() == name || (t.Property.AsView() == core::StringView(u8"all") && IsTransitionable(name)))
                        spec = &t;
                if (spec == nullptr || spec->Duration <= 0.0f)
                    continue;
                const StyleValue* before = previous.Value(name);
                StyleValue initial;
                if (before == nullptr)
                {
                    // Set now and by no rule before (a toast's `:leaving { opacity: 0 }` over a rule
                    // that never set it): from its initial value, as CSS's computed value was. An
                    // inherited one took its parent's: not here.
                    const StylePropertySpec* property = FindStyleProperty(name);
                    if (property == nullptr || property->Inherited)
                        continue;
                    const core::StringView text = property->Initial != nullptr ? core::StringView(property->Initial)
                                                  : property->Grammar == StyleGrammar::Transforms ? core::StringView(u8"none")
                                                                                                  : core::StringView{};
                    if (text.Size() == 0 || text == p.Value.AsView() || !ParseStyleValue(property->Grammar, text, initial))
                        continue; // no initial value, or no change from it
                    before = &initial;
                }
                else if (previous.Get(name) == p.Value.AsView())
                    continue; // no change
                StyleValue from = *before;
                if (animation)
                    (void)animation->TrackValue(name, from); // retarget from where a running track is
                if (ensure())
                    animation->StartTransition(name, from, p.Typed, *spec);
            }
            // A property no rule sets any more (a class taken off: a toast's `.entering`) goes back
            // to its initial value, transitioned there as CSS does, not snapped: toward the table's
            // initial value (`none` for a transform). Inherited ones take their parent's: not here.
            for (const ResolvedProperty& p : previous.Properties())
            {
                const core::StringView name = p.Name.AsView();
                if (ResolvedStyle::IsCustomProperty(name) || p.Typed.Kind == StyleValueKind::None || resolved.Value(name) != nullptr)
                    continue;
                const StylePropertySpec* property = FindStyleProperty(name);
                if (property == nullptr || property->Inherited)
                    continue;
                const core::StringView initial = property->Initial != nullptr          ? core::StringView(property->Initial)
                                                 : property->Grammar == StyleGrammar::Transforms ? core::StringView(u8"none")
                                                                                                 : core::StringView{};
                StyleValue to;
                if (initial.Size() == 0 || !ParseStyleValue(property->Grammar, initial, to))
                    continue;
                const TransitionSpec* spec = nullptr;
                for (const TransitionSpec& t : transitions)
                    if (t.Property.AsView() == name || (t.Property.AsView() == core::StringView(u8"all") && IsTransitionable(name)))
                        spec = &t;
                if (spec == nullptr || spec->Duration <= 0.0f)
                    continue;
                StyleValue from = p.Typed;
                if (animation)
                    (void)animation->TrackValue(name, from);
                if (ensure())
                    animation->StartTransition(name, from, to, *spec);
            }
        }

        // The states the sheets read through an ancestor and through a sibling (LearnRelations).
        // A value that reads the viewport's size: a number in vw or vh (`50vw`, `calc(100vh - 2px)`).
        [[nodiscard]] static bool ReadsViewport(core::StringView value) noexcept
        {
            for (usize i = 1; i + 1 < value.Size(); ++i)
                if (value[i] == u8'v' && (value[i + 1] == u8'w' || value[i + 1] == u8'h') &&
                    ((value[i - 1] >= u8'0' && value[i - 1] <= u8'9') || value[i - 1] == u8'.'))
                    return true;
            return false;
        }
        // The widgets whose inline style reads the viewport restyle after it resized (the sheets
        // reading none of it).
        void MarkViewportReaders(Node& node)
        {
            if (const UINode* ui = Cast<UINode>(&node))
                for (const InlineStyleDeclaration& d : ui->GetInlineStyle())
                    if (ReadsViewport(d.Value.AsView()))
                    {
                        node.MarkStyleDirty(false);
                        break;
                    }
            for (usize i = 0; i < node.ChildCount(); ++i)
                MarkViewportReaders(*node.GetChildAt(i));
        }

        void LearnRelations()
        {
            m_ancestorStates = 0;
            m_siblingStates = 0;
            m_readsSiblings = false;
            m_siblingReadsAbove.Clear();
            m_sheetsReadViewport = false;
            m_sizeQueries.Clear();
            const auto learn = [&](const StyleSheet& sheet)
            {
                for (const StyleRule& rule : sheet.Rules())
                {
                    if (rule.Media().FeatureCount() != 0)
                        m_sizeQueries.PushBack(&rule.Media()); // any feature: the size's among them, perhaps
                    for (const StyleProperty& p : rule.Properties())
                        m_sheetsReadViewport = m_sheetsReadViewport || ReadsViewport(p.Value.AsView());
                    rule.Selector().CollectRelationStates(m_ancestorStates, m_siblingStates);
                    m_readsSiblings = m_readsSiblings || rule.Selector().ReadsSiblings();
                    rule.Selector().ForEachSiblingReadAbove([&](const StyleSelectorRule& compound) { m_siblingReadsAbove.PushBack(compound); });
                }
            };
            learn(m_userAgent);
            learn(m_sheet);
            for (const SubtreeSheet& s : m_subtrees)
                learn(s.Sheet);
            m_relationsKnown = true;
        }

        StyleSheet m_userAgent;
        StyleSheet m_sheet;
        Array<SubtreeSheet> m_subtrees;
        MediaContext m_context;
        IResourceProvider* m_resources = nullptr;     // non-owning; loads background-image assets
        fonts::IFontService* m_fontService = nullptr; // non-owning; resolves font-family
        Function<bool(core::StringView, core::StringView)> m_fontFaceLoader; // the host's; loads @font-face
        bool m_fontFacesLoaded = false; // this sheet's faces were asked for
        bool m_importsExpanded = false; // this sheet's @imports are in it
        f32 m_rootFontSize = 16.0f;                   // CSS `rem` base
        // Whose entries an address's are: the widget's place in its GUI's element table when they
        // were made (the table held, so a closed GUI's reads as gone, not freed).
        struct Owner
        {
            RefPtr<ElementTable> Table;
            u32 Slot = 0;
            u32 Generation = 0;
        };
        // Whether the entries at `widget`'s address are its own: none yet, or made for it (a widget
        // in no GUI has nothing to check against, and keeps them).
        [[nodiscard]] bool IsOwn(const Node& widget) const
        {
            const Owner* owner = m_owners.Find(const_cast<Node*>(&widget));
            return owner == nullptr || !owner->Table || owner->Table->Resolve(owner->Slot, owner->Generation) == &widget;
        }
        // Makes the entries at `widget`'s address its own, dropping a destroyed widget's first.
        void Claim(Node& widget)
        {
            if (!IsOwn(widget))
                Forget(&widget);
            if (m_owners.Find(&widget) != nullptr)
                return;
            const Node::ElementRef ref = widget.TakeElementRef();
            m_owners.InsertOrAssign(&widget, Owner{RefPtr<ElementTable>(ref.table), ref.slot, ref.generation});
        }
        // Drops the entries of every widget gone since, once the caches have doubled since the
        // last sweep (so a GUI that keeps its widgets pays nothing).
        void SweepGone()
        {
            Array<Node*> gone;
            for (const auto& entry : m_owners)
                if (entry.value.Table && entry.value.Table->Resolve(entry.value.Slot, entry.value.Generation) != entry.key)
                    gone.PushBack(entry.key);
            for (Node* node : gone)
                Forget(node);
            m_sweepAt = Max<usize>(kFirstSweep, m_owners.Size() * 2);
        }
        static constexpr usize kFirstSweep = 256;

        HashMap<Node*, Owner> m_owners; // whose entries each address's are
        usize m_sweepAt = kFirstSweep;
        HashMap<Node*, ResolvedStyle> m_cache; // last-applied style per widget (non-owning keys)
        HashMap<Node*, RefPtr<StyleAnimation>> m_animations; // widget -> its running transitions and animations
        HashMap<Node*, Array<core::String>> m_startedAnimations; // widget -> the @keyframes it has started
        bool m_allDirty = true; // the next ApplyTree restyles everything (a new sheet, media, fonts)
        bool m_relationsKnown = false;
        bool m_sheetsReadViewport = false;     // a declaration in vw or vh: a resize restyles everything
        Array<const MediaQuery*> m_sizeQueries; // the rules' media queries with features, asked again on a resize
        bool m_viewportResized = false;        // the viewport's size changed, no sheet reading it
        u32 m_ancestorStates = 0; // states a rule reads through an ancestor: a change restyles the subtree
        u32 m_siblingStates = 0;  // states a rule reads through an earlier sibling: a change restyles the later siblings
        u32 m_lastRestyleCount = 0;
        bool m_readsSiblings = false; // some rule reads siblings: a rearrangement restyles them
        Array<StyleSelectorRule> m_siblingReadsAbove; // compounds reading siblings with a step below: what such a child holds restyles too
        AncestorFilter m_ancestors; // the names above the widget ApplyTree's walk is at
        bool m_filtering = false;   // inside that walk (a widget styled any other way has no filter)
    };
}
