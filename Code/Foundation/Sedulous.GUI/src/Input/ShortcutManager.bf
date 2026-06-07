namespace Sedulous.GUI;

using System;
using System.Collections;

/// Manages global and scoped keyboard shortcuts. Owned by UIContext.
/// Dispatch order: focused view key handlers -> ShortcutManager -> IAcceleratorHandler.
public class ShortcutManager
{
	private UIContext mContext;
	private List<Shortcut> mShortcuts = new .();

	public this(UIContext context)
	{
		mContext = context;
	}

	/// Register a shortcut. ShortcutManager takes ownership.
	public void Add(Shortcut shortcut)
	{
		mShortcuts.Add(shortcut);
	}

	/// Register a global shortcut (fires regardless of focus).
	public Shortcut AddGlobal(KeyCode key, KeyModifiers modifiers, delegate void() action)
	{
		let s = new Shortcut(key, modifiers, action);
		mShortcuts.Add(s);
		return s;
	}

	/// Register a scoped shortcut (fires only when scope view or descendant has focus).
	public Shortcut AddScoped(KeyCode key, KeyModifiers modifiers, delegate void() action, View @scope)
	{
		let s = new Shortcut(key, modifiers, action, @scope);
		mShortcuts.Add(s);
		return s;
	}

	/// Remove and delete a shortcut.
	public void Remove(Shortcut shortcut)
	{
		if (mShortcuts.Remove(shortcut))
			delete shortcut;
	}

	/// Remove all shortcuts scoped to a specific view (called when view is deleted).
	public void RemoveScopedTo(View view)
	{
		for (int i = mShortcuts.Count - 1; i >= 0; i--)
		{
			if (mShortcuts[i].Scope === view)
			{
				delete mShortcuts[i];
				mShortcuts.RemoveAtFast(i);
			}
		}
	}

	/// Try to dispatch a key event. Returns true if a shortcut consumed it.
	/// Checks scoped shortcuts first (most specific), then global.
	public bool TryDispatch(KeyCode key, KeyModifiers modifiers)
	{
		let focusedView = mContext.FocusManager?.FocusedView;

		// First pass: scoped shortcuts (only fire if focused view is within scope).
		for (let shortcut in mShortcuts)
		{
			if (!shortcut.IsEnabled || shortcut.Scope == null)
				continue;

			if (!shortcut.Matches(key, modifiers))
				continue;

			if (focusedView != null && IsInScope(focusedView, shortcut.Scope))
			{
				shortcut.Action();
				return true;
			}
		}

		// Second pass: global shortcuts.
		for (let shortcut in mShortcuts)
		{
			if (!shortcut.IsEnabled || shortcut.Scope != null)
				continue;

			if (shortcut.Matches(key, modifiers))
			{
				shortcut.Action();
				return true;
			}
		}

		return false;
	}

	/// Check if a view is the scope view or a descendant of it.
	private bool IsInScope(View view, View @scope)
	{
		var v = view;
		while (v != null)
		{
			if (v === @scope) return true;
			v = v.Parent;
		}
		return false;
	}

	public ~this()
	{
		for (let s in mShortcuts)
			delete s;
		delete mShortcuts;
	}
}
