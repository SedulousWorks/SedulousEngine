using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A titled band with a body that folds away.
///
/// The band is a real child view rather than something drawn here, which is what lets header
/// actions be ordinary children with their own hit testing. Collapsing sets the content to
/// Gone rather than hiding it, so it stops costing layout as well as pixels.
class Expander : ViewGroup
{
	/// The band's MINIMUM height. Oversized actions grow it past this.
	public Property<float> HeaderHeight = new .(28.0f) ~ delete _;
	/// The gap between the band and the content.
	public Property<float> ContentSpacing = new .(4.0f) ~ delete _;
	public Event<delegate void(Expander, bool)> OnExpandedChanged ~ _.Dispose();

	private String mHeaderText = new .() ~ delete _;
	/// BORROWED: both are held as children, so the group's own references are the owning ones.
	private ExpanderHeader mHeader;
	private View mContent = null;
	private bool mIsExpanded = true;

	public this()
	{
		IsFocusable = true;
		HeaderHeight.SetOwner(this);
		ContentSpacing.SetOwner(this);

		mHeader = new ExpanderHeader(this);
		AddView(mHeader);
	}

	public this(StringView headerText) : this()
	{
		mHeaderText.Set(headerText);
	}

	public bool IsExpanded => mIsExpanded;

	public void SetIsExpanded(bool value)
	{
		if (mIsExpanded == value)
			return;

		mIsExpanded = value;
		// GONE rather than Hidden: a collapsed body must not take part in layout either.
		if (mContent != null)
			mContent.Visibility = mIsExpanded ? .Visible : .Gone;

		Invalidate();
		OnExpandedChanged(this, mIsExpanded);
	}

	public void Toggle() => SetIsExpanded(!mIsExpanded);
	public void Expand() => SetIsExpanded(true);
	public void Collapse() => SetIsExpanded(false);

	public StringView HeaderText => mHeaderText;

	public void SetHeaderText(StringView text)
	{
		mHeaderText.Set(text);
		Invalidate();
	}

	/// Borrowed; may be null.
	public View Content => mContent;

	/// Replaces the body, CONSUMING the caller's reference. Null clears.
	public void SetContent(View content)
	{
		if (mContent != null)
			RemoveView(mContent);

		mContent = content;
		if (content != null)
		{
			// Matched to the current state on the way in, so content added to a collapsed
			// expander does not appear until it is opened.
			content.Visibility = mIsExpanded ? .Visible : .Gone;
			AddView(content);
		}
	}

	/// The overload that also places the child; the other keeps whatever placement it carries.
	public void SetContent(View content, LayoutStyle layout)
	{
		if (content != null)
			content.SetLayout(layout);

		SetContent(content);
	}

	/// Right-aligned widgets in the band, a copy or remove button being the usual case. A press
	/// they handle never reaches the toggle.
	public void SetHeaderActions(View actions) => mHeader.SetActions(actions);
	public void SetHeaderActions(View actions, LayoutStyle layout) =>
		mHeader.SetActions(actions, layout);

	/// The band's measured height, which is at least HeaderHeight once it has been measured.
	public float HeaderBandHeight => mHeader.MeasuredSize.Y;

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		switch (e.Key)
		{
		case .Space, .Return:
			Toggle();
			e.Handled = true;
		case .Right:
			// The arrows OPEN and CLOSE rather than toggling, and are left unhandled when
			// there is nothing to do, so Right inside an open expander can move focus on.
			if (!mIsExpanded)
			{
				SetIsExpanded(true);
				e.Handled = true;
			}
		case .Left:
			if (mIsExpanded)
			{
				SetIsExpanded(false);
				e.Handled = true;
			}
		default:
		}
	}

	public override void OnActivate() => Toggle();

	protected override void OnMeasure(BoxConstraints constraints)
	{
		mHeader.Measure(constraints.Loosen());
		let bandHeight = mHeader.MeasuredSize.Y;

		var contentHeight = 0.0f;
		if ((mContent != null) && (mContent.Visibility != .Gone))
		{
			let inner = constraints.Deflate(Padding).Loosen();
			let margin = mContent.Layout.Margin.Value;
			mContent.Measure(inner.Deflate(margin));
			contentHeight = ContentSpacing.Value + mContent.MeasuredSize.Y + margin.TotalVertical;
		}

		MeasuredSize = .(constraints.ConstrainWidth(constraints.BoundedMaxWidth(200.0f)),
			constraints.ConstrainHeight(bandHeight + contentHeight));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// The band spans the full width, ignoring the padding: it is chrome, and a themed
		// header that stopped short of the edges would not read as a band.
		let bandHeight = mHeader.MeasuredSize.Y;
		mHeader.Layout(0, 0, width, bandHeight);

		if ((mContent == null) || (mContent.Visibility == .Gone))
			return;

		let margin = mContent.Layout.Margin.Value;
		let contentTop = bandHeight + ContentSpacing.Value;
		mContent.Layout(margin.Left, contentTop + margin.Top,
			Max(0.0f, width - margin.TotalHorizontal),
			Max(0.0f, height - contentTop - margin.TotalVertical));
	}
}
