using System;
using System.Collections;

namespace Sedulous.UI;

/// The global and scoped keyboard shortcuts, owned by the context.
///
/// PARTIAL PORT: registration and removal are here. TryDispatch and its scope test walk the
/// focused view's parent chain and stay in the ledger.
class ShortcutManager
{
	/// BORROWED: the context owns this.
	private UIContext mContext;
	private List<Shortcut> mShortcuts = new .() ~ ReleaseAll(_);

	public this(UIContext context)
	{
		mContext = context;
	}

	private static void ReleaseAll(List<Shortcut> shortcuts)
	{
		for (let shortcut in shortcuts)
			shortcut.ReleaseRef();
		delete shortcuts;
	}

	/// CONSUMES the caller's reference.
	public void Add(Shortcut shortcut) => mShortcuts.Add(shortcut);

	/// Fires whatever has focus. Answers the shortcut BORROWED, the manager owning it.
	public Shortcut AddGlobal(KeyCode key, KeyModifiers modifiers, delegate void() action)
	{
		let shortcut = new Shortcut(key, modifiers, action, null);
		mShortcuts.Add(shortcut);
		return shortcut;
	}

	/// Fires only while `scopeView` or a descendant has focus. Answers it BORROWED.
	public Shortcut AddScoped(KeyCode key, KeyModifiers modifiers, delegate void() action,
		View scopeView)
	{
		let shortcut = new Shortcut(key, modifiers, action, scopeView);
		mShortcuts.Add(shortcut);
		return shortcut;
	}

	public void Remove(Shortcut shortcut)
	{
		for (int i < mShortcuts.Count)
		{
			if (mShortcuts[i] == shortcut)
			{
				mShortcuts[i].ReleaseRef();
				mShortcuts.RemoveAt(i);
				return;
			}
		}
	}

	/// Removes every shortcut scoped to a view, which is what happens when that view goes.
	public void RemoveScopedTo(View view)
	{
		for (int i = mShortcuts.Count - 1; i >= 0; i--)
		{
			if (mShortcuts[i].Scope == view)
			{
				mShortcuts[i].ReleaseRef();
				mShortcuts.RemoveAtFast(i);
			}
		}
	}

	public int Count => mShortcuts.Count;

	/// Runs the first shortcut matching a key, answering whether one did.
	///
	/// SCOPED shortcuts are tried first: a shortcut belonging to the dialog you are in should
	/// beat a global one on the same key, or a text editor's Ctrl+F would be stolen by the
	/// window's.
	public bool TryDispatch(KeyCode key, KeyModifiers modifiers)
	{
		let focused = mContext.GetFocusManager().FocusedView;

		for (let shortcut in mShortcuts)
		{
			if (!shortcut.IsEnabled || (shortcut.Scope == null))
				continue;
			if (!shortcut.Matches(key, modifiers))
				continue;
			if ((focused != null) && IsInScope(focused, shortcut.Scope))
			{
				shortcut.Action();
				return true;
			}
		}

		for (let shortcut in mShortcuts)
		{
			if (!shortcut.IsEnabled || (shortcut.Scope != null))
				continue;
			if (shortcut.Matches(key, modifiers))
			{
				shortcut.Action();
				return true;
			}
		}

		return false;
	}

	/// Whether a view sits inside a scope, itself counting as inside.
	///
	/// Named scopeView because `scope` is a Beef keyword.
	private static bool IsInScope(View view, View scopeView)
	{
		var current = view;
		while (current != null)
		{
			if (current == scopeView)
				return true;
			current = current.Parent;
		}
		return false;
	}
}
