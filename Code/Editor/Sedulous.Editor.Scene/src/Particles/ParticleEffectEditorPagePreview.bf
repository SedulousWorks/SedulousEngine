using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Engine.Render;
using Sedulous.Engine.Particles;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// The preview half: the simulating scene, the effect attached to its emitter entity with
/// the page's own resolved resource, the transport and the emission gizmo.
extension ParticleEffectEditorPage
{
	private void BuildPreviewScene()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if ((scene == null) || (mAsset == null))
			return;
		mPreview.SetSimulationEnabled(true); // particles must simulate to animate the preview

		mEmitter = scene.CreateEntity("Emitter");
		if (let mgr = scene.GetSystem<ParticleEffectComponentManager>())
		{
			mgr.Add(mEmitter);
			mgr.SetEffect(mEmitter, mAsset.Effect);
		}
		RebuildPreviewResources(); // resolve the effect's mesh and material refs so mesh systems render

		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.CastsShadows = false;
		}
	}

	private ParticleEffectComponent* PreviewComponent()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		let mgr = (scene != null) ? scene.GetSystem<ParticleEffectComponentManager>() : null;
		return ((mgr != null) && mEmitter.IsAssigned) ? mgr.Get(mEmitter) : null;
	}

	/// (Re)attaches the asset's live effect, borrowed, with a fresh instance.
	private void AttachPreviewEffect()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		let mgr = (scene != null) ? scene.GetSystem<ParticleEffectComponentManager>() : null;
		if ((mgr != null) && (mAsset != null) && mEmitter.IsAssigned && (mgr.Get(mEmitter) != null))
			mgr.SetEffect(mEmitter, mAsset.Effect);
	}

	/// Clones the effect into the page's own resource and resolves its texture, mesh and
	/// material refs, which the component borrows for extraction.
	private void RebuildPreviewResources()
	{
		let c = PreviewComponent();
		if ((c == null) || (mAsset == null))
			return;
		let manager = mContext.Resources;
		let previous = mPreviewResource;
		if (manager == null)
		{
			// Headless, or no project: nothing to resolve against.
			mPreviewResource = null;
			c.AttachedResource = null;
			delete previous;
			return;
		}
		let resource = new ParticleEffectResource();
		ParticleEffectSerialization.CloneEffect(mAsset.Effect, resource.Effect, mSerializers).IgnoreError();
		resource.ResolveReferences(manager);
		c.AttachedResource = resource;
		mPreviewResource = resource;
		delete previous;
	}

	/// Unhooks the borrowed effect and resource ahead of the page's own teardown.
	private void DetachPreview()
	{
		if (let c = PreviewComponent())
		{
			c.AttachedResource = null;
			DeleteAndNullify!(c.Instance);
			c.Effect = null;
		}
	}

	private View BuildTransport()
	{
		let transport = new FlexLayout();
		transport.Direction = .Horizontal;
		transport.Spacing = 6.0f;
		transport.Padding = .(6, 4);

		let play = new Button("Play");
		play.OnClick.Add(new [=this](btn) => { Play(); });
		let stop = new Button("Stop");
		stop.OnClick.Add(new [=this](btn) => { Stop(); });
		let restart = new Button("Restart");
		restart.OnClick.Add(new [=this](btn) => { Restart(); });
		let pause = new Button("Pause");
		pause.OnClick.Add(new [=this](btn) => { SetPaused(!mPaused); });
		transport.AddView(play);
		transport.AddView(stop);
		transport.AddView(restart);
		transport.AddView(pause);

		let speedLabel = new Label("Speed");
		speedLabel.FontSize.Value = 12.0f;
		speedLabel.VAlign.Value = .Middle;
		transport.AddView(speedLabel);
		let speed = new Slider(0.0f, 3.0f, 1.0f);
		speed.OnValueChanged.Add(new [=this](slider, v) =>
			{
				mSimSpeed = v;
				mPreview.SetTimeScale(v);
			});
		var speedWidth = LayoutStyle();
		speedWidth.Width = SizeSpec.Fixed(Unit.Dp(90.0f));
		transport.AddView(speed, speedWidth);

		mStatsLabel = new Label("");
		mStatsLabel.FontSize.Value = 12.0f;
		mStatsLabel.VAlign.Value = .Middle;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		transport.AddView(mStatsLabel, grow);
		return transport;
	}

	public void Play()
	{
		mPaused = false;
		if (mAsset != null)
		{
			for (int32 i < mAsset.Effect.SystemCount)
				mAsset.Effect.GetSystem(i).Emitter.IsEmitting = true;
		}
		if (let c = PreviewComponent())
		{
			if (c.Instance != null)
				c.Instance.IsActive = true;
		}
	}

	public void Stop()
	{
		if (let c = PreviewComponent())
		{
			if (c.Instance != null)
				c.Instance.Stop();
		}
	}

	public void Restart()
	{
		if (let c = PreviewComponent())
		{
			if (c.Instance != null)
				c.Instance.Reset();
		}
		Play();
	}

	public void SetPaused(bool paused)
	{
		mPaused = paused;
		if (let c = PreviewComponent())
		{
			if (c.Instance != null)
				c.Instance.IsActive = !paused;
		}
	}

	/// The selected system's emission shape, at its position, in the preview's debug lane.
	private void DrawEmissionGizmo()
	{
		if ((mPreview == null) || !mPreview.IsValid)
			return;
		let sys = SelectedSystem;
		if (sys == null)
			return;
		let shape = ParticleEffectEdit.EmissionShapeOf(sys);
		if (shape == null)
			return;
		let dd = mPreview.SceneDebugDraw;
		let c = Color(0.30f, 0.85f, 1.0f, 1.0f);
		let o = sys.Position;
		let up = Float3(0.0f, 1.0f, 0.0f);
		switch (shape.Type)
		{
		case .Sphere, .Hemisphere:
			dd.DrawWireSphere(o, Math.Max(shape.Radius, 0.01f), c);
		case .Box:
			dd.DrawWireBoxCenter(o, shape.Extents, c);
		case .Cone:
			dd.DrawCone(o, up, Math.Max(shape.Radius, 0.5f), Math.Max(shape.Angle, 0.01f), c);
		case .Ring, .Circle:
			dd.DrawCircleNormal(o, Math.Max(shape.Radius, 0.01f), up, c);
		case .Edge:
			let half = Float3(Math.Max(shape.Radius, 0.01f), 0.0f, 0.0f);
			dd.DrawLine(o - half, o + half, c);
		default:
			dd.DrawCross(o, 0.15f, c);
		}
	}
}
