using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// Expander: a header that shows or hides its content, HTML's <details>. Its header is a button
// (the button core's) with a disclosure chevron for its indicator and the expander's `title` for
// its text; activating it toggles `open`, and each change reports `toggle` (a ToggleEvent).
// Expanders of one `name` in one GUI are exclusive, as HTML's are: opening one closes the others.
// Content can be built on first open (a factory), and with `animate` it opens and closes by easing
// its height through a clip. Markup's children are its content.

/// An expander's header: a button whose indicator is the disclosure chevron
/// (`expanderheader::chevron` its colour), pointing down while its expander is open.
[GuiReflect]
class ExpanderHeader : ButtonBase
{
	private bool mOpen = false;

	public this()
	{
		Tag = "expanderheader";
		using (StyleWriteScope(this))
		{
			SetTextAlignment(.Start, .Middle); // its text beside its indicator
		}
		MakeIndicator();
	}

	public void SetOpenShown(bool open)
	{
		mOpen = open;
		let indicator = IndicatorPart;
		if (indicator != null)
			indicator.Invalidate();
	}

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("chevron");
	}

	// A drag resting on a closed header opens its expander.
	protected override bool OnDragHoverOpen(Float2 local)
	{
		if (mOpen)
			return false;
		ActivateAsClick();
		return true;
	}

	protected override Float2 IndicatorSize => .(12.0f, 12.0f);

	protected override void DrawIndicator(DrawContext ctx, Rect area)
	{
		let chevron = GetPartStyle("chevron");
		var color = chevron.HasBackground ? chevron.Box.BackgroundColor : Color(0.80f, 0.84f, 0.90f, 1.0f);
		color.A *= chevron.Opacity;
		DrawDisclosure(ctx, area, mOpen, color, IsRightToLeft);
	}
}

[GuiReflect(true)]
class Expander : UIWidget
{
	/// How long the height takes to ease open or closed.
	private const float cRevealSeconds = 0.18f;

	private ExpanderHeader mHeader ~ _.ReleaseRef();
	private Panel mClip ~ _.ReleaseRef();
	private Panel mContent ~ _.ReleaseRef();
	private String mName = new .() ~ delete _;
	private bool mOpen = false;
	// What bindings reading `open` follow.
	private Observable mOpenChanged = new .() ~ delete _;
	private bool mAnimated = false;
	private bool mAnimating = false;
	private float mReveal = 0.0f;
	private delegate void(Node content) mFactory ~ delete _;
	private delegate void(bool open) mOnToggled ~ delete _;

	public this()
	{
		Tag = "expander";
		AccessRoleName = "group"; // what a screen reader takes it for
		mHeader = new ExpanderHeader();
		mHeader.SetOnClick(new () => { Open = !mOpen; });
		AddChild(mHeader);
		// The content sits in a clip, which an animation sizes; the content keeps its own height.
		mClip = new Panel();
		mClip.ClipChildren = true;
		mClip.Displayed = false;
		AddChild(mClip);
		mContent = new Panel();
		mContent.Tag = "expandercontent"; // a sheet's `expander > * > expandercontent`
		mContent.EditLayoutStyle(scope (s) => { s.Shrink = 0.0f; });
		mClip.AddChild(mContent);
	}

	/// Its header's text.
	[GuiProperty("title", .None, "name")]
	public StringView Title
	{
		get => mHeader.Text;
		set => mHeader.Text = value;
	}

	/// Open, its content shown; each change, the user's or code's, reports `toggle`, as <details>
	/// does. Read, it is a read a binding records.
	[GuiProperty("open", .TwoWay, "expanded")]
	public bool Open
	{
		get
		{
			mOpenChanged.Track();
			return mOpen;
		}
		set => SetOpen(value);
	}

	public void Toggle()
	{
		SetOpen(!mOpen);
	}

	/// Its group's name: expanders of one name in one GUI open one at a time.
	[GuiProperty("name")]
	public StringView Name
	{
		get => mName;
		set => mName.Set(value);
	}

	/// Opens and closes by easing its height (instead of at once).
	[GuiProperty("animate")]
	public bool Animated
	{
		get => mAnimated;
		set => mAnimated = value;
	}

	/// Builds the content the first time it opens (a heavy panel left unbuilt until wanted).
	/// OWNERSHIP of `factory` transfers.
	public void SetContentFactory(delegate void(Node content) factory)
	{
		delete mFactory;
		mFactory = factory;
	}

	/// Each change of `open` (the user's or code's). OWNERSHIP of `callback` transfers.
	public void SetOnToggled(delegate void(bool open) callback)
	{
		delete mOnToggled;
		mOnToggled = callback;
	}

	public ExpanderHeader Header => mHeader;
	/// What holds its content (markup's children go here).
	public Node Content => mContent;
	public override Node ChildHost => mContent;
	/// How far open its height is, 0 to 1 (1 when not animating).
	public float Reveal => mReveal;
	// :checked when open.
	public override uint32 WidgetStates => mOpen ? WidgetStateChecked : WidgetStateNone;

	private void SetOpen(bool open)
	{
		if (open == mOpen)
			return;
		mOpen = open;
		mOpenChanged.Notify();
		mHeader.SetOpenShown(open);
		MarkStyleStateDirty(StateChecked); // `expander:checked` styles an open one
		if (open)
		{
			if (mFactory != null)
			{
				let factory = mFactory;
				mFactory = null;
				factory(mContent);
				delete factory;
			}
			// One of a named group open: the others close.
			if (!mName.IsEmpty)
				CloseNamed(RootNode);
		}
		if (mAnimated && (ActionManager != null))
			AnimateHeight();
		else
		{
			mReveal = open ? 1.0f : 0.0f;
			mClip.EditLayoutStyle(scope (s) => { s.Height = LayoutLength(); });
			mClip.Displayed = open;
		}
		if (mOnToggled != null)
			mOnToggled(open);
		SendEvent(scope ToggleEvent(this, open, .Code));
	}

	private void CloseNamed(Node node)
	{
		for (int i = 0; i < node.ChildCount; i++)
		{
			let child = node.GetChildAt(i);
			if (let other = child as Expander)
			{
				if ((other != this) && other.mOpen && (other.mName == mName))
					other.SetOpen(false);
			}
			CloseNamed(child);
		}
	}

	// The clip's height eases from where it is toward the content's (open) or nothing (closed);
	// open, the clip then gives the content its own height again.
	private void AnimateHeight()
	{
		mClip.Displayed = true;
		if (mAnimating)
			return;
		mAnimating = true;
		let tick = new TickAction(new (elapsed) =>
			{
				let step = (float)elapsed.TotalSeconds / cRevealSeconds;
				mReveal = mOpen ? Math.Min(1.0f, mReveal + step) : Math.Max(0.0f, mReveal - step);
				let eased = mReveal * mReveal * (3.0f - 2.0f * mReveal); // smoothstep
				let full = mContent.Size.Y;
				let done = mOpen ? (mReveal >= 1.0f) : (mReveal <= 0.0f);
				let natural = done && mOpen;
				mClip.EditLayoutStyle(scope (s) => { s.Height = natural ? LayoutLength() : LayoutLength.Px(full * eased); });
				if (!done)
					return true;
				if (!mOpen)
					mClip.Displayed = false;
				mAnimating = false;
				return false;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}
}
