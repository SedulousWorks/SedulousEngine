using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A modal dialog: a title, some content, and a row of buttons, shown centred over everything.
///
/// The three bands are a vertical flex inside the dialog rather than something the dialog lays
/// out itself, so content between the title and the buttons behaves like content anywhere else.
class Dialog : ViewGroup
{
	private const float TitleHeight = 24.0f;
	private const float ButtonRowHeight = 36.0f;
	/// A dialog never takes more than this share of the viewport, whatever its Max says.
	private const float ViewportShare = 0.8f;

	public String Title = new .() ~ delete _;
	public DialogResult Result = .None;
	public Event<delegate void(Dialog, DialogResult)> OnClosed ~ _.Dispose();

	public Property<float> MinWidth = new .(250.0f) ~ delete _;
	public Property<float> MinHeight = new .(120.0f) ~ delete _;
	public Property<float> MaxWidth = new .(400.0f) ~ delete _;
	public Property<float> MaxHeight = new .(300.0f) ~ delete _;

	/// OWNED, and a VISUAL child: the dialog's own chrome, not part of its content.
	private FlexLayout mLayout;
	/// BORROWED; held by the layout.
	private Label mTitleLabel;
	/// BORROWED, but see SetContent: the row is detached and re-added, and our RemoveView drops
	/// the tree's reference, so it is pinned across that window.
	private FlexLayout mButtonRow;
	private View mContent = null;

	public this(StringView title)
	{
		ClipsContent = true;
		// Focusable but NOT a tab stop, so a dialog with no focusable content can still hold
		// keyboard focus and answer Escape the moment it opens.
		IsFocusable = true;

		MinWidth.SetOwner(this);
		MinHeight.SetOwner(this);
		MaxWidth.SetOwner(this);
		MaxHeight.SetOwner(this);
		Title.Set(title);

		mLayout = new FlexLayout();
		mLayout.Direction = .Vertical;
		mLayout.Spacing = 10;
		mLayout.Padding = .(12, 10);
		mLayout.Parent = this;

		mTitleLabel = new Label(title);
		var titleStyle = LayoutStyle();
		titleStyle.Width = SizeSpec.Match();
		titleStyle.Height = SizeSpec.Fixed(Unit.Dp(TitleHeight));
		mLayout.AddView(mTitleLabel, titleStyle);

		mButtonRow = new FlexLayout();
		mButtonRow.Direction = .Horizontal;
		mButtonRow.Spacing = 8;
		// Right aligned, which is where a dialog's buttons belong.
		mButtonRow.JustifyContent = .End;
		mLayout.AddView(mButtonRow, ButtonRowStyle());
	}

	public ~this()
	{
		if (mLayout.Context != null)
			mLayout.Context.DetachView(mLayout);

		mLayout.Parent = null;
		mLayout.ReleaseRef();
	}

	/// Borrowed; null until content is set.
	public View Content => mContent;
	/// Borrowed.
	public FlexLayout ButtonRow => mButtonRow;

	// ---- Building ---------------------------------------------------------------------------

	/// Sets the body, between the title and the buttons. CONSUMES the caller's reference.
	public void SetContent(View content)
	{
		if (mContent != null)
			mLayout.RemoveView(mContent);

		mContent = content;

		// The button row is taken out and put back so the content lands BEFORE it. AddRef
		// across the gap, because RemoveView drops the tree's reference and the row would
		// otherwise be freed between the two calls.
		mButtonRow.AddRef();
		mLayout.RemoveView(mButtonRow);

		var contentStyle = LayoutStyle();
		contentStyle.Width = SizeSpec.Match();
		// The content takes the slack, so the title and buttons keep their heights.
		contentStyle.FlexGrow = 1;
		mLayout.AddView(content, contentStyle);

		mLayout.AddView(mButtonRow, ButtonRowStyle());
	}

