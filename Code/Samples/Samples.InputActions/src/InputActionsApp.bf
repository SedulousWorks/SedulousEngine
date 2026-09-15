using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.VFS;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Input;
using Sedulous.Extensions.Imgui;
using Sedulous.Graphics;
using Sedulous.Input;
using Sedulous.Input.Resource;
using Sedulous.Runtime.Client;
using Sedulous.Settings;
using Sedulous.Shell;
using Sedulous.Xml.Serialization;
using cimgui_Beef;

namespace Samples.InputActions;

/// The whole input stack in one application: named actions over three device families, an
/// exclusive menu set, the smoothing processors, the time scale, a rebind overlay persisted to
/// the user settings file, and the touch regions drawn where they are.
///
/// The moving square is the window's CLEAR COLOUR, position mapped to colour. Nothing here is
/// about drawing: the colour is just somewhere to put the numbers.
class InputActionsApp : IApplication
{
	/// OWNED, because both take constructor arguments a default construction cannot supply.
	private InputSubsystem mInput = null ~ delete _;
	private ImguiSubsystem mOverlayGui = null ~ delete _;

	/// The pristine defaults, kept UNTOUCHED so a reset has something to go back to.
	private InputMap mAsset = null ~ delete _;
	/// The user's rebinds live in the settings store, which owns the section.
	private Settings mStore = new .() ~ delete _;

	private ActionRef mMove = .();
	private ActionRef mJump = .();
	private ActionRef mConfirm = .();

	/// The action being rebound, empty when nothing is being captured.
	private String mCapturing = new .() ~ delete _;
	private CaptureFilter mCaptureFilter = .();

	private float mX = 0.5f;
	private float mY = 0.5f;

	private InputBindingOverrides Overlay => mStore.Section<InputBindingOverrides>();

	/// OWNED: this sample is a bare IApplication, so it finds the data root itself rather
	/// than taking one a DefaultApplication resolved.
	private NativeFileSystem mDataMount = null ~ delete _;

	public void Configure(IApplicationHost host)
	{
		mDataMount = new NativeFileSystem(FindDataRoot(.. scope String()));
		mInput = new InputSubsystem((host.Shell != null) ? host.Shell.Input : null);
		host.Context.RegisterSubsystem<InputSubsystem>(mInput);

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
		{
			mOverlayGui = new ImguiSubsystem(graphics.Raw, graphics.FramesInFlight, mDataMount);
			host.Context.RegisterSubsystem<ImguiSubsystem>(mOverlayGui);
		}
	}

	public void OnStartup(IApplicationHost host)
	{
		// The overrides section is read back by TYPE, so the table has to know it first.
		InputResources.RegisterAll();

		mAsset = DefaultInputMap.Create();
		LoadOverlay();
		ApplyEffectiveMap();

		Console.WriteLine("InputActions: WASD, a stick or a touch drives the clear colour;");
		Console.WriteLine("  the panel has rebinding, the time scale, and the menu toggle.");
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		let actions = mInput.Runtime;
		let shellInput = (host.Shell != null) ? host.Shell.Input : null;

		if (let gui = host.Context.GetSubsystem<ImguiSubsystem>())
		{
			gui.NewFrame(shellInput, deltaTime);
			DrawDebugPanel(host);
			DrawTouchOverlay(host);
		}

		UpdateCapture(shellInput);

		let move = actions.Value2D(mMove);
		mX = Math.Clamp(mX + move.X * deltaTime * 0.6f, 0.0f, 1.0f);
		mY = Math.Clamp(mY + move.Y * deltaTime * 0.6f, 0.0f, 1.0f);

		if (actions.WasPressed(mJump))
			Console.WriteLine("InputActions: Jump!");
		if (actions.WasPressed(mConfirm))
			Console.WriteLine("InputActions: Confirm.");
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		frame.Clear(0.1f + 0.8f * mX, 0.1f + 0.8f * mY, 0.25f, 1.0f);

		if (let gui = host.Context.GetSubsystem<ImguiSubsystem>())
			gui.Render(ref frame);
	}

