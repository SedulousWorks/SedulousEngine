// Gallery - the camera's behaviour: the lesson list beside the view, a free flight through the hall,
// and a glide to a lesson when its row is clicked.
//
// Fly with WASD or the left stick, Q and E (or the shoulders) to sink and rise, Shift (or pressing
// the stick) to go faster; look with the mouse while its right button is held, or the right stick.
// H (or Y) hides the list and the caption. A row glides the camera to that lesson's viewpoint
// ("ViewNN"), looking at its exhibit ("LessonNN"), and shows what the lesson teaches and its file in
// the caption at the foot of the view; flying by hand again leaves both alone.
//
// GENERATED from Tools/scripts/Gallery.as.in by Tools/ui.py, which fills in the lessons' handlers
// from Tools/lessons.py: edit the template and the table, not the generated copy.
Guid kGalleryDoc = Guid::FromString("19918547-b90e-1f4a-b488-1dde85e7d18b");

// Smooth start and stop for the glide: 0 to 1 over t in 0 to 1.
float SmoothGlide(float t)
{
	t = Clamp(t, 0.0f, 1.0f);
	return t * t * (3.0f - 2.0f * t);
}

class Gallery
{
	Entity self;
	Scene@ scene;

	[4.0, "Flying speed (m/s)"] float speed;
	[3.0, "How much faster with Fast held"] float fastFactor;
	[0.15, "Mouse look (degrees per pixel moved)"] float mouseLook;
	[110.0, "Stick look (degrees per second at full tilt)"] float stickLook;
	[1.2, "How long a glide to a lesson takes (s)"] float glideTime;
	[0.0, "Starting yaw (degrees; 0 looks down -Z)"] float startYaw;
	[-8.0, "Starting pitch (degrees; up is positive)"] float startPitch;
	[12.0, "How far a glide turns left of its lesson while the list shows (degrees), so the lesson sits in the free view"] float listYaw;

	private float m_yaw = 0.0f;
	private float m_pitch = 0.0f;
	private bool m_gliding = false;
	private float m_glideT = 0.0f;
	private Float3 m_fromPos = Float3(0.0f, 0.0f, 0.0f);
	private Float3 m_toPos = Float3(0.0f, 0.0f, 0.0f);
	private float m_fromYaw = 0.0f;
	private float m_toYaw = 0.0f;
	private float m_fromPitch = 0.0f;
	private float m_toPitch = 0.0f;
	private bool m_panelShown = true;
	private bool m_captioned = false;

	void onStart()
	{
		m_yaw = startYaw;
		m_pitch = startPitch;
		UIScreen s = Ui.Push(kGalleryDoc);
		s.FindButton("lesson-1").OnClick(ScriptCallback(this.onLesson1));
		s.FindButton("lesson-2").OnClick(ScriptCallback(this.onLesson2));
		s.FindButton("lesson-3").OnClick(ScriptCallback(this.onLesson3));
		s.FindButton("lesson-4").OnClick(ScriptCallback(this.onLesson4));
		s.FindButton("lesson-5").OnClick(ScriptCallback(this.onLesson5));
		s.FindButton("lesson-6").OnClick(ScriptCallback(this.onLesson6));
		s.FindButton("lesson-7").OnClick(ScriptCallback(this.onLesson7));
		s.FindButton("lesson-8").OnClick(ScriptCallback(this.onLesson8));
		s.FindButton("lesson-9").OnClick(ScriptCallback(this.onLesson9));
		s.FindButton("lesson-10").OnClick(ScriptCallback(this.onLesson10));
		s.FindButton("lesson-11").OnClick(ScriptCallback(this.onLesson11));
		place(self.GetWorldPosition());
	}

	void onUpdate(float dt)
	{
		if (Input.WasPressed("TogglePanel"))
		{
			m_panelShown = !m_panelShown;
			Ui.Find("gallery-panel").SetVisible(m_panelShown);
			Ui.Find("gallery-caption").SetVisible(m_panelShown && m_captioned);
		}

		// Looking: the mouse while its right button is held, or the right stick.
		Float2 look = Float2(0.0f, 0.0f);
		if (Input.IsDown("LookHold"))
		{
			Float2 m = Input.Value2D("Look");
			look = Float2(-m.X * mouseLook, -m.Y * mouseLook);
		}
		Float2 stick = Input.Value2D("LookStick");
		look = Float2(look.X - stick.X * stickLook * dt, look.Y + stick.Y * stickLook * dt);

		// Flying: along where the camera looks, and straight up or down.
		Float2 move = Input.Value2D("Move");
		float rise = (Input.IsDown("Rise") ? 1.0f : 0.0f) - (Input.IsDown("Sink") ? 1.0f : 0.0f);
		bool manual = Abs(look.X) + Abs(look.Y) + Abs(move.X) + Abs(move.Y) + Abs(rise) > 0.0001f;

		if (m_gliding && !manual)
		{
			m_glideT += dt / glideTime;
			float k = SmoothGlide(m_glideT);
			Float3 at = Float3(m_fromPos.X + (m_toPos.X - m_fromPos.X) * k,
				m_fromPos.Y + (m_toPos.Y - m_fromPos.Y) * k,
				m_fromPos.Z + (m_toPos.Z - m_fromPos.Z) * k);
			m_yaw = m_fromYaw + (m_toYaw - m_fromYaw) * k;
			m_pitch = m_fromPitch + (m_toPitch - m_fromPitch) * k;
			m_gliding = m_glideT < 1.0f;
			place(at);
			return;
		}
		m_gliding = false; // a hand on the controls takes over from a glide

		m_yaw += look.X;
		m_pitch = Clamp(m_pitch + look.Y, -85.0f, 85.0f);
		float fast = Input.IsDown("Fast") ? fastFactor : 1.0f;
		float yaw = DegreesToRadians(m_yaw);
		float pitch = DegreesToRadians(m_pitch);
		// Forward from yaw and pitch (yaw 0 looks down -Z); right is level.
		Float3 forward = Float3(-Sin(yaw) * Cos(pitch), Sin(pitch), -Cos(yaw) * Cos(pitch));
		Float3 right = Float3(Cos(yaw), 0.0f, -Sin(yaw));
		float step = speed * fast * dt;
		Float3 p = self.GetWorldPosition();
		place(Float3(p.X + (forward.X * move.Y + right.X * move.X) * step,
			p.Y + (forward.Y * move.Y + rise) * step,
			p.Z + (forward.Z * move.Y + right.Z * move.X) * step));
	}

