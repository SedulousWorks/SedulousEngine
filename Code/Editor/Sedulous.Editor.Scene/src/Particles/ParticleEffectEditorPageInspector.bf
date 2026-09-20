using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The inspector half: rows for the selected effect, system, emitter or module.
extension ParticleEffectEditorPage
{
	private static readonly StringView[3] cSimModes = .("CPU", "GPU", "Auto");
	private static readonly StringView[2] cSpaces = .("World", "Local");
	private static readonly StringView[4] cBlendModes = .("Alpha", "Additive", "Premultiplied", "Multiply");
	private static readonly StringView[7] cRenderModes = .("Billboard", "Stretched", "Horizontal", "Vertical", "Mesh", "Trail", "Light");
	private static readonly StringView[3] cEmissionModes = .("Continuous", "Burst", "Continuous + Burst");

	private void RebuildInspector()
	{
		mGrid.Clear();
		if (mAsset == null)
			return;
		mTitleLabel.SetText(scope $"Systems: {mAsset.Effect.SystemCount}");

		switch (mSelected.Kind)
		{
		case .Effect:
			BuildEffectInspector();
		case .System, .InitializersFolder, .BehaviorsFolder:
			if (let sys = SelectedSystem)
				BuildSystemInspector(sys);
		case .Emitter:
			if (let sys = SelectedSystem)
				BuildEmitterInspector(sys);
		case .Initializer:
			if (let sys = SelectedSystem)
				BuildModuleInspector(sys.GetInitializer(mSelected.ModuleIndex));
		case .Behavior:
			if (let sys = SelectedSystem)
				BuildModuleInspector(sys.GetBehavior(mSelected.ModuleIndex));
		}
	}

	private void QueueInspectorRebuild()
	{
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(new [=this]() => { RebuildInspector(); });
		else
			RebuildInspector();
	}

	private void BuildEffectInspector()
	{
		ParticleRows.Button(mGrid, "Add System", "Effect", new [=this]() => { AddSystem(); });
	}

