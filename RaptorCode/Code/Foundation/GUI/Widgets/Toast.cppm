// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :toast partition, what is left of it after slice S15: ToastHost's posts from a script,
// one of which takes a node's handle (S19, the script surface; ToastSeverity's and ToastRequest's
// reflection stays in Scene/GUIReflectionImpl.cpp with it). The rest is
// Code/Foundation/Sedulous.GUI/src/Widgets/Toast.bf (ToastSeverity, ToastAction, ToastRequest,
// ToastCard, ToastHost).

export namespace foundation::gui
{
    class ToastHost : public UIWidget
    {
    public:
        // --- S19: the script surface (reflected in Scene/GUIReflectionImpl.cpp) ---
        // A script's (reflected): `host.post(request)`, `host.postContent(request, widget)`.
        ToastId PostScript(ToastRequest request) { return Post(core::Move(request)); }
        ToastId PostContentScript(ToastRequest request, core::Variant content)
        {
            Node* node = Node::FromHandle(content);
            request.Content = core::RefPtr<UIWidget>(node != nullptr ? Cast<UIWidget>(node) : nullptr);
            return Post(core::Move(request));
        }
    };
}
