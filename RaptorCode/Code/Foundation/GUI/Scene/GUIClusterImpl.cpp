// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - module implementation unit for foundation.gui.
//
// Holds Node method bodies that call into the EventDispatcher. They cannot be inline in
// the :node interface partition without making it import :event_dispatcher, which imports
// :node back (a module-partition cycle). An implementation unit sees the whole module (it
// implicitly imports the primary interface) and is outside the interface dependency graph
// - the same pattern as foundation.ui's UIClusterImpl.cpp.

module;
#include "Core/Prelude.h"

module foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

namespace foundation::gui
{
    SceneRoot* Node::GetSceneRoot() { return core::Cast<SceneRoot>(GetRootNode()); }

    bool Node::AreMnemonicsShown()
    {
        SceneRoot* root = GetSceneRoot();
        return root != nullptr && root->GetEventDispatcher()->AreMnemonicsShown();
    }

    const PartStyle& UINode::GetPartStyle(core::StringView part) const
    {
        for (const NamedPartStyle& p : m_partStyles)
            if (p.Name.AsView() == part)
                return p.Style;
        static const PartStyle kNone{}; // here, not in the interface: one per process in a shared build
        return kNone;
    }

    void Node::SetCommand(StringView id)
    {
        m_command.Set(core::String(id));
        if (m_commandBound)
            return;
        m_commandBound = true;
        // One binding follows the id, the GUI the control is in, focus, the command's state and its
        // handlers: whichever changes, the control's state follows.
        Bind([this]()
             {
                 const core::String commandId(m_command.Get());
                 SceneRoot* root = ObserveSceneRoot();
                 if (commandId.Size() == 0 || root == nullptr)
                     return;
                 // Availability on the active root's focus path (the window the user is in).
                 const bool available = root->GetContext().IsCommandAvailable(commandId.AsView());
                 const Command* command = root->GetContext().GetCommands().Find(commandId.AsView());
                 BoundCommandState state;
                 state.Available = available;
                 state.Checked = command != nullptr && command->IsChecked();
                 const core::String reason(command != nullptr && !command->IsEnabled() ? command->GetDisabledReason() : core::StringView{});
                 state.Reason = reason.AsView();
                 Untracked([&] { OnBoundCommandState(state); });
             });
        // A second follows what the control shows of it: its label and icon, and its keys (E5).
        Bind([this]()
             {
                 const core::String commandId(m_command.Get());
                 SceneRoot* root = ObserveSceneRoot();
                 if (commandId.Size() == 0 || root == nullptr)
                     return;
                 root->GetContext().GetCommands().TrackChanges();
                 const Command* command = root->GetContext().GetCommands().Find(commandId.AsView());
                 const core::String label(command != nullptr ? command->GetLabel() : commandId.AsView());
                 const core::String icon(command != nullptr ? command->GetIcon() : core::StringView{});
                 // The keys that run it here: the binding matched in this node's own contexts.
                 const Array<KeyContextLayer> contexts = root->KeyContextsAt(this);
                 const core::String shortcut = root->GetContext().GetKeymap().ShortcutText(commandId.AsView(), contexts.AsSpan());
                 Untracked([&] { OnBoundCommandText(label.AsView(), icon.AsView(), shortcut.AsView()); });
             });
    }

    bool Node::RunBoundCommand()
    {
        SceneRoot* root = HasCommand() ? GetSceneRoot() : nullptr;
        return root != nullptr && root->RunCommand(GetCommand());
    }

    void Node::NotifyCommandsChanged()
    {
        if (SceneRoot* root = GetSceneRoot())
            root->GetContext().GetCommands().NotifyChanged();
    }

    void Node::RequestFocus()
    {
        if (EventDispatcher* dispatcher = GetEventDispatcher())
            dispatcher->SetFocusNode(this);
    }

    void Node::ReleaseFocus()
    {
        if (EventDispatcher* dispatcher = GetEventDispatcher())
            if (dispatcher->GetFocusNode() == this)
                dispatcher->SetFocusNode(nullptr);
    }

    void Node::Leave()
    {
        if (m_leaving || m_parent == nullptr)
            return;
        EventDispatcher* dispatcher = GetEventDispatcher();
        if (dispatcher == nullptr)
        {
            RemoveFromParent(); // in no GUI: nothing to wait for, nothing walking it
            return;
        }
        m_leaving = true;
        if (m_enterPhase != 0)
        {
            m_enterPhase = 0; // an entrance cut short: it leaves from where it is
            MarkStyleStateDirty(StateEntering);
        }
        // Out of input now, as a removed subtree is (hover, press, capture, focus, its popups):
        // a second Back while it fades does not reach it.
        dispatcher->NotifySubtreeRemoved(*this);
        MarkStyleStateDirty(StateLeaving);
        Invalidate();
        // A sheet plays the exit: in a GUI no style pass runs over, or not styled itself (a sheet
        // styles widgets), it has none, and goes at the GUI's next drain (never inside the event
        // that sent it away).
        if (!GetRootNode()->HasStylePass() || Cast<UIWidget>(this) == nullptr)
            FinishLeaving();
    }