	private void BuildSystemInspector(ParticleSystem sys)
	{
		let g = mGrid;
		let sysIndex = mSelected.SystemIndex;

		let rm = sys.RenderMode;
		let billboardFamily = (rm == .Billboard) || (rm == .StretchedBillboard) || (rm == .HorizontalBillboard) || (rm == .VerticalBillboard);
		let textured = billboardFamily || (rm == .Trail);
		let meshMode = rm == .Mesh;

		{
			let cat = "General";
			g.AddProperty(new StringEditor("Name", sys.Name, new [=this, =sys](v) =>
				{
					sys.Name.Set(v);
					CommitEdit("sys-name");
				}, cat));
			ParticleRows.Enum(g, "Simulation", (int32)sys.DesiredMode, cSimModes, new [=this, =sys](v) =>
				{
					sys.DesiredMode = (SimulationMode)v;
					CommitEdit("sim-mode");
				}, cat);
			ParticleRows.Enum(g, "Sim Space", (int32)sys.SimulationSpace, cSpaces, new [=this, =sys](v) =>
				{
					sys.SimulationSpace = (ParticleSpace)v;
					CommitEdit("sim-space");
				}, cat);
			ParticleRows.Enum(g, "Blend Mode", (int32)sys.BlendMode, cBlendModes, new [=this, =sys](v) =>
				{
					sys.BlendMode = (ParticleBlendMode)v;
					CommitEdit("blend");
				}, cat);
			ParticleRows.Enum(g, "Render Mode", (int32)sys.RenderMode, cRenderModes, new [=this, =sys](v) =>
				{
					sys.RenderMode = (ParticleRenderMode)v;
					CommitEdit("render");
					QueueInspectorRebuild();
				}, cat);
			let key = new String()..AppendF("maxp-{}", sysIndex);
			g.AddProperty(new IntEditor("Max Particles", sys.MaxParticles, 1, 1000000, new [=this, =sys, =key](v) =>
				{
					sys.SetMaxParticles((int32)v);
					CommitEdit(key);
				} ~ delete key, cat));
			ParticleRows.Bool(this, g, "Sort Particles", &sys.SortParticles, cat);
			ParticleRows.Bool(this, g, "Soft Particles", &sys.SoftParticles, cat);
			ParticleRows.Float(this, g, "Soft Distance", &sys.SoftDistance, cat, 0.0, 10.0, 0.01);
			ParticleRows.Float(this, g, "Prewarm Time", &sys.PrewarmTime, cat, 0.0, 60.0, 0.1);
		}

		if (textured)
		{
			let cat = "Texture";
			ParticleRows.Button(g, sys.TextureRef.IsNil ? "(none)" : "(set - click to change)", cat, new [=this, =sysIndex]() =>
				{
					PickSystemRef(sysIndex, scope StringView[]("TextureAsset"), new [=this, =sysIndex](picked) =>
						{
							if (let s = mAsset.Effect.GetSystem(sysIndex))
							{
								s.TextureRef = picked;
								CommitEdit("texture");
								RebuildPreviewResources();
								RebuildInspector();
							}
						});
				});
		}

		if (meshMode)
		{
			let cat = "Mesh";
			ParticleRows.Button(g, sys.MeshRef.IsNil ? "(none)" : "(set - click to change)", cat, new [=this, =sysIndex]() =>
				{
					PickSystemRef(sysIndex, scope StringView[]("StaticMeshAsset", "SkinnedMeshAsset"), new [=this, =sysIndex](picked) =>
						{
							if (let s = mAsset.Effect.GetSystem(sysIndex))
							{
								s.MeshRef = picked;
								CommitEdit("mesh");
								RebuildPreviewResources(); // re-resolve the new mesh
								RebuildInspector();
							}
						});
				});
			ParticleRows.Float(this, g, "Mesh Scale", &sys.MeshScale, cat, 0.001, 1000.0, 0.01);

			let slots = new ContainerListEditor("Materials", cat);
			for (int mi < sys.MaterialRefs.Count)
			{
				let name = new String("Material ")..AppendF("{}", mi);
				if (mi == 0)
					name.Append(" (whole mesh)");
				if (sys.MaterialRefs[mi].IsNil)
					name.Append(" (none)");
				slots.SlotNames.Add(name);
			}
			slots.OnAdd = new [=this, =sysIndex]() =>
				{
					if (let s = mAsset.Effect.GetSystem(sysIndex))
					{
						s.MaterialRefs.Add(.());
						CommitEdit("material-add");
						RebuildPreviewResources();
						QueueInspectorRebuild();
					}
				};
			slots.OnRemoveSlot = new [=this, =sysIndex](slot) =>
				{
					let s = mAsset.Effect.GetSystem(sysIndex);
					if ((s != null) && (slot >= 0) && (slot < s.MaterialRefs.Count))
					{
						s.MaterialRefs.RemoveAt(slot);
						CommitEdit("material-remove");
						RebuildPreviewResources();
						QueueInspectorRebuild();
					}
				};
			slots.OnMoveSlot = new [=this, =sysIndex](slot, up) =>
				{
					let s = mAsset.Effect.GetSystem(sysIndex);
					if ((s == null) || (up && (slot == 0)) || (slot < 0))
						return;
					let other = up ? (slot - 1) : (slot + 1);
					if ((slot < s.MaterialRefs.Count) && (other < s.MaterialRefs.Count))
					{
						Swap!(s.MaterialRefs[slot], s.MaterialRefs[other]);
						CommitEdit("material-move");
						RebuildPreviewResources();
						QueueInspectorRebuild();
					}
				};
			slots.OnPickSlot = new [=this, =sysIndex](slot) =>
				{
					PickSystemRef(sysIndex, scope StringView[]("MaterialAsset"), new [=this, =sysIndex, =slot](picked) =>
						{
							let s = mAsset.Effect.GetSystem(sysIndex);
							if ((s != null) && (slot >= 0) && (slot < s.MaterialRefs.Count))
							{
								s.MaterialRefs[slot] = picked;
								CommitEdit("material");
								RebuildPreviewResources(); // re-resolve the new material
								RebuildInspector();
							}
						});
				};
			g.AddProperty(slots);
		}

		{
			let cat = "LOD";
			ParticleRows.Float(this, g, "Start Distance", &sys.LodStartDistance, cat, 0.0, 10000.0, 0.5);
			ParticleRows.Float(this, g, "Cull Distance", &sys.LodCullDistance, cat, 0.0, 10000.0, 0.5);
			ParticleRows.Float(this, g, "Min Rate", &sys.LodMinRate, cat, 0.0, 1.0, 0.01);
		}

		if (billboardFamily)
		{
			let cat = "Flipbook";
			ParticleRows.Bool(this, g, "Enabled", &sys.Flipbook.Enabled, cat);
			ParticleRows.Int(this, g, "Columns", &sys.Flipbook.Columns, cat, 1, 64);
			ParticleRows.Int(this, g, "Rows", &sys.Flipbook.Rows, cat, 1, 64);
			ParticleRows.Float(this, g, "FPS", &sys.Flipbook.Fps, cat, 0.0, 120.0, 0.5);
			ParticleRows.Bool(this, g, "Over Lifetime", &sys.Flipbook.OverLifetime, cat);
			ParticleRows.Int(this, g, "Start Frame", &sys.Flipbook.StartFrame, cat, 0, 4096);
		}

		if (rm == .Trail)
		{
			let cat = "Trail";
			ParticleRows.Bool(this, g, "Enabled", &sys.Trail.Enabled, cat);
			ParticleRows.Int(this, g, "Max Points", &sys.Trail.MaxPoints, cat, 2, 256);
			ParticleRows.Float(this, g, "Record Interval", &sys.Trail.RecordInterval, cat, 0.0, 1.0, 0.001);
			ParticleRows.Float(this, g, "Lifetime", &sys.Trail.Lifetime, cat, 0.0, 10.0, 0.05);
			ParticleRows.Float(this, g, "Width Start", &sys.Trail.WidthStart, cat, 0.0, 10.0, 0.01);
			ParticleRows.Float(this, g, "Width End", &sys.Trail.WidthEnd, cat, 0.0, 10.0, 0.01);
			ParticleRows.Float(this, g, "Min Vertex Dist", &sys.Trail.MinVertexDistance, cat, 0.0, 10.0, 0.01);
			ParticleRows.Bool(this, g, "Use Particle Color", &sys.Trail.UseParticleColor, cat);
			ParticleRows.Color(this, g, "Trail Color", &sys.Trail.TrailColor, cat);
		}
	}

