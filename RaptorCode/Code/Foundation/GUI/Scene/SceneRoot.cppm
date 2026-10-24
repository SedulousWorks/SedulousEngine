// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :scene_root partition, what is left of it after slice S12: GUIContext's members whose
// bodies belong to a later slice (S18 accessibility), and the two calls of GUIContext::Update
// into accessibility. The rest is Code/Foundation/Sedulous.GUI/src/Scene/SceneRoot.bf
// (GUIContext, SceneRoot; the debug overlay's input half in Scene/DebugOverlayImpl.bf; the data
// tweens in Styling/TweenImpl.bf).

export namespace foundation::gui
{
    class GUIContext : public RefCounted
    {
    public:
        // --- S18: accessibility (Scene/AccessibilityImpl.cpp; SceneRoot.bf has the fields) ---
        /// Runs an action now; false when its node is gone or does not take it. AccessibilityImpl.cpp.
        bool RunAccessAction(const AccessActionRequest& request);
        /// `root`'s whole tree as it is now, listening or not (the inspector's, a test's).
        [[nodiscard]] AccessTreeUpdate BuildAccessTree(SceneRoot& root);
        /// `node`'s accessibility node as it is now; false when it has none of its own (no role,
        /// hidden, or a part of a leaf: what a screen reader reads it as is an ancestor's).
        bool DescribeAccess(Node& node, AccessNode& out);
        /// An item view's key among this GUI's, given the first time it is asked (E17b).
        [[nodiscard]] u32 AccessViewKey(Node& view); // AccessibilityImpl.cpp

    private:
        void RunAccessRequests();  // AccessibilityImpl.cpp: the requests queued, each run
        void FlushAccessibility(); // AccessibilityImpl.cpp: each root's changes to the bridge
    };

    // GUIContext::Update's first and last lines (SceneRoot.bf's Update leaves them out until S18):
    inline void GUIContext::Update(core::Duration elapsed)
    {
        RunAccessRequests(); // what a platform asked since: this frame shows it
        // ...
        FlushAccessibility();
    }
}