	// Glides to lesson `n`: its viewpoint ("ViewNN"), looking at its exhibit ("LessonNN").
	private void showLesson(int n, string title, string summary, string file)
	{
		string id = (n < 10 ? "0" : "") + n;
		Entity view = scene.FindEntityByName("View" + id);
		Entity exhibit = scene.FindEntityByName("Lesson" + id);
		Ui.FindLabel("gallery-title").SetText(n + ". " + title);
		Ui.FindLabel("gallery-about").SetText(summary);
		Ui.FindLabel("gallery-file").SetText(file);
		m_captioned = true;
		Ui.Find("gallery-caption").SetVisible(m_panelShown);
		if (!view.IsValid() || !exhibit.IsValid())
			return;
		m_fromPos = self.GetWorldPosition();
		m_toPos = view.GetWorldPosition();
		Float3 target = exhibit.GetWorldPosition();
		Float3 dir = Float3(target.X - m_toPos.X, target.Y - m_toPos.Y, target.Z - m_toPos.Z);
		float len = Sqrt(dir.X * dir.X + dir.Y * dir.Y + dir.Z * dir.Z);
		if (len < 0.0001f)
			return;
		m_fromYaw = m_yaw;
		m_fromPitch = m_pitch;
		// Turned a little left while the list covers the left of the screen, so the lesson sits in
		// the middle of what is left.
		m_toYaw = RadiansToDegrees(Atan2(-dir.X, -dir.Z)) + (m_panelShown ? listYaw : 0.0f);
		m_toPitch = RadiansToDegrees(Asin(dir.Y / len));
		// The short way round.
		while (m_toYaw - m_fromYaw > 180.0f) m_toYaw -= 360.0f;
		while (m_toYaw - m_fromYaw < -180.0f) m_toYaw += 360.0f;
		m_glideT = 0.0f;
		m_gliding = true;
	}

	private void place(Float3 at)
	{
		self.SetLocalPosition(at);
		self.SetLocalRotation(FromYawPitchRoll(DegreesToRadians(m_yaw), DegreesToRadians(m_pitch), 0.0f));
	}

	private void onLesson1() { showLesson(1, "Unlit Colour", "The smallest shader: a properties block and Surface().", "Sources/01_UnlitColour.hlsl"); }
	private void onLesson2() { showLesson(2, "Textured", "A texture and its sampler, the uv, the vertex colour; lit by the scene.", "Sources/02_Textured.hlsl"); }
	private void onLesson3() { showLesson(3, "Lava", "Time() makes it move; emission makes it glow.", "Sources/03_Lava.hlsl"); }
	private void onLesson4() { showLesson(4, "Hologram", "viewDir makes a fresnel rim, screenPos scanlines; alpha on a blended material.", "Sources/04_Hologram.hlsl"); }
	private void onLesson5() { showLesson(5, "Triplanar Rock", "Mapped by world position, no uv; a normal map turned into tangent space.", "Sources/05_TriplanarRock.hlsl"); }
	private void onLesson6() { showLesson(6, "Dissolve", "alpha on a masked material cuts holes, in the shadow too; a burning edge.", "Sources/06_Dissolve.hlsl"); }
	private void onLesson7() { showLesson(7, "Waves", "Vertex() moves the vertices into waves; the shadow and the light follow.", "Sources/07_Waves.hlsl"); }
	private void onLesson8() { showLesson(8, "Wind", "Vertex() by localPosition: the hoist stays on the pole, the fly end flaps.", "Sources/08_Wind.hlsl"); }
	private void onLesson9() { showLesson(9, "Built-in PBR", "The engine's own material written as a surface: the reference to start from.", "Sources/09_BuiltInPbr.hlsl"); }
	private void onLesson10() { showLesson(10, "Toon", "Both stages written out: the light in bands, a shadow colour, a rim.", "Sources/10_Toon.hlsl"); }
	private void onLesson11() { showLesson(11, "Custom Lighting", "Walking the lights itself (LightsAt, LightAt, ShadowOf): half-Lambert and Blinn-Phong.", "Sources/11_CustomLighting.hlsl"); }
}
