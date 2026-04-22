using System;

namespace Sedulous.GUI;

/// Safe weak reference to a UI element.
/// Uses ID lookup through GUIContext to avoid dangling pointers.
/// The element may be deleted at any time; always check validity before use.
public struct ElementHandle<T> where T : UIElement
{
	private UIElementId mId;
	private GUIContext mContext;

	/// Creates a handle from an element ID and context.
	public this(UIElementId id, GUIContext context)
	{
		mId = id;
		mContext = context;
	}

	/// The element ID this handle refers to.
	public UIElementId Id => mId;

	/// The context that owns the element.
	public GUIContext Context => mContext;

	/// Attempts to resolve the handle to an element.
	/// Returns null if the element has been deleted or the handle is invalid.
	public T TryResolve()
	{
		if (mContext == null || !mId.IsValid)
			return null;

		let element = mContext.GetElementById(mId);
		if (element == null)
			return null;

		// Check if element is pending deletion
		if (element.IsPendingDeletion)
			return null;

		return element as T;
	}

	/// Returns true if the element is still valid (exists and not pending deletion).
	public bool IsValid => TryResolve() != null;

	/// Creates an invalid/empty handle.
	public static ElementHandle<T> Invalid => .(UIElementId.Invalid, null);

	/// Implicit conversion from element creates handle.
	public static implicit operator ElementHandle<T>(T element)
	{
		if (element == null)
			return Invalid;
		return .(element.Id, element.Context);
	}

	public static bool operator ==(ElementHandle<T> lhs, ElementHandle<T> rhs)
	{
		return lhs.mId == rhs.mId && lhs.mContext == rhs.mContext;
	}

	public static bool operator !=(ElementHandle<T> lhs, ElementHandle<T> rhs)
	{
		return !(lhs == rhs);
	}
}
