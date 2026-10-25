using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// ButtonBase: the one button core, after Godot's BaseButton. It activates on a click, Return,
// Space or the pad's South; `toggle` makes it hold a checked state (`:checked`); `action-on="press"`
// activates it on the press instead of the release; `repeat` activates it again while it is held
// (after a delay, at an interval, on the GUI's clock, only while the pointer is over it); a group
// makes its toggles exclusive. A group is a ButtonGroup from code or a `name` in markup, the name's
// scope being the GUI the button is in (two windows' groups of one name never meet). The arrows
// move round an exclusive group, checking as they go, as a browser's radios do.
//
// A button is a container: `text` and an icon are shorthands for parts it makes (a text and an
// image, nodes of their own, which take the button's text style, as Window's title does), and
// markup may put anything inside it. CheckBox, RadioButton and ToggleSwitch are this core with an
// indicator part, a node drawn by the button from its own parts (checkbox::box and ::mark, ...).
//
// A change the user makes reports `change` (and the toggled callback); a state set from code
// reports nothing but to bindings, as a range's value does.

/// When a button activates: on the release over it (a click), or on the press.
enum ButtonAction : uint8
{
	Release,
	Press,
}

/// An exclusive group of toggle buttons from code (markup groups them by a `name`): at most one
/// is checked, and unless it allows none, a click on the checked one leaves it checked. The
/// buttons hold the group, so it outlives them, and each leaves it as it goes.
class ButtonGroup : RefCounted
{
	// Not owned: each leaves as it goes.
	private List<ButtonBase> mButtons = new .() ~ delete _;
	private bool mAllowsNone = false;
	private delegate void(ButtonBase button) mOnChanged ~ delete _;

	/// A click on the checked button unchecks it (Godot's allow_unpress).
	public bool AllowsNone
	{
		get => mAllowsNone;
		set => mAllowsNone = value;
	}

	/// The buttons in it, in the order they joined.
	public Span<ButtonBase> Buttons => mButtons;

	/// The checked one, if any.
	public ButtonBase Checked
	{
		get
		{
			for (let b in mButtons)
			{
				if (b.Checked)
					return b;
			}
			return null;
		}
	}

	/// The user checked `button` (not code's changes). OWNERSHIP of `callback` transfers.
	public void SetOnChanged(delegate void(ButtonBase button) callback)
	{
		delete mOnChanged;
		mOnChanged = callback;
	}

	internal void Join(ButtonBase button)
	{
		mButtons.Add(button);
	}

	internal void Leave(ButtonBase button)
	{
		for (int i = 0; i < mButtons.Count; i++)
		{
			if (mButtons[i] == button)
			{
				mButtons.RemoveAt(i);
				return;
			}
		}
	}

	internal void NotifyChanged(ButtonBase button)
	{
		if (mOnChanged != null)
			mOnChanged(button);
	}
}

// A button's indicator (a check box's box, a radio's ring, a switch's track): a node of its own,
// laid out among the button's children and sized by a sheet as `checkbox > indicator`, drawn
// by its button from the button's parts.
[GuiReflect]
class ButtonIndicator : UIWidget
{
	// Its parent, which owns it.
	private ButtonBase mOwner;

	public this(ButtonBase owner)
	{
		mOwner = owner;
		Tag = "indicator";
		HitTestVisible = false; // a press on it is the button's
	}

	public override Float2 MeasureContent(Float2 available) => mOwner.[Friend]IndicatorSize;

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		mOwner.[Friend]DrawIndicator(ctx, ContentBounds);
	}
}

