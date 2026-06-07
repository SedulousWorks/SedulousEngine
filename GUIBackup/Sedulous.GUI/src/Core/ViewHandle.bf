namespace Sedulous.GUI;

using System;
using System.Collections;

/// Indirection wrapper for safe view references.
///
/// Every View gets a ViewHandle at construction via ViewHandleRegistry.
/// The handle's View field is set to null immediately when the view is
/// deleted. External code holding a ViewHandle can safely check
/// handle.View != null at any point within a frame.
///
/// Convention: ViewHandle is for within-frame fast access. For persistent
/// cross-frame references, use ViewId with context.GetViewById().
/// At frame end, ViewHandleRegistry.PurgeInvalidated() deletes handles
/// whose views have been destroyed.
public class ViewHandle
{
	/// The view this handle refers to, or null if the view has been deleted.
	public View View;

	public this(View view)
	{
		View = view;
	}

	/// Clears the reference. Called immediately when the view is deleted.
	public void Invalidate()
	{
		View = null;
	}

	/// Returns true if the referenced view is still alive.
	public bool IsValid => View != null;
}

/// Static registry that owns all ViewHandles. Handles are created at view
/// construction and purged at frame end when their view has been destroyed.
/// All operations are main-thread only (no locking).
public static class ViewHandleRegistry
{
	private static List<ViewHandle> sHandles = new .() ~ DeleteContainerAndItems!(_);

	/// Creates a new handle for a view and registers it.
	public static ViewHandle Create(View view)
	{
		let handle = new ViewHandle(view);
		sHandles.Add(handle);
		return handle;
	}

	/// Deletes all handles whose views have been destroyed.
	/// Called at frame end after the mutation queue drains.
	public static void PurgeInvalidated()
	{
		for (int i = sHandles.Count - 1; i >= 0; i--)
		{
			if (!sHandles[i].IsValid)
			{
				delete sHandles[i];
				sHandles.RemoveAtFast(i);
			}
		}
	}

	/// Returns the number of live handles (for diagnostics/testing).
	public static int Count => sHandles.Count;
}
