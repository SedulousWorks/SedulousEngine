using System;
using Sedulous.GUI;

namespace Samples.GUISandbox;

/// What the pages do, wired by native code once every page is in the tree: the handlers, bindings
/// and tweens that make the Controls, Text, Menus, Motion, Data binding, Input and Navigation pages
/// live. Values the pages show go through the GUI's data (`{{name}}` in their markup) where they
/// are shared, and straight into a label where only that label shows them.
extension GUISandboxApp
{
	// === The Controls page ===

	/// Lines the log was given, and tabs added.
	private int mLogLines = 0;
	private int mAddedTabs = 0;

	// === The Input page's viewer ===

	/// Where the last gesture left the picture, each gesture on top of it.
	private double mViewX = 0.0;
	private double mViewY = 0.0;
	private double mViewScale = 1.0;
	/// Degrees.
	private double mViewTurn = 0.0;

	// === The Text page's field ===

	private int mFieldInputs = 0;
	private int mFieldChanges = 0;
	private int mFieldSubmits = 0;

	// === The Menus page ===

	/// The window it builds when asked; a window closed by its button is gone, and is built again.
	private Element<Sedulous.GUI.Window> mPageWindow = null ~ delete _;

	/// A handler on the sandbox's widget `id`; deleted unused when there is none.
	private void Listen(StringView id, StringView eventName, delegate bool(Event e) handler)
	{
		GameMenu.Listen(mShellNode, id, eventName, handler);
	}

	private void WirePages()
	{
		if (mShellNode == null)
			return;
		WireControls();
		WireText();
		WireMenus();
		WireMotion();
		WireBinding();
		WireInput();
		WireNavigation();
	}

	/// A GUI data value moved by `by`.
	private void Tally(StringView name, double by)
	{
		mGuiFacade.SetNumber(name, mGuiFacade.GetNumber(name) + by);
	}

	/// A percentage of a fraction, rounded to the nearest whole one.
	private static int Percent(double fraction) => (int)(fraction * 100.0 + 0.5);

	// === Controls ===
	// The buttons count into the GUI's data (a label shows it through {{clicks}}); the bar and the
	// number follow the slider, and the echo the text field, through bindings, with no handlers.

	private void WireControls()
	{
		Listen("controls-add", "click", new (e) => { Tally("clicks", 1.0); return false; });
		Listen("controls-add5", "click", new (e) => { Tally("clicks", 5.0); return false; });
		Listen("controls-reset", "click", new (e) =>
			{
				mGuiFacade.SetNumber("clicks", 0.0);
				return false;
			});
		Listen("controls-repeat", "click", new (e) => { Tally("clicks", 1.0); return false; });
		Listen("controls-press", "click", new (e) => { Tally("clicks", 1.0); return false; });
		Listen("controls-log-add", "click", new (e) => { AddLogLine(); return false; });
		Listen("controls-tab-add", "click", new (e) => { AddTab(); return false; });

		if (let slider = FindById(mShellNode, "controls-slider") as Slider)
		{
			if (let progress = FindById(mShellNode, "controls-progress"))
				progress.BindNumber("value", new () => slider.Value);
			if (let value = FindById(mShellNode, "controls-slider-value"))
				value.BindText("text", new (outText) => { outText.AppendF("{}%", Percent(slider.Value)); });
		}
		let vertical = FindById(mShellNode, "controls-vertical") as Slider;
		let stepped = FindById(mShellNode, "controls-stepped") as Slider;
		let freq = FindById(mShellNode, "controls-freq") as Slider;
		if (let ranges = FindById(mShellNode, "controls-ranges"))
		{
			if ((vertical != null) && (stepped != null) && (freq != null))
			{
				ranges.BindText("text", new (outText) =>
					{
						outText.AppendF("vertical {}, stepped {} of 10, exponential {} Hz", (int)vertical.Value, (int)stepped.Value, (int)freq.Value);
					});
			}
		}
		if (let field = FindById(mShellNode, "controls-field") as TextField)
		{
			if (let echo = FindById(mShellNode, "controls-echo"))
			{
				echo.BindText("text", new (outText) =>
					{
						let text = field.Text;
						if (text.IsEmpty)
							outText.Append("(the echo follows the field)");
						else
							outText.AppendF("echo: {}", text);
					});
			}
		}
	}

	private void AddLogLine()
	{
		let log = FindById(mShellNode, "controls-log");
		if (log == null)
			return;
		mLogLines++;
		if (let line = log.AddElement("Label") as Sedulous.GUI.Label)
		{
			line.Text = scope $"Line {mLogLines} arrived";
			line.AddClass("scroll-line");
		}
	}

