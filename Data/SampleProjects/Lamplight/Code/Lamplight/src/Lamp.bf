using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Materials;
using Sedulous.Engine.Render;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// An oil lamp, a torch or a lantern the thief can put out and light again: in reach, the HUD says
/// which, and the Interact control does it. Out, its light is off and its flame and chimney stop
/// glowing (their material slots swapped for dark ones), so the room goes as dark as the renderer
/// and the light meter say. Lit at the start unless Lit is off.
[Behaviour("lamplight.lamp")]
[DisplayName("Lamp"), Category("Lamplight")]
[Description("A lamp the thief puts out and lights again with Interact: its light, and its flame and chimney's materials, follow.")]
class Lamp : Behaviour
{
	[Description("The thief")]
	public EntityRef Thief = .();
	[Description("The lamp's light")]
	public EntityRef Light = .();
	[Description("How near the thief must stand to reach it (m)")]
	public float Reach = 1.6f;
	[Description("Lit at the start")]
	public bool Lit = true;
	[Description("The material slot of the flame")]
	public int32 FlameSlot = 1;
	[Description("The material slot of the chimney")]
	public int32 ChimneySlot = 2;
	[Description("The flame burning")]
	public Ref<Material> FlameLit = .(Guid());
	[Description("The flame out")]
	public Ref<Material> FlameOut = .(Guid());
	[Description("The chimney glowing")]
	public Ref<Material> ChimneyLit = .(Guid());
	[Description("The chimney dark")]
	public Ref<Material> ChimneyOut = .(Guid());

	/// The entities the references name in this scene, found as it starts.
	private EntityHandle mThief = .Invalid;
	private EntityHandle mLight = .Invalid;
	/// This lamp set the HUD's prompt (only the lamp that set it clears it).
	private bool mPrompting = false;

	protected override void OnStart()
	{
		mThief = Scene.FindEntity(Thief.Id);
		mLight = Scene.FindEntity(Light.Id);
		Apply();
	}

	protected override void OnUpdate(float dt)
	{
		if (!Scene.IsValid(mThief))
			return;
		let a = Scene.GetWorldPosition(Entity);
		let b = Scene.GetWorldPosition(mThief);
		let dx = a.X - b.X;
		let dz = a.Z - b.Z;
		let near = dx * dx + dz * dz <= Reach * Reach;
		if (near && Pieces.WasPressed(Run, "Interact"))
		{
			Lit = !Lit;
			Apply();
		}
		Prompt(near);
	}

	/// The light on or off, and the flame's and the chimney's materials to match. A slot below 0
	/// (a torch has no chimney) changes nothing.
	private void Apply()
	{
		if (Scene.IsValid(mLight))
		{
			if (let light = Scene.GetComponent<LightComponent>(mLight))
				light.Enabled = Lit;
		}
		if (let meshes = Scene.GetSystem<MeshComponentManager>())
		{
			meshes.SetMaterial(Entity, Lit ? FlameLit.Id : FlameOut.Id, FlameSlot);
			meshes.SetMaterial(Entity, Lit ? ChimneyLit.Id : ChimneyOut.Id, ChimneySlot);
		}
	}

	/// The HUD's prompt while in reach; cleared on leaving, only by the lamp that set it.
	private void Prompt(bool near)
	{
		if (near)
		{
			let panel = Hud.Find(Run, "hud-prompt-panel");
			if (panel == null)
				return; // the HUD is not up
			// The control Interact takes on the device in hand, not the action's name.
			let use = Pieces.Describe(Run, "Interact", .. scope String());
			Hud.SetText(Hud.Find(Run, "hud-prompt"), scope String()..AppendF(Lit ? "{}: put out the lamp" : "{}: light the lamp", use));
			panel.Visible = true;
			if (let pick = Hud.Find(Run, "hud-pick")) // a door's
				pick.Visible = false;
			mPrompting = true;
		}
		else if (mPrompting)
		{
			if (let panel = Hud.Find(Run, "hud-prompt-panel"))
				panel.Visible = false;
			mPrompting = false;
		}
	}
}
