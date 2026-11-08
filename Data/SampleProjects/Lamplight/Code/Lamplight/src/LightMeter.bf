using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Engine.Render;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// How lit the thief is, on the HUD: the light reaching the chest (the renderer's own lights,
/// falloff and shadows, RenderExtract.LightAt), as a meter that eases toward it and a word for it.
/// Darkness is cover; the guards read the same light. In the dark he would be lost to the player
/// too, so as the meter empties his figure takes on a faint cold glow of its own (its materials'
/// EmissiveColor, for this mesh alone): seen by the camera, lighting nothing, so the meter and the
/// guards still read the dark.
[Behaviour("lamplight.light_meter")]
[DisplayName("Light Meter"), Category("Lamplight")]
[Description("Shows on the HUD how lit the thief stands, and gives his figure a faint glow in the dark.")]
class LightMeter : Behaviour
{
	[Description("Where the light is read, above the thief's centre (m): the chest")]
	public float ChestHeight = 0.4f;
	[Description("The light (luminance) that fills half the meter")]
	public float HalfLight = 0.15f;
	[Description("How quickly the meter follows the light")]
	public float Follow = 6.0f;
	[Description("Below this much light (the meter's 0..1) the glow comes up")]
	public float GlowBelow = 0.3f;
	[Description("The glow's strength in full dark (its EmissiveColor intensity)")]
	public float GlowStrength = 0.03f;
	[Description("How many material slots the figure has")]
	public int32 Slots = 7;

	/// The meter as shown, 0..1.
	private float mShown = 0.0f;
	/// The figure's mesh, in the model under the thief (Thief finds it the same way).
	private EntityHandle mFigure = .Invalid;
	/// The glow last set.
	private float mGlow = -1.0f;

	/// How lit, 0..1: the luminance over itself plus HalfLight, so the dark between the lamps reads
	/// near empty, moonlight about half and standing under a lamp near full.
	private float LightLevel()
	{
		let p = Scene.GetWorldPosition(Entity);
		let luminance = Pieces.Luminance(RenderExtract.LightAt(Scene, .(p.X, p.Y + ChestHeight, p.Z)));
		return luminance / (luminance + HalfLight);
	}

	protected override void OnStart()
	{
		mShown = LightLevel();
	}

	protected override void OnUpdate(float dt)
	{
		mShown += (LightLevel() - mShown) * Min(Follow * dt, 1.0f);
		// The HUD is the game's, looked up each frame: a new level's HUD is a new tree.
		if (let bar = Hud.Find(Run, "hud-light") as ProgressBar)
		{
			bar.Value = mShown;
			Hud.SetText(Hud.Find(Run, "hud-light-label"), (mShown < 0.25f) ? "Hidden" : ((mShown < 0.6f) ? "Dim" : "Lit"));
		}
		Glow();
	}

	/// The glow from the meter: none above GlowBelow, rising to GlowStrength in full dark. Set only
	/// when it has moved a step, not every frame.
	private void Glow()
	{
		let dark = (GlowBelow - mShown) / GlowBelow;
		let g = GlowStrength * Clamp(dark, 0.0f, 1.0f);
		if (Abs(g - mGlow) < 0.01f)
			return;
		mGlow = g;
		if (!Scene.IsValid(mFigure))
			mFigure = Pieces.Figure(Scene, Entity, "Thief", "ThiefRig");
		let meshes = Scene.GetSystem<MeshComponentManager>();
		if (!Scene.IsValid(mFigure) || (meshes == null))
			return;
		for (int32 slot < Slots)
			meshes.SetMaterialProperty(mFigure, slot, "EmissiveColor", .(0.55f, 0.65f, 0.9f, g), sizeof(Float4));
	}
}
