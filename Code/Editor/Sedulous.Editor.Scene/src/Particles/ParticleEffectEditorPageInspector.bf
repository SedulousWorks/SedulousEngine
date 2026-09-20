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
		InPlaceRows.Button(mGrid, "Add System", "Effect", new [=this]() => { AddSystem(); });
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
			InPlaceRows.Enum(g, "Simulation", (int32)sys.DesiredMode, cSimModes, new [=this, =sys](v) =>
				{
					sys.DesiredMode = (SimulationMode)v;
					CommitEdit("sim-mode");
				}, cat);
			InPlaceRows.Enum(g, "Sim Space", (int32)sys.SimulationSpace, cSpaces, new [=this, =sys](v) =>
				{
					sys.SimulationSpace = (ParticleSpace)v;
					CommitEdit("sim-space");
				}, cat);
			InPlaceRows.Enum(g, "Blend Mode", (int32)sys.BlendMode, cBlendModes, new [=this, =sys](v) =>
				{
					sys.BlendMode = (ParticleBlendMode)v;
					CommitEdit("blend");
				}, cat);
			InPlaceRows.Enum(g, "Render Mode", (int32)sys.RenderMode, cRenderModes, new [=this, =sys](v) =>
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
			InPlaceRows.Bool(g, "Sort Particles", &sys.SortParticles, cat, mCommit);
			InPlaceRows.Bool(g, "Soft Particles", &sys.SoftParticles, cat, mCommit);
			InPlaceRows.Float(g, "Soft Distance", &sys.SoftDistance, cat, mCommit, 0.0, 10.0, 0.01);
			InPlaceRows.Float(g, "Prewarm Time", &sys.PrewarmTime, cat, mCommit, 0.0, 60.0, 0.1);
		}

		if (textured)
		{
			let cat = "Texture";
			InPlaceRows.Button(g, sys.TextureRef.IsNil ? "(none)" : "(set - click to change)", cat, new [=this, =sysIndex]() =>
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
			InPlaceRows.Button(g, sys.MeshRef.IsNil ? "(none)" : "(set - click to change)", cat, new [=this, =sysIndex]() =>
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
			InPlaceRows.Float(g, "Mesh Scale", &sys.MeshScale, cat, mCommit, 0.001, 1000.0, 0.01);

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
			InPlaceRows.Float(g, "Start Distance", &sys.LodStartDistance, cat, mCommit, 0.0, 10000.0, 0.5);
			InPlaceRows.Float(g, "Cull Distance", &sys.LodCullDistance, cat, mCommit, 0.0, 10000.0, 0.5);
			InPlaceRows.Float(g, "Min Rate", &sys.LodMinRate, cat, mCommit, 0.0, 1.0, 0.01);
		}

		if (billboardFamily)
		{
			let cat = "Flipbook";
			InPlaceRows.Bool(g, "Enabled", &sys.Flipbook.Enabled, cat, mCommit);
			InPlaceRows.Int(g, "Columns", &sys.Flipbook.Columns, cat, mCommit, 1, 64);
			InPlaceRows.Int(g, "Rows", &sys.Flipbook.Rows, cat, mCommit, 1, 64);
			InPlaceRows.Float(g, "FPS", &sys.Flipbook.Fps, cat, mCommit, 0.0, 120.0, 0.5);
			InPlaceRows.Bool(g, "Over Lifetime", &sys.Flipbook.OverLifetime, cat, mCommit);
			InPlaceRows.Int(g, "Start Frame", &sys.Flipbook.StartFrame, cat, mCommit, 0, 4096);
		}

		if (rm == .Trail)
		{
			let cat = "Trail";
			InPlaceRows.Bool(g, "Enabled", &sys.Trail.Enabled, cat, mCommit);
			InPlaceRows.Int(g, "Max Points", &sys.Trail.MaxPoints, cat, mCommit, 2, 256);
			InPlaceRows.Float(g, "Record Interval", &sys.Trail.RecordInterval, cat, mCommit, 0.0, 1.0, 0.001);
			InPlaceRows.Float(g, "Lifetime", &sys.Trail.Lifetime, cat, mCommit, 0.0, 10.0, 0.05);
			InPlaceRows.Float(g, "Width Start", &sys.Trail.WidthStart, cat, mCommit, 0.0, 10.0, 0.01);
			InPlaceRows.Float(g, "Width End", &sys.Trail.WidthEnd, cat, mCommit, 0.0, 10.0, 0.01);
			InPlaceRows.Float(g, "Min Vertex Dist", &sys.Trail.MinVertexDistance, cat, mCommit, 0.0, 10.0, 0.01);
			InPlaceRows.Bool(g, "Use Particle Color", &sys.Trail.UseParticleColor, cat, mCommit);
			InPlaceRows.Color(g, "Trail Color", &sys.Trail.TrailColor, cat, mCommit);
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

		InPlaceRows.Enum(g, "Mode", (int32)em.Mode, cEmissionModes, new [=this, =em](v) =>
			{
				em.Mode = (EmissionMode)v;
				CommitEdit("emit-mode");
				QueueInspectorRebuild();
			}, cat);
		if (continuous)
			InPlaceRows.Float(g, "Spawn Rate", &em.SpawnRate, cat, mCommit, 0.0, 100000.0, 1.0);
		InPlaceRows.Float(g, "Duration (s)", &em.Duration, cat, mCommit, 0.0, 600.0, 0.1);
		InPlaceRows.Bool(g, "Looping", &em.Looping, cat, mCommit);
		if (burst)
		{
			InPlaceRows.Int(g, "Burst Count", &em.BurstCount, cat, mCommit, 0, 100000);
			InPlaceRows.Float(g, "Burst Interval", &em.BurstInterval, cat, mCommit, 0.0, 600.0, 0.05);
			InPlaceRows.Int(g, "Burst Cycles (0=inf)", &em.BurstCycles, cat, mCommit, 0, 100000);
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
			ParticleRows.EmissionShape(g, "Shape", &posInit.Shape, cat, mCommit);
			InPlaceRows.Bool(g, "Local Space", &posInit.LocalSpace, cat, mCommit);
		}
		else if (let velInit = module as VelocityInitializer)
		{
			InPlaceRows.Float3(g, "Base Velocity", &velInit.BaseVelocity, cat, mCommit);
			InPlaceRows.Float3(g, "Randomness", &velInit.Randomness, cat, mCommit);
			InPlaceRows.Float(g, "Shape Dir Speed", &velInit.ShapeDirectionSpeed, cat, mCommit);
			InPlaceRows.Float(g, "Velocity Inherit", &velInit.VelocityInheritance, cat, mCommit, 0.0, 1.0, 0.01);
			ParticleRows.EmissionShape(g, "Shape", &velInit.Shape, cat, mCommit);
		}
		else if (let lifeInit = module as LifetimeInitializer)
			ParticleRows.RangeFloat(g, "Lifetime", &lifeInit.Lifetime, cat, mCommit, 0.0, 100.0, 0.05);
		else if (let colorInit = module as ColorInitializer)
			ParticleRows.RangeColor(g, "Color", &colorInit.Color, cat, mCommit);
		else if (let sizeInit = module as SizeInitializer)
			ParticleRows.RangeFloat2(g, "Size", &sizeInit.Size, cat, mCommit);
		else if (let rotInit = module as RotationInitializer)
		{
			ParticleRows.RangeFloat(g, "Rotation", &rotInit.Rotation, cat, mCommit);
			ParticleRows.RangeFloat(g, "Rotation Speed", &rotInit.RotationSpeed, cat, mCommit);
		}
		else if (let orientInit = module as MeshOrientationInitializer)
		{
			InPlaceRows.Bool(g, "Random Axis", &orientInit.RandomAxis, cat, mCommit);
			InPlaceRows.Float3(g, "Fixed Axis", &orientInit.FixedAxis, cat, mCommit);
		}
		else if (let gravity = module as GravityBehavior)
		{
			InPlaceRows.Float(g, "Multiplier", &gravity.Multiplier, cat, mCommit);
			InPlaceRows.Float3(g, "Direction", &gravity.Direction, cat, mCommit);
		}
		else if (let drag = module as DragBehavior)
			InPlaceRows.Float(g, "Drag", &drag.Drag, cat, mCommit);
		else if (let wind = module as WindBehavior)
		{
			InPlaceRows.Float3(g, "Force", &wind.Force, cat, mCommit);
			InPlaceRows.Float(g, "Turbulence", &wind.Turbulence, cat, mCommit);
		}
		else if (let turbulence = module as TurbulenceBehavior)
		{
			InPlaceRows.Float(g, "Strength", &turbulence.Strength, cat, mCommit);
			InPlaceRows.Float(g, "Frequency", &turbulence.Frequency, cat, mCommit);
			InPlaceRows.Float(g, "Speed", &turbulence.Speed, cat, mCommit);
		}
		else if (let vortex = module as VortexBehavior)
		{
			InPlaceRows.Float(g, "Strength", &vortex.Strength, cat, mCommit);
			InPlaceRows.Float3(g, "Center", &vortex.Center, cat, mCommit);
			InPlaceRows.Float3(g, "Axis", &vortex.Axis, cat, mCommit);
		}
		else if (let attractor = module as AttractorBehavior)
		{
			InPlaceRows.Float(g, "Strength", &attractor.Strength, cat, mCommit);
			InPlaceRows.Float3(g, "Position", &attractor.Position, cat, mCommit);
			InPlaceRows.Float(g, "Radius", &attractor.Radius, cat, mCommit, 0.0, 1000.0, 0.05);
		}
		else if (let radial = module as RadialForceBehavior)
			InPlaceRows.Float(g, "Strength", &radial.Strength, cat, mCommit);
		else if (let collision = module as CollisionBehavior)
			BuildCollisionInspector(collision, cat);
		else if (let colorCurve = module as ColorOverLifetimeBehavior)
			ParticleRows.CurveColor(g, "Color", &colorCurve.Curve, cat, this);
		else if (let alphaCurve = module as AlphaOverLifetimeBehavior)
			ParticleRows.CurveFloat(g, "Alpha", &alphaCurve.Curve, cat, this);
		else if (let sizeCurve = module as SizeOverLifetimeBehavior)
			ParticleRows.CurveFloat2(g, "Size", &sizeCurve.Curve, cat, this);
		else if (let rotCurve = module as RotationOverLifetimeBehavior)
			ParticleRows.CurveFloat(g, "Rotation", &rotCurve.Curve, cat, this);
		else if (let speedCurve = module as SpeedOverLifetimeBehavior)
			ParticleRows.CurveFloat(g, "Speed", &speedCurve.Curve, cat, this);
	}

	private void BuildCollisionInspector(CollisionBehavior collision, StringView cat)
	{
		let g = mGrid;
		InPlaceRows.Float(g, "Radius", &collision.Radius, cat, mCommit, 0.0, 10.0, 0.01);
		InPlaceRows.Float(g, "Bounce", &collision.Bounce, cat, mCommit, 0.0, 1.0, 0.01);
		InPlaceRows.Float(g, "Friction", &collision.Friction, cat, mCommit, 0.0, 1.0, 0.01);
		InPlaceRows.Float(g, "Lifetime Loss", &collision.LifetimeLoss, cat, mCommit, 0.0, 1.0, 0.01);
		InPlaceRows.Int(g, "Plane Count", &collision.PlaneCount, "Collision Planes", mCommit, 0, CollisionBehavior.MaxPlanes);
		for (int32 i = 0; (i < collision.PlaneCount) && (i < CollisionBehavior.MaxPlanes); i++)
		{
			let c = scope $"Plane {i}";
			InPlaceRows.Float3(g, "Normal", &collision.Planes[i].Normal, c, mCommit);
			InPlaceRows.Float(g, "Distance", &collision.Planes[i].Distance, c, mCommit, -1000.0, 1000.0, 0.05);
		}
		InPlaceRows.Int(g, "Sphere Count", &collision.SphereCount, "Collision Spheres", mCommit, 0, CollisionBehavior.MaxSpheres);
		for (int32 i = 0; (i < collision.SphereCount) && (i < CollisionBehavior.MaxSpheres); i++)
		{
			let c = scope $"Sphere {i}";
			InPlaceRows.Float3(g, "Center", &collision.Spheres[i].Center, c, mCommit);
			InPlaceRows.Float(g, "Radius", &collision.Spheres[i].Radius, c, mCommit, 0.0, 1000.0, 0.05);
		}
		InPlaceRows.Int(g, "Box Count", &collision.BoxCount, "Collision Boxes", mCommit, 0, CollisionBehavior.MaxBoxes);
		for (int32 i = 0; (i < collision.BoxCount) && (i < CollisionBehavior.MaxBoxes); i++)
		{
			let c = scope $"Box {i}";
			InPlaceRows.Float3(g, "Center", &collision.Boxes[i].Center, c, mCommit);
			InPlaceRows.Float3(g, "Half Extents", &collision.Boxes[i].HalfExtents, c, mCommit);
		}
	}
}
