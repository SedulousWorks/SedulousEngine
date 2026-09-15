using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.Extensions.Imgui;
using Sedulous.Graphics;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.UI.Resource;
using Samples.Common;
using cimgui_Beef;

namespace Samples.PhysicsPlayground;

/// The physics stack with a scene on top of it: a crate wall, a cooked ramp and boulder, a
/// kinematic sweeper, a motorised hinge, a character, a trigger volume, and raycast shoving.
///
/// All three UI tiers ride along on purpose. The screen button is the proof that a click the UI
/// consumed does NOT also reach the world.
class PhysicsPlaygroundApp : DefaultApplication
{
	private const int cCrateColumns = 5;
	private const int cCrateRows = 4;

	private Scene mScene = null;
	private PhysicsSceneSystem mPhysics = null;

	private EntityHandle mCamera = .Invalid;
	private EntityHandle mSweeper = .Invalid;
	private EntityHandle mBoulder = .Invalid;
	private EntityHandle mHero = .Invalid;
	private EntityHandle mHudEntity = .Invalid;
	private EntityHandle mKioskEntity = .Invalid;
	private List<EntityHandle> mCrates = new .() ~ delete _;

	private UIDocument mHudDocument = null ~ delete _;
	private UIDocument mKioskDocument = null ~ delete _;
	private UIDocument mNameplateDocument = null ~ delete _;
	private bool mHudBound = false;
	private bool mKioskBound = false;
	private uint32 mHudClicks = 0;
	private uint32 mKioskTaps = 0;

	private CollisionShape mRampShape = null ~ delete _;
	private CollisionShape mBoulderShape = null ~ delete _;

	private uint32 mLastSurface = 0;
	private bool mHaveSurface = false;

	/// OWNED, because it takes the device and the frame count a default construction cannot
	/// supply.
	private ImguiSubsystem mOverlay = null ~ delete _;

	private FlyCamera mFly = .();
	private float mSweepAngle = 0.0f;

	public override void Configure(IApplicationHost host)
	{
		// Physics, input and UI all come from the base. Registering them again would leave
		// two instances ticking the same scene.
		base.Configure(host);

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
		{
			mOverlay = new ImguiSubsystem(graphics.Raw, graphics.FramesInFlight, DataFileSystem);
			host.Context.RegisterSubsystem<ImguiSubsystem>(mOverlay);
		}
	}

	public override void OnLaunch(IApplicationHost host)
	{
		base.OnLaunch(host);

		mScene = PrimaryScenes.CreateScene("playground");
		mPhysics = mScene.GetSystem<PhysicsSceneSystem>();
		if (mPhysics != null)
			mPhysics.Settings.DebugDraw = true; // the wireframes ARE this sample's rendering

		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera);

		mFly.Position = .(8.0f, 6.0f, 14.0f);
		mFly.Yaw = 0.5f;
		mFly.Pitch = -0.3f;
		mFly.MoveSpeed = 10.0f;
		mFly.FastSpeed = 30.0f;

		BuildWorld();
		mScene.Start();
		mScene.SetSimulationEnabled(true);

		Console.WriteLine("PhysicsPlayground: WASD and the right button to fly, left button to");
		Console.WriteLine("shove, R to respawn, arrows and Space to drive the character.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (input != null)
			mFly.Update(input.Keyboard, input.Mouse, deltaTime);
		PushCameraToEntity();

		if ((input == null) || (mScene == null))
			return;

		if (input.Keyboard.IsKeyPressed(.Escape))
			host.RequestExit(0);
		if (input.Keyboard.IsKeyPressed(.R))
			RespawnStack();

		DriveCharacter(input);
		BindHudButton();
		BindKioskButton();
		ShoveUnderCursor(host, input);
		ReportTriggers();

		if (mOverlay != null)
		{
			mOverlay.NewFrame(input, deltaTime);
			DrawHud(host);
		}

		AdvanceSweeper(host, deltaTime);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if ((mScene != null) && (frame.Height > 0))
		{
			if (let cameras = mScene.GetSystem<CameraComponentManager>())
			{
				if (let camera = cameras.Get(mCamera))
					camera.Aspect = (float)frame.Width / (float)frame.Height;
			}
		}

		base.OnRenderWindow(host, ref frame);

		if (mOverlay != null)
			mOverlay.Render(ref frame);
	}

	// ---- the world ----

