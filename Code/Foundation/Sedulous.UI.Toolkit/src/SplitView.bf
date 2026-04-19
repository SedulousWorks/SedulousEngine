namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Resizable two-pane container with a draggable divider.
public class SplitView : ViewGroup
{
	private View mFirst;
	private View mSecond;
	private float mSplitRatio = 0.5f;
	private bool mDragging;
	private bool mDividerHovered;

	public Orientation Orientation = .Horizontal;
	public float MinPaneSize = 50;

	/// Width/height of the draggable divider area.
	public float DividerSize
	{
		get => Context?.Theme?.GetDimension("SplitView.DividerSize", 6) ?? 6;
	}

	public Event<delegate void(SplitView, float)> OnSplitChanged ~ _.Dispose();

	/// Split ratio (0..1). 0 = first pane collapsed, 1 = second pane collapsed.
	public float SplitRatio
	{
		get => mSplitRatio;
		set
		{
			let clamped = Math.Clamp(value, 0, 1);
			if (mSplitRatio != clamped)
			{
				mSplitRatio = clamped;
				InvalidateLayout();
				OnSplitChanged(this, clamped);
			}
		}
	}

	/// Set the two panes. SplitView takes ownership via AddView.
	public void SetPanes(View first, View second)
	{
		if (mFirst != null) RemoveView(mFirst, true);
		if (mSecond != null) RemoveView(mSecond, true);

		mFirst = first;
		mSecond = second;

		if (first != null) AddView(first);
		if (second != null) AddView(second);

		InvalidateLayout();
	}

	public View FirstPane => mFirst;
	public View SecondPane => mSecond;

	// === Measurement ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		// SplitView fills its parent.
		MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(0));
	}

	// === Layout ===

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let w = right - left;
		let h = bottom - top;
		let divSize = DividerSize;

		if (Orientation == .Horizontal)
		{
			let available = w - divSize;
			var firstW = available * mSplitRatio;
			var secondW = available - firstW;

			// Enforce minimums.
			if (firstW < MinPaneSize && available > MinPaneSize * 2)
			{ firstW = MinPaneSize; secondW = available - firstW; }
			if (secondW < MinPaneSize && available > MinPaneSize * 2)
			{ secondW = MinPaneSize; firstW = available - secondW; }

			if (mFirst != null)
			{
				mFirst.Measure(.Exactly(firstW), .Exactly(h));
				mFirst.Layout(0, 0, firstW, h);
			}
			if (mSecond != null)
			{
				let secondX = firstW + divSize;
				mSecond.Measure(.Exactly(secondW), .Exactly(h));
				mSecond.Layout(secondX, 0, secondW, h);
			}
		}
		else
		{
			let available = h - divSize;
			var firstH = available * mSplitRatio;
			var secondH = available - firstH;

			if (firstH < MinPaneSize && available > MinPaneSize * 2)
			{ firstH = MinPaneSize; secondH = available - firstH; }
			if (secondH < MinPaneSize && available > MinPaneSize * 2)
			{ secondH = MinPaneSize; firstH = available - secondH; }

			if (mFirst != null)
			{
				mFirst.Measure(.Exactly(w), .Exactly(firstH));
				mFirst.Layout(0, 0, w, firstH);
			}
			if (mSecond != null)
			{
				let secondY = firstH + divSize;
				mSecond.Measure(.Exactly(w), .Exactly(secondH));
				mSecond.Layout(0, secondY, w, secondH);
			}
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);

		// Draw divider.
		let divRect = GetDividerRect();
		let divState = (mDividerHovered || mDragging) ? ControlState.Hover : ControlState.Normal;
		if (!ctx.TryDrawDrawable("SplitView.Divider", divRect, divState))
		{
			let divColor = mDividerHovered || mDragging
				? (ctx.Theme?.GetColor("SplitView.DividerHover", .(80, 85, 105, 255)) ?? .(80, 85, 105, 255))
				: (ctx.Theme?.GetColor("SplitView.Divider", .(55, 58, 70, 255)) ?? .(55, 58, 70, 255));
			ctx.VG.FillRect(divRect, divColor);
		}

		// Grip indicator in divider center.
		if (!ctx.TryDrawDrawable("SplitView.Grip", divRect, divState))
		{
			let gripColor = ctx.Theme?.GetColor("SplitView.Grip", .(100, 105, 120, 180)) ?? .(100, 105, 120, 180);
			let cx = divRect.X + divRect.Width * 0.5f;
			let cy = divRect.Y + divRect.Height * 0.5f;
			let dotR = 1.5f;

			if (Orientation == .Horizontal)
			{
				for (int i = -2; i <= 2; i++)
					ctx.VG.FillCircle(.(cx, cy + i * 5), dotR, gripColor);
			}
			else
			{
				for (int i = -2; i <= 2; i++)
					ctx.VG.FillCircle(.(cx + i * 5, cy), dotR, gripColor);
			}
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		if (IsInDivider(e.X, e.Y))
		{
			mDragging = true;
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
		{
			let divSize = DividerSize;
			if (Orientation == .Horizontal)
			{
				let available = Width - divSize;
				if (available > 0)
				{
					let minRatio = (available > MinPaneSize * 2) ? MinPaneSize / available : 0;
					let maxRatio = (available > MinPaneSize * 2) ? 1.0f - MinPaneSize / available : 1;
					SplitRatio = Math.Clamp((e.X - divSize * 0.5f) / available, minRatio, maxRatio);
				}
			}
			else
			{
				let available = Height - divSize;
				if (available > 0)
				{
					let minRatio = (available > MinPaneSize * 2) ? MinPaneSize / available : 0;
					let maxRatio = (available > MinPaneSize * 2) ? 1.0f - MinPaneSize / available : 1;
					SplitRatio = Math.Clamp((e.Y - divSize * 0.5f) / available, minRatio, maxRatio);
				}
			}
		}
		else
		{
			let wasHovered = mDividerHovered;
			mDividerHovered = IsInDivider(e.X, e.Y);
			if (mDividerHovered != wasHovered)
			{
				if (mDividerHovered)
					Cursor = (Orientation == .Horizontal) ? .SizeWE : .SizeNS;
				else
					Cursor = .Default;
			}
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button != .Left || !mDragging) return;
		mDragging = false;
		Context?.FocusManager.ReleaseCapture();
		e.Handled = true;
	}

	public override void OnMouseLeave()
	{
		mDividerHovered = false;
		if (!mDragging) Cursor = .Default;
	}

	// === Internal ===

	private RectangleF GetDividerRect()
	{
		let divSize = DividerSize;
		if (Orientation == .Horizontal)
		{
			let available = Width - divSize;
			let divX = available * mSplitRatio;
			return .(divX, 0, divSize, Height);
		}
		else
		{
			let available = Height - divSize;
			let divY = available * mSplitRatio;
			return .(0, divY, Width, divSize);
		}
	}

	private bool IsInDivider(float x, float y)
	{
		let r = GetDividerRect();
		return x >= r.X && x < r.X + r.Width && y >= r.Y && y < r.Y + r.Height;
	}
}
