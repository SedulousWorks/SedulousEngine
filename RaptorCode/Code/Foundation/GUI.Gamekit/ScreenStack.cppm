// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Gamekit - :screen_stack partition, what is left of it after the GUI.Gamekit port: the
// members whose bodies or types belong to a later slice (S19, the script surface: node handles).
// The rest is Code/Foundation/Sedulous.GUI.Gamekit/src/ScreenStack.bf (Screen, ScreenStack).

export namespace foundation::gui
{
    class Screen : public UIWidget
    {
    public:
        /// The script surface: its stack (null when on none).
        [[nodiscard]] core::Variant StackElement();
    };

    class ScreenStack : public UIWidget
    {
    public:
        // === The script surface (reflected in GamekitReflection.cpp) ===
        core::Variant PushScript(core::StringView path) { return HandleOf(PushDocument(path)); }
        core::Variant PushNodeScript(core::Variant content)
        {
            Node* node = Node::FromHandle(content);
            return node != nullptr ? HandleOf(Push(*node)) : core::Variant{};
        }
        core::Variant ReplaceScript(core::StringView path) { return HandleOf(ReplaceDocument(path)); }
        core::Variant ReplaceNodeScript(core::Variant content)
        {
            Node* node = Node::FromHandle(content);
            return node != nullptr ? HandleOf(Replace(*node)) : core::Variant{};
        }
        [[nodiscard]] core::Variant TopScript() const { return HandleOf(Top()); }
        [[nodiscard]] i32 CountScript() const noexcept { return static_cast<i32>(m_screens.Size()); }

    private:
        [[nodiscard]] static core::Variant HandleOf(Screen* screen)
        {
            return screen != nullptr ? screen->HandleAs(Screen::StaticType()) : core::Variant{};
        }
    };

    inline core::Variant Screen::StackElement()
    {
        return m_stack != nullptr ? m_stack->HandleAs(ScreenStack::StaticType()) : core::Variant{};
    }
}
