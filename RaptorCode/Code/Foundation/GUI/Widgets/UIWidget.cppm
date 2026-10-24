// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :ui_widget partition, what is left of it after slice S9: opening the context menu, whose
// body is in Scene/GUIReflectionImpl.cpp and needs :menu (S15). The rest is
// Code/Foundation/Sedulous.GUI/src/Widgets/UIWidget.bf (the WidgetState constants, UIWidget,
// MarkupChildHost).

export namespace foundation::gui
{
    class UIWidget : public UINode
    {
    protected:
        void OnContextMenu(const MouseEvent& event) override
        {
            if (!m_contextMenuId.IsEmpty() && OpenContextMenu(event))
                event.Handled = true;
        }

    private:
        // Finds the menu (kept once found: open, it leaves the page for the top layer, and
        // closed, the tree) and opens it at the event's position. GUIClusterImpl.cpp, which sees
        // :menu.
        bool OpenContextMenu(const MouseEvent& event);
    };
}
