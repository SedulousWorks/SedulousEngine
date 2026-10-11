// LightMeter - how lit the thief is, on the HUD: the light reaching the chest (the renderer's own
// lights, falloff and shadows, scene.Render.LightAt), as a meter that eases toward it and a word for
// it. Darkness is cover; the guards read the same light. In the dark he would be lost to the player
// too, so as the meter empties his figure takes on a faint cold glow of its own (its materials'
// EmissiveColor, for this mesh alone): seen by the camera, lighting nothing, so the meter and the
// guards still read the dark.
class LightMeter
{
	Entity self;
	Scene@ scene;

	[0.4, "Where the light is read, above the thief's centre (m): the chest"] float chestHeight;
	[0.15, "The light (luminance) that fills half the meter"] float halfLight;
	[6.0, "How quickly the meter follows the light"] float follow;
	[0.3, "Below this much light (the meter's 0..1) the glow comes up"] float glowBelow;
	[0.03, "The glow's strength in full dark (its EmissiveColor intensity)"] float glowStrength;
	[7, "How many material slots the figure has"] int slots;

	private float m_shown = 0.0f;
	private ProgressBar m_bar;
	private Label m_label;
	private Entity m_figure;
	private float m_glow = -1.0f; // the glow last set

	// How lit, 0..1: the luminance over itself plus `halfLight`, so the dark between the lamps
	// reads near empty, moonlight about half and standing under a lamp near full.
	float level()
	{
		Float3 p = self.GetWorldPosition();
		Float3 light = scene.Render.LightAt(Float3(p.X, p.Y + chestHeight, p.Z));
		float luminance = 0.2126f * light.X + 0.7152f * light.Y + 0.0722f * light.Z;
		return luminance / (luminance + halfLight);
	}

	void onStart()
	{
		// The HUD is the game's (Lamplight.as pushes it before the level loads).
		m_bar = Ui.FindProgressBar("hud-light");
		m_label = Ui.FindLabel("hud-light-label");
		m_shown = level();
	}

	void onUpdate(float dt)
	{
		float k = follow * dt;
		m_shown += (level() - m_shown) * (k > 1.0f ? 1.0f : k);
		if (m_bar.IsValid)
		{
			m_bar.SetValue(m_shown);
		}
		if (m_label.IsValid)
		{
			m_label.SetText(m_shown < 0.25f ? "Hidden" : (m_shown < 0.6f ? "Dim" : "Lit"));
		}
		glow();
	}

	// The glow from the meter: none above `glowBelow`, rising to `glowStrength` in full dark. Set
	// only when it has moved a step, not every frame.
	private void glow()
	{
		float dark = (glowBelow - m_shown) / glowBelow;
		float g = glowStrength * (dark < 0.0f ? 0.0f : (dark > 1.0f ? 1.0f : dark));
		if (Abs(g - m_glow) < 0.01f)
		{
			return;
		}
		m_glow = g;
		Entity fig = figure();
		if (!fig.IsValid())
		{
			return;
		}
		for (int slot = 0; slot < slots; ++slot)
		{
			scene.Render.SetMaterialFloat4(fig, slot, "EmissiveColor", Float4(0.55f, 0.65f, 0.9f, g));
		}
	}

	// The figure's mesh, in the model under the thief (Thief.as finds it the same way).
	private Entity figure()
	{
		if (!m_figure.IsValid())
		{
			Entity model = self.FindChildByName("Thief");
			Entity rig = model.IsValid() ? model.FindChildByName("ThiefRig") : Entity::Invalid;
			m_figure = rig.IsValid() ? rig.FindChildByName("Thief") : Entity::Invalid;
		}
		return m_figure;
	}
}