	private void BuildWorld()
	{
		let bodies = mScene.GetSystem<RigidBodyComponentManager>();
		if (bodies == null)
			return;

		// An infinite plane rather than a slab, so a crate that flies off the stack still
		// lands on something.
		{
			let entity = mScene.CreateEntity("ground");
			let body = bodies.Add(entity);
			body.Motion = .Static;
			body.Layer = .Static;
			body.Shape = .Plane;
			body.PlaneHalfExtent = 200.0f;
		}

		mRampShape = CookedShapes.Ramp();
		if (mRampShape != null)
		{
			let entity = mScene.CreateEntity("ramp");
			let body = bodies.Add(entity);
			body.Motion = .Static;
			body.Layer = .Static;
			body.Shape = .Cooked;
			body.CollisionShape.SetDirect(mRampShape);
		}

		mBoulderShape = CookedShapes.Boulder();
		if (mBoulderShape != null)
		{
			mBoulder = mScene.CreateEntity("boulder");
			mScene.SetLocalPosition(mBoulder, .(14.0f, 8.0f, 0.0f));
			let body = bodies.Add(mBoulder);
			body.Shape = .Cooked; // a HULL may move; a triangle mesh may not
			body.CollisionShape.SetDirect(mBoulderShape);
			body.Friction = 0.4f;
		}

		for (int row < cCrateRows)
		{
			for (int column < cCrateColumns)
			{
				let entity = mScene.CreateEntity("crate");
				mScene.SetLocalPosition(entity, CratePosition(row, column));
				let body = bodies.Add(entity);
				body.HalfExtents = .(0.5f, 0.5f, 0.5f);
				body.Friction = 0.6f;
				mCrates.Add(entity);
			}
		}

		BuildHero();
		BuildKiosk();
		BuildSpinner(bodies);
		BuildHud();

		// A kinematic sweeper the update drives in a circle, which is what shows that a
		// kinematic body pushes dynamic ones without being pushed back.
		{
			mSweeper = mScene.CreateEntity("sweeper");
			mScene.SetLocalPosition(mSweeper, .(6.0f, 0.75f, 0.0f));
			let body = bodies.Add(mSweeper);
			body.Motion = .Kinematic;
			body.Layer = .Kinematic;
			body.HalfExtents = .(0.4f, 0.75f, 0.4f);
		}

		{
			let entity = mScene.CreateEntity("trigger");
			mScene.SetLocalPosition(entity, .(0.0f, 6.0f, 0.0f));
			let body = bodies.Add(entity);
			body.Motion = .Kinematic;
			body.IsTrigger = true;
			body.HalfExtents = .(2.0f, 1.0f, 2.0f);
		}
	}

	private static Float3 CratePosition(int row, int column) =>
		.((column - 2) * 1.05f, 0.5f + row * 1.05f, 0.0f);

	private void BuildHero()
	{
		mHero = mScene.CreateEntity("hero");
		mScene.SetLocalPosition(mHero, .(-6.0f, 0.9f, 4.0f));

		if (let characters = mScene.GetSystem<CharacterComponentManager>())
		{
			let hero = characters.Add(mHero);
			// A crate is about a tonne at Jolt's default density, so the default strength
			// barely nudges one. The shove has to read on screen.
			hero.MaxStrength = 6000.0f;
		}

		mNameplateDocument = new UIDocument();
		mNameplateDocument.Markup.Set(PlaygroundMarkup.cNameplate);

		if (let billboards = mScene.GetSystem<UIBillboardComponentManager>())
		{
			let plate = billboards.Add(mHero);
			plate.Document.SetDirect(mNameplateDocument);
			plate.Offset = .(0.0f, 1.4f, 0.0f); // above the capsule
			plate.ScaleMode = .Distance;
			plate.ReferenceDistance = 12.0f;
		}
	}

	private void BuildKiosk()
	{
		let entity = mScene.CreateEntity("kiosk");
		mScene.SetLocalPosition(entity, .(4.0f, 1.6f, -6.0f));

		mKioskDocument = new UIDocument();
		mKioskDocument.Markup.Set(PlaygroundMarkup.cKiosk);

		if (let panels = mScene.GetSystem<UIWorldPanelComponentManager>())
		{
			let panel = panels.Add(entity);
			panel.Document.SetDirect(mKioskDocument);
			panel.SizeMeters = .(1.6f, 1.0f);
			panel.PixelsPerMeter = 220.0f;
			mKioskEntity = entity;
		}
	}