    void Node::FinishLeaving()
    {
        if (!m_leaving || m_leaveQueued)
            return;
        MutationQueue* queue = GetMutationQueue();
        if (queue == nullptr)
        {
            RemoveFromParent();
            return;
        }
        m_leaveQueued = true;
        // Never inside the style pass's walk or an animation's tick: at the GUI's next drain. Still
        // leaving then, it goes (a node removed or taken back meanwhile is not leaving any more).
        RefPtr<Node> self(this);
        queue->Enqueue([self]()
                       {
                           if (self->m_leaving)
                               self->RemoveFromParent();
                       });
    }

    void Node::Enter()
    {
        if (m_leaving || m_parent == nullptr)
            return;
        if (GetEventDispatcher() == nullptr || !GetRootNode()->HasStylePass() || Cast<UIWidget>(this) == nullptr)
        {
            m_enterPhase = 0;
            SendEvent(Event(EventType::Entered, this)); // nothing plays an entrance here
            return;
        }
        m_enterPhase = 1;
        MarkStyleStateDirty(StateEntering);
        Invalidate();
    }

    void Node::MotionSettled()
    {
        // The style pass has not shown its state yet (a transition of before ended first): it
        // tells again once it has.
        if (IsStyleDirty())
            return;
        if (m_leaving)
        {
            FinishLeaving();
            return;
        }
        if (m_enterPhase == 0 || m_enterQueued)
            return;
        const auto advance = [](Node& node)
        {
            if (node.m_enterPhase == 1)
            {
                node.m_enterPhase = 2; // :entering goes: to its own style, through its transitions
                node.MarkStyleStateDirty(StateEntering);
            }
            else if (node.m_enterPhase == 2)
            {
                node.m_enterPhase = 0;
                node.SendEvent(Event(EventType::Entered, &node));
            }
        };
        MutationQueue* queue = GetMutationQueue();
        if (queue == nullptr)
        {
            advance(*this);
            return;
        }
        // Not inside the style pass's walk or an animation's tick: at the GUI's next drain, if the
        // entrance is still at this step then.
        m_enterQueued = true;
        RefPtr<Node> self(this);
        const u8 phase = m_enterPhase;
        queue->Enqueue([self, phase, advance]()
                       {
                           self->m_enterQueued = false;
                           if (self->m_enterPhase == phase)
                               advance(*self);
                       });
    }

    void Node::SetInert(bool inert)
    {
        if (inert == m_inert)
            return;
        m_inert = inert;
        if (inert)
            if (EventDispatcher* dispatcher = GetEventDispatcher())
                dispatcher->NotifySubtreeRemoved(*this); // it holds nothing of the input now
    }

    void Node::NotifyRemovingChild(Node& child)
    {
        if (EventDispatcher* dispatcher = GetEventDispatcher())
            dispatcher->NotifySubtreeRemoved(child);
    }

    bool Node::RouteEvent(Event& event)
    {
        // The path, target first, held for the walk: a handler may remove nodes from it.
        Array<RefPtr<Node>> path(MemoryAllocator());
        for (Node* n = this; n != nullptr; n = n->m_parent)
        {
            path.PushBack(RefPtr<Node>(n));
            if (n->m_routeStop)
                break; // a modal popup: what holds it is inert
        }
        Node* const root = GetRootNode();
        // A node removed from the tree during the walk takes no further part in it.
        const auto inTree = [root](Node& n) { return n.GetRootNode() == root; };
        event.Target = this;
        event.Handled = false;
        event.Phase = EventPhase::Capture;
        for (usize i = path.Size(); i-- > 1;)
        {
            if (!inTree(*path[i]))
                continue;
            path[i]->DeliverRouted(event);
            if (event.Handled)
                return true;
        }
        event.Phase = EventPhase::Target;
        if (inTree(*this))
            DeliverRouted(event);
        event.Phase = EventPhase::Bubble;
        // Past an open popup, its owner and what holds that hear the event in their listeners, not
        // their own handlers: an event in a popup is not one on what opened it (E5).
        bool pastPopup = IsInTopLayer();
        for (usize i = 1; i < path.Size() && !event.Handled; ++i)
        {
            if (inTree(*path[i]))
                path[i]->DeliverRouted(event, !pastPopup);
            pastPopup = pastPopup || path[i]->IsInTopLayer();
        }
        return event.Handled;
    }
}