	/// Opens the asset picker for one of a system's refs; `onPicked` is consumed.
	private void PickSystemRef(int32 sysIndex, Span<StringView> typeNames, delegate void(Guid) onPicked)
	{
		let ctx = Ctx;
		if ((ctx == null) || (mContext.Project == null))
		{
			delete onPicked;
			return;
		}
		let dialog = new AssetPickerDialog(mContext, typeNames);
		dialog.OnPicked = onPicked;
		dialog.Show(ctx);
	}

	private void BuildEmitterInspector(ParticleSystem sys)
	{
		let g = mGrid;
		let cat = "Emitter";
		let em = sys.Emitter;

		let continuous = (em.Mode == .Continuous) || (em.Mode == .ContinuousAndBurst);
		let burst = (em.Mode == .Burst) || (em.Mode == .ContinuousAndBurst);

		ParticleRows.Enum(g, "Mode", (int32)em.Mode, cEmissionModes, new [=this, =em](v) =>
			{
				em.Mode = (EmissionMode)v;
				CommitEdit("emit-mode");
				QueueInspectorRebuild();
			}, cat);
		if (continuous)
			ParticleRows.Float(this, g, "Spawn Rate", &em.SpawnRate, cat, 0.0, 100000.0, 1.0);
		ParticleRows.Float(this, g, "Duration (s)", &em.Duration, cat, 0.0, 600.0, 0.1);
		ParticleRows.Bool(this, g, "Looping", &em.Looping, cat);
		if (burst)
		{
			ParticleRows.Int(this, g, "Burst Count", &em.BurstCount, cat, 0, 100000);
			ParticleRows.Float(this, g, "Burst Interval", &em.BurstInterval, cat, 0.0, 600.0, 0.05);
			ParticleRows.Int(this, g, "Burst Cycles (0=inf)", &em.BurstCycles, cat, 0, 100000);
		}
	}

