using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The editor's keys GENERATED from the action registry.
/// Every action's effective chord (the user's override or the declaration's default) and every
/// alternate chord is bound in the GUI's keymap to a command named by the action's id, and the
/// window's root handles each such command by the registry's Execute: the one funnel, so a chord
/// and a menu click are the same thing. The keymap runs a binding of a focused widget's own
/// context before one with none, so a focused text field keeps Ctrl+Z for its own undo. Bound
/// again on every registry change (a registration, a rebind), the bindings and handlers before
/// taken away first.
class ActionShortcuts
{
	/// An action with a key bound, and its handler's token on the root.
	private struct Handled
	{
		/// The registry's.
		public EditorActionDeclaration Action;
		public uint32 Token;

		public this(EditorActionDeclaration action, uint32 token)
		{
			Action = action;
			Token = token;
		}
	}

	/// BORROWED: the GUI's context owns the keymap, the window the root, the editor context the
	/// registry; all outlive this.
	private Keymap mKeymap;
	private Node mHandler;
	private EditorActionRegistry mActions;
	/// Each action with a key bound, its handler on the root.
	private List<Handled> mHandled = new .() ~ delete _;
	/// How many keys are bound (a chord and an alternate are two).
	private int mBoundCount = 0;
	/// The bindings again when the registry changes.
	private Effect mChanged = null ~ delete _;

	/// The bindings go in `keymap`; `handler` (the window's root, on every focus path) runs them.
	public this(Keymap keymap, Node handler, EditorActionRegistry actions)
	{
		mKeymap = keymap;
		mHandler = handler;
		mActions = actions;
		mChanged = new Effect(new () =>
			{
				mActions.TrackChanges();
				// The registry is all it follows: what binding reads is not recorded, so only a
				// registration or a rebind binds again.
				Observer.Untracked(scope () => { Rebind(); });
			});
	}

	/// The commands run through this object, so its bindings and handlers go with it, and the
	/// registry no longer reaches it.
	public ~this()
	{
		DeleteAndNullify!(mChanged);
		Unbind();
	}

	/// The bindings as the registry answers now.
	public void Rebind()
	{
		Unbind();
		for (let action in mActions.Actions)
		{
			let main = Bind(action, mActions.Shortcut(action.Id));
			let alternate = Bind(action, action.AlternateShortcut);
			if (!main && !alternate)
				continue;
			// Captures the registry, not this: the command needs nothing of this set to run.
			let registry = mActions;
			let token = mHandler.OnCommand(action.Id, new [=registry, =action](command) => { registry.Execute(action.Id).IgnoreError(); });
			mHandled.Add(.(action, token));
		}
	}

	/// How many keys are bound (a chord and an alternate are two).
	public int BoundCount => mBoundCount;

	private bool Bind(EditorActionDeclaration action, EditorShortcut chord)
	{
		if (!chord.IsSet || !mKeymap.Bind(chord.Stroke, action.Id))
			return false;
		mBoundCount++;
		return true;
	}

	private void Unbind()
	{
		// One entry per action: UnbindCommand takes all its keys.
		for (let handled in mHandled)
		{
			mKeymap.UnbindCommand(handled.Action.Id);
			mHandler.RemoveCommandHandler(handled.Token);
		}
		mHandled.Clear();
		mBoundCount = 0;
	}
}
