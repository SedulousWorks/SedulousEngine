using System;
using System.Collections;

namespace Sedulous.GUI;

/// An event that validates element existence before invoking handlers.
/// Handlers are associated with their owning element, and skipped if the element
/// has been deleted or detached from the context.
public class ElementBoundEvent<TArgs> where TArgs : class
{
	public typealias Handler = delegate void(TArgs args);

	private struct HandlerEntry
	{
		public UIElement Owner;
		public Handler Callback;
	}

	private List<HandlerEntry> mHandlers = new .() ~ delete _;
	private List<HandlerEntry> mToRemove = new .() ~ delete _;
	private bool mInvoking = false;

	/// Adds a handler associated with the specified owner element.
	/// The handler will be skipped during invoke if the owner is no longer valid.
	public void Add(UIElement owner, Handler handler)
	{
		mHandlers.Add(.() { Owner = owner, Callback = handler });
	}

	/// Removes all handlers associated with the specified owner.
	public void Remove(UIElement owner)
	{
		if (mInvoking)
		{
			// Defer removal until after invoke completes
			for (let entry in mHandlers)
			{
				if (entry.Owner == owner)
					mToRemove.Add(entry);
			}
		}
		else
		{
			for (int i = mHandlers.Count - 1; i >= 0; i--)
			{
				if (mHandlers[i].Owner == owner)
					mHandlers.RemoveAt(i);
			}
		}
	}

	/// Removes a specific handler.
	public void Remove(UIElement owner, Handler handler)
	{
		if (mInvoking)
		{
			for (let entry in mHandlers)
			{
				if (entry.Owner == owner && entry.Callback == handler)
				{
					mToRemove.Add(entry);
					break;
				}
			}
		}
		else
		{
			for (int i = mHandlers.Count - 1; i >= 0; i--)
			{
				if (mHandlers[i].Owner == owner && mHandlers[i].Callback == handler)
				{
					mHandlers.RemoveAt(i);
					break;
				}
			}
		}
	}

	/// Invokes all valid handlers with the given arguments.
	/// Handlers whose owner is deleted or detached are skipped.
	public void Invoke(TArgs args)
	{
		if (mHandlers.Count == 0)
			return;

		mInvoking = true;

		for (let entry in mHandlers)
		{
			// Skip if owner is no longer valid
			if (entry.Owner == null)
				continue;
			if (entry.Owner.IsPendingDeletion)
				continue;
			if (entry.Owner.Context == null)
				continue;

			entry.Callback(args);
		}

		mInvoking = false;

		// Process deferred removals
		if (mToRemove.Count > 0)
		{
			for (let entry in mToRemove)
			{
				for (int i = mHandlers.Count - 1; i >= 0; i--)
				{
					if (mHandlers[i].Owner == entry.Owner && mHandlers[i].Callback == entry.Callback)
					{
						mHandlers.RemoveAt(i);
						break;
					}
				}
			}
			mToRemove.Clear();
		}
	}

	/// Clears all handlers.
	public void Clear()
	{
		mHandlers.Clear();
		mToRemove.Clear();
	}

	/// Whether there are any handlers registered.
	public bool HasHandlers => mHandlers.Count > 0;

	/// Number of registered handlers.
	public int Count => mHandlers.Count;
}

/// An event that validates element existence before invoking handlers.
/// Non-generic version for events without arguments.
public class ElementBoundEvent
{
	public typealias Handler = delegate void();

	private struct HandlerEntry
	{
		public UIElement Owner;
		public Handler Callback;
	}

	private List<HandlerEntry> mHandlers = new .() ~ delete _;
	private List<HandlerEntry> mToRemove = new .() ~ delete _;
	private bool mInvoking = false;

	/// Adds a handler associated with the specified owner element.
	public void Add(UIElement owner, Handler handler)
	{
		mHandlers.Add(.() { Owner = owner, Callback = handler });
	}

	/// Removes all handlers associated with the specified owner.
	public void Remove(UIElement owner)
	{
		if (mInvoking)
		{
			for (let entry in mHandlers)
			{
				if (entry.Owner == owner)
					mToRemove.Add(entry);
			}
		}
		else
		{
			for (int i = mHandlers.Count - 1; i >= 0; i--)
			{
				if (mHandlers[i].Owner == owner)
					mHandlers.RemoveAt(i);
			}
		}
	}

	/// Removes a specific handler.
	public void Remove(UIElement owner, Handler handler)
	{
		if (mInvoking)
		{
			for (let entry in mHandlers)
			{
				if (entry.Owner == owner && entry.Callback == handler)
				{
					mToRemove.Add(entry);
					break;
				}
			}
		}
		else
		{
			for (int i = mHandlers.Count - 1; i >= 0; i--)
			{
				if (mHandlers[i].Owner == owner && mHandlers[i].Callback == handler)
				{
					mHandlers.RemoveAt(i);
					break;
				}
			}
		}
	}

	/// Invokes all valid handlers.
	public void Invoke()
	{
		if (mHandlers.Count == 0)
			return;

		mInvoking = true;

		for (let entry in mHandlers)
		{
			// Skip if owner is no longer valid
			if (entry.Owner == null)
				continue;
			if (entry.Owner.IsPendingDeletion)
				continue;
			if (entry.Owner.Context == null)
				continue;

			entry.Callback();
		}

		mInvoking = false;

		// Process deferred removals
		if (mToRemove.Count > 0)
		{
			for (let entry in mToRemove)
			{
				for (int i = mHandlers.Count - 1; i >= 0; i--)
				{
					if (mHandlers[i].Owner == entry.Owner && mHandlers[i].Callback == entry.Callback)
					{
						mHandlers.RemoveAt(i);
						break;
					}
				}
			}
			mToRemove.Clear();
		}
	}

	/// Clears all handlers.
	public void Clear()
	{
		mHandlers.Clear();
		mToRemove.Clear();
	}

	/// Whether there are any handlers registered.
	public bool HasHandlers => mHandlers.Count > 0;

	/// Number of registered handlers.
	public int Count => mHandlers.Count;
}