[GuiReflect, Scriptable]
class ButtonBase : UIWidget
{
	private delegate void() mOnClick ~ delete _;
	private delegate void(bool on) mOnToggled ~ delete _;
	private ButtonGroup mGroup = null;
	private String mName = new .() ~ delete _;
	private Label mTextPart = null ~ _?.ReleaseRef();
	// Its access key, from an `&` in its text.
	private char32 mMnemonic = '\0';
	private Sedulous.GUI.Image mIconPart = null ~ _?.ReleaseRef();
	private ButtonIndicator mIndicator = null ~ _?.ReleaseRef();
	// What bindings reading the state follow.
	private Observable mCheckedChanged = new .() ~ delete _;
	private Observable mTextChanged = new .() ~ delete _;
	private ButtonAction mActionOn = .Release;
	private bool mToggle = false;
	private bool mChecked = false;
	private bool mIndeterminate = false;
	private bool mKeepsChecked = false;
	// Its text is its command's label (OnBoundCommandText).
	private bool mTextFromCommand = false;
	private bool mRepeat = false;
	// Held, repeating.
	private bool mRepeating = false;
	// Its tick is running.
	private bool mRepeatRunning = false;
	private float mRepeatDelay = 0.5f;
	private float mRepeatInterval = 0.08f;
	// Seconds toward the next repeat (below 0: the delay).
	private float mRepeatClock = 0.0f;