	/// Capture started from the panel: the FIRST matching input wins, and Escape cancels.
	private void UpdateCapture(IInputManager shellInput)
	{
		if (mCapturing.IsEmpty || (shellInput == null))
			return;

		if ((shellInput.Keyboard != null) && shellInput.Keyboard.IsKeyPressed(.Escape))
		{
			mCapturing.Clear();
			return;
		}

		let devices = scope ShellInputSource(shellInput);
		if (!BindingCapture.Capture(devices, mCaptureFilter, let captured))
			return;

		// A REPLACEMENT rather than an addition: rebinding means these are the keys now.
		let replacement = scope Binding[](captured);
		Overlay.Set("Gameplay", mCapturing, replacement);
		mCapturing.Clear();
		SaveOverlay();
		ApplyEffectiveMap();
	}

	/// The effective map is the pristine asset with the user's overlay laid over it, rebuilt
	/// from scratch every time: applying an overlay to an already overlaid map would compound.
	private void ApplyEffectiveMap()
	{
		let effective = scope InputMap();
		mAsset.CopyTo(effective);
		Overlay.ApplyTo(effective);

		mInput.SetMap(effective); // the runtime keeps its own copy
		mMove = mInput.Runtime.Resolve("Move");
		mJump = mInput.Runtime.Resolve("Jump");
		mConfirm = mInput.Runtime.Resolve("Confirm");
	}

	private static void OverlayPath(String outPath)
	{
		let directory = scope String();
		GetUserDataDirectory(directory);
		PathJoin(directory, "inputactions.rebinds.xml", outPath);
	}

	private void LoadOverlay()
	{
		let path = scope String();
		OverlayPath(path);

		let bytes = scope List<uint8>();
		if (File.ReadAll(path, bytes) case .Err)
			return;

		let stream = scope Sedulous.Core.IO.MemoryStream();
		stream.Write(bytes);
		stream.Seek(0, .Begin);

		SerializerFactory factory = scope (innerStream, mode) =>
			new XmlSerializerContext(innerStream, mode);
		if (mStore.Load(stream, factory) case .Ok)
			Console.WriteLine("InputActions: loaded the user's rebinds.");
	}

	private void SaveOverlay()
	{
		let stream = scope Sedulous.Core.IO.MemoryStream();
		SerializerFactory factory = scope (innerStream, mode) =>
			new XmlSerializerContext(innerStream, mode);
		if (!(mStore.Save(stream, factory) case .Ok))
			return;

		let path = scope String();
		OverlayPath(path);

		let directory = scope String();
		PathParent(path, directory);
		Directory.CreateDirectory(directory).IgnoreError();

		if (File.WriteAll(path, stream.Bytes) case .Ok)
			Console.WriteLine("InputActions: rebinds saved.");
	}

	private void DrawDebugPanel(IApplicationHost host)
	{
		let actions = mInput.Runtime;

		igSetNextWindowPos(.() { x = 10, y = 10 }, (int32)ImGuiCond.ImGuiCond_FirstUseEver, .());
		igBegin("Input", null, 0);

		let move = actions.Value2D(mMove);
		igText(scope $"Move  {move.X:+0.00;-0.00} {move.Y:+0.00;-0.00}");
		igText(scope $"Jump  {actions.IsDown(mJump) ? "DOWN" : "up"}");

		// The engine time scale: Move is flagged for it and slows, Jump's press is not.
		var scale = host.Context.TimeScale;
		if (igSliderFloat("time scale", &scale, 0.0f, 2.0f, "%.2f", 0))
			host.Context.TimeScale = scale;

		let menuOpen = actions.ExclusiveDepth > 0;
		if (igButton(menuOpen ? "Close Menu (gameplay resumes)".CStr()
			: "Open Menu (gameplay suppressed)".CStr(), .()))
		{
			if (menuOpen)
				actions.PopExclusiveSet();
			else
				actions.PushExclusiveSet("Menu");
		}

		igSeparator();
		igText("Rebinding (an overlay over the pristine defaults):");
		DrawRebindRow("Jump");
		DrawRebindRow("Move");

		if (igButton("Reset ALL to defaults", .()))
		{
			ClearAndDeleteItems!(Overlay.Overrides);
			mCapturing.Clear();
			SaveOverlay();
			ApplyEffectiveMap();
		}

		if (!mCapturing.IsEmpty)
		{
			igTextColored(.() { x = 1, y = 0.8f, z = 0.2f, w = 1 },
				scope $"Press the new input for {mCapturing} (Esc cancels)...");
		}

		igEnd();
	}

