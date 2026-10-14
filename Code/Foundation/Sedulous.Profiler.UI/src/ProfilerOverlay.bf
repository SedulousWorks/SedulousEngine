using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

enum OverlayCorner : uint8
{
	TopRight,
	TopLeft,
	BottomRight,
	BottomLeft
}

/// The in-game overlay: a panel in a corner holding the frame time graph, the frame stats, the
/// longest CPU scopes and GPU passes, and the counters, over whatever it is laid out on. It
/// fills what it is given and takes no pointer input, so the game below plays on.
class ProfilerOverlay : ViewGroup
{
	public const float PanelWidth = 360.0f;
	public const float Padding = 8.0f;
	public const float Gap = 6.0f;
	public const float Margin = 8.0f;

	/// The children, BORROWED: the group holds them.
	private FrameTimeGraph mGraph;
	private FrameStats mStats;
	private TopList mScopes;
	private TopList mPasses;
	private CounterStrip mCounters;
	/// The five above, in panel order.
	private List<ProfilerView> mViews = new .() ~ delete _;
	private OverlayCorner mCorner = .TopRight;
	private Rectangle mPanel;

	public this()
	{
		IsHitTestVisible = false;
		mGraph = new .();
		mStats = new .();
		mScopes = new .(.Scopes, 6);
		mPasses = new .(.GpuPasses, 5);
		mCounters = new .();
		ProfilerView[5] views = .(mGraph, mStats, mScopes, mPasses, mCounters);
		for (let view in views)
		{
			mViews.Add(view);
			AddView(view); // consumes the reference new gave
		}
	}

	/// What every view reads (BORROWED; null shows nothing).
	public IProfileSource Source
	{
		set
		{
			for (let view in mViews)
				view.Source = value;
		}
	}

	/// A new frame: every view recomputes from the source.
	public void Refresh()
	{
		for (let view in mViews)
			view.Refresh();
	}

	public OverlayCorner Corner
	{
		get => mCorner;
		set
		{
			mCorner = value;
			Invalidate();
		}
	}

	/// The panel's bounds in the overlay, from the last layout.
	public Rectangle Panel => mPanel;

	public FrameTimeGraph Graph => mGraph;
	public FrameStats Stats => mStats;
	public TopList Scopes => mScopes;
	public TopList Passes => mPasses;
	public CounterStrip Counters => mCounters;

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRoundedRect(mPanel, 6.0f, mGraph.Palette.Panel);
		DrawChildren(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// It fills what it is given; the panel inside is its views' height.
		let inner = PanelWidth - 2 * Padding;
		for (let view in mViews)
			view.Measure(.(inner, inner, 0.0f, BoxConstraints.Expand().MaxHeight)); // the panel's width
		let width = BoxConstraints.IsBounded(constraints.MaxWidth) ? constraints.MaxWidth : PanelWidth;
		let height = BoxConstraints.IsBounded(constraints.MaxHeight) ? constraints.MaxHeight : PanelHeight;
		MeasuredSize = .(constraints.ConstrainWidth(width), constraints.ConstrainHeight(height));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let panelWidth = Math.Min(PanelWidth, Math.Max(width - 2 * Margin, 0.0f));
		let panelHeight = PanelHeight;
		let right = (mCorner == .TopRight) || (mCorner == .BottomRight);
		let bottom = (mCorner == .BottomRight) || (mCorner == .BottomLeft);
		mPanel = .(right ? Math.Max(width - Margin - panelWidth, 0.0f) : Margin,
			bottom ? Math.Max(height - Margin - panelHeight, 0.0f) : Margin, panelWidth, panelHeight);
		var y = mPanel.Y + Padding;
		for (let view in mViews)
		{
			view.Layout(mPanel.X + Padding, y, panelWidth - 2 * Padding, view.MeasuredSize.Y);
			y += view.MeasuredSize.Y + Gap;
		}
	}

	private float PanelHeight
	{
		get
		{
			var height = 2 * Padding;
			for (let view in mViews)
				height += view.MeasuredSize.Y;
			return height + Gap * (float)(mViews.Count - 1);
		}
	}
}