	private void AddTab()
	{
		let tabs = FindById(mShellNode, "controls-tabs");
		if (tabs == null)
			return;
		mAddedTabs++;
		if (let page = tabs.AddElement("TabPage") as TabPage)
		{
			page.Title = scope $"Added {mAddedTabs}";
			if (let body = page.AddElement("Label") as Sedulous.GUI.Label)
			{
				body.Text = "A page added by the page's code.";
				body.AddClass("caption");
			}
		}
	}

	// === Text ===
	// The rich text's links and the field's events, shown through the GUI's data.

	private void WireText()
	{
		mGuiFacade.SetText("linkText", "Click a link: it is reported as a link event with its id.");
		ShowFieldEvents("");
		Listen("text-rich", "link", new (e) =>
			{
				if (let link = e as LinkEvent)
					mGuiFacade.SetText("linkText", scope $"link: {link.Link}");
				return true;
			});
		Listen("text-field", "input", new (e) =>
			{
				mFieldInputs++;
				ShowFieldEvents("");
				return false;
			});
		Listen("text-field", "change", new (e) =>
			{
				mFieldChanges++;
				ShowFieldEvents("committed");
				return false;
			});
		Listen("text-field", "submit", new (e) =>
			{
				mFieldSubmits++;
				ShowFieldEvents("submitted");
				return false;
			});
	}

	private void ShowFieldEvents(StringView last)
	{
		let text = scope String()..AppendF("input {}, change {}, submit {}", mFieldInputs, mFieldChanges, mFieldSubmits);
		if (!last.IsEmpty)
			text.AppendF(": {}", last);
		mGuiFacade.SetText("fieldEvents", text);
	}

	// === Menus ===
	// The menus written in markup say what was picked: an item's `activate` bubbles, through its
	// menu to what opened it, so one listener on the section hears them all, the event's target the
	// item. And what the page builds itself: a menu of sixty items, longer than the window, which
	// scrolls; a window of its own; and a toast it fills in and posts.

	private void WireMenus()
	{
		Listen("menus-markup", "activate", new (e) =>
			{
				if (let said = FindById(mShellNode, "menus-markup-said") as Sedulous.GUI.Label)
				{
					let item = e.Target as UIWidget;
					StringView id = (item != null) ? item.Id : default;
					said.Text = scope $"Picked from markup: {id}";
				}
				return true;
			});
		Listen("toast-code", "click", new (e) =>
			{
				PostPageToast();
				return true;
			});

		// A menu longer than the window: it scrolls. It waits under its button, styled as the page.
		if (let button = FindById(mShellNode, "menus-long"))
		{
			if (let menu = button.AddElement("Menu") as Menu)
			{
				menu.SetAutoWidth(true);
				for (int i = 1; i <= 60; i++)
				{
					let number = i;
					menu.AddItem(scope $"Item {i}", new () =>
						{
							if (let said = FindById(mShellNode, "menus-long-said") as Sedulous.GUI.Label)
								said.Text = scope $"Picked from the long menu: item {number}";
						});
				}
				button.On("click", new (e) =>
					{
						menu.OpenBelowNode(button);
						return true;
					});
			}
		}

		Listen("menus-code-window", "click", new (e) =>
			{
				OpenPageWindow();
				return true;
			});
	}

	/// The page's own window, built when asked (over the whole GUI, centred in it).
	private void OpenPageWindow()
	{
		var window = (mPageWindow != null) ? mPageWindow.Get() : null;
		if (window == null)
		{
			window = mRoot.AddElement("Window") as Sedulous.GUI.Window;
			if (window == null)
				return;
			DeleteAndNullify!(mPageWindow);
			mPageWindow = new Element<Sedulous.GUI.Window>(window);
			window.Width = 320.0f;
			window.Height = 160.0f;
			window.Title = "From the Menus page";
			if (let text = window.AddElement("Label") as Sedulous.GUI.Label)
			{
				text.Text = "The page's code built this window and its text.";
				text.AddClass("text");
			}
		}
		if (!window.IsOpen)
			window.OpenInPlace();
	}

	/// A toast the page fills in and posts, its action heard by the post's callback.
	private void PostPageToast()
	{
		if (mToasts == null)
			return;
		let request = scope ToastRequest();
		request.Title = "From the Menus page";
		request.Message = "The page's code filled in this request and posted it.";
		request.Severity = .Success;
		request.Classes = "pop";
		request.AddAction("again", "Again", "");
		mToasts.Post(request, new (action) =>
			{
				if (action.Id != "again")
					return;
				if (let said = FindById(mShellNode, "toast-said") as Sedulous.GUI.Label)
					said.Text = scope $"The page heard its toast's action: {action.Id}.";
			});
	}