	protected this()
	{
		AccessRoleName = "button"; // what a screen reader takes it for
		TabFocusable = true;
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			SetTextAlignment(.Center, .Middle);
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Center;
					s.ColumnGap = 6.0f;
				});
		}
	}

	/// A screen reader may press it.
	public override bool AccessActivates => true;

	public ~this()
	{
		if (mGroup != null)
		{
			mGroup.Leave(this);
			mGroup.ReleaseRef();
			mGroup = null;
		}
	}

	// === Activation ===

	/// Invoked on each activation (a click, a key, a repeat). OWNERSHIP of `callback` transfers.
	public void SetOnClick(delegate void() callback)
	{
		delete mOnClick;
		mOnClick = callback;
	}

	public bool HasOnClick => mOnClick != null;

	public ButtonAction ActionOn
	{
		get => mActionOn;
		set => mActionOn = value;
	}

	/// "release" or "press" (markup's and a sheet's `action-on`).
	[GuiProperty("action-on"), Scriptable]
	public StringView ActionOnName
	{
		get => (mActionOn == .Press) ? "press" : "release";
		set => mActionOn = (value == "press") ? .Press : .Release;
	}

	/// Activates again while held: on the press, then after the delay at the interval.
	[GuiProperty("repeat"), Scriptable]
	public bool Repeat
	{
		get => mRepeat;
		set => mRepeat = value;
	}

	[GuiProperty("repeat-delay"), Scriptable]
	public float RepeatDelay
	{
		get => mRepeatDelay;
		set => mRepeatDelay = Math.Max(0.0f, value);
	}

	[GuiProperty("repeat-interval"), Scriptable]
	public float RepeatInterval
	{
		get => mRepeatInterval;
		set => mRepeatInterval = Math.Max(0.01f, value);
	}

	// === Toggle ===

	/// Whether it holds a checked state (`toggle`): a click checks and unchecks it.
	[GuiProperty("toggle"), Scriptable]
	public bool IsToggle
	{
		get => mToggle;
		set
		{
			if (value == mToggle)
				return;
			mToggle = value;
			if (!mToggle)
				ApplyChecked(false);
		}
	}

	/// Its access key: the character its text marked with `&`.
	public override char32 Mnemonic => mMnemonic;

	/// A checked button that keeps its check (a radio) is its focus group's current member.
	public override bool IsCurrentInGroup => mChecked && KeepsChecked;

	/// Whether it is checked (a read a binding records). Set from code: an exclusive group's others
	/// clear; no events.
	[GuiProperty("checked", .TwoWay), Scriptable]
	public bool Checked
	{
		get
		{
			mCheckedChanged.Track();
			return mChecked;
		}
		set
		{
			if (mToggle || !value)
				ApplyChecked(value);
		}
	}

	/// Toggled by the user (each change the user makes, not code's). OWNERSHIP of `callback`
	/// transfers.
	public void SetOnToggled(delegate void(bool on) callback)
	{
		delete mOnToggled;
		mOnToggled = callback;
	}

	// === Group ===

	/// The group it is in (null: none); a group's toggles are exclusive. It takes a reference of its
	/// own: the caller keeps its.
	public ButtonGroup Group
	{
		get => mGroup;
		set
		{
			if (value == mGroup)
				return;
			if (mGroup != null)
			{
				mGroup.Leave(this);
				mGroup.ReleaseRef();
			}
			mGroup = value;
			if (mGroup != null)
			{
				mGroup.AddRef();
				mGroup.Join(this);
			}
		}
	}

	/// Its group's name in markup (buttons of one name in one GUI are a group).
	[GuiProperty("name"), Scriptable]
	public StringView Name
	{
		get => mName;
		set => mName.Set(value);
	}

	/// The buttons of its group, itself among them, in tree order for a name's (none: ungrouped).
	public void CollectGroup(List<ButtonBase> outGroup)
	{
		if (mGroup != null)
		{
			for (let b in mGroup.Buttons)
				outGroup.Add(b);
			return;
		}
		if (mName.IsEmpty)
			return;
		CollectNamed(RootNode, outGroup);
	}

	// === Content ===

	/// Its text (a part it makes, after its icon; empty: none).
	[GuiProperty("", .Translatable, "name"), Scriptable]
	public StringView Text
	{
		get
		{
			mTextChanged.Track();
			return (mTextPart != null) ? mTextPart.Text : default;
		}
		set
		{
			mTextFromCommand = false;
			ApplyText(value);
		}
	}

	/// Its icon (an image part before its text; null: none). The part takes a reference of its own:
	/// the caller keeps its.
	public void SetIcon(Drawable icon)
	{
		if (icon == null)
		{
			if (mIconPart != null)
			{
				mIconPart.RemoveFromParent();
				mIconPart.ReleaseRef();
				mIconPart = null;
			}
			return;
		}
		EnsureIconPart();
		mIconPart.SetDrawable(icon);
	}

	/// Its icon by path (markup's `icon`), loaded through the GUI's resource provider; empty: none.
	[GuiProperty("icon"), Scriptable]
	public StringView Icon
	{
		get => (mIconPart != null) ? mIconPart.Source : default;
		set
		{
			if (value.IsEmpty)
			{
				SetIcon(null);
				return;
			}
			EnsureIconPart();
			mIconPart.Source = value;
		}
	}

	/// The parts it made (null until it has them).
	public Label TextPart => mTextPart;
	public Sedulous.GUI.Image IconPart => mIconPart;
	public Node IndicatorPart => mIndicator;

	// Markup: <Button text="Save">, its text a part.
	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name == "text")
		{
			Text = value;
			return true;
		}
		return base.SetMarkupAttribute(name, value);
	}

	/// Its text's first baseline (a row aligned by baseline lines buttons up with labels): the
	/// text part sits centred across its content box.
	public override float BaselineAt(Float2 size)
	{
		if ((mTextPart == null) || !mTextPart.Displayed)
			return base.BaselineAt(size);
		let c = Chrome;
		let pc = mTextPart.Chrome;
		// Its arranged height, or before it is arranged, one line's.
		let partH = (mTextPart.Size.Y > 0.0f) ? mTextPart.Size.Y : mTextPart.GetTextLayout().LineHeight + pc.TotalVertical;
		let contentH = Math.Max(0.0f, size.Y - c.TotalVertical);
		return c.Top + (contentH - partH) * 0.5f + mTextPart.BaselineAt(.(mTextPart.Size.X, partH));
	}

	// A button with no text of its own shows its command's label.
	public override void OnBoundCommandText(StringView label, StringView icon, StringView shortcut)
	{
		if ((Text.Length != 0) && !mTextFromCommand)
			return;
		ApplyText(label);
		mTextFromCommand = true;
	}

	public override void OnBoundCommandState(BoundCommandState state)
	{
		Enabled = state.Available;
		if (mToggle)
			ApplyChecked(state.Checked);
	}

	public override uint32 WidgetStates =>
		(mChecked ? WidgetStateChecked : WidgetStateNone) | (mIndeterminate ? WidgetStateIndeterminate : WidgetStateNone);

	// --- The indicator (a check box's box, a radio's ring, a switch's track) ---

	/// Makes the indicator part (first among its children); the button draws it.
	protected void MakeIndicator()
	{
		if (mIndicator != null)
			return;
		mIndicator = new ButtonIndicator(this);
		AddChildAt(mIndicator, 0);
	}

	/// The indicator's size when nothing sizes it.
	protected virtual Float2 IndicatorSize => .(20.0f, 20.0f);

	/// Draws the indicator into `area` (its content box, in its space) from the button's parts.
	protected virtual void DrawIndicator(DrawContext ctx, Rect area)
	{
	}

	/// A radio's way: a click on it checked leaves it checked, grouped or not.
	protected void SetKeepsChecked(bool keeps)
	{
		mKeepsChecked = keeps;
	}

	/// The mixed state (CSS's :indeterminate): a check box shows it until it is set.
	protected bool IndeterminateState
	{
		get => mIndeterminate;
		set
		{
			if (value == mIndeterminate)
				return;
			mIndeterminate = value;
			MarkStyleStateDirty(StateIndeterminate);
			RedrawIndicator();
		}
	}

	/// The checked state changed (a switch moves its knob).
	protected virtual void OnCheckedChange()
	{
	}

	// --- Activation ---

	/// One activation: a toggle toggles (unless an exclusive group keeps it), a command runs, the
	/// click callback is invoked.
	protected void Activate()
	{
		if (mToggle && !HasCommand)
		{
			let keep = mChecked && !mIndeterminate && KeepsChecked;
			if (!keep)
				ChangeCheckedByUser(mIndeterminate ? true : !mChecked);
		}
		if (HasCommand)
			RunBoundCommand(); // bound to a command, the command decides (its state comes back)
		if (mOnClick != null)
			mOnClick();
	}

	protected override bool OnActivate() => ActivateAsClick(); // Return, Space, South: a click

	protected override void OnMouseClick(MouseEvent e)
	{
		e.Handled = true; // a click inside a clickable card is the button's, not the card's
		Activate();
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((e.Button != .Left) || ((mActionOn != .Press) && !mRepeat))
			return;
		e.Handled = true;
		// It activates now: the release makes no second click.
		let dispatcher = EventDispatcher;
		if (dispatcher != null)
			dispatcher.SuppressClick();
		ActivateAsClick();
		if (mRepeat)
			StartRepeat();
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		mRepeating = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mRepeating = false;
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if ((e.Modifiers != 0) || !mToggle)
			return;
		let key = (KeyCode)e.KeyCode;
		// Down and the arrow toward the inline end go on; Up and toward the start go back.
		let step = (key == .Down) ? 1 : (key == .Up) ? -1 : InlineStep(key);
		if (step == 0)
			return;
		let group = scope List<ButtonBase>();
		CollectGroup(group);
		if (group.Count < 2)
			return;
		int at = 0;
		while ((at < group.Count) && (group[at] != this))
			++at;
		if (at == group.Count)
			return;
		// The next one that can take it, round the group.
		for (int n = 1; n < group.Count; ++n)
		{
			let next = group[(step > 0) ? (at + n) % group.Count : (at + group.Count - n) % group.Count];
			if (!next.IsTreeEnabled || !next.Displayed || !next.TabFocusable)
				continue;
			next.RequestFocus();
			if (!next.mChecked)
				next.ActivateAsClick();
			break;
		}
		e.Handled = true;
	}

	// Its text part takes its font, colour and alignment (a sheet's inheritance gives the same).
	protected override void OnTextStyleChange()
	{
		if (mTextPart == null)
			return;
		ShareTextStyle(mTextPart);
		using (StyleWriteScope(mTextPart))
		{
			mTextPart.SetTextAlignment(TextAlignH, .Middle);
		}
	}

	private void ApplyText(StringView marked)
	{
		// Its access key: `&File` shows `File`, F its key.
		let mnemonic = scope Sedulous.GUI.Mnemonic();
		ParseMnemonic(marked, mnemonic);
		mMnemonic = mnemonic.Key;
		StringView text = mnemonic.Shown;
		if ((text.Length == 0) && (mTextPart == null))
			return;
		if (mTextPart == null)
		{
			mTextPart = new Label();
			mTextPart.Tag = "text"; // not a `label`: a sheet's labels are not its text
			mTextPart.HitTestVisible = false;
			using (StyleWriteScope(mTextPart))
			{
				mTextPart.SetTextAlignment(TextAlignH, .Middle); // its button's
				// It takes the space the icon and the indicator leave, its text aligned in it.
				mTextPart.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
			}
			ShareTextStyle(mTextPart);
			AddChildAt(mTextPart, PartIndex + ((mIconPart != null) ? 1 : 0));
		}
		mTextPart.SetMnemonicRange(mnemonic.Start, mnemonic.End);
		if (text == mTextPart.Text)
			return;
		mTextPart.Text = text;
		mTextPart.SetMnemonicRange(mnemonic.Start, mnemonic.End);
		mTextChanged.Notify();
	}

	private void EnsureIconPart()
	{
		if (mIconPart != null)
			return;
		mIconPart = new Sedulous.GUI.Image();
		mIconPart.Tag = "icon";
		mIconPart.HitTestVisible = false; // a press on it is the button's
		mIconPart.Fit = .Contain;
		AddChildAt(mIconPart, PartIndex);
	}

	// Where its first part goes: after its indicator.
	private int PartIndex => (mIndicator != null) ? 1 : 0;

	private bool KeepsChecked
	{
		get
		{
			if (mGroup != null)
				return !mGroup.AllowsNone;
			return mKeepsChecked || !mName.IsEmpty;
		}
	}

	private void ApplyChecked(bool check)
	{
		let settled = mIndeterminate;
		if ((check == mChecked) && !settled)
			return;
		mIndeterminate = false; // a choice settles the mixed state
		let changed = check != mChecked;
		mChecked = check;
		MarkStyleStateDirty(StateChecked | StateIndeterminate);
		RedrawIndicator();
		if (changed)
		{
			mCheckedChanged.Notify();
			OnCheckedChange();
		}
		// An exclusive group's others clear.
		if (mChecked)
		{
			let group = scope List<ButtonBase>();
			CollectGroup(group);
			for (let other in group)
			{
				if ((other != this) && other.mToggle)
					other.ApplyChecked(false);
			}
		}
	}

	private void ChangeCheckedByUser(bool check)
	{
		let before = mChecked;
		ApplyChecked(check);
		if (mChecked == before)
			return;
		if (mOnToggled != null)
			mOnToggled(mChecked);
		if (mChecked && (mGroup != null))
			mGroup.NotifyChanged(this);
		SendEvent(scope Event(.Changed, this));
	}

	private void RedrawIndicator()
	{
		Invalidate();
		if (mIndicator != null)
			mIndicator.Invalidate();
	}

	private void CollectNamed(Node node, List<ButtonBase> outGroup)
	{
		for (int i = 0; i < node.ChildCount; i++)
		{
			let child = node.GetChildAt(i);
			if (let b = child as ButtonBase)
			{
				if ((b.mGroup == null) && (b.mName == mName))
					outGroup.Add(b);
			}
			CollectNamed(child, outGroup);
		}
	}

	// Held, it activates again after the delay, then at the interval, while the pointer is over it.
	private void StartRepeat()
	{
		mRepeating = true;
		mRepeatClock = -mRepeatDelay;
		if (mRepeatRunning || (ActionManager == null))
			return;
		mRepeatRunning = true;
		let tick = new TickAction(new (elapsed) =>
			{
				if (!mRepeating || !IsTreeEnabled)
				{
					mRepeating = false;
					mRepeatRunning = false;
					return false;
				}
				if (!Hovered)
					return true; // paused while the pointer is off it
				mRepeatClock += (float)elapsed.TotalSeconds;
				while (mRepeating && (mRepeatClock >= mRepeatInterval))
				{
					mRepeatClock -= mRepeatInterval;
					ActivateAsClick();
				}
				return true;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}
}
