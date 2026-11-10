using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Node's and UINode's members that reach the GUI a node is in: its SceneRoot, the root's
// EventDispatcher and its GUIContext (focus, routing, leaving and entering, inert, the bound
// command, a part's style).

extension Node
{
	/// The root of the GUI this node is in, or null when it is in none (a detached subtree:
	/// RootNode gives its topmost node).
	public Sedulous.GUI.SceneRoot SceneRoot => RootNode as Sedulous.GUI.SceneRoot;

	/// Whether access keys are underlined now (while Alt is held, or always as its GUI says).
	public bool AreMnemonicsShown
	{
		get
		{
			let root = SceneRoot;
			return (root != null) && root.EventDispatcher.AreMnemonicsShown;
		}
	}

	/// The GUI this node is in, read as a binding's dependency: the binding reruns when the node
	/// joins or leaves one (a control bound to a command, made by markup before it is attached).
	public Sedulous.GUI.SceneRoot ObserveSceneRoot()
	{
		mSceneRootChanged.Track();
		return SceneRoot;
	}

	/// Focuses this node (through its GUI's dispatcher; nothing in no GUI).
	public void RequestFocus()
	{
		let dispatcher = EventDispatcher;
		if (dispatcher != null)
			dispatcher.FocusNode = this;
	}