	// === Motion ===
	// A level's end, played with tweens. The card fades in and springs from small to its size; a
	// sequence waits, pops each gem (a fade beside an ease-out-back scale, together), fills the score
	// bar while a label bound to it counts, then slides a toast in, waits and slides it out. Every
	// tween gives its start, so playing again starts over from the same place.

	private void WireMotion()
	{
		Listen("motion-replay", "click", new (e) =>
			{
				PlayMotion();
				return true;
			});
		if (let bar = FindById(mShellNode, "motion-score-bar") as ProgressBar)
		{
			if (let score = FindById(mShellNode, "motion-score"))
				score.BindText("text", new (outText) => { outText.AppendF("Score {}", (int)(bar.Value * 125.0 + 0.5)); });
		}
	}

	/// `step` added to `group`, which takes its own reference: the caller's is let go.
	private static void AddStep(TweenGroup group, Sedulous.GUI.Action step)
	{
		group.Add(step);
		step.ReleaseRef();
	}

	/// A gem popping: a fade beside an ease-out-back scale. The caller releases it.
	private static TweenGroup Pop(Node gem)
	{
		let pop = new TweenParallel();
		AddStep(pop, gem.CreateTween("opacity", "1", 0.2f, "linear").From("0"));
		AddStep(pop, gem.CreateTween("transform", "rotate(45deg) scale(1)", 0.35f, "ease-out-back").From("rotate(45deg) scale(0.2)"));
		return pop;
	}

	private void PlayMotion()
	{
		let card = FindById(mShellNode, "motion-card");
		let bar = FindById(mShellNode, "motion-score-bar");
		let toast = FindById(mShellNode, "motion-toast");
		if ((card == null) || (bar == null) || (toast == null))
			return;
		card.Animate("opacity", "1", 0.25f, "ease-out").From("0").ReleaseRef();
		card.SpringTo("transform", "scale(1)", 260.0f, 14.0f, 1.0f).From("scale(0.6)").ReleaseRef();
		Node[3] gems = default;
		for (int i < 3)
		{
			gems[i] = FindById(mShellNode, scope $"motion-gem-{i + 1}");
			if (gems[i] != null)
				gems[i].Animate("opacity", "0", 0.0f, "linear").ReleaseRef(); // hidden until popped
		}
		bar.Animate("value", "0", 0.0f, "linear").ReleaseRef();
		toast.Animate("opacity", "0", 0.0f, "linear").ReleaseRef();

		let sequence = new TweenSequence();
		sequence.Wait(0.35f);
		for (let gem in gems)
		{
			if (gem != null)
				AddStep(sequence, Pop(gem));
		}
		AddStep(sequence, bar.CreateTween("value", "100", 1.2f, "ease-out-cubic").From("0"));
		let slideIn = new TweenParallel();
		AddStep(slideIn, toast.CreateTween("opacity", "1", 0.25f, "linear").From("0"));
		AddStep(slideIn, toast.CreateTween("transform", "translate(0, 0)", 0.4f, "ease-out-back").From("translate(120px, 0)"));
		AddStep(sequence, slideIn);
		sequence.Wait(1.6f);
		let slideOut = new TweenParallel();
		AddStep(slideOut, toast.CreateTween("opacity", "0", 0.3f, "linear"));
		AddStep(slideOut, toast.CreateTween("transform", "translate(120px, 0)", 0.3f, "ease-in-cubic"));
		AddStep(sequence, slideOut);
		card.Play(sequence); // the card's GUI runs it, with a reference of its own
		sequence.ReleaseRef();
	}

	// === Data binding ===

	/// The percentage label follows a function of the GUI's volume.
	private void WireBinding()
	{
		if (let percent = FindById(mShellNode, "binding-percent"))
			percent.BindText("text", new (outText) => { outText.AppendF("{}%", Percent(mGuiFacade.GetNumber("volume"))); });
	}

	// === Input ===
	// The clickable card counts the clicks that reach it (the button's stop at the button); the pad
	// shows where it was pressed and how many presses of a run that was; the glass over a button
	// lets clicks through (pointer-events: none); the canvas says what was dropped on it; the viewer
	// turns two fingers' gestures into its picture's transform.

