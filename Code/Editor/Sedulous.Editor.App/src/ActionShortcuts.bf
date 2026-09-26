using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The global shortcuts GENERATED from the action registry. Every action's effective chord
/// (the user's override or the declaration's default) and every alternate chord becomes one
/// global shortcut on the UI ShortcutManager whose callback is the registry's Execute, the one
/// funnel, so a chord and a menu click are the same thing. Globals dispatch AFTER the focused
/// view, and text controls mark their key-downs handled, so a focused textbox keeps Ctrl+Z for
/// its own undo. Rebuilt on every registry change (a registration, a rebind), the previous
/// bindings removed first.
class ActionShortcuts
{
	/// BORROWED: the UI context owns the manager, the editor context the registry; both
	/// outlive this.
	private ShortcutManager mShortcuts;
	private EditorActionRegistry mActions;
	/// Owned by the registry's event while subscribed; removed (and deleted) with this.
	private delegate void() mOnActionsChanged;
	/// BORROWED: the manager owns them.
	private List<Shortcut> mBound = new .() ~ delete _;

	public this(ShortcutManager shortcuts, EditorActionRegistry actions)
	{
		mShortcuts = shortcuts;
		mActions = actions;
		mOnActionsChanged = new => Rebind;
		mActions.OnActionsChanged.Add(mOnActionsChanged);
		Rebind();
	}

	public ~this()
	{
		mActions.OnActionsChanged.Remove(mOnActionsChanged, true);
		Unbind();
	}

	/// The bindings as the registry answers now.
	public void Rebind()
	{
		Unbind();
		for (let action in mActions.Actions)
		{
			Bind(action, mActions.Shortcut(action.Id));
			Bind(action, action.AlternateShortcut);
		}
	}

	public int BoundCount => mBound.Count;

	private void Bind(EditorActionDeclaration action, EditorShortcut chord)
	{
		if (!chord.IsSet)
			return;
		let registry = mActions;
		mBound.Add(mShortcuts.AddGlobal(chord.Key, chord.Modifiers, new [=registry, =action]() => { registry.Execute(action.Id).IgnoreError(); }));
	}

	private void Unbind()
	{
		for (let shortcut in mBound)
			mShortcuts.Remove(shortcut);
		mBound.Clear();
	}
}
