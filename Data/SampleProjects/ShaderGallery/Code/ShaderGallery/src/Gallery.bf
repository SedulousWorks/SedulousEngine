using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Engine.Input;
using Sedulous.Engine.Gameplay;

namespace ShaderGallery;

/// One lesson of the gallery: its row in the list, what its caption says, and the hall's
/// entities a click on its row glides to. The table of them is Lessons.All.
struct Lesson
{
	/// Its number: its row's id is "lesson-<Number>", and its caption starts with it.
	public int32 Number;
	public StringView Title;
	/// What it teaches, the caption's middle line.
	public StringView Summary;
	/// Its shader's source in the project, the caption's last line.
	public StringView File;
	/// Its viewpoint, where a glide to it ends.
	public StringView View;
	/// Its exhibit, which the camera faces at the end of the glide.
	public StringView Exhibit;

	public this(int32 number, StringView title, StringView summary, StringView file, StringView view, StringView exhibit)
	{
		Number = number;
		Title = title;
		Summary = summary;
		File = file;
		View = view;
		Exhibit = exhibit;
	}
}

/// The camera's behaviour: the lesson list beside the view, a free flight through the hall, and a
/// glide to a lesson when its row is clicked.
///
/// Fly with WASD or the left stick, Q and E (or the shoulders) to sink and rise, Shift (or
/// pressing the stick) to go faster; look with the mouse while its right button is held, or the
/// right stick. H (or Y) hides the list and the caption. A row glides the camera to that lesson's
/// viewpoint, looking at its exhibit, and shows what the lesson teaches and its file in the
/// caption at the foot of the view; flying by hand again leaves both alone. The actions are the
/// project's input map's (Tools/controls.py), the list the GUI document LessonList names
/// (Tools/ui.py writes it, with the lesson table).
[Behaviour("shadergallery.gallery")]
[DisplayName("Gallery")]
[Category("Shader Gallery")]
[Description("The lesson list, a free flight through the hall, and a glide to the lesson picked.")]
class Gallery : Behaviour
{
	[Description("Flying speed (m/s)")]
	public float Speed = 4.0f;
	[Description("How much faster with Fast held")]
	public float FastFactor = 3.0f;
	[Description("Mouse look (degrees per pixel moved)")]
	public float MouseLook = 0.15f;
	[Description("Stick look (degrees per second at full tilt)")]
	public float StickLook = 110.0f;
	[Description("How long a glide to a lesson takes (s)")]
	public float GlideTime = 1.2f;
	[Description("Starting yaw (degrees; 0 looks down -Z)")]
	public float StartYaw = 0.0f;
	[Description("Starting pitch (degrees; up is positive)")]
	public float StartPitch = -8.0f;
	[Description("How far a glide turns left of its lesson while the list shows (degrees), so the lesson sits in the free view")]
	public float ListYaw = 12.0f;
	[Description("The lesson list's GUI document, pushed on the run's screens as the gallery starts (it blocks none of the hall's input)")]
	public Ref<GuiDocument> LessonList = .(Guid());

	private float mYaw = 0.0f;
	private float mPitch = 0.0f;
	private bool mGliding = false;
	private float mGlideT = 0.0f;
	private Float3 mFromPos = .(0.0f, 0.0f, 0.0f);
	private Float3 mToPos = .(0.0f, 0.0f, 0.0f);
	private float mFromYaw = 0.0f;
	private float mToYaw = 0.0f;
	private float mFromPitch = 0.0f;
	private float mToPitch = 0.0f;
	private bool mPanelShown = true;
	private bool mCaptioned = false;
	/// The lesson list's screen on the run's stack, a reference held from OnStart to OnDestroy;
	/// null outside a run with a GUI, or when the document did not load.
	private Screen mScreen = null;
	/// Each row's click handler, by lesson, for Off as the behaviour goes: the GUI owns the
	/// handlers, which call into this instance.
	private int32[Lessons.Count] mRowTokens = default;

	/// Smooth start and stop for the glide: 0 to 1 over t in 0 to 1.
	private static float SmoothGlide(float t)
	{
		let k = Clamp(t, 0.0f, 1.0f);
		return k * k * (3.0f - 2.0f * k);
	}

	protected override void OnStart()
	{
		mYaw = StartYaw;
		mPitch = StartPitch;
		ShowList();
		Place(Scene.GetWorldPosition(Entity));
	}

	protected override void OnDestroy()
	{
		if (mScreen != null)
		{
			for (int i < Lessons.Count)
			{
				let row = mScreen.FindElement(scope $"lesson-{Lessons.All[i].Number}");
				if (row != null)
					row.Off(mRowTokens[i]);
			}
			// Off the stack when it is still on top, so a fresh instance (a re-read, a scene
			// loaded again) pushes the only copy.
			let stack = mScreen.Stack;
			if ((stack != null) && (stack.Top == mScreen))
				stack.Pop();
			mScreen.ReleaseRef();
			mScreen = null;
		}
	}

	/// The lesson list on the run GUI's screen stack, over the hall, its caption hidden until a
	/// lesson is picked, and each row wired to its lesson.
	private void ShowList()
	{
		let gui = RunServices.Get<GuiFacade>(Run);
		let root = (gui != null) ? gui.Root() : null;
		let stack = (root != null) ? (root.FindElement("screens") as ScreenStack) : null;
		if ((stack == null) || (LessonList.Id == Guid.Empty))
			return;
		mScreen = stack.PushDocument(LessonList.Id.ToString(.. scope .()));
		if (mScreen == null)
			return;
		mScreen.AddRef();
		SetVisible("gallery-caption", false);
		for (int i < Lessons.Count)
		{
			let row = mScreen.FindElement(scope $"lesson-{Lessons.All[i].Number}");
			if (row == null)
				continue;
			let index = i;
			mRowTokens[index] = row.On("click", new [=this, =index] (e) =>
				{
					ShowLesson(Lessons.All[index]);
					return true;
				});
		}
	}

