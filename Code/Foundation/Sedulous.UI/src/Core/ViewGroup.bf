using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A view that holds children.
///
/// PARTIAL PORT. The child list, padding and the lookups over them are here. The mutation API
/// (AddView, RemoveView, InsertView, MoveView) needs UIContext's AttachView and DetachView,
/// which in turn need the transition machinery and the view id registry, so it stays in the
/// ledger with them. Until then this list is only ever empty.
class ViewGroup : View
{
	public Thickness Padding = .();

	/// OWNED: the tree holds a reference to each child.
	private List<View> mChildren = new .() ~ ReleaseChildren(_);

	public this() {}

	private static void ReleaseChildren(List<View> children)
	{
		for (let child in children)
			child.ReleaseRef();
		delete children;
	}

	public int ChildCount => mChildren.Count;
	public View GetChildAt(int index) => mChildren[index];

	/// The children this group DRAWS, which a control may make differ from the children it
	/// holds: a scroll view's scrollbars are visual children of the view, not content.
	public virtual int VisualChildCount => mChildren.Count;

	public virtual View GetVisualChild(int index) =>
		(index < mChildren.Count) ? mChildren[index] : null;

	/// The box inside the padding, in this group's own coordinates.
	public Rectangle ContentBounds => .(Padding.Left, Padding.Top,
		Max(0.0f, Width - Padding.Left - Padding.Right),
		Max(0.0f, Height - Padding.Top - Padding.Bottom));

	/// A descendant by name, searched depth first. Null when nothing matches.
	public View FindByName(StringView name)
	{
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!child.Name.IsEmpty && (child.Name == name))
				return child;

			if (let childGroup = child as ViewGroup)
			{
				let found = childGroup.FindByName(name);
				if (found != null)
					return found;
			}
		}
		return null;
	}

	/// The same, cast to a type. Null when the name does not match or the match is not a T.
	public T FindByName<T>(StringView name) where T : View => FindByName(name) as T;
}
