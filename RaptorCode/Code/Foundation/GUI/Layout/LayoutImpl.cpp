// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - module implementation unit: layout, what is left of it after slice S8: the two parts of
// Node's scrolling that read the EventDispatcher, for S11. The rest is
// Code/Foundation/Sedulous.GUI/src/Layout/LayoutImpl.bf.

namespace foundation::gui
{
    // Node::SetScrollExtent, after the extent and the latch are applied (LayoutImpl.bf's
    // SetScrollExtent ends where this begins), with `before` taken at its top:
        const core::Float2 before = m_contentExtent; // as it was before the content changed
        if (m_smoothScrolling)
            m_scrollTarget = ClampScroll(m_scrollTarget);
        // The focused widget inside keeps its focus area in view (a caret on a line just typed,
        // which the old range could not reach).
        if (extent == before)
            return;
        const EventDispatcher* dispatcher = GetEventDispatcher();
        Node* focused = dispatcher != nullptr ? dispatcher->GetFocusNode() : nullptr;
        Rect area;
        if (focused == nullptr || focused == this || !focused->GetFocusArea(area))
            return;
        for (const Node* up = focused->GetParent(); up != nullptr; up = up->GetParent())
            if (up == this)
            {
                ScrollIntoView(*focused, area, ScrollAlign::Nearest, ScrollBehavior::Instant);
                return;
            }
    }

    // Node::ScrollDefaultAction, case MouseDown, grabbing the thumb (LayoutImpl.bf has the rest of
    // this block, without the capture):
                if (thumb.Contains(p)) // grab the thumb where it was taken
                {
                    m_scrollDragAxis = axis;
                    MarkStyleStateDirty(StateHover | StateActive); // ::scrollbar-thumb:active
                    m_scrollDragGrab = axis == 1 ? p.y - thumb.y : p.x - thumb.x;
                    if (EventDispatcher* dispatcher = GetEventDispatcher())
                        dispatcher->CapturePointer(*this);
                }
}