	private void BuildModuleInspector(Object module)
	{
		if (module == null)
			return;
		let g = mGrid;
		let cat = ParticleEffectEdit.ModuleLabel(module, .. scope .());

		if (let posInit = module as PositionInitializer)
		{
			ParticleRows.EmissionShape(this, g, "Shape", &posInit.Shape, cat);
			ParticleRows.Bool(this, g, "Local Space", &posInit.LocalSpace, cat);
		}
		else if (let velInit = module as VelocityInitializer)
		{
			ParticleRows.Float3(this, g, "Base Velocity", &velInit.BaseVelocity, cat);
			ParticleRows.Float3(this, g, "Randomness", &velInit.Randomness, cat);
			ParticleRows.Float(this, g, "Shape Dir Speed", &velInit.ShapeDirectionSpeed, cat);
			ParticleRows.Float(this, g, "Velocity Inherit", &velInit.VelocityInheritance, cat, 0.0, 1.0, 0.01);
			ParticleRows.EmissionShape(this, g, "Shape", &velInit.Shape, cat);
		}
		else if (let lifeInit = module as LifetimeInitializer)
			ParticleRows.RangeFloat(this, g, "Lifetime", &lifeInit.Lifetime, cat, 0.0, 100.0, 0.05);
		else if (let colorInit = module as ColorInitializer)
			ParticleRows.RangeColor(this, g, "Color", &colorInit.Color, cat);
		else if (let sizeInit = module as SizeInitializer)
			ParticleRows.RangeFloat2(this, g, "Size", &sizeInit.Size, cat);
		else if (let rotInit = module as RotationInitializer)
		{
			ParticleRows.RangeFloat(this, g, "Rotation", &rotInit.Rotation, cat);
			ParticleRows.RangeFloat(this, g, "Rotation Speed", &rotInit.RotationSpeed, cat);
		}
		else if (let orientInit = module as MeshOrientationInitializer)
		{
			ParticleRows.Bool(this, g, "Random Axis", &orientInit.RandomAxis, cat);
			ParticleRows.Float3(this, g, "Fixed Axis", &orientInit.FixedAxis, cat);
		}
		else if (let gravity = module as GravityBehavior)
		{
			ParticleRows.Float(this, g, "Multiplier", &gravity.Multiplier, cat);
			ParticleRows.Float3(this, g, "Direction", &gravity.Direction, cat);
		}
		else if (let drag = module as DragBehavior)
			ParticleRows.Float(this, g, "Drag", &drag.Drag, cat);
		else if (let wind = module as WindBehavior)
		{
			ParticleRows.Float3(this, g, "Force", &wind.Force, cat);
			ParticleRows.Float(this, g, "Turbulence", &wind.Turbulence, cat);
		}
		else if (let turbulence = module as TurbulenceBehavior)
		{
			ParticleRows.Float(this, g, "Strength", &turbulence.Strength, cat);
			ParticleRows.Float(this, g, "Frequency", &turbulence.Frequency, cat);
			ParticleRows.Float(this, g, "Speed", &turbulence.Speed, cat);
		}
		else if (let vortex = module as VortexBehavior)
		{
			ParticleRows.Float(this, g, "Strength", &vortex.Strength, cat);
			ParticleRows.Float3(this, g, "Center", &vortex.Center, cat);
			ParticleRows.Float3(this, g, "Axis", &vortex.Axis, cat);
		}
		else if (let attractor = module as AttractorBehavior)
		{
			ParticleRows.Float(this, g, "Strength", &attractor.Strength, cat);
			ParticleRows.Float3(this, g, "Position", &attractor.Position, cat);
			ParticleRows.Float(this, g, "Radius", &attractor.Radius, cat, 0.0, 1000.0, 0.05);
		}
		else if (let radial = module as RadialForceBehavior)
			ParticleRows.Float(this, g, "Strength", &radial.Strength, cat);
		else if (let collision = module as CollisionBehavior)
			BuildCollisionInspector(collision, cat);
		else if (let colorCurve = module as ColorOverLifetimeBehavior)
			ParticleRows.CurveColor(this, g, "Color", &colorCurve.Curve, cat);
		else if (let alphaCurve = module as AlphaOverLifetimeBehavior)
			ParticleRows.CurveFloat(this, g, "Alpha", &alphaCurve.Curve, cat);
		else if (let sizeCurve = module as SizeOverLifetimeBehavior)
			ParticleRows.CurveFloat2(this, g, "Size", &sizeCurve.Curve, cat);
		else if (let rotCurve = module as RotationOverLifetimeBehavior)
			ParticleRows.CurveFloat(this, g, "Rotation", &rotCurve.Curve, cat);
		else if (let speedCurve = module as SpeedOverLifetimeBehavior)
			ParticleRows.CurveFloat(this, g, "Speed", &speedCurve.Curve, cat);
	}