	/// A blade on a motorised hinge, welded to the world: walk the character into it to be
	/// batted away.
	private void BuildSpinner(RigidBodyComponentManager bodies)
	{
		let entity = mScene.CreateEntity("spinner");
		mScene.SetLocalPosition(entity, .(-6.0f, 1.0f, -4.0f));

		let body = bodies.Add(entity);
		body.HalfExtents = .(2.0f, 0.1f, 0.1f);

		if (let joints = mScene.GetSystem<JointComponentManager>())
		{
			let joint = joints.Add(entity);
			joint.Kind = .Hinge;
			joint.LocalAxis = .(0.0f, 1.0f, 0.0f);
			joint.MotorEnabled = true;
			joint.MotorTargetVelocity = 2.0f;
		}
	}

	private void BuildHud()
	{
		mHudDocument = new UIDocument();
		mHudDocument.Markup.Set(PlaygroundMarkup.cHud);

		let entity = mScene.CreateEntity("hud");
		if (let canvases = mScene.GetSystem<UICanvasComponentManager>())
		{
			let canvas = canvases.Add(entity);
			canvas.Document.SetDirect(mHudDocument);
			mHudEntity = entity;
		}
	}

	// ---- the update ----

	/// The arrow keys drive the character along WORLD axes rather than the camera's, so the
	/// fly camera can be looking anywhere while it walks.
	private void DriveCharacter(IInputManager input)
	{
		let characters = mScene.GetSystem<CharacterComponentManager>();
		if (characters == null)
			return;

		let hero = characters.Get(mHero);
		if (hero == null)
			return;

		const float cSpeed = 4.0f;
		var move = Float3(0.0f, 0.0f, 0.0f);
		if (input.Keyboard.IsKeyDown(.Right))
			move.X += cSpeed;
		if (input.Keyboard.IsKeyDown(.Left))
			move.X -= cSpeed;
		if (input.Keyboard.IsKeyDown(.Up))
			move.Z -= cSpeed;
		if (input.Keyboard.IsKeyDown(.Down))
			move.Z += cSpeed;

		hero.MoveVelocity = move;
		if (input.Keyboard.IsKeyPressed(.Space))
			hero.JumpSpeed = 6.0f;
	}

	/// Bound from the update rather than at build time: the tree does not exist until the UI
	/// subsystem has instantiated the document.
	private void BindHudButton()
	{
		if (mHudBound || (mScene == null))
			return;

		let canvases = mScene.GetSystem<UICanvasComponentManager>();
		if (canvases == null)
			return;

		let canvas = canvases.Get(mHudEntity);
		if ((canvas == null) || (canvas.Root == null))
			return;

		let group = canvas.Root as ViewGroup;
		if (group == null)
			return;

		let button = group.FindByName<Button>("hud-btn");
		if (button == null)
			return;

		button.OnClick.Add(new (sender) =>
			{
				mHudClicks++;
				button.SetText(scope $"Clicks: {mHudClicks}");
				Console.WriteLine("PhysicsPlayground: HUD button clicked.");
			});
		mHudBound = true;
	}

	private void BindKioskButton()
	{
		if (mKioskBound || (mScene == null))
			return;

		let panels = mScene.GetSystem<UIWorldPanelComponentManager>();
		if (panels == null)
			return;

		let panel = panels.Get(mKioskEntity);
		if ((panel == null) || (panel.RenderRoot == null))
			return;

		let button = panel.RenderRoot.FindByName<Button>("kiosk-btn");
		if (button == null)
			return;

		button.OnClick.Add(new (sender) =>
			{
				mKioskTaps++;
				button.SetText(scope $"Taps: {mKioskTaps}");
				Console.WriteLine("PhysicsPlayground: kiosk panel tapped.");
			});
		mKioskBound = true;
	}

	private void ShoveUnderCursor(IApplicationHost host, IInputManager input)
	{
		// A click the UI ate never reaches the world. That gate IS what the HUD button is
		// there to demonstrate.
		let gameUi = host.Context.GetSubsystem<UISubsystem>();
		if ((gameUi != null) && gameUi.PointerOverUI)
			return;

		if (!input.Mouse.IsButtonPressed(.Left) || (mPhysics == null) || (mPhysics.World == null))
			return;

		let direction = ShoveDirection(host, input);
		if (!mPhysics.World.RayCast(mFly.Position, direction, 200.0f, let hit))
			return;

		// A crate is about a tonne, so the impulse has to be in the thousands. A few hundred
		// only WAKES the body, which reads as a highlight rather than a shove.
		mPhysics.World.AddImpulse(hit.Body, .(direction.X * 4000.0f,
			direction.Y * 4000.0f + 1400.0f, direction.Z * 4000.0f));
		mLastSurface = hit.Surface;
		mHaveSurface = true;
	}

