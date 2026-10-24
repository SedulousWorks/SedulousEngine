// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :menu partition, what is left of it after slice S15: Menu's opening below a node a script
// hands it, which takes a node's handle (S19, the script surface). The rest is
// Code/Foundation/Sedulous.GUI/src/Widgets/Menu.bf (MenuRow, MenuSeparator, MenuItem, MenuSubItem,
// MenuScrollArrow, Menu; UIWidget's context menu in Widgets/UIWidget.bf).

export namespace foundation::gui
{
    class Menu : public UIWidget
    {
    public:
        // --- S19: the script surface (reflected in Scene/GUIReflectionImpl.cpp) ---
        /// Opens it below `anchor` (a node's handle), as that node's popup; whether it opened.
        [[nodiscard]] core::Variant OpenBelowNode(core::Variant anchor)
        {
            Node* node = Node::FromHandle(anchor);
            if (node != nullptr)
            {
                PopupOptions options;
                options.Anchor = node;
                options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 0.0f, true};
                options.TakesFocus = true;
                options.ReturnHome = true; // a script's menu: back where it waits, to open again
                OpenAs(*node, core::Move(options));
            }
            return core::Variant::From<bool>(node != nullptr && IsOpen());
        }
    };
}