	private void BuildCollisionInspector(CollisionBehavior collision, StringView cat)
	{
		let g = mGrid;
		ParticleRows.Float(this, g, "Radius", &collision.Radius, cat, 0.0, 10.0, 0.01);
		ParticleRows.Float(this, g, "Bounce", &collision.Bounce, cat, 0.0, 1.0, 0.01);
		ParticleRows.Float(this, g, "Friction", &collision.Friction, cat, 0.0, 1.0, 0.01);
		ParticleRows.Float(this, g, "Lifetime Loss", &collision.LifetimeLoss, cat, 0.0, 1.0, 0.01);
		ParticleRows.Int(this, g, "Plane Count", &collision.PlaneCount, "Collision Planes", 0, CollisionBehavior.MaxPlanes);
		for (int32 i = 0; (i < collision.PlaneCount) && (i < CollisionBehavior.MaxPlanes); i++)
		{
			let c = scope $"Plane {i}";
			ParticleRows.Float3(this, g, "Normal", &collision.Planes[i].Normal, c);
			ParticleRows.Float(this, g, "Distance", &collision.Planes[i].Distance, c, -1000.0, 1000.0, 0.05);
		}
		ParticleRows.Int(this, g, "Sphere Count", &collision.SphereCount, "Collision Spheres", 0, CollisionBehavior.MaxSpheres);
		for (int32 i = 0; (i < collision.SphereCount) && (i < CollisionBehavior.MaxSpheres); i++)
		{
			let c = scope $"Sphere {i}";
			ParticleRows.Float3(this, g, "Center", &collision.Spheres[i].Center, c);
			ParticleRows.Float(this, g, "Radius", &collision.Spheres[i].Radius, c, 0.0, 1000.0, 0.05);
		}
		ParticleRows.Int(this, g, "Box Count", &collision.BoxCount, "Collision Boxes", 0, CollisionBehavior.MaxBoxes);
		for (int32 i = 0; (i < collision.BoxCount) && (i < CollisionBehavior.MaxBoxes); i++)
		{
			let c = scope $"Box {i}";
			ParticleRows.Float3(this, g, "Center", &collision.Boxes[i].Center, c);
			ParticleRows.Float3(this, g, "Half Extents", &collision.Boxes[i].HalfExtents, c);
		}
	}
}
