using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Base class for controls that display a single piece of content.
/// The Content property can be a UIElement or will be converted to text.
/// ContentControl owns its content and will delete it when replaced or when destroyed.
public class ContentControl : Control
{
	private UIElement mContent ~ delete _;

	/// The content of this control.
	/// Setting a new content will delete the previous content (deferred if attached to context).
	public UIElement Content
	{
		get => mContent;
		set
		{
			if (mContent == value)
				return;

			// Detach and delete old content
			if (mContent != null)
			{
				let oldContent = mContent;
				mContent = null;

				oldContent.SetParent(null);
				if (Context != null)
				{
					// Queue for deferred deletion - MutationQueue will handle unregistration
					Context.MutationQueue.QueueDelete(oldContent);
				}
				else
				{
					// Not attached to context, safe to delete immediately
					delete oldContent;
				}
			}

			mContent = value;

			// Attach new content
			if (mContent != null)
			{
				// If content has a parent, detach from it first
				mContent.DetachFromParent();

				mContent.SetParent(this);
				if (Context != null)
					mContent.OnAttachedToContext(Context);
			}

			InvalidateLayout();
		}
	}

	/// Detaches the content and returns it to the caller.
	/// The caller takes ownership of the returned element.
	public UIElement DetachContent()
	{
		if (mContent == null)
			return null;

		let content = mContent;
		mContent = null;

		content.SetParent(null);
		if (Context != null)
			content.OnDetachedFromContext();

		InvalidateLayout();
		return content;
	}

	/// Whether this control has content.
	public bool HasContent => mContent != null;

	/// Override to support polymorphic child detachment.
	public override UIElement TryDetachChild(UIElement child)
	{
		if (child == mContent)
			return DetachContent();
		return null;
	}

	/// Gets the number of visual children.
	public override int VisualChildCount => mContent != null ? 1 : 0;

	/// Gets a visual child by index.
	public override UIElement GetVisualChild(int index)
	{
		if (index == 0 && mContent != null)
			return mContent;
		return null;
	}

	/// Override to propagate context to content.
	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		if (mContent != null)
			mContent.OnAttachedToContext(context);
	}

	/// Override to propagate context removal to content.
	public override void OnDetachedFromContext()
	{
		if (mContent != null)
			mContent.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	/// Measure: measure content and add padding/border.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mContent == null || mContent.Visibility == .Collapsed)
			return .Zero;

		let contentSize = mContent.Measure(constraints);
		return contentSize;
	}

	/// Arrange: arrange content within content bounds.
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (mContent != null && mContent.Visibility != .Collapsed)
		{
			mContent.Arrange(contentBounds);
		}
	}

	/// Render: draw background/border then content.
	protected override void RenderOverride(DrawContext ctx)
	{
		RenderBackground(ctx);

		if (mContent != null)
			mContent.Render(ctx);
	}

	/// Hit test: check bounds and return self (content is part of this control).
	/// Content is considered visual decoration, not a separate interactive element.
	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Content is part of this control - return self, not the content
		return IsHitTestVisible ? this : null;
	}

	/// Whether focus is within this control or its content.
	public override bool IsFocusWithin
	{
		get
		{
			if (IsFocused)
				return true;
			if (let control = mContent as Control)
				return control.IsFocusWithin;
			return false;
		}
	}
}
