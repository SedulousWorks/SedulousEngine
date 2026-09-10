using System;
using System.Diagnostics;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A view that holds children.
///
/// A child is OWNED by its parent: AddView takes the caller's reference and RemoveView drops
/// it, so dropping a group frees the subtree beneath it.
class ViewGroup : View
{
	public Thickness Padding = .();

	/// OWNED: the tree holds a reference to each child.
	private List<View> mChildren = new .() ~ ReleaseChildren(_);

	public this() {}

	public ~this()
	{
		// A destroyed group must not leave a child pointing back at it. RemoveView clears the
		// back pointer for children it detaches, but destruction just releases the array, so a
		// child still held elsewhere would keep a dangling Parent and the next AddView would
		// dereference freed memory trying to detach it from the old one.
		//
		// The context detach matters for the same reason: a still attached subtree destroyed
		// by dropping its owning reference would leave the registry and the focus and hover
		// tables holding views that have gone.
		for (let child in mChildren)
		{
			if (child == null)
				continue;
			if (child.Context != null)
				child.Context.DetachView(child);
			if (child.Parent == this)
				child.Parent = null;
		}
	}

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

	// ---- Mutation ------------------------------------------------------------------------------

	/// Mutating the tree while it is being DRAWN corrupts the child walk in progress. Doing so
	/// during LAYOUT is legitimate, since that is where a virtualised list realises its rows.
	/// A draw phase mutation should go through the context's mutation queue.
	private void AssertNotDrawing()
	{
		Debug.Assert((Context == null) || (Context.CurrentPhase != .Drawing),
			"mutate the view tree outside the draw phase, or defer it through the mutation queue");
	}

	/// Adds a child, keeping its current layout style. CONSUMES the caller's reference.
	public virtual ViewGroup AddView(View child)
	{
		AssertNotDrawing();
		if ((child == null) || (child == this))
			return this;
		if (mChildren.Contains(child))
			return this;

		if (let oldParent = child.Parent as ViewGroup)
			oldParent.RemoveView(child);

		child.Parent = this;
		if (Context != null)
			Context.AttachView(child);
		else
			child.Context = null;

		mChildren.Add(child);
		Invalidate();
		return this;
	}

	/// Adds a child and sets its layout in one step. CONSUMES the caller's reference.
	public ViewGroup AddView(View child, LayoutStyle layout)
	{
		if (child != null)
			child.SetLayout(layout);
		return AddView(child);
	}

	/// Removes a child, releasing the tree's reference, which frees it unless something else
	/// holds one.
	public void RemoveView(View child)
	{
		AssertNotDrawing();
		if (child == null)
			return;

		for (int i < mChildren.Count)
		{
			if (mChildren[i] != child)
				continue;

			if (child.Context != null)
				child.Context.DetachView(child);
			child.Parent = null;
			mChildren.RemoveAt(i);
			Invalidate();
			// Released LAST, so the detach and the back pointer clear above run while the
			// view is certainly still alive.
			child.ReleaseRef();
			return;
		}
	}

	public void RemoveAllViews()
	{
		AssertNotDrawing();
		for (let child in mChildren)
		{
			if (child.Context != null)
				child.Context.DetachView(child);
			child.Parent = null;
			child.ReleaseRef();
		}
		mChildren.Clear();
		Invalidate();
	}

	/// CONSUMES the caller's reference. The index is clamped to the end.
	public void InsertView(View child, int index)
	{
		AssertNotDrawing();
		if ((child == null) || (child == this))
			return;
		if (mChildren.Contains(child))
			return;

		if (let oldParent = child.Parent as ViewGroup)
			oldParent.RemoveView(child);

		child.Parent = this;
		if (Context != null)
			Context.AttachView(child);
		else
			child.Context = null;

		mChildren.Insert(Math.Min(index, mChildren.Count), child);
		Invalidate();
	}

	/// CONSUMES the caller's reference.
	public void InsertView(View child, int index, LayoutStyle layout)
	{
		if (child != null)
			child.SetLayout(layout);
		InsertView(child, index);
	}

	/// Moves an EXISTING child to a new index, a pure reorder with no detach and reattach, so
	/// focus, hover and registration all survive it.
	public void MoveView(View child, int index)
	{
		if ((child == null) || mChildren.IsEmpty)
			return;

		// The order decides which child :first-child and :last-child match.
		if (Context != null)
			Context.InvalidateStyles();

		let current = mChildren.IndexOf(child);
		if (current < 0)
			return;

		let target = (index >= mChildren.Count) ? (mChildren.Count - 1) : Math.Max(index, 0);
		if (target == current)
			return;

		mChildren.RemoveAt(current);
		// Inserting at `target` AFTER the removal lands the child at exactly `target` whichever
		// direction it moved, the removal having already shifted the trailing entries.
		mChildren.Insert(target, child);
		Invalidate();
	}
}
