using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.Input;

// A binding's input on the grid (hint "inputCode": a key, a mouse button, a gamepad's button or
// stick): a key capture showing the input it is, which, clicked, listens for the next one pressed on
// any device the action takes, as the old page's key caps did. The page listens (it reads the
// devices each frame); while it does the button reads so and its focus takes every key, so no
// shortcut runs the key pressed. Escape is an input a game binds, so it does not cancel: clicking
// again does, or the focus leaving.

/// What the capture editor asks of its page, by the row's path. Each owned; one unset does nothing.
class InputCaptureServices
{
	/// The input the row holds, as the page names it ("W", "Gamepad A", "Left Stick"), appended.
	public delegate void(StringView path, String outText) Describe ~ delete _;
	/// Listens for the row's input, or (listening already) stops.
	public delegate void(StringView path) Toggle ~ delete _;
	/// Whether the page listens for the row's input now.
	public delegate bool(StringView path) Listening ~ delete _;
	/// Stops listening (the focus left the row's button).
	public delegate void() Cancel ~ delete _;
}

class InputCaptureEditor : SingleControlEditor
{
	public const String cListening = "Press an input...";

	// The button: its focus leaving stops a listen.
	private class CaptureButton : Sedulous.GUI.Button
	{
		private InputCaptureEditor mOwner;

		public this(InputCaptureEditor owner)
		{
			mOwner = owner;
		}

		// The press is the button's: the grid's row would take the focus on it, and the focus leaving
		// would stop the listen before this click could.
		protected override void OnMouseDown(MouseEvent e)
		{
			if (e.Button == .Left)
				e.Handled = true;
			base.OnMouseDown(e);
		}

		protected override void OnFocusLost()
		{
			if (mOwner.IsListening && (mOwner.mServices.Cancel != null))
			{
				mOwner.mServices.Cancel();
				mOwner.Show();
			}
			base.OnFocusLost();
		}
	}

	/// The page's; it outlives the editor.
	private InputCaptureServices mServices;
	private CaptureButton mButton ~ _.ReleaseRef();
	/// The objects' inputs differ.
	private bool mMixed = false;

	/// `services` is borrowed and outlives it.
	public this(InputCaptureServices services)
	{
		mServices = services;
		AddClass("input-capture");
		mButton = new CaptureButton(this);
		mButton.AddClass("key-capture");
		mButton.SetOnClick(new [=this] () =>
			{
				if (mServices.Toggle != null)
					mServices.Toggle(Path);
				Show();
			});
		Hold(mButton);
	}

	/// The editor for every input row `registry` shows; `services` outlives it.
	public static void Register(PropertyEditorRegistry registry, InputCaptureServices services)
	{
		registry.RegisterHint(InputMapRows.cInputCodeHint, new [=services] () => new InputCaptureEditor(services));
	}

	public Sedulous.GUI.Button Button => mButton;
	public bool IsListening => (mServices.Listening != null) && mServices.Listening(Path);

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mMixed = value.Mixed;
		Show();
	}

	// The button as the listen stands: it says so and takes every key while it listens. The editor
	// shows itself when it starts or stops one, not the grid: a refresh of the rows could take its
	// focus, and its focus leaving stops the listen.
	private void Show()
	{
		let listening = IsListening;
		if (listening)
			mButton.Text = cListening;
		else if (mMixed)
			mButton.Text = MixedValueText();
		else
		{
			let described = scope String();
			if (mServices.Describe != null)
				mServices.Describe(Path, described);
			mButton.Text = described;
		}
		if (listening)
			mButton.AddClass("capturing");
		else
			mButton.RemoveClass("capturing");
		// While it listens its focus takes every key (none runs a shortcut instead).
		mButton.CapturesAllKeys = listening;
		if (listening)
			mButton.FocusElement();
		mButton.Enabled = !IsReadOnly;
		mButton.Tooltip = listening ? "Press the input to bind (click again to stop)" : "Click, then press the input to bind";
	}
}
