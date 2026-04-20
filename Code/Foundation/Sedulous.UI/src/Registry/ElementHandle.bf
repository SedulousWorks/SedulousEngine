namespace Sedulous.UI;

/// Type-safe weak reference to a View. Resolves through UIContext's
/// element registry - returns null if the view has been destroyed.
public struct ElementHandle<T> where T : View
{
	private ViewId mId;

	public this(ViewId id) { mId = id; }
	public this(T view) { mId = (view != null) ? view.Id : .Invalid; }

	public bool IsValid => mId.IsValid;
	public ViewId Id => mId;

	/// Returns the live view, or null if destroyed or wrong type.
	public T TryResolve(UIContext context)
	{
		if (!mId.IsValid || context == null)
			return null;

		let view = context.GetElementById(mId);
		if (view == null || view.IsPendingDeletion)
			return null;

		return view as T;
	}

	public static ElementHandle<T> Invalid => .(.Invalid);
}
