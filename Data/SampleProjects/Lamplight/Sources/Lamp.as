// Lamp - an oil lamp the thief can put out and light again: in reach, the HUD says which, and the
// Interact control does it. Out, its light is off and its flame and chimney stop glowing (their
// materials swapped for dark ones, scene.Render.SetMaterial), so the room goes as dark as the
// renderer and the light meter say. Lit at the start unless `lit` is off.
class Lamp
{
	Entity self;
	Scene@ scene;

	[null, "The thief"] Entity thief;
	[null, "The lamp's light"] Entity light;
	[1.6, "How near the thief must stand to reach it (m)"] float reach;
	[true, "Lit at the start"] bool lit;
	[1, "The material slot of the flame"] int flameSlot;
	[2, "The material slot of the chimney"] int chimneySlot;
	["asset:Material", "The flame burning"] Guid flameLit;
	["asset:Material", "The flame out"] Guid flameOut;
	["asset:Material", "The chimney glowing"] Guid chimneyLit;
	["asset:Material", "The chimney dark"] Guid chimneyOut;

	private bool m_prompting = false;

	void onStart()
	{
		apply();
	}

	void onUpdate(float dt)
	{
		if (!thief.IsValid())
			return;
		Float3 a = self.GetWorldPosition();
		Float3 b = thief.GetWorldPosition();
		float dx = a.X - b.X;
		float dz = a.Z - b.Z;
		bool near = dx * dx + dz * dz <= reach * reach;
		if (near && Input.WasPressed("Interact"))
		{
			lit = !lit;
			apply();
		}
		prompt(near);
	}

	// A slot below 0 (a torch has no chimney) changes nothing.
	private void apply()
	{
		if (light.IsValid())
		{
			LightComponent lamp = LightComponent(light);
			lamp.Enabled = lit;
		}
		scene.Render.SetMaterial(self, lit ? flameLit : flameOut, flameSlot);
		scene.Render.SetMaterial(self, lit ? chimneyLit : chimneyOut, chimneySlot);
	}

	// The HUD's prompt while in reach; cleared on leaving, only by the lamp that set it.
	private void prompt(bool near)
	{
		if (near)
		{
			Label text = Ui.FindLabel("hud-prompt");
			if (text.IsValid)
				text.SetText(lit ? "Interact: put out the lamp" : "Interact: light the lamp");
			Ui.Find("hud-prompt-panel").SetVisible(true);
			m_prompting = true;
		}
		else if (m_prompting)
		{
			Ui.Find("hud-prompt-panel").SetVisible(false);
			m_prompting = false;
		}
	}
}
