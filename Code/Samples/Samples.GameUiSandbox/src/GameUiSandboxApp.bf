using System;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.Input;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Samples.GameUiSandbox;

/// The game interface kit on screen: a screen pushed onto the subsystem's stack and filled with
/// the widgets a game actually uses.
///
/// The point is the SCREEN TIER rather than any one widget: a heads up display is a screen, a
/// pause menu is another one pushed over it, and backing out pops rather than exits.
class GameUiSandboxApp : DefaultApplication
{
	private Scene mScene = null;
	private EntityHandle mCamera = .Invalid;
	private UISubsystem mUI = null;

	private ToastHost mToasts = null;
	private Bar mHealth = null;
	private Ticker mScore = null;

	private InputMap mMap = new .() ~ delete _;
	private int64 mScoreValue = 0;
	private float mHealthValue = 1.0f;
	private bool mQuit = false;

	public override void OnLaunch(IApplicationHost host)
	{
		base.OnLaunch(host);

		// A camera and nothing else: the opaque screen covers the view, but a frame still has to
		// have something to render.
		mScene = PrimaryScenes.CreateScene("gameui");
		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera);
		mScene.Start();

		mUI = host.Context.GetSubsystem<UISubsystem>();
		if (mUI == null)
			return;

		// The toasts live on the screen ROOT rather than on a screen, so they survive a push and
		// float above whatever is on top.
		mToasts = new ToastHost();
		mUI.ScreenRoot.AddView(mToasts);

		BuildInputMap();
		mUI.Screens.Push(BuildHudScreen());

		Console.WriteLine("GameUiSandbox: up and down move the menu, Enter activates. Esc exits.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime); // ticks the interface, which is what animates the widgets

		if (mToasts != null)
			mToasts.Update(deltaTime); // ages the timed ones out

		if (mQuit)
		{
			host.RequestExit(0);
			return;
		}

		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (input == null)
			return;

		if (input.Keyboard.IsKeyPressed(.Escape))
		{
			// Escape BACKS OUT first and only exits when there is nothing to back out of, which
			// is what a player expects of it.
			if (!mUI.Screens.HandleBack())
				host.RequestExit(0);
		}

		if (input.Keyboard.IsKeyPressed(.E) && (mToasts != null))
			ShowToast("Delivered!", .Info, 1.5f);
	}

	/// The action the prompt advertises, which is also what the prompt reads its key from: the
	/// binding is stated ONCE and the label follows it.
	private void BuildInputMap()
	{
		let set = new ActionSet();
		set.Name.Set("Gameplay");

		let deliver = new InputAction();
		deliver.Name.Set("Deliver");

		Binding key = .();
		key.Source = .Key;
		key.Code = (uint32)Sedulous.Shell.KeyCode.E;
		deliver.Bindings.Add(key);

		Binding pad = .();
		pad.Source = .GamepadButton;
		pad.Code = (uint32)GamepadButton.South;
		deliver.Bindings.Add(pad);

		set.Actions.Add(deliver);
		mMap.Sets.Add(set);
	}

	private void ShowToast(StringView message, ToastSeverity severity, float seconds)
	{
		ToastRequest request = .();
		request.Message = message;
		request.Severity = severity;
		request.DurationSeconds = seconds;
		mToasts.Show(request);
	}

	private static Label Text(StringView text, float size = 16.0f)
	{
		let label = new Label(text);
		label.FontSize.Value = size;
		return label;
	}

	private static FlexLayout Row(float spacing)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.AlignItems = .Center;
		row.Spacing = spacing;
		return row;
	}

	private UIScreen BuildHudScreen()
	{
		let screen = new UIScreen();
		screen.Mode = .Opaque;
		screen.SetTransition(.(.Fade, 0.2f));

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 16.0f;
		column.Padding = .(48.0f, 40.0f);

		column.AddView(Text("Game UI Kit Sandbox", 28.0f));

		let prompt = new ButtonPrompt();
		prompt.SetFromAction(mMap, "Deliver", "Deliver");
		column.AddView(prompt);

		{
			let row = Row(8.0f);
			row.AddView(Text("Score"));
			mScore = new Ticker();
			mScore.FontSize.Value = 20.0f;
			row.AddView(mScore);
			column.AddView(row);
		}
		{
			let row = Row(8.0f);
			row.AddView(Text("Health"));
			mHealth = new Bar();
			mHealth.SetFill(1.0f);

			LayoutStyle style = .();
			style.Width = SizeSpec.Fixed(Unit.Px(220));
			row.AddView(mHealth, style);
			column.AddView(row);
		}

		let menu = new MenuList();
		menu.AddItem("Score +250", new () =>
			{
				mScoreValue += 250;
				if (mScore != null)
					mScore.AnimateTo(mScoreValue);
			});
		menu.AddItem("Take damage", new () =>
			{
				mHealthValue = Math.Max(0.0f, mHealthValue - 0.2f);
				if (mHealth != null)
					mHealth.AnimateTo(mHealthValue);
			});
		menu.AddItem("Heal", new () =>
			{
				mHealthValue = Math.Min(1.0f, mHealthValue + 0.3f);
				if (mHealth != null)
					mHealth.AnimateTo(mHealthValue);
			});
		menu.AddItem("Show toast", new () =>
			{
				if (mToasts != null)
					ShowToast("Objective complete!", .Success, 3.0f);
			});
		menu.AddItem("Pause menu", new () => mUI.Screens.Push(BuildPauseScreen()));
		menu.AddItem("Quit", new () => { mQuit = true; });
		column.AddView(menu);

		screen.AddView(column);
		return screen;
	}

	private UIScreen BuildPauseScreen()
	{
		let screen = new UIScreen();
		screen.Mode = .Modal; // shields the display below without hiding it
		screen.SetTransition(.(.Scale, 0.18f));

		// The scrim goes on FIRST so it draws behind the card, dimming the frozen display
		// rather than the card itself.
		screen.AddView(new ColorView(Color(0.0f, 0.0f, 0.0f, 0.55f), 0.0f, 0.0f));

		let center = new FlexLayout();
		center.Direction = .Vertical;
		center.JustifyContent = .Center;
		center.AlignItems = .Center;

		// A solid CARD, because a menu laid straight over the dimmed display reads as a jumble
		// of two screens rather than one on top of another.
		let card = new Panel();
		card.SetStyle(.Background, new ColorDrawable(Color(0.12f, 0.13f, 0.17f, 0.98f)));

		// The padding lives on the inner layout, which honours it; the panel is what paints
		// the background behind it.
		let content = new FlexLayout();
		content.Direction = .Vertical;
		content.AlignItems = .Center;
		content.Spacing = 16.0f;
		content.Padding = .(40.0f, 28.0f);

		content.AddView(Text("Paused", 26.0f));

		let menu = new MenuList();
		menu.AddItem("Resume", new () => mUI.Screens.Pop());
		menu.AddItem("Quit", new () => { mQuit = true; });
		content.AddView(menu);

		card.AddView(content);
		center.AddView(card);
		screen.AddView(center);
		return screen;
	}
}
