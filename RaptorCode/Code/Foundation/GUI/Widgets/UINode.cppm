// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :ui_node partition, what is left of it after slice S9: the part-style lookup, whose body
// is in Scene/GUIClusterImpl.cpp (S11), and the two members that read it. The rest is
// Code/Foundation/Sedulous.GUI/src/Widgets/UINode.bf (InlineStyleDeclaration, MotionValue, UINode).

export namespace foundation::gui
{
    class UINode : public Node
    {
    public:
        /// A modal popup's dim: its `::backdrop` part over the default one.
        void DrawBackdrop(DrawContext& ctx, const Rect& bounds) const override
        {
            GetPartStyle(u8"backdrop").Draw(ctx, bounds, FilledBox(Color{0.0f, 0.0f, 0.0f, 0.45f}));
        }

        /// The sheet's style for `part` (an empty one when the sheet styles it not).
        [[nodiscard]] const PartStyle& GetPartStyle(core::StringView part) const; // GUIClusterImpl.cpp
        [[nodiscard]] const PartStyle* FindPartStyle(core::StringView part) const override { return &GetPartStyle(part); }
    };
}
