namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

public enum DialogResult { None, OK, Cancel }

/// Modal dialog with title, content, and button row.
/// Shown via PopupLayer as a centered modal popup.
public class Dialog : ViewGroup
{
	public String Title ~ delete _;
	public DialogResult Result = .None;
	public Event<delegate void(Dialog, DialogResult)> OnClosed ~ _.Dispose();

	/// Minimum dialog width.
	public Property<float> MinWidth = new .(250) ~ delete _;
	/// Minimum dialog height.
	public Property<float> MinHeight = new .(120) ~ delete _;
	/// Maximum dialog width. Clamped to 80% of viewport if larger.
	public Property<float> MaxWidth = new .(400) ~ delete _;
	/// Maximum dialog height. Clamped to 80% of viewport if larger.
	public Property<float> MaxHeight = new .(300) ~ delete _;

	private FlexLayout mLayout ~ delete _;
	private Label mTitleLabel;
	private FlexLayout mButtonRow;
	private View mContent;

	public this(StringView title)
	{
		ClipsContent = true;
		MinWidth.SetOwner(this);
		MinHeight.SetOwner(this);
		MaxWidth.SetOwner(this);
		MaxHeight.SetOwner(this);
		Title = new String(title);

		mLayout = new FlexLayout();
		mLayout.Direction = .Vertical;
		mLayout.Spacing = 10;
		mLayout.Padding = .(12, 10);
		mLayout.Parent = this;

		// Title
		mTitleLabel = new Label(title);
		mLayout.AddView(mTitleLabel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		// Button row (right-aligned)
		mButtonRow = new FlexLayout();
		mButtonRow.Direction = .Horizontal;
		mButtonRow.Spacing = 8;
		mButtonRow.JustifyContent = .End;
		mLayout.AddView(mButtonRow, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(36))
		});
	}

	/// Set the content view (between title and buttons).
	public void SetContent(View content)
	{
		if (mContent != null)
			mLayout.RemoveView(mContent, true);

		mContent = content;
		mLayout.RemoveView(mButtonRow, false);
		mLayout.AddView(content, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});
		mLayout.AddView(mButtonRow, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(36))
		});
	}

	/// Add a button to the button row.
	public Button AddButton(StringView text, DialogResult result)
	{
		let btn = new Button(text);
		let dialogResult = result;
		btn.OnClick.Add(new (b) =>
		{
			Close(dialogResult);
		});
		mButtonRow.AddView(btn);
		return btn;
	}

	/// Show as a centered modal dialog.
	public void Show(UIContext ctx, bool ownsView = true)
	{
		let root = ctx.ActiveInputRoot;
		if (root == null) return;

		// Show at (0,0) first so dialog gets context-attached for measurement.
		// AttachView now recurses through VisualChildren, so the internal
		// FlexLayout and its buttons get attached automatically.
		root.PopupLayer.ShowPopup(this, null, 0, 0,
			closeOnClickOutside: false, isModal: true, ownsView: ownsView);

		// Now measure with context available, then reposition to center.
		// Use logical coordinates (physical / DpiScale) to match layout space.
		let dpi = Math.Max(root.DpiScale, 0.01f);
		let viewportW = root.ViewportSize.X / dpi;
		let viewportH = root.ViewportSize.Y / dpi;
		let maxW = Math.Min(MaxWidth.Value, viewportW * 0.8f);
		let maxH = Math.Min(MaxHeight.Value, viewportH * 0.8f);
		Measure(BoxConstraints(MinWidth.Value, maxW, MinHeight.Value, maxH));

		let finalW = MeasuredSize.X;
		let finalH = MeasuredSize.Y;

		let x = (viewportW - finalW) * 0.5f;
		let y = (viewportH - finalH) * 0.5f;

		Layout(x, y, finalW, finalH);
		root.PopupLayer.UpdatePopupPosition(this, x, y);
	}

	/// Close the dialog with a result. Deferred via MutationQueue.
	public void Close(DialogResult result = .None)
	{
		if (result != .None)
			Result = result;
		OnClosed(this, Result);
		let ctx = Context;
		if (ctx != null)
			ctx.MutationQueue.QueueAction(new () => {
				ctx.ActiveInputRoot?.PopupLayer.ClosePopup(this);
			});
	}

	// === Visual children: the internal layout ===

	public override int VisualChildCount => 1;
	public override View GetVisualChild(int index) => (index == 0) ? mLayout : null;

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// Apply Dialog's own min/max, then intersect with input constraints.
		let effMinW = Math.Max(MinWidth.Value, constraints.MinWidth);
		let effMaxW = Math.Min(MaxWidth.Value > 0 ? MaxWidth.Value : float.MaxValue, constraints.MaxWidth);
		let effMinH = Math.Max(MinHeight.Value, constraints.MinHeight);
		let effMaxH = Math.Min(MaxHeight.Value > 0 ? MaxHeight.Value : float.MaxValue, constraints.MaxHeight);

		// First pass: measure with unconstrained height so simple content
		// (text labels) wraps to its natural size.
		let inner = BoxConstraints(0, effMaxW, 0, float.MaxValue);
		mLayout.Measure(inner);

		// Clamp to [min, max].
		let finalW = Math.Clamp(mLayout.MeasuredSize.X, effMinW, effMaxW);
		let finalH = Math.Clamp(mLayout.MeasuredSize.Y, effMinH, effMaxH);

		// Second pass: if height was clamped (content was larger or smaller
		// than bounds), re-measure with the final bounded height so Grow
		// children (e.g., SplitView) distribute space correctly.
		if (finalH != mLayout.MeasuredSize.Y)
			mLayout.Measure(BoxConstraints(finalW, finalW, finalH, finalH));

		MeasuredSize = .(finalW, finalH);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mLayout.Layout(0, 0, width, height);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let bg = ResolveStyleDrawable(.Background);
		if (bg != null)
			bg.Draw(ctx, bounds, GetControlState());
		else
		{
			ctx.VG.FillRoundedRect(bounds, 6, .(50, 52, 62, 255));
			ctx.VG.StrokeRoundedRect(bounds, 6, .(80, 85, 100, 255), 1);
		}
		DrawChildren(ctx);
	}

	// === Escape to close ===

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Key == .Escape)
		{
			Close(.Cancel);
			e.Handled = true;
		}
	}

	// === Static factories ===

	/// Create a simple alert dialog with an OK button.
	public static Dialog Alert(StringView title, StringView message)
	{
		let dialog = new Dialog(title);
		let label = new Label(message);
		dialog.SetContent(label);
		dialog.AddButton("OK", .OK);
		return dialog;
	}

	/// Create a confirm dialog with OK and Cancel buttons.
	public static Dialog Confirm(StringView title, StringView message)
	{
		let dialog = new Dialog(title);
		let label = new Label(message);
		dialog.SetContent(label);
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		return dialog;
	}
}
