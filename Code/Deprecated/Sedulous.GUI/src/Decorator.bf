using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Base class for controls that wrap a single child element visually.
/// Similar to ContentControl but semantically indicates a visual wrapper
/// rather than content container. Examples: Border, Viewbox.
/// Decorator owns its child and will delete it when replaced or destroyed.
public class Decorator : Control
{
	private UIElement mChild ~ delete _;

	/// The child element being decorated.
	/// Setting a new child will delete the previous child (deferred if attached to context).
	public UIElement Child
	{
		get => mChild;
		set
		{
			if (mChild == value)
				return;

			// Detach and delete old child
			if (mChild != null)
			{
				let oldChild = mChild;
				mChild = null;

				oldChild.SetParent(null);
				if (Context != null)
				{
					// Queue for deferred deletion - MutationQueue will handle unregistration
					Context.MutationQueue.QueueDelete(oldChild);
				}
				else
				{
					// Not attached to context, safe to delete immediately
					delete oldChild;
				}
			}

			mChild = value;

			// Attach new child
			if (mChild != null)
			{
				// If child has a parent, detach from it first
				mChild.DetachFromParent();

				mChild.SetParent(this);
				if (Context != null)
					mChild.OnAttachedToContext(Context);
			}

			InvalidateLayout();
		}
	}

	/// Detaches the child and returns it to the caller.
	/// The caller takes ownership of the returned element.
	public UIElement DetachChild()
	{
		if (mChild == null)
			return null;

		let child = mChild;
		mChild = null;

		child.SetParent(null);
		if (Context != null)
			child.OnDetachedFromContext();

		InvalidateLayout();
		return child;
	}

	/// Whether this decorator has a child.
	public bool HasChild => mChild != null;

	/// Override to support polymorphic child detachment.
	public override UIElement TryDetachChild(UIElement child)
	{
		if (child == mChild)
			return DetachChild();
		return null;
	}

	/// Gets the number of visual children.
	public override int VisualChildCount => mChild != null ? 1 : 0;

	/// Gets a visual child by index.
	public override UIElement GetVisualChild(int index)
	{
		if (index == 0 && mChild != null)
			return mChild;
		return null;
	}

	/// Override to propagate context to child.
	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		if (mChild != null)
			mChild.OnAttachedToContext(context);
	}

	/// Override to propagate context removal to child.
	public override void OnDetachedFromContext()
	{
		if (mChild != null)
			mChild.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	/// Measure: measure child.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mChild == null || mChild.Visibility == .Collapsed)
			return .Zero;

		let childSize = mChild.Measure(constraints);
		return childSize;
	}

	/// Arrange: arrange child within content bounds.
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (mChild != null && mChild.Visibility != .Collapsed)
		{
			mChild.Arrange(contentBounds);
		}
	}

	/// Render: draw background/border then child.
	/// Applies clipping to child if ClipToBounds is true.
	protected override void RenderOverride(DrawContext ctx)
	{
		RenderBackground(ctx);

		if (mChild != null)
		{
			if (ClipToBounds)
				ctx.PushClipRect(ContentBounds);

			mChild.Render(ctx);

			if (ClipToBounds)
				ctx.PopClip();
		}
	}

	/// Hit test: test child first, then self.
	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		if (mChild != null)
		{
			let hit = mChild.HitTest(point);
			if (hit != null)
				return hit;
		}

		return IsHitTestVisible ? this : null;
	}

	/// Whether focus is within this decorator or its child.
	public override bool IsFocusWithin
	{
		get
		{
			if (IsFocused)
				return true;
			if (let control = mChild as Control)
				return control.IsFocusWithin;
			return false;
		}
	}
}
