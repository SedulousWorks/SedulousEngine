namespace Sedulous.Engine.Input;

using System;
using System.Collections;
using Sedulous.Shell.Input;

/// Delegate for action callbacks.
delegate void ActionCallback(InputAction action);

/// A named context containing a set of actions.
/// Different contexts can be active for different game states (menu, gameplay, etc.).
class InputContext
{
	/// Context name (e.g., "Gameplay", "Menu", "Dialog").
	public String Name { get; private set; } = new .() ~ delete _;

	/// Whether this context blocks input from lower-priority contexts.
	public bool BlocksInput = false;

	/// Whether this context is currently enabled.
	public bool Enabled = true;

	/// Priority (higher = processed first).
	public int32 Priority = 0;

	private Dictionary<String, InputAction> mActions = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
	private Dictionary<String, ActionCallback> mCallbacks = new .() ~ {
		for (let kv in _)
		{
			delete kv.key;
			delete kv.value;
		}
		delete _;
	};

	public this(StringView name, int32 priority = 0)
	{
		Name.Set(name);
		Priority = priority;
	}

	public ~this()
	{

	}

	/// Registers a new action in this context.
	public InputAction RegisterAction(StringView name)
	{
		let action = new InputAction(name);
		mActions[new String(name)] = action;
		return action;
	}

	/// Gets an action by name.
	public InputAction GetAction(StringView name)
	{
		if (mActions.TryGetValue(scope String(name), let action))
			return action;
		return null;
	}

	/// Checks if an action exists.
	public bool HasAction(StringView name)
	{
		return mActions.ContainsKey(scope String(name));
	}

	/// Removes an action by name.
	public void RemoveAction(StringView name)
	{
		let key = scope String(name);
		if (mActions.TryGetValue(key, let action))
		{
			for (let kv in mActions)
			{
				if (kv.key == key)
				{
					let actualKey = kv.key;
					mActions.Remove(actualKey);
					delete actualKey;
					delete action;
					break;
				}
			}
		}

		// Also remove callback if present
		if (mCallbacks.TryGetValue(key, let callback))
		{
			for (let kv in mCallbacks)
			{
				if (kv.key == key)
				{
					let actualKey = kv.key;
					mCallbacks.Remove(actualKey);
					delete actualKey;
					delete callback;
					break;
				}
			}
		}
	}

	/// Registers a callback for when an action is triggered (WasPressed).
	public void OnAction(StringView actionName, ActionCallback callback)
	{
		let key = scope String(actionName);
		if (mCallbacks.TryGetValue(key, let existing))
		{
			for (let kv in mCallbacks)
			{
				if (kv.key == key)
				{
					let actualKey = kv.key;
					mCallbacks.Remove(actualKey);
					delete actualKey;
					delete existing;
					break;
				}
			}
		}

		mCallbacks[new String(actionName)] = callback;
	}

	/// Removes a callback for an action.
	public void RemoveCallback(StringView actionName)
	{
		let key = scope String(actionName);
		if (mCallbacks.TryGetValue(key, let callback))
		{
			for (let kv in mCallbacks)
			{
				if (kv.key == key)
				{
					let actualKey = kv.key;
					mCallbacks.Remove(actualKey);
					delete actualKey;
					delete callback;
					break;
				}
			}
		}
	}

	/// Updates all actions in this context.
	public void Update(IInputManager input)
	{
		if (!Enabled)
			return;

		for (let action in mActions.Values)
		{
			action.Update(input);

			// Fire callbacks on WasPressed
			if (action.WasPressed)
			{
				if (mCallbacks.TryGetValue(action.Name, let callback))
					callback(action);
			}
		}
	}

	/// Gets the number of actions in this context.
	public int ActionCount => mActions.Count;

	/// Enumerates all action names.
	public Dictionary<String, InputAction>.KeyEnumerator ActionNames => mActions.Keys;

	/// Enumerates all actions.
	public Dictionary<String, InputAction>.ValueEnumerator Actions => mActions.Values;
}