	private void DrawRebindRow(StringView actionName)
	{
		// The EFFECTIVE first binding, which is what a player sees on the row.
		Binding first = .();
		var haveFirst = false;
		for (let set in mInput.Runtime.Map.Sets)
		{
			for (let action in set.Actions)
			{
				if (action.Name != actionName)
					continue;
				if (!action.Bindings.IsEmpty)
				{
					first = action.Bindings[0];
					haveFirst = true;
				}
				break;
			}
		}

		let label = haveFirst
			? scope:: String()..AppendF("{}: {}#{}", actionName,
				BindingLabels.SourceLabel(first.Source), first.Code)
			: scope:: String()..AppendF("{}: (unbound)", actionName);
		igTextUnformatted(label, null);

		igSameLine(180.0f, -1.0f);
		if (igButton(scope $"Rebind##{actionName}", .()))
		{
			mCapturing.Set(actionName);
			mCaptureFilter = .();
			if (actionName == "Move")
			{
				// An Axis2D takes a STICK: the keyboard keeps the default composite, which a
				// single captured key could not replace.
				mCaptureFilter.Keys = false;
				mCaptureFilter.MouseButtons = false;
				mCaptureFilter.GamepadButtons = false;
				mCaptureFilter.GamepadSticks = true;
			}
		}

		igSameLine(0.0f, -1.0f);
		if (igButton(scope $"Reset##{actionName}", .()))
		{
			Overlay.Clear("Gameplay", actionName);
			SaveOverlay();
			ApplyEffectiveMap();
		}
	}

	/// The touch regions drawn where they actually are, plus the live contacts. A virtual
	/// stick with no visible zone is guesswork.
	private void DrawTouchOverlay(IApplicationHost host)
	{
		let draw = igGetForegroundDrawList_ViewportPtr(igGetMainViewport());
		if (draw == null)
			return;

		let size = igGetIO_Nil().DisplaySize;
		Rect(draw, size, 0.0f, 0.3f, 0.45f, 0.7f, 0x78FFA05A);   // the stick zone
		Rect(draw, size, 0.55f, 0.55f, 0.45f, 0.45f, 0x785A8CFF); // the jump zone

		let shellInput = (host.Shell != null) ? host.Shell.Input : null;
		if ((shellInput == null) || (shellInput.Touch == null))
			return;

		let touch = shellInput.Touch;
		for (int32 i < touch.TouchCount)
		{
			if (!touch.GetTouchPoint(i, let point))
				continue;
			ImDrawList_AddCircle(draw,
				.() { x = point.X * size.x, y = point.Y * size.y }, 24.0f, 0xC8FFFFFF, 0, 3.0f);
		}
	}

	private static void Rect(ImDrawList* draw, ImVec2 size, float x, float y, float w, float h,
		uint32 color)
	{
		ImDrawList_AddRect(draw, .() { x = x * size.x, y = y * size.y },
			.() { x = (x + w) * size.x, y = (y + h) * size.y }, color, 0.0f, 0, 2.0f);
	}
}
