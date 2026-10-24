// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :navigation partition
//
// Directional focus navigation (G7 of Specs/vg-and-gui-lab.md), automatic by default: a geometric
// picker takes the best focusable widget in the pressed direction, so most screens need no
// authoring. A candidate must lie beyond the focused widget in that direction; those overlapping
// it on the cross axis come first (a row's neighbour before a widget diagonally nearer), then the
// nearest along the axis, then the nearest across it. Hidden, disabled and clipped-away widgets
// are skipped.
//
// Where the geometry is wrong, a widget says where a direction goes (nav-up and the rest: an id,
// or none to stop), which is followed first.
//
// Focus scopes (Node::SetNavScope) bound the search: navigation stays inside the focused widget's
// scope, and at its edge passes to the scope around it, wraps to the scope's other side, or stays
// (contain, for a dialog). Entering a scope from outside lands on what was last focused in it, else
// on its default focus, else on the picked widget.

module;
#include "Core/Prelude.h"

export module foundation.gui:navigation;

import foundation.core; // Array, Max, Min, Abs
import :rect;
import :node;
import :ui_widget; // ids (a scope's default focus)

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class NavDirection : u8
    {
        Up,
        Down,
        Left,
        Right,
    };

    /// What became of one candidate of a directional move.
    enum class NavVerdict : u8
    {
        Chosen,  ///< the best: focus went there (or into the scope holding it)
        Beaten,  ///< beyond the focused widget that way, with a worse score
        Behind,  ///< not beyond it that way
        Clipped, ///< hidden by a clipping ancestor
    };
    /// One candidate a directional move weighed: where it was (in the GUI's world), its name, its
    /// score (lower is better; at 1e6 and over, one not overlapping the focused widget across the
    /// move) and what became of it.
    struct NavCandidate
    {
        Rect Bounds;
        core::String Name;
        f32 Score = -1.0f;
        NavVerdict Verdict = NavVerdict::Behind;
    };
    /// What the last directional move weighed (E8c: the debug overlay draws it, the inspector
    /// lists it): from where, which way, every candidate of the last search, and whether an
    /// override decided it or the search wrapped round its scope.
    struct NavTrace
    {
        NavDirection Direction = NavDirection::Down;
        Rect From;
        Array<NavCandidate> Candidates;
        bool Overridden = false; ///< a nav-up (and the rest) said where it went
        bool Wrapped = false;    ///< it measured again from the scope's other side
        bool Any = false;        ///< a move happened since the GUI began
        static constexpr f32 kNoOverlapTier = 1.0e6f;
    };

    namespace detail
    {
        // Whether `node` can take focus from navigation: tab-focusable, enabled, and shown with all
        // its ancestors (visible, and in the layout: not under a page switched away), and not leaving or inert.
        [[nodiscard]] inline bool IsNavigable(const Node& node)
        {
            return node.IsTabFocusable() && node.IsTreeEnabled() && node.IsTreeVisible() && !node.IsTreeInert();
        }

        // Whether a clipping ancestor hides `node` (a scroller's clip does not count: it scrolls a
        // focused widget into view).
        [[nodiscard]] inline bool IsClippedAway(const Node& node, const Rect& bounds)
        {
            for (const Node* n = node.GetParent(); n != nullptr; n = n->GetParent())
                if (n->ClipsChildren() && !n->ScrollsDescendantsIntoView() &&
                    (n->GetParent() == nullptr || !n->GetParent()->ScrollsDescendantsIntoView()))
                {
                    const Rect clip = n->GetScreenBounds();
                    if (bounds.x + bounds.width <= clip.x || bounds.x >= clip.x + clip.width ||
                        bounds.y + bounds.height <= clip.y || bounds.y >= clip.y + clip.height)
                        return true;
                }
            return false;
        }

        inline void CollectNavigable(Node& node, Array<Node*>& out)
        {
            if (!node.IsVisible() || !node.IsDisplayed())
                return;
            if (IsNavigable(node))
                out.PushBack(&node);
            for (usize i = 0; i < node.ChildCount(); ++i)
                CollectNavigable(*node.GetChildAt(i), out);
        }

        [[nodiscard]] inline Node* FindWidgetById(Node& node, core::StringView id)
        {
            if (const UIWidget* widget = core::Cast<UIWidget>(&node); widget != nullptr && widget->GetId() == id)
                return &node;
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (Node* found = FindWidgetById(*node.GetChildAt(i), id))
                    return found;
            return nullptr;
        }

        [[nodiscard]] inline bool IsInside(const Node* node, const Node& ancestor)
        {
            for (const Node* n = node; n != nullptr; n = n->GetParent())
                if (n == &ancestor)
                    return true;
            return false;
        }

        // The score of moving from `from` to `to` in `direction`: lower is better; negative when
        // `to` is not beyond `from` that way. Overlap on the cross axis is a tier of its own.
        [[nodiscard]] inline f32 Score(const Rect& from, const Rect& to, NavDirection direction)
        {
            const bool vertical = direction == NavDirection::Up || direction == NavDirection::Down;
            const f32 fromNear = direction == NavDirection::Down    ? from.y + from.height
                                 : direction == NavDirection::Up    ? from.y
                                 : direction == NavDirection::Right ? from.x + from.width
                                                                    : from.x;
            const f32 toNear = direction == NavDirection::Down    ? to.y
                               : direction == NavDirection::Up    ? to.y + to.height
                               : direction == NavDirection::Right ? to.x
                                                                  : to.x + to.width;
            const f32 toCenter = vertical ? to.y + to.height * 0.5f : to.x + to.width * 0.5f;
            const f32 fromCenter = vertical ? from.y + from.height * 0.5f : from.x + from.width * 0.5f;
            const bool forward = direction == NavDirection::Down || direction == NavDirection::Right;
            // Beyond: its centre past ours, and its near edge at or past our leading edge, give or
            // take a quarter of the smaller one's size (neighbours that touch or overlap a little).
            // A wide field in the row above is not to the right of a button under it, though its
            // centre is (user report: Back, then right, took the settings' text field).
            if (forward ? toCenter <= fromCenter : toCenter >= fromCenter)
                return -1.0f;
            const f32 slack = 0.25f * Min(vertical ? from.height : from.width, vertical ? to.height : to.width);
            if (forward ? toNear < fromNear - slack : toNear > fromNear + slack)
                return -1.0f;
            const f32 along = Max(0.0f, forward ? toNear - fromNear : fromNear - toNear);
            const f32 crossFromLo = vertical ? from.x : from.y;
            const f32 crossFromHi = vertical ? from.x + from.width : from.y + from.height;
            const f32 crossToLo = vertical ? to.x : to.y;
            const f32 crossToHi = vertical ? to.x + to.width : to.y + to.height;
            const f32 overlap = Min(crossFromHi, crossToHi) - Max(crossFromLo, crossToLo);
            const f32 crossCenterGap = Abs((crossFromLo + crossFromHi) * 0.5f - (crossToLo + crossToHi) * 0.5f);
            constexpr f32 kNoOverlapTier = NavTrace::kNoOverlapTier; // every overlapping candidate beats every other
            if (overlap > 0.0f)
                return along + crossCenterGap * 0.01f;
            const f32 crossGap = -overlap;
            return kNoOverlapTier + along + crossGap * 2.0f;
        }

        // The innermost scope holding `node` (null when none: the whole GUI is the scope).
        [[nodiscard]] inline Node* ScopeOf(Node* node)
        {
            for (Node* n = node != nullptr ? node->GetParent() : nullptr; n != nullptr; n = n->GetParent())
                if (n->GetNavScope() != NavScope::None)
                    return n;
            return nullptr;
        }
    }

    /// The best focusable widget from `from` in `direction` among the navigable widgets under
    /// `within`, or null. Wrapping (true) measures from just outside `within`'s opposite edge, so
    /// the first widget on that side is picked. `trace`, when given, gets every candidate weighed.
    [[nodiscard]] inline Node* PickInDirection(Node& within, const Node* from, const Rect& fromBounds, NavDirection direction,
                                               NavTrace* trace = nullptr)
    {
        Array<Node*> candidates;
        detail::CollectNavigable(within, candidates);
        if (trace != nullptr)
            trace->Candidates.Clear(); // the last search is the one that decided
        Node* best = nullptr;
        f32 bestScore = 0.0f;
        usize bestEntry = 0;
        for (Node* candidate : candidates)
        {
            if (candidate == from || (from != nullptr && detail::IsInside(from, *candidate)))
                continue; // not itself, nor what holds it (a focusable scroller around it)
            const Rect bounds = candidate->GetScreenBounds();
            const bool clipped = detail::IsClippedAway(*candidate, bounds);
            const f32 score = clipped ? -1.0f : detail::Score(fromBounds, bounds, direction);
            if (trace != nullptr)
                trace->Candidates.PushBack(NavCandidate{bounds, candidate->DebugName(), score,
                                                        clipped ? NavVerdict::Clipped : score < 0.0f ? NavVerdict::Behind : NavVerdict::Beaten});
            if (score < 0.0f)
                continue;
            if (best == nullptr || score < bestScore)
            {
                best = candidate;
                bestScore = score;
                bestEntry = trace != nullptr ? trace->Candidates.Size() - 1 : 0;
            }
        }
        if (trace != nullptr && best != nullptr)
            trace->Candidates[bestEntry].Verdict = NavVerdict::Chosen;
        return best;
    }

    /// Where focus lands entering `scope` (the outermost scope a move crosses into): what was last
    /// focused in it, else its default focus, else `picked`.
    [[nodiscard]] inline Node* EntryInto(Node& scope, Node* picked)
    {
        if (Node* remembered = scope.GetRememberedFocus();
            remembered != nullptr && detail::IsInside(remembered, scope) && detail::IsNavigable(*remembered))
            return remembered;
        if (scope.GetDefaultFocusId().Size() != 0)
            if (Node* fallback = detail::FindWidgetById(scope, scope.GetDefaultFocusId());
                fallback != nullptr && detail::IsNavigable(*fallback))
                return fallback;
        // A focus group no one has focused in yet: its current member (a checked radio).
        if (scope.IsFocusGroup())
        {
            Array<Node*> members;
            detail::CollectNavigable(scope, members);
            for (Node* member : members)
                if (member->IsCurrentInGroup())
                    return member;
        }
        return picked;
    }

    /// What `focused`'s override `which` says (nav-up and the rest): `stop` set for `none`, the
    /// widget for an id found navigable under `root`, else null (auto, empty, or an id not there).
    [[nodiscard]] inline Node* FollowOverride(Node& root, const Node& focused, Node::NavOverride which, bool& stop)
    {
        stop = false;
        const core::StringView target = focused.GetNavOverride(which);
        if (target.Size() == 0 || target == core::StringView(u8"auto"))
            return nullptr;
        if (target == core::StringView(u8"none"))
        {
            stop = true;
            return nullptr;
        }
        Node* found = detail::FindWidgetById(root, target);
        return found != nullptr && detail::IsNavigable(*found) ? found : nullptr;
    }

    /// The widget directional navigation moves focus to from `focused` (under `root`, the GUI or a
    /// modal), or null to stay. With nothing focused, the root's entry (its remembered or default
    /// focus, else the first navigable widget).
    [[nodiscard]] inline Node* NavigateFrom(Node& root, Node* focused, NavDirection direction, NavTrace* trace = nullptr)
    {
        if (trace != nullptr)
        {
            *trace = NavTrace{};
            trace->Direction = direction;
            trace->Any = true;
            if (focused != nullptr)
                trace->From = focused->GetScreenBounds();
        }
        // Nothing focused, focus outside `root`, or on something that does not take focus: the entry.
        if (focused == nullptr || !detail::IsInside(focused, root) || !detail::IsNavigable(*focused))
        {
            Array<Node*> all;
            detail::CollectNavigable(root, all);
            return EntryInto(root, all.IsEmpty() ? nullptr : all[0]);
        }
        // An override where the geometry is wrong comes first.
        const Node::NavOverride which = direction == NavDirection::Up     ? Node::NavOverrideUp
                                        : direction == NavDirection::Down ? Node::NavOverrideDown
                                        : direction == NavDirection::Left ? Node::NavOverrideLeft
                                                                          : Node::NavOverrideRight;
        bool stop = false;
        if (Node* overridden = FollowOverride(root, *focused, which, stop))
        {
            if (trace != nullptr)
                trace->Overridden = true;
            return overridden;
        }
        if (stop)
            return nullptr;
        const Rect from = focused->GetScreenBounds();
        // Search the focused widget's scope, then outward while a scope passes its edge on.
        for (Node* scope = detail::ScopeOf(focused);; scope = detail::ScopeOf(scope))
        {
            Node& within = (scope != nullptr && detail::IsInside(scope, root)) ? *scope : root;
            if (Node* picked = PickInDirection(within, focused, from, direction, trace))
            {
                // Crossing into a scope (one holding the pick but not the focused widget): its entry.
                Node* entered = nullptr;
                for (Node* s = detail::ScopeOf(picked); s != nullptr && s != &within; s = detail::ScopeOf(s))
                    if (!detail::IsInside(focused, *s))
                        entered = s;
                return entered != nullptr ? EntryInto(*entered, picked) : picked;
            }
            if (within.GetNavScope() == NavScope::Wrap)
            {
                // From just past the scope's opposite edge, along the same line.
                const Rect edge = within.GetScreenBounds();
                Rect outside = from;
                switch (direction)
                {
                case NavDirection::Down: outside.y = edge.y - from.height - 1.0f; break;
                case NavDirection::Up: outside.y = edge.y + edge.height + 1.0f; break;
                case NavDirection::Right: outside.x = edge.x - from.width - 1.0f; break;
                case NavDirection::Left: outside.x = edge.x + edge.width + 1.0f; break;
                }
                if (trace != nullptr)
                    trace->Wrapped = true;
                return PickInDirection(within, nullptr, outside, direction, trace);
            }
            if (within.GetNavScope() == NavScope::Contain || &within == &root)
                return nullptr; // a dialog's edge, or the GUI's
            // Pass: on to the scope around this one.
        }
    }

    /// Where focus goes when `node` is focused by a program: itself when it takes focus, else its
    /// entry (remembered, default, or first focusable widget under it); null when nothing does.
    [[nodiscard]] inline Node* FocusTargetOf(Node& node)
    {
        if (detail::IsNavigable(node))
            return &node;
        Array<Node*> all;
        detail::CollectNavigable(node, all);
        return EntryInto(node, all.IsEmpty() ? nullptr : all[0]);
    }

    /// The innermost containing scope holding `node` (a dialog's: Tab stays inside it), or null.
    [[nodiscard]] inline Node* ContainingScopeOf(Node* node)
    {
        for (Node* scope = detail::ScopeOf(node); scope != nullptr; scope = detail::ScopeOf(scope))
            if (scope->GetNavScope() == NavScope::Contain)
                return scope;
        return nullptr;
    }

    /// Records `focused` as the remembered focus of every scope holding it.
    inline void RememberInScopes(Node& focused)
    {
        for (Node* scope = detail::ScopeOf(&focused); scope != nullptr; scope = detail::ScopeOf(scope))
            scope->RememberFocus(focused);
    }
}