	/// Through the CURSOR while it is free, and along the camera forward while looking
	/// captures the mouse: the same convention the kiosk panel's pointer uses, so aiming
	/// means the same thing in both.
	private Float3 ShoveDirection(IApplicationHost host, IInputManager input)
	{
		let captured = mFly.MouseCaptured || input.Mouse.IsButtonDown(.Right);
		let window = (host.Shell != null) ? host.Shell.MainWindow : null;
		if (captured || (window == null) || (window.Width <= 0) || (window.Height <= 0))
			return mFly.Forward;

		var fovY = 1.04719755f;
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
		{
			if (let camera = cameras.Get(mCamera))
				fovY = camera.FovYRadians;
		}

		let width = (float)window.Width;
		let height = (float)window.Height;
		let ndcX = (input.Mouse.X / width) * 2.0f - 1.0f;
		let ndcY = 1.0f - (input.Mouse.Y / height) * 2.0f;
		let tanHalfY = Tan(fovY * 0.5f);
		let tanHalfX = tanHalfY * (width / height);

		return Normalized(mFly.Forward + mFly.Right * (ndcX * tanHalfX)
			+ mFly.Up * (ndcY * tanHalfY));
	}

	private void ReportTriggers()
	{
		if (mPhysics == null)
			return;

		for (let event in mPhysics.Events)
		{
			if (event.Kind == .TriggerEnter)
				Console.WriteLine("PhysicsPlayground: trigger entered!");
		}
	}

	private void RespawnStack()
	{
		if ((mPhysics == null) || (mPhysics.World == null))
			return;

		let bodies = mScene.GetSystem<RigidBodyComponentManager>();
		if (bodies == null)
			return;

		for (int i < mCrates.Count)
		{
			let body = bodies.Get(mCrates[i]);
			if ((body == null) || !body.Body.IsValid)
				continue;

			let position = CratePosition(i / cCrateColumns, i % cCrateColumns);
			mPhysics.World.SetBodyTransform(body.Body, position, Quaternion.Identity);
			mPhysics.World.SetLinearVelocity(body.Body, .(0, 0, 0));

			// Both interpolation ends, or the crate is drawn sliding from where it was.
			body.PrevPosition = position;
			body.CurrPosition = position;
			body.PrevRotation = Quaternion.Identity;
			body.CurrRotation = Quaternion.Identity;
		}
	}

	private void AdvanceSweeper(IApplicationHost host, float deltaTime)
	{
		mSweepAngle += 0.6f * deltaTime * host.Context.TimeScale;
		if (!mSweeper.IsAssigned)
			return;

		mScene.SetLocalPosition(mSweeper, .(6.0f * Cos(mSweepAngle), 0.75f,
			6.0f * Sin(mSweepAngle)));
	}

	private void PushCameraToEntity()
	{
		if (mScene == null)
			return;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);
	}

	private void DrawHud(IApplicationHost host)
	{
		igSetNextWindowPos(.() { x = 10, y = 10 }, (int32)ImGuiCond.ImGuiCond_FirstUseEver, .());
		igBegin("Physics", null, 0);

		if ((mPhysics != null) && (mPhysics.World != null))
		{
			igText(scope $"bodies: {mPhysics.World.BodyCount}");

			var gravity = mPhysics.World.Gravity;
			if (igSliderFloat("gravity y", &gravity.Y, -30.0f, 10.0f, "%.2f", 0))
				mPhysics.World.SetGravity(gravity);
		}

		var scale = host.Context.TimeScale;
		if (igSliderFloat("time scale", &scale, 0.0f, 2.0f, "%.2f", 0))
			host.Context.TimeScale = scale;

		if (mHaveSurface)
			igText(scope $"last hit surface slot: {mLastSurface}");

		if (let characters = mScene.GetSystem<CharacterComponentManager>())
		{
			if (let hero = characters.Get(mHero))
			{
				let state = hero.Grounded ? "grounded" : "airborne";
				igText(scope $"character: {state}");
			}
		}

		igText("left button shoves, R respawns, arrows and Space walk, Esc quits");
		igEnd();
	}
}