	private static LayoutStyle ButtonRowStyle()
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(ButtonRowHeight));
		return style;
	}

	/// Adds a button, and answers it borrowed so a caller can wire more to it.
	///
	/// A result of None makes the button CALLER MANAGED: clicking it does not close the
	/// dialog, so a validation failure can keep it up. Any other result closes with it.
	public Button AddButton(StringView text, DialogResult result)
	{
		let button = new Button(text);

		if (result != .None)
			button.OnClick.Add(new [=](b) => { Close(result); });

		mButtonRow.AddView(button);
		return button;
	}

	// ---- Showing ----------------------------------------------------------------------------

	/// Shows the dialog centred and modal.
	///
	/// CONSUMES the caller's reference when ownsView, which is the usual case: from then on the
	/// layer holds the dialog and closing destroys it.
	public void Show(UIContext context, bool ownsView = true)
	{
		let root = context.ActiveInputRoot;
		if (root == null)
			return;

		// Shown at the origin FIRST, so the dialog is attached to the context and can resolve
		// fonts; only then can it be measured, and only then is there a size to centre.
		if (!ownsView)
			AddRef();

		root.GetPopupLayer().ShowPopup(this, null, 0, 0, false, true, ownsView);

		let logical = root.LogicalSize;
		let maxWidth = Min(MaxWidth.Value, logical.X * ViewportShare);
		let maxHeight = Min(MaxHeight.Value, logical.Y * ViewportShare);
		Measure(BoxConstraints(MinWidth.Value, maxWidth, MinHeight.Value, maxHeight));

		let width = MeasuredSize.X;
		let height = MeasuredSize.Y;
		let x = (logical.X - width) * 0.5f;
		let y = (logical.Y - height) * 0.5f;

		Layout(x, y, width, height);
		root.GetPopupLayer().UpdatePopupPosition(this, x, y);

		// The first focusable child, usually the first button, else the dialog itself. Either
		// way Escape and Return work without a click first, and Tab starts inside the dialog.
		let focus = context.GetFocusManager();
		if (!focus.FocusFirstIn(this))
			focus.SetFocus(this);
	}

	/// Closes with a result. A result of None leaves whatever the dialog already had.
	public void Close(DialogResult result = .None)
	{
		if (result != .None)
			Result = result;

		// Reported BEFORE the close is queued, so a handler reads the result while the dialog
		// is still alive and can still be asked about its content.
		OnClosed(this, Result);

		let context = Context;
		if (context == null)
			return;

		// QUEUED: a close commonly runs from a button's own click handling, and tearing the
		// dialog down mid dispatch would pull the ground out from under it.
		context.MutationQueue.QueueAction(new [=]() =>
			{
				if (let root = context.ActiveInputRoot)
					root.GetPopupLayer().ClosePopup(this);
			});
	}

	// ---- Factories --------------------------------------------------------------------------

	/// A message and an OK button. OWNERSHIP transfers.
	public static Dialog Alert(StringView title, StringView message)
	{
		let dialog = new Dialog(title);
		dialog.SetContent(WrappedMessage(message));
		dialog.AddButton("OK", .OK);
		return dialog;
	}

	/// A message with OK and Cancel. OWNERSHIP transfers.
	public static Dialog Confirm(StringView title, StringView message)
	{
		let dialog = new Dialog(title);
		dialog.SetContent(WrappedMessage(message));
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		return dialog;
	}

	/// Wrapped, so a long message grows the dialog downward rather than running off the side.
	private static Label WrappedMessage(StringView message)
	{
		let label = new Label(message);
		label.WordWrap.Value = true;
		return label;
	}

	// ---- Input ------------------------------------------------------------------------------

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Key != .Escape)
			return;

		// Escape is a CANCEL, not a bare close: dismissing without choosing is a decision.
		Close(.Cancel);
		e.Handled = true;
	}

	// ---- Layout and draw --------------------------------------------------------------------

	public override int VisualChildCount => 1;

	public override View GetVisualChild(int index) => (index == 0) ? mLayout : null;

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// The dialog's own bounds, intersected with whatever it was given.
		let minWidth = Max(MinWidth.Value, constraints.MinWidth);
		let maxWidth = Min((MaxWidth.Value > 0) ? MaxWidth.Value : FloatMax, constraints.MaxWidth);
		let minHeight = Max(MinHeight.Value, constraints.MinHeight);
		let maxHeight = Min((MaxHeight.Value > 0) ? MaxHeight.Value : FloatMax, constraints.MaxHeight);

		// Measured with UNBOUNDED height first, so text finds its natural wrapped size rather
		// than being squeezed into a guess.
		mLayout.Measure(.(0, maxWidth, 0, FloatMax));

		let width = Clamp(mLayout.MeasuredSize.X, minWidth, maxWidth);
		let height = Clamp(mLayout.MeasuredSize.Y, minHeight, maxHeight);

		// If the clamp moved the height, the content must be measured again against the height
		// it will actually get, or a growing child distributes the wrong slack.
		if (height != mLayout.MeasuredSize.Y)
			mLayout.Measure(BoxConstraints.Tight(width, height));

		MeasuredSize = .(width, height);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mLayout.Layout(0, 0, width, height);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
		{
			background.Draw(ctx, bounds, GetControlState());
		}
		else
		{
			ctx.VG.FillRoundedRect(bounds, 6.0f, Color(50 / 255.0f, 52 / 255.0f, 62 / 255.0f, 1.0f));
			ctx.VG.StrokeRoundedRect(bounds, 6.0f, Color(80 / 255.0f, 85 / 255.0f, 100 / 255.0f, 1.0f), 1.0f);
		}

		DrawChildren(ctx);
	}
}
