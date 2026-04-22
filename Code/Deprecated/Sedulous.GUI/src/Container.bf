using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Base class for elements that can contain multiple children.
/// Provides child management with clear ownership semantics.
public abstract class Container : UIElement
{
	private List<UIElement> mChildren = new .() ~ DeleteContainerAndItems!(_);

	/// The children of this container.
	public List<UIElement> Children => mChildren;

	/// Number of children.
	public int ChildCount => mChildren.Count;

	/// Gets a child by index.
	public UIElement GetChild(int index)
	{
		if (index < 0 || index >= mChildren.Count)
			return null;
		return mChildren[index];
	}

	/// Adds a child element. Transfers ownership to this container.
	/// If the element already has a parent, it will be detached first.
	public void AddChild(UIElement child)
	{
		if (child == null)
			return;

		// If child has a parent, detach from it first
		child.DetachFromParent();

		mChildren.Add(child);
		child.SetParent(this);

		// Propagate context if we have one
		if (Context != null)
			child.OnAttachedToContext(Context);

		InvalidateLayout();
	}

	/// Inserts a child at the specified index.
	public void InsertChild(int index, UIElement child)
	{
		if (child == null)
			return;

		// If child has a parent, detach from it first
		child.DetachFromParent();

		mChildren.Insert(Math.Clamp(index, 0, mChildren.Count), child);
		child.SetParent(this);

		// Propagate context if we have one
		if (Context != null)
			child.OnAttachedToContext(Context);

		InvalidateLayout();
	}

	/// Removes a child from this container.
	/// If deleteAfterRemove is true (default), the child will be deleted (deferred if attached to context).
	/// If false, ownership returns to the caller.
	public void RemoveChild(UIElement child, bool deleteAfterRemove = true)
	{
		if (child == null)
			return;

		let index = mChildren.IndexOf(child);
		if (index < 0)
			return;

		mChildren.RemoveAt(index);
		child.SetParent(null);

		if (deleteAfterRemove)
		{
			if (Context != null)
			{
				// Queue for deferred deletion - MutationQueue will handle unregistration
				Context.MutationQueue.QueueDelete(child);
			}
			else
			{
				// Not attached to context, safe to delete immediately
				delete child;
			}
		}
		else
		{
			// Just removing, not deleting - unregister now
			if (Context != null)
				child.OnDetachedFromContext();
		}

		InvalidateLayout();
	}

	/// Removes and returns a child at the specified index.
	/// Ownership is transferred to the caller.
	public UIElement DetachChild(int index)
	{
		if (index < 0 || index >= mChildren.Count)
			return null;

		let child = mChildren[index];
		mChildren.RemoveAt(index);
		child.SetParent(null);

		if (Context != null)
			child.OnDetachedFromContext();

		InvalidateLayout();
		return child;
	}

	/// Removes and returns the specified child.
	/// Ownership is transferred to the caller.
	public UIElement DetachChild(UIElement child)
	{
		if (child == null)
			return null;

		let index = mChildren.IndexOf(child);
		if (index < 0)
			return null;

		return DetachChild(index);
	}

	/// Removes all children from this container.
	/// If deleteAll is true (default), all children will be deleted (deferred if attached to context).
	/// If false, children are just removed (caller doesn't get ownership though).
	public void ClearChildren(bool deleteAll = true)
	{
		for (let child in mChildren)
		{
			child.SetParent(null);
			if (deleteAll)
			{
				if (Context != null)
				{
					// Queue for deferred deletion - MutationQueue will handle unregistration
					Context.MutationQueue.QueueDelete(child);
				}
				else
				{
					// Not attached to context, safe to delete immediately
					delete child;
				}
			}
			else
			{
				// Just removing, not deleting - unregister now
				if (Context != null)
					child.OnDetachedFromContext();
			}
		}
		mChildren.Clear();
		InvalidateLayout();
	}

	/// Override to support polymorphic child detachment.
	public override UIElement TryDetachChild(UIElement child)
	{
		return DetachChild(child);
	}

	/// Override to support polymorphic child addition.
	public override bool TryAddChild(UIElement child)
	{
		AddChild(child);
		return true;
	}

	/// Gets the number of visual children.
	public override int VisualChildCount => mChildren.Count;

	/// Gets a visual child by index.
	public override UIElement GetVisualChild(int index)
	{
		if (index < 0 || index >= mChildren.Count)
			return null;
		return mChildren[index];
	}

	/// Override to propagate context to children.
	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		for (let child in mChildren)
			child.OnAttachedToContext(context);
	}

	/// Override to propagate context removal to children.
	public override void OnDetachedFromContext()
	{
		for (let child in mChildren)
			child.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	/// Default measure: measure all children and return the largest.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float maxWidth = 0;
		float maxHeight = 0;

		for (let child in mChildren)
		{
			if (child.Visibility == .Collapsed)
				continue;

			let childSize = child.Measure(constraints);
			maxWidth = Math.Max(maxWidth, childSize.Width);
			maxHeight = Math.Max(maxHeight, childSize.Height);
		}

		return .(maxWidth, maxHeight);
	}

	/// Default arrange: arrange all children to fill content bounds.
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		for (let child in mChildren)
		{
			if (child.Visibility == .Collapsed)
				continue;

			child.Arrange(contentBounds);
		}
	}

	/// Default render: render all children in order.
	/// Applies clipping if ClipToBounds is true.
	protected override void RenderOverride(DrawContext ctx)
	{
		if (ClipToBounds)
			ctx.PushClipRect(ArrangedBounds);

		for (let child in mChildren)
		{
			child.Render(ctx);
		}

		if (ClipToBounds)
			ctx.PopClip();
	}

	/// Hit test: test children in reverse order (topmost first), then self.
	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		// Transform hit point if this element has a render transform
		var hitPoint = point;

		if (RenderTransform != Matrix.Identity)
		{
			// Calculate the inverse transform to map screen point to local space
			let originX = ArrangedBounds.X + ArrangedBounds.Width * RenderTransformOrigin.X;
			let originY = ArrangedBounds.Y + ArrangedBounds.Height * RenderTransformOrigin.Y;

			let toOrigin = Matrix.CreateTranslation(-originX, -originY, 0);
			let fromOrigin = Matrix.CreateTranslation(originX, originY, 0);
			let fullTransform = toOrigin * RenderTransform * fromOrigin;

			// Try to invert the transform
			Matrix inverseTransform;
			if (Matrix.TryInvert(fullTransform, out inverseTransform))
			{
				let transformed = Vector2.Transform(point, inverseTransform);
				hitPoint = transformed;
			}
		}

		if (!ArrangedBounds.Contains(hitPoint.X, hitPoint.Y))
			return null;

		// Test children in reverse order (topmost first)
		// Pass the transformed point so children can apply their own transforms
		for (int i = mChildren.Count - 1; i >= 0; i--)
		{
			let child = mChildren[i];
			let hit = child.HitTest(hitPoint);
			if (hit != null)
				return hit;
		}

		return IsHitTestVisible ? this : null;
	}
}