	/// Gives the focus up when this node has it.
	public void ReleaseFocus()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher != null) && (dispatcher.FocusNode == this))
			dispatcher.FocusNode = null;
	}

	/// Sends an input event (pointer, wheel, key, text) along its route to this node: down from
	/// the root through the capture listeners, at this node, and back up through each node's own
	/// handler (OnMouseDown and the rest) and its bubble listeners; a handler marking it Handled
	/// ends the route once that node is done. The path is held for the walk, so a handler may
	/// remove nodes on it (one that left the tree is skipped). True when it was handled.
	public bool RouteEvent(Event e)
	{
		// The path, target first, held for the walk: a handler may remove nodes from it.
		let path = scope List<Node>();
		defer
		{
			for (let n in path)
				n.ReleaseRef();
		}
		for (var n = this; n != null; n = n.mParent)
		{
			n.AddRef();
			path.Add(n);
			if (n.mRouteStop)
				break; // a modal popup: what holds it is inert
		}
		// A node removed from the tree during the walk takes no further part in it.
		let root = RootNode;
		e.Target = this;
		e.Handled = false;
		e.Phase = .Capture;
		for (int i = path.Count - 1; i >= 1; i--)
		{
			if (path[i].RootNode != root)
				continue;
			path[i].DeliverRouted(e);
			if (e.Handled)
				return true;
		}
		e.Phase = .Target;
		if (RootNode == root)
			DeliverRouted(e);
		e.Phase = .Bubble;
		// Past an open popup, its owner and what holds that hear the event in their listeners, not
		// their own handlers: an event in a popup is not one on what opened it.
		var pastPopup = InTopLayer;
		for (int i = 1; (i < path.Count) && !e.Handled; i++)
		{
			if (path[i].RootNode == root)
				path[i].DeliverRouted(e, !pastPopup);
			pastPopup = pastPopup || path[i].InTopLayer;
		}
		return e.Handled;
	}

	/// Leaves its parent after its exit plays: at the GUI's next update when nothing plays one (no
	/// style pass, or a node no sheet styles), at once in no GUI.
	public void Leave()
	{
		if (mLeaving || (mParent == null))
			return;
		let dispatcher = EventDispatcher;
		if (dispatcher == null)
		{
			RemoveFromParent(); // in no GUI: nothing to wait for, nothing walking it
			return;
		}
		mLeaving = true;
		if (mEnterPhase != 0)
		{
			mEnterPhase = 0; // an entrance cut short: it leaves from where it is
			MarkStyleStateDirty(StateEntering);
		}
		// Out of input now, as a removed subtree is (hover, press, capture, focus, its popups): a
		// second Back while it fades does not reach it.
		dispatcher.NotifySubtreeRemoved(this);
		MarkStyleStateDirty(StateLeaving);
		Invalidate();
		// A sheet plays the exit: in a GUI no style pass runs over, or not styled itself (a sheet
		// styles widgets), it has none, and goes at the GUI's next drain (never inside the event
		// that sent it away).
		if (!RootNode.HasStylePass || !(this is UIWidget))
			FinishLeaving();
	}

	/// An inert node and what it holds take no pointer, focus, navigation, keys or commands, and
	/// still draw (a game's screen under a blocking one). Made inert, what the dispatcher held in
	/// it lets go, as of a removed subtree: a press held, the hover, the focus, its popups.
	public void SetInert(bool inert)
	{
		if (inert == mInert)
			return;
		mInert = inert;
		if (inert)
		{
			let dispatcher = EventDispatcher;
			if (dispatcher != null)
				dispatcher.NotifySubtreeRemoved(this); // it holds nothing of the input now
		}
	}

	/// The style pass's: what moves it has ended, so it goes (at the next safe point, once).
	public void FinishLeaving()
	{
		if (!mLeaving || mLeaveQueued)
			return;
		let queue = MutationQueue;
		if (queue == null)
		{
			RemoveFromParent();
			return;
		}
		mLeaveQueued = true;
		// Never inside the style pass's walk or an animation's tick: at the GUI's next drain. Still
		// leaving then, it goes (a node removed or taken back meanwhile is not leaving any more).
		let self = this;
		AddRef(); // the deferred step's, let go with it
		queue.Enqueue(new () =>
			{
				if (self.mLeaving)
					self.RemoveFromParent();
			}
			~
			{
				self.ReleaseRef();
			});
	}

	/// Plays its way in: `:entering` while the sheet's entrance runs (a keyframe animation, or
	/// values it starts from, as CSS's @starting-style), until what that started has ended; then
	/// `:entering` goes, the node moves to its own style (through its transitions), and once that
	/// has settled it hears `entered`. Leave cuts an entrance short, leaving from where it is. In
	/// no GUI, in one no style pass runs over, or not styled, it has no entrance and hears
	/// `entered` at once.
	public void Enter()
	{
		if (mLeaving || (mParent == null))
			return;
		if ((EventDispatcher == null) || !RootNode.HasStylePass || !(this is UIWidget))
		{
			mEnterPhase = 0;
			SendEvent(scope Event(.Entered, this)); // nothing plays an entrance here
			return;
		}
		mEnterPhase = 1;
		mEntranceStart = true;
		MarkStyleStateDirty(StateEntering);
		Invalidate();
	}

	/// The style pass's: nothing the sheet started on it waits now. A leaving node goes; an
	/// arriving one takes its entrance's next step (at the GUI's next drain).
	public void MotionSettled()
	{
		// The style pass has not shown its state yet (a transition of before ended first): it
		// tells again once it has.
		if (IsStyleDirty)
			return;
		if (mLeaving)
		{
			FinishLeaving();
			return;
		}
		if ((mEnterPhase == 0) || mEnterQueued)
			return;
		let queue = MutationQueue;
		if (queue == null)
		{
			AdvanceEntrance();
			return;
		}
		// Not inside the style pass's walk or an animation's tick: at the GUI's next drain, if the
		// entrance is still at this step then.
		mEnterQueued = true;
		let self = this;
		let phase = mEnterPhase;
		AddRef(); // the deferred step's, let go with it
		queue.Enqueue(new () =>
			{
				self.mEnterQueued = false;
				if (self.mEnterPhase == phase)
					self.AdvanceEntrance();
			}
			~
			{
				self.ReleaseRef();
			});
	}

	/// Runs the bound command along the focus path; false with none, or none ran.
	public bool RunBoundCommand()
	{
		let root = HasCommand ? SceneRoot : null;
		return (root != null) && root.RunCommand(Command);
	}

	/// A click at the centre, as activation delivers it (listeners see a click, as with a mouse).
	public bool ActivateAsClick()
	{
		let click = scope MouseEvent(.MouseClick, this, ConvertToWorldSpace(.(mSize.X * 0.5f, mSize.Y * 0.5f)));
		RouteEvent(click);
		return true;
	}

	// An entrance's next step: `:entering` goes, to its own style through its transitions; or,
	// that settled, it hears `entered`.
	private void AdvanceEntrance()
	{
		if (mEnterPhase == 1)
		{
			mEnterPhase = 2;
			MarkStyleStateDirty(StateEntering);
		}
		else if (mEnterPhase == 2)
		{
			mEnterPhase = 0;
			SendEvent(scope Event(.Entered, this));
		}
	}

	// Binds this control to command `id` (Command's setter). One binding follows the id, the GUI
	// the control is in, focus, the command's state and its handlers: whichever changes, the
	// control's state follows. A second follows what the control shows of it: its label and icon,
	// and its keys.
	private void BindCommand(StringView id)
	{
		mCommand.Set(id);
		if (mCommandBound)
			return;
		mCommandBound = true;
		Bind(new () =>
			{
				let commandId = scope String(mCommand.Get());
				let root = ObserveSceneRoot();
				if ((commandId.Length == 0) || (root == null))
					return;
				// Availability on the active root's focus path (the window the user is in).
				let available = root.Context.IsCommandAvailable(commandId);
				let command = root.Context.Commands.Find(commandId);
				var state = BoundCommandState();
				state.Available = available;
				state.Checked = (command != null) && command.Checked;
				let reason = scope String(((command != null) && !command.Enabled) ? command.DisabledReason : default);
				state.Reason = reason;
				Observer.Untracked(scope () => { OnBoundCommandState(state); });
			});
		Bind(new () =>
			{
				let commandId = scope String(mCommand.Get());
				let root = ObserveSceneRoot();
				if ((commandId.Length == 0) || (root == null))
					return;
				root.Context.Commands.TrackChanges();
				let command = root.Context.Commands.Find(commandId);
				let label = scope String((command != null) ? command.Label : (StringView)commandId);
				let icon = scope String((command != null) ? command.Icon : default);
				// The keys that run it here: the binding matched in this node's own contexts.
				let contexts = scope List<KeyContextLayer>();
				defer { ClearAndDeleteItems!(contexts); }
				root.KeyContextsAt(this, contexts);
				let shortcut = scope String();
				root.Context.Keymap.ShortcutText(commandId, (Span<KeyContextLayer>)contexts, shortcut);
				Observer.Untracked(scope () => { OnBoundCommandText(label, icon, shortcut); });
			});
	}
}

extension UINode
{
	/// The sheet's style for `part` (an empty one when the sheet styles it not). Borrowed: read
	/// it, never change it.
	public PartStyle GetPartStyle(StringView part)
	{
		for (let p in mPartStyles)
		{
			if (p.Name == part)
				return p.Style;
		}
		return GUIClusterImplDetail.sNoPartStyle;
	}
}

/// What GUIClusterImpl.bf keeps out of the public surface.
internal static class GUIClusterImplDetail
{
	/// The style of a part no sheet styles: one for the process.
	public static PartStyle sNoPartStyle = new .() ~ delete _;
}