	protected override void OnUpdate(float dt)
	{
		let input = RunServices.Get<InputFacade>(Run);
		if ((input != null) && input.WasPressed("TogglePanel"))
		{
			mPanelShown = !mPanelShown;
			SetVisible("gallery-panel", mPanelShown);
			SetVisible("gallery-caption", mPanelShown && mCaptioned);
		}

		// Looking: the mouse while its right button is held, or the right stick.
		Float2 look = .(0.0f, 0.0f);
		Float2 move = .(0.0f, 0.0f);
		float rise = 0.0f;
		bool fastHeld = false;
		if (input != null)
		{
			if (input.IsDown("LookHold"))
			{
				let mouse = input.Value2D("Look");
				look = .(-mouse.X * MouseLook, -mouse.Y * MouseLook);
			}
			let stick = input.Value2D("LookStick");
			look = .(look.X - stick.X * StickLook * dt, look.Y + stick.Y * StickLook * dt);
			// Flying: along where the camera looks, and straight up or down.
			move = input.Value2D("Move");
			rise = (input.IsDown("Rise") ? 1.0f : 0.0f) - (input.IsDown("Sink") ? 1.0f : 0.0f);
			fastHeld = input.IsDown("Fast");
		}
		let manual = Abs(look.X) + Abs(look.Y) + Abs(move.X) + Abs(move.Y) + Abs(rise) > 0.0001f;

		if (mGliding && !manual)
		{
			mGlideT += dt / GlideTime;
			let k = SmoothGlide(mGlideT);
			let at = Float3(mFromPos.X + (mToPos.X - mFromPos.X) * k,
				mFromPos.Y + (mToPos.Y - mFromPos.Y) * k,
				mFromPos.Z + (mToPos.Z - mFromPos.Z) * k);
			mYaw = mFromYaw + (mToYaw - mFromYaw) * k;
			mPitch = mFromPitch + (mToPitch - mFromPitch) * k;
			mGliding = mGlideT < 1.0f;
			Place(at);
			return;
		}
		mGliding = false; // a hand on the controls takes over from a glide

		mYaw += look.X;
		mPitch = Clamp(mPitch + look.Y, -85.0f, 85.0f);
		let fast = fastHeld ? FastFactor : 1.0f;
		let yaw = DegreesToRadians(mYaw);
		let pitch = DegreesToRadians(mPitch);
		// Forward from yaw and pitch (yaw 0 looks down -Z); right is level.
		let forward = Float3(-Sin(yaw) * Cos(pitch), Sin(pitch), -Cos(yaw) * Cos(pitch));
		let right = Float3(Cos(yaw), 0.0f, -Sin(yaw));
		let step = Speed * fast * dt;
		let p = Scene.GetWorldPosition(Entity);
		Place(Float3(p.X + (forward.X * move.Y + right.X * move.X) * step,
			p.Y + (forward.Y * move.Y + rise) * step,
			p.Z + (forward.Z * move.Y + right.Z * move.X) * step));
	}

	/// Glides to `lesson`: its viewpoint, looking at its exhibit, its caption shown.
	private void ShowLesson(Lesson lesson)
	{
		SetText("gallery-title", scope $"{lesson.Number}. {lesson.Title}");
		SetText("gallery-about", lesson.Summary);
		SetText("gallery-file", lesson.File);
		mCaptioned = true;
		SetVisible("gallery-caption", mPanelShown);
		let view = Scene.FindEntityByName(lesson.View);
		let exhibit = Scene.FindEntityByName(lesson.Exhibit);
		if (!Scene.IsValid(view) || !Scene.IsValid(exhibit))
			return;
		mFromPos = Scene.GetWorldPosition(Entity);
		mToPos = Scene.GetWorldPosition(view);
		let target = Scene.GetWorldPosition(exhibit);
		let dir = Float3(target.X - mToPos.X, target.Y - mToPos.Y, target.Z - mToPos.Z);
		let len = Sqrt(dir.X * dir.X + dir.Y * dir.Y + dir.Z * dir.Z);
		if (len < 0.0001f)
			return;
		mFromYaw = mYaw;
		mFromPitch = mPitch;
		// Turned a little left while the list covers the left of the screen, so the lesson sits
		// in the middle of what is left.
		mToYaw = RadiansToDegrees(Atan2(-dir.X, -dir.Z)) + (mPanelShown ? ListYaw : 0.0f);
		mToPitch = RadiansToDegrees(Asin(dir.Y / len));
		// The short way round.
		while (mToYaw - mFromYaw > 180.0f)
			mToYaw -= 360.0f;
		while (mToYaw - mFromYaw < -180.0f)
			mToYaw += 360.0f;
		mGlideT = 0.0f;
		mGliding = true;
	}

	private void Place(Float3 at)
	{
		Scene.SetLocalPosition(Entity, at);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(DegreesToRadians(mYaw), DegreesToRadians(mPitch), 0.0f));
	}

	/// Shows or hides the list's element `id`; nothing without the list.
	private void SetVisible(StringView id, bool visible)
	{
		if (mScreen == null)
			return;
		if (let node = mScreen.FindElement(id))
			node.Visible = visible;
	}

	/// Sets the text of the list's label `id`; nothing without the list.
	private void SetText(StringView id, StringView text)
	{
		if (mScreen == null)
			return;
		if (let label = mScreen.FindElement(id) as Label)
			label.Text = text;
	}
}
