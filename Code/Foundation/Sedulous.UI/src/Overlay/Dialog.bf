namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

public enum DialogResult { None, OK, Cancel }

/// Modal dialog with title, content, and button row.
/// Shown via PopupLayer as a modal popup.
public class Dialog : ViewGroup
{
	public String Title ~ delete _;
	public DialogResult Result = .None;
	public Event<delegate void(Dialog, DialogResult)> OnClosed ~ _.Dispose();

	/// Maximum dialog width. Clamped to 80% of viewport if larger.
	public float MaxWidth = 400;
	/// Maximum dialog height. Clamped to 80% of viewport if larger.
	public float MaxHeight = 300;

	private LinearLayout mLayout ~ delete _;
	private Label mTitleLabel;
	private LinearLayout mButtonRow;
	private View mContent;

	public this(StringView title)
	{
		ClipsContent = true;
		Title = new String(title);

		mLayout = new LinearLayout();
		mLayout.Orientation = .Vertical;
		mLayout.Spacing = 10;
		mLayout.Padding = .(12, 10);
		mLayout.Parent = this;

		// Title
		mTitleLabel = new Label();
		mTitleLabel.SetText(title);
		mTitleLabel.StyleId = new String("SectionLabel");
		mLayout.AddView(mTitleLabel, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 24 });

		// Button row (right-aligned).
		mButtonRow = new LinearLayout();
		mButtonRow.Orientation = .Horizontal;
		mButtonRow.Spacing = 8;
		mLayout.AddView(mButtonRow, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 36 });
	}

	/// Set the content view (between title and buttons).
	public void SetContent(View content)
	{
		if (mContent != null)
			mLayout.RemoveView(mContent, true);

		mContent = content;
		// Insert content before the button row - remove it, add content, re-add.
		// Content uses Weight=1 to fill available space between title and buttons,
		// constrained by the dialog's MaxWidth/MaxHeight.
		mLayout.RemoveView(mButtonRow, false);
		mLayout.AddView(content, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 0, Weight = 1 });
		mLayout.AddView(mButtonRow, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 36 });
	}

	/// Add a button to the button row.
	public Button AddButton(StringView text, DialogResult result)
	{
		let btn = new Button();
		btn.SetText(text);
		let dialogResult = result;
		btn.OnClick.Add(new (b) =>
		{
			Close(dialogResult);
		});
		mButtonRow.AddView(btn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
		return btn;
	}

	/// Show as a centered modal dialog. Dialog is owned by PopupLayer
	/// and deleted on close (fire-and-forget for Alert/Confirm usage).
	public void Show(UIContext ctx, bool ownsView = true)
	{
		// Show at (0,0) first so the dialog gets context-attached
		// (needed for font measurement in labels).
		ctx.PopupLayer.ShowPopup(this, null, 0, 0,
			closeOnClickOutside: false, isModal: true, ownsView: ownsView);

		// Now measure with context available, then reposition to center.
		let viewportW = ctx.ActiveInputRoot.ViewportSize.X;
		let viewportH = ctx.ActiveInputRoot.ViewportSize.Y;
		let maxW = Math.Min(MaxWidth, viewportW * 0.8f);
		let maxH = Math.Min(MaxHeight, viewportH * 0.8f);
		Measure(.AtMost(maxW), .AtMost(maxH));

		// Clamp to max bounds in case measure didn't respect AtMost fully
		let finalW = Math.Min(MeasuredSize.X, maxW);
		let finalH = Math.Min(MeasuredSize.Y, maxH);

		let x = (viewportW - finalW) * 0.5f;
		let y = (viewportH - finalH) * 0.5f;

		Layout(x, y, finalW, finalH);
		ctx.PopupLayer.UpdatePopupPosition(this, x, y);
	}

	/// Close the dialog with a result. Deferred via MutationQueue so the close
	/// happens after the current event handler returns (avoids use-after-free
	/// when PopupLayer owns the dialog and deletes it on close).
	public void Close(DialogResult result = .None)
	{
		if (result != .None)
			Result = result;
		OnClosed(this, Result);
		let ctx = Context;
		if (ctx != null)
			ctx.MutationQueue.QueueAction(new () => {
				ctx.PopupLayer?.ClosePopup(this);
			});
	}

	// === Visual children: the internal layout ===

	public override int VisualChildCount => 1;
	public override View GetVisualChild(int index) => (index == 0) ? mLayout : null;

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		// Enforce MaxWidth/MaxHeight as upper bounds on the measure spec,
		// even if the PopupLayer passes a larger AtMost constraint.
		var clampedW = wSpec;
		var clampedH = hSpec;
		if (MaxWidth > 0 && (wSpec.Mode == .AtMost || wSpec.Mode == .Unspecified))
			clampedW = .AtMost(Math.Min(MaxWidth, wSpec.Size));
		if (MaxHeight > 0 && (hSpec.Mode == .AtMost || hSpec.Mode == .Unspecified))
			clampedH = .AtMost(Math.Min(MaxHeight, hSpec.Size));

		mLayout.Measure(clampedW, clampedH);
		MeasuredSize = .(Math.Min(mLayout.MeasuredSize.X, clampedW.Size),
						 Math.Min(mLayout.MeasuredSize.Y, clampedH.Size));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		mLayout.Layout(0, 0, right - left, bottom - top);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		if (!ctx.TryDrawDrawable("Dialog.Background", bounds, GetControlState()))
			ctx.FillThemedBox(bounds, "Dialog",
				defaultBg: .(50, 52, 62, 255), defaultBorder: .(80, 85, 100, 255),
				defaultRadius: 6, defaultBorderWidth: 1);
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
		let label = new Label();
		label.SetText(message);
		dialog.SetContent(label);
		dialog.AddButton("OK", .OK);
		return dialog;
	}

	/// Create a confirm dialog with OK and Cancel buttons.
	public static Dialog Confirm(StringView title, StringView message)
	{
		let dialog = new Dialog(title);
		let label = new Label();
		label.SetText(message);
		dialog.SetContent(label);
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		return dialog;
	}
}