	private void WireInput()
	{
		let gui = mGuiFacade;
		gui.SetNumber("cardClicks", 0.0);
		gui.SetNumber("buttonClicks", 0.0);
		gui.SetNumber("padX", 0.0);
		gui.SetNumber("padY", 0.0);
		gui.SetNumber("padClicks", 0.0);
		gui.SetNumber("glassClicks", 0.0);
		gui.SetText("paint", "nothing yet");
		Listen("input-click-card", "click", new (e) => { Tally("cardClicks", 1.0); return false; });
		Listen("input-card-button", "click", new (e) => { Tally("buttonClicks", 1.0); return false; });
		Listen("input-pad", "mousedown", new (e) =>
			{
				let mouse = e as MouseEvent;
				if ((mouse == null) || (e.CurrentTarget == null))
					return false;
				// From device pixels to the pad's own units.
				let local = e.CurrentTarget.ConvertToNodeSpace(mouse.Position);
				mGuiFacade.SetNumber("padX", (double)(int)local.X);
				mGuiFacade.SetNumber("padY", (double)(int)local.Y);
				mGuiFacade.SetNumber("padClicks", (double)mouse.ClickCount);
				return true;
			});
		Listen("input-under-glass", "click", new (e) => { Tally("glassClicks", 1.0); return false; });
		Listen("input-canvas", "drop", new (e) =>
			{
				let drag = e as DragEvent;
				if ((drag == null) || (drag.Payload == null))
					return false;
				let payload = drag.Payload;
				let what = IsText(payload.Value) ? TextOf(payload.Value) : (StringView)payload.Label;
				mGuiFacade.SetText("paint", scope $"{what} ({EffectName(drag.Effect)})");
				return true;
			});
		Listen("input-viewer", "gesturechange", new (e) =>
			{
				if (let gesture = e as GestureEvent)
				{
					ShowView(mViewX + gesture.Translation.X, mViewY + gesture.Translation.Y, mViewScale * gesture.Scale,
						mViewTurn + gesture.Rotation * cDegreesPerRadian);
				}
				return true;
			});
		Listen("input-viewer", "gestureend", new (e) =>
			{
				if (let gesture = e as GestureEvent)
				{
					mViewX += gesture.Translation.X;
					mViewY += gesture.Translation.Y;
					mViewScale *= gesture.Scale;
					mViewTurn += gesture.Rotation * cDegreesPerRadian;
				}
				ShowView(mViewX, mViewY, mViewScale, mViewTurn);
				return true;
			});
		// Cancelled: back where it was.
		Listen("input-viewer", "gesturecancel", new (e) =>
			{
				ShowView(mViewX, mViewY, mViewScale, mViewTurn);
				return true;
			});
		Listen("input-viewer-reset", "click", new (e) =>
			{
				mViewX = 0.0;
				mViewY = 0.0;
				mViewScale = 1.0;
				mViewTurn = 0.0;
				ShowView(mViewX, mViewY, mViewScale, mViewTurn);
				return true;
			});
		gui.SetText("viewer", "Scale 100%, turned 0 degrees, moved 0, 0");
	}

	private const double cDegreesPerRadian = 57.29578;

	private static StringView EffectName(DropEffect effect)
	{
		switch (effect)
		{
		case .Copy: return "copy";
		case .Move: return "move";
		case .Link: return "link";
		default: return "none";
		}
	}

	/// The viewer's picture at a place, a scale and a turn, and what the label says of it.
	private void ShowView(double x, double y, double scale, double turn)
	{
		if (let photo = FindById(mShellNode, "input-photo"))
		{
			let transform = scope String()..AppendF("translate({:F3}px, {:F3}px) rotate({:F3}deg) scale({:F4})", x, y, turn, scale);
			photo.Animate("transform", transform, 0.0f, "linear").ReleaseRef();
		}
		mGuiFacade.SetText("viewer", scope $"Scale {Percent(scale)}%, turned {(int)turn} degrees, moved {(int)x}, {(int)y}");
	}

	// === Navigation ===
	// The editor panel handles "demo.cut", so the Cut button (bound to the command) is lit only
	// while focus is inside it; Ctrl+X runs it there through a binding in the "editor" key context.

	private void WireNavigation()
	{
		mGuiFacade.DefineCommand("demo.cut", "Cut");
		if (let editor = FindById(mShellNode, "navigation-editor"))
			editor.OnCommand("demo.cut", new (command) => { Tally("cuts", 1.0); });
		mGuiFacade.BindKey("ctrl-x", "demo.cut", "editor");
	}
}
