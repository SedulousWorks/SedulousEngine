using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Engine.UI;

/// One canvas's host inside a scene's root: what carries its order and its scaler.
///
/// NEVER hit testable itself. It is a placement wrapper, and a wrapper that swallowed clicks
/// would shield the canvas it exists to place.
class CanvasHostView : ViewGroup
{
	public int32 Order = 0;
	/// Swept by the canvas sync when the component behind it has gone.
	public bool Seen = false;
	public CanvasScalerMode ScalerMode = .ConstantPixel;
	public Float2 ReferenceResolution = .(0.0f, 0.0f);

	public this()
	{
		IsHitTestVisible = false;
	}

	/// The size the document LAYS OUT at: the reference resolution when scaling, and the
	/// host's own size otherwise.
	public Float2 LayoutSizeFor(float width, float height)
	{
		if ((ScalerMode == .ReferenceResolution) && (ReferenceResolution.X > 0.0f)
			&& (ReferenceResolution.Y > 0.0f))
			return ReferenceResolution;

		return .(width, height);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(constraints.MaxHeight));

		let inner = LayoutSizeFor(MeasuredSize.X, MeasuredSize.Y);
		let childConstraints = BoxConstraints.Tight(inner.X, inner.Y);

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility != .Gone)
				child.Measure(childConstraints);
		}
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let inner = LayoutSizeFor(width, height);

		var scale = 1.0f;
		var offsetX = 0.0f;
		var offsetY = 0.0f;

		if ((inner.X != width) || (inner.Y != height))
		{
			// The standard rule: scaled uniformly to the smaller fit, letterboxed, centred.
			scale = Math.Min(width / inner.X, height / inner.Y);
			offsetX = (width - inner.X * scale) * 0.5f;
			offsetY = (height - inner.Y * scale) * 0.5f;
		}

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone)
				continue;

			child.Layout(offsetX, offsetY, inner.X, inner.Y);
			// Scaled about the TOP LEFT, so the drawn rectangle is the offset plus the scaled
			// content, and hit testing undoes exactly the same transform.
			child.Transform.Scale = .(scale, scale);
			child.Transform.Origin = .(0.0f, 0.0f);
		}
	}

	/// Keeps a scene root's canvas hosts ordered, STABLY for ties, the child sequence being
	/// insertion order between sorts.
	///
	/// Moving is a pure reorder rather than a detach and re-attach, so focus and hover survive
	/// an order change. The targets start at child one because the billboard layer holds
	/// child nought, and the root keeps its popup layer last.
	public static void SortByOrder(RootView root)
	{
		let hosts = scope System.Collections.List<CanvasHostView>();
		for (int i < root.ChildCount)
		{
			if (let host = root.GetChildAt(i) as CanvasHostView)
				hosts.Add(host);
		}

		// A stable insertion sort: equal orders keep the sequence they came in with.
		for (int i = 1; i < hosts.Count; i++)
		{
			let key = hosts[i];
			var j = i;
			while ((j > 0) && (hosts[j - 1].Order > key.Order))
			{
				hosts[j] = hosts[j - 1];
				j--;
			}
			hosts[j] = key;
		}

		for (int i < hosts.Count)
			root.MoveView(hosts[i], 1 + i);
	}
}
