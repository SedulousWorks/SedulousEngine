using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Core.IO;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation.Tests;

/// Inverse kinematics on scene entities: the end bone follows a
/// moving target entity in the world, through a model space that is the mesh entity's (moved
/// and turned apart from the animator); the weight eases over FadeSeconds and the modifier
/// leaves the player at nought; components run in their order; an unknown bone disables with
/// one log line; SetTarget sets a point and Reached and Error read the result; and a removed
/// component leaves no modifier behind.
class IkComponentTests
{
	/// Counts the IK warnings that reach it.
	private class IkLog : BaseLogger
	{
		public int Lines = 0;
		public this() : base(.Warning, "Test") {}
		protected override void LogMessage(LogLevel level, StringView message)
		{
			if (message.Contains("inverse kinematics"))
				Lines++;
		}
	}

	/// A rider: the animator on Rider (moved and turned), its skinned mesh Body offset under it
	/// (so model space is Body's world, not Rider's), an IK entity per component under Rider, and
	/// targets at the top of the scene.
	private class Stage
	{
		public Skeleton Skeleton = new .(6);
		public Scene Level = new .("ik");
		public EntityHandle Rider;
		public EntityHandle Body;

		public this()
		{
			// Pelvis(0); Thigh(1) at the hip; Shin(2) 4 below; Foot(3) 3 below that; Spine(4); Head(5).
			StringView[6] names = .("Pelvis", "Thigh", "Shin", "Foot", "Spine", "Head");
			int32[6] parents = .(-1, 0, 1, 2, 0, 4);
			Float3[6] offsets = .(.(0, 10, 0), .(1, 0, 0), .(0, -4, 0.2f), .(0, -3, -0.2f), .(0, 2, 0), .(0, 1, 0));
			for (int32 i < 6)
			{
				let bone = Skeleton.Bones[i];
				bone.Index = i;
				bone.Name.Set(names[i]);
				bone.ParentIndex = parents[i];
				bone.LocalBindPose.Position = offsets[i];
			}
			Skeleton.BuildNameMap();
			Skeleton.FindRootBones();
			Skeleton.BuildChildIndices();
			Skeleton.ComputeInverseBindPoses();

			Level.AddSystem<MeshComponentManager>();
			AnimationScene.AddAnimationSceneManagers(Level);
			Rider = Level.CreateEntity("Rider");
			Level.SetLocalTransform(Rider, .(.(5, 0, -2), Quaternion.FromAxisAngle(.(0, 1, 0), 0.6f), .(1, 1, 1)));
			Body = Level.CreateEntity("Body");
			Level.SetParent(Body, Rider);
			Level.SetLocalTransform(Body, .(.(0, 0.5f, 0.3f), Quaternion.FromAxisAngle(.(1, 0, 0), 0.2f), .(1, 1, 1)));
			let animator = Level.GetSystem<SkeletalAnimationComponentManager>().Add(Rider);
			animator.Skeleton.SetDirect(Skeleton);
			animator.MeshEntities.Add(EntityRef(Level.GetEntityId(Body)));
		}

		public ~this()
		{
			// The scene first: its animator borrows the skeleton.
			delete Level;
			delete Skeleton;
		}

		public EntityHandle Target(StringView name, Float3 at)
		{
			let e = Level.CreateEntity(name);
			Level.SetLocalTransform(e, .(at, .Identity, .(1, 1, 1)));
			return e;
		}

		public TwoBoneIkComponent* Leg(StringView name, EntityHandle target, int32 order = 0)
		{
			let e = Level.CreateEntity(name);
			Level.SetParent(e, Rider);
			let c = Level.GetSystem<TwoBoneIkComponentManager>().Add(e);
			c.StartBone.Set("Thigh");
			c.MidBone.Set("Shin");
			c.EndBone.Set("Foot");
			if (Level.IsValid(target))
				c.Target = EntityRef(Level.GetEntityId(target));
			c.FadeSeconds = 0.0f;
			c.Order = order;
			return c;
		}

		public TwoBoneIkComponent* LegOf(StringView name)
			=> Level.GetSystem<TwoBoneIkComponentManager>().Get(Level.FindEntityByName(name));

		public AnimationPlayer Player => Level.GetSystem<SkeletalAnimationComponentManager>().Get(Rider).Player;

		/// The bone's world position as the palette draws it: the final pose, through Body's world.
		public Float3 BoneWorld(int32 bone)
		{
			Player.GetSkinningMatrices();
			let cache = scope ModelPoseCache();
			cache.Build(Skeleton, Player.GetFinalPoses());
			return TransformPoint(InverseKinematics.Position(cache.At(bone)), Level.GetWorldMatrix(Body));
		}

		public void Tick(float seconds = 1.0f / 60.0f)
		{
			Level.Update(seconds);
			Player.GetSkinningMatrices();
		}
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) <= 1e-4f;

	[Test]
	public static void TheEndBoneFollowsAMovingTargetEntityThroughTheMeshsModelSpace()
	{
		let s = scope Stage();
		let target = s.Target("Step", .(6, 4, 0));
		s.Leg("LegIk", target);
		s.Tick(); // the animator builds its player
		s.Tick(); // the IK component finds it and solves
		Test.Assert(Length(s.BoneWorld(3) - Float3(6, 4, 0)) < 1.0e-3f);

		Float3[3] points = .(.(7, 4, 1), .(4.5f, 5, -1), .(6, 6, 2));
		for (let at in points)
		{
			s.Level.SetLocalTransform(target, .(at, .Identity, .(1, 1, 1)));
			s.Tick(); // the same frame's target: composed fresh in PostUpdate
			Test.Assert(Length(s.BoneWorld(3) - at) < 1.0e-3f);
		}
		// The rider walks on: the chain's start moves with it and the foot stays planted.
		var riderAt = s.Level.GetLocalTransform(s.Rider);
		riderAt.Position.X += 0.5f;
		s.Level.SetLocalTransform(s.Rider, riderAt);
		s.Tick();
		Test.Assert(Length(s.BoneWorld(3) - Float3(6, 6, 2)) < 1.0e-3f);
	}

	[Test]
	public static void TheWeightEasesOverFadeSecondsAndAtNoughtTheModifierLeavesThePlayer()
	{
		let s = scope Stage();
		let target = s.Target("Step", .(6, 4, 0));
		s.Leg("LegIk", target).FadeSeconds = 0.5f;
		s.Tick(0.1f);
		for (int frame = 1; frame <= 5; frame++)
		{
			s.Tick(0.1f);
			Test.Assert(Near(s.LegOf("LegIk").Runtime.Weight, 0.2f * (float)frame));
		}
		Test.Assert(Length(s.BoneWorld(3) - Float3(6, 4, 0)) < 1.0e-3f); // fully on
		Test.Assert(s.Player.Modifiers.Count == 1);

		s.LegOf("LegIk").Active = false;
		s.Tick(0.25f);
		Test.Assert(Near(s.LegOf("LegIk").Runtime.Weight, 0.5f));
		Test.Assert(Length(s.BoneWorld(3) - Float3(6, 4, 0)) > 1.0e-2f); // half way back
		s.Tick(0.25f);
		Test.Assert(s.LegOf("LegIk").Runtime.Weight == 0.0f);
		Test.Assert(s.Player.Modifiers.IsEmpty); // no solve, no model space build
	}

	[Test]
	public static void ComponentsOnOneAnimatorRunInTheirOrder()
	{
		// Two chains on the same leg reaching for different points: the later one has the last word.
		let s = scope Stage();
		let a = s.Target("A", .(6, 4, 0));
		let b = s.Target("B", .(7, 5, 1));
		s.Leg("IkA", a, 0);
		s.Leg("IkB", b, 1);
		s.Tick();
		s.Tick();
		Test.Assert(Length(s.BoneWorld(3) - Float3(7, 5, 1)) < 1.0e-3f);

		s.LegOf("IkA").Order = 2; // A now runs after B
		s.Tick();
		Test.Assert(Length(s.BoneWorld(3) - Float3(6, 4, 0)) < 1.0e-3f);
		Test.Assert(s.Player.Modifiers.Count == 2);
	}

	[Test]
	public static void AnUnknownBoneOrNoAnimatorDisablesItWithOneLogLine()
	{
		let log = new IkLog();
		InitGlobalLogger(log, true);
		defer ShutdownGlobalLogger();

		let s = scope Stage();
		let target = s.Target("Step", .(6, 4, 0));
		s.Leg("LegIk", target).MidBone.Set("Knee"); // not in the skeleton
		for (int frame < 10)
			s.Tick();
		Test.Assert(s.LegOf("LegIk").Runtime.Status == .UnknownBone);
		Test.Assert(log.Lines == 1);
		Test.Assert(s.Player.Modifiers.IsEmpty);

		// Fixed, it solves; an IK entity with no animator above it logs once more.
		s.LegOf("LegIk").MidBone.Set("Shin");
		s.LegOf("LegIk").Runtime.ResolvedFor = null; // an edit re-resolves
		s.Tick();
		Test.Assert(s.LegOf("LegIk").Runtime.Status == .Solving);
		let stray = s.Level.CreateEntity("Stray");
		let legs = s.Level.GetSystem<TwoBoneIkComponentManager>();
		legs.Add(stray).StartBone.Set("Thigh");
		for (int frame < 5)
			s.Tick();
		Test.Assert(legs.Get(stray).Runtime.Status == .NoAnimator);
		Test.Assert(log.Lines == 2);
	}

	[Test]
	public static void SetTargetGivesAPointTheResultReadsAndRemovalLeavesNothingBehind()
	{
		let s = scope Stage();
		s.Leg("LegIk", .Invalid); // no target entity: SetTarget's point
		let owner = s.Level.FindEntityByName("LegIk");
		IkScene.SetTarget(s.Level, owner, .(6, 4, 0));
		s.Tick();
		s.Tick();
		Test.Assert(IkScene.Reached(s.Level, owner));
		Test.Assert(IkScene.Error(s.Level, owner) < 1.0e-3f);
		Test.Assert(Length(s.BoneWorld(3) - Float3(6, 4, 0)) < 1.0e-3f);

		IkScene.SetTarget(s.Level, owner, .(30, 4, 0)); // out of reach
		s.Tick();
		Test.Assert(!IkScene.Reached(s.Level, owner));
		Test.Assert(IkScene.Error(s.Level, owner) > 10.0f);

		// An aim on the head alongside it: both must reach for Reached.
		let head = s.Level.CreateEntity("HeadIk");
		s.Level.SetParent(head, s.Rider);
		let aim = s.Level.GetSystem<AimIkComponentManager>().Add(head);
		aim.Bones.Add(new AimIkBone("Head", 1.0f));
		aim.FadeSeconds = 0.0f;
		IkScene.SetTarget(s.Level, head, s.BoneWorld(5) + Float3(1, 0, 3));
		s.Tick();
		Test.Assert(IkScene.Reached(s.Level, head));
		Test.Assert(s.Player.Modifiers.Count == 2);

		// Removing the components takes their modifiers off the player (it holds them borrowed).
		s.Level.GetSystem<TwoBoneIkComponentManager>().Remove(owner);
		Test.Assert(s.Player.Modifiers.Count == 1);
		s.Level.DestroyEntity(head);
		s.Tick();
		Test.Assert(s.Player.Modifiers.IsEmpty);
		s.Tick(); // and the player runs on with nothing dangling
		Test.Assert(!IkScene.Reached(s.Level, head));
	}

	/// The head's aim (its +z) in the skeleton's model space, from the final pose.
	private static Float3 HeadAimModel(Stage s)
	{
		s.Player.GetSkinningMatrices();
		let cache = scope ModelPoseCache();
		cache.Build(s.Skeleton, s.Player.GetFinalPoses());
		let m = cache.At(5);
		return Normalized(Float3(m.M[2][0], m.M[2][1], m.M[2][2]));
	}

	/// A point at `offset` from the head (0, 13, 0) in model space, as a world position.
	private static Float3 FromHead(Stage s, Float3 offset)
		=> TransformPoint(Float3(0, 13, 0) + offset, s.Level.GetWorldMatrix(s.Body));

	private static AimIkComponent* HeadAim(Stage s, EntityHandle target)
	{
		let e = s.Level.CreateEntity("HeadIk");
		s.Level.SetParent(e, s.Rider);
		let c = s.Level.GetSystem<AimIkComponentManager>().Add(e);
		c.Bones.Add(new AimIkBone("Head", 1.0f));
		c.Target = EntityRef(s.Level.GetEntityId(target));
		c.MaxTurn = 60.0f;
		c.MaxTilt = 30.0f;
		c.FadeSeconds = 0.0f;
		return c;
	}

	private static void MoveTo(Stage s, EntityHandle e, Float3 at)
		=> s.Level.SetLocalTransform(e, .(at, .Identity, .(1, 1, 1)));

	/// A target behind, high above, is held at the turn limit on its side, never over the top.
	[Test]
	public static void AnAimHoldsATargetBehindAtTheTurnLimitOnItsSideNeverOverTheTop()
	{
		let s = scope Stage();
		let target = s.Target("Coin", .(0, 0, 0));
		MoveTo(s, target, FromHead(s, .(1, 9, -10))); // behind, to +x, high above
		HeadAim(s, target);
		s.Tick();
		s.Tick();
		let aim = HeadAimModel(s);
		Test.Assert(aim.Z > 0.0f);
		Test.Assert(Math.Abs(aim.Y - Sin(30.0f * DegToRad)) < 1.0e-3f);
		Test.Assert(Math.Abs(Atan2(aim.X, aim.Z) - 60.0f * DegToRad) < 1.0e-3f);
	}

	/// Release eases off past the limits and comes back when the target does.
	[Test]
	public static void ReleaseEasesOffPastTheLimitsAndComesBackWhenTheTargetDoes()
	{
		let s = scope Stage();
		let target = s.Target("Coin", .(0, 0, 0));
		MoveTo(s, target, FromHead(s, .(1, 0, 4))); // ahead
		let added = HeadAim(s, target);
		added.BeyondLimits = .Release;
		added.FadeSeconds = 0.1f;
		let owner = s.Level.FindEntityByName("HeadIk");
		let aims = s.Level.GetSystem<AimIkComponentManager>();
		for (int i < 12)
			s.Tick();
		Test.Assert(Math.Abs(aims.Get(owner).Runtime.Weight - 1.0f) < 1.0e-5f);
		Test.Assert(Dot(HeadAimModel(s), Normalized(Float3(1, 0, 4))) > 1.0f - 1.0e-4f);

		MoveTo(s, target, FromHead(s, .(1, 0, -4))); // behind: past the turn
		// The frame's ease runs before the frame's solve, so the solve that finds the target
		// beyond starts the ease a frame later.
		s.Tick();
		s.Tick();
		Test.Assert(aims.Get(owner).Runtime.Weight < 1.0f, "easing off, not snapping");
		Test.Assert(aims.Get(owner).Runtime.Weight > 0.0f);
		for (int i < 12)
			s.Tick();
		Test.Assert(aims.Get(owner).Runtime.Weight == 0.0f);
		Test.Assert(Dot(HeadAimModel(s), Float3(0, 0, 1)) > 1.0f - 1.0e-5f, "the animated aim");
		Test.Assert(s.Player.Modifiers.Count == 1, "still watching at weight nought");

		MoveTo(s, target, FromHead(s, .(-1, 0, 4))); // ahead again
		for (int i < 12)
			s.Tick();
		Test.Assert(Math.Abs(aims.Get(owner).Runtime.Weight - 1.0f) < 1.0e-5f);
		Test.Assert(Dot(HeadAimModel(s), Normalized(Float3(-1, 0, 4))) > 1.0f - 1.0e-4f);

		// Off: it leaves the player, released or not.
		aims.Get(owner).Active = false;
		for (int i < 12)
			s.Tick();
		Test.Assert(s.Player.Modifiers.IsEmpty);
	}

	/// A version 1 record's one maxAngle becomes both limits, held: it loads through the
	/// manager (which accepts version 1 as well as the current one) and consumes nothing past
	/// its fields.
	[Test]
	public static void AVersionOneRecordsOneMaxAngleBecomesBothLimitsHeld()
	{
		let stream = scope MemoryStream();
		{
			// A version 1 record, as a scene saved before the two limits holds it.
			let writer = scope BinarySerializer(stream, .Write);
			BeginVersionedPayload(writer, TypeIdOf("aim_ik"), 1);
			writer.Key("bones");
			let bones = scope List<AimIkBone>();
			SerializeList(writer, bones);
			var nil = Guid();
			SerializeValue(writer, "target", ref nil);
			SerializeValue(writer, "up", ref nil);
			var aimAxis = Float3(0, 0, 1);
			SerializeValue(writer, "aimAxis", ref aimAxis);
			var upAxis = Float3(0, 1, 0);
			SerializeValue(writer, "upAxis", ref upAxis);
			var maxAngle = 70.0f;
			SerializeValue(writer, "maxAngle", ref maxAngle);
			var weight = 1.0f;
			SerializeValue(writer, "weight", ref weight);
			var fade = 0.35f;
			SerializeValue(writer, "fadeSeconds", ref fade);
			var active = false;
			SerializeValue(writer, "active", ref active);
			int32 order = 0;
			SerializeValue(writer, "order", ref order);
			var debugDraw = false;
			SerializeValue(writer, "debugDraw", ref debugDraw);
			EndVersionedPayload(writer);
			uint32 trailing = 77;
			SerializeValue(writer, "trailing", ref trailing);
			Test.Assert(writer.IsOk);
		}

		let scene = scope Scene();
		let aims = scene.AddSystem<AimIkComponentManager>();
		let entity = scene.CreateEntity("Head");
		stream.Seek(0, .Begin);
		let reader = scope BinarySerializer(stream, .Read);
		aims.ReadComponent(reader, entity);
		uint32 trailing = 0;
		SerializeValue(reader, "trailing", ref trailing);
		Test.Assert(reader.IsOk, "a version 1 record loads");
		let aim = aims.Get(entity);
		Test.Assert(aim.MaxTurn == 70.0f);
		Test.Assert(aim.MaxTilt == 70.0f);
		Test.Assert(aim.BeyondLimits == .Hold);
		Test.Assert(aim.FadeSeconds == 0.35f);
		Test.Assert(!aim.Active);
		Test.Assert(trailing == 77, "nothing past the version 1 fields was consumed");
	}

	/// Flat ground at `Height` everywhere, answered as the scene's solid surface ray query (the
	/// seam physics fills in a running game); counts the rays it is asked.
	private class FlatGround : SceneSystem, ISceneRayQuery
	{
		public float Height = 0.0f;
		public int Casts = 0;

		public override ISceneRayQuery AsRayQuery => this;

		public bool CastRay(Float3 origin, Float3 direction, float maxDistance, uint32 groupMask, out SceneRayHit outHit)
		{
			outHit = .();
			Casts++;
			if (direction.Y >= -1.0e-6f)
				return false;
			let t = (origin.Y - Height) / -direction.Y;
			if ((t < 0.0f) || (t > maxDistance))
				return false;
			outHit.Distance = t;
			outHit.Position = origin + direction * t;
			outHit.Normal = .(0, 1, 0);
			return true;
		}
	}

	[Test]
	public static void FeetStandOnTheGroundTheScenesRayQueryFindsProbedOnceAFrame()
	{
		// A biped's hips and legs (origin at its feet, ankles 0.1 up) under an animator on Walker.
		let skeleton = scope Skeleton(7);
		StringView[7] names = .("Hips", "ThighL", "ShinL", "FootL", "ThighR", "ShinR", "FootR");
		int32[7] parents = .(-1, 0, 1, 2, 0, 4, 5);
		Float3[7] offsets = .(.(0, 1, 0), .(0.15f, 0, 0), .(0, -0.45f, 0.02f), .(0, -0.45f, -0.02f),
			.(-0.15f, 0, 0), .(0, -0.45f, 0.02f), .(0, -0.45f, -0.02f));
		for (int32 i < 7)
		{
			let bone = skeleton.Bones[i];
			bone.Index = i;
			bone.Name.Set(names[i]);
			bone.ParentIndex = parents[i];
			bone.LocalBindPose.Position = offsets[i];
		}
		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();

		let level = scope Scene("feet");
		level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		let ground = level.AddSystem<FlatGround>();

		let walker = level.CreateEntity("Walker");
		level.SetLocalTransform(walker, .(.(2, 0, 1), Quaternion.FromAxisAngle(.(0, 1, 0), 0.6f), .(1, 1, 1)));
		let animator = level.GetSystem<SkeletalAnimationComponentManager>().Add(walker);
		animator.Skeleton.SetDirect(skeleton);
		let feet = level.CreateEntity("FeetIk");
		level.SetParent(feet, walker);
		let foot = level.GetSystem<FootIkComponentManager>().Add(feet);
		foot.Legs.Add(new FootIkLegBones("ThighL", "ShinL", "FootL"));
		foot.Legs.Add(new FootIkLegBones("ThighR", "ShinR", "FootR"));
		foot.PelvisBone.Set("Hips");
		foot.FadeSeconds = 0.0f;

		AnimationPlayer player = null;
		float FootWorldY(int32 bone)
		{
			player.GetSkinningMatrices();
			let cache = scope ModelPoseCache();
			cache.Build(skeleton, player.GetFinalPoses());
			return TransformPoint(InverseKinematics.Position(cache.At(bone)), level.GetWorldMatrix(walker)).Y;
		}

		ground.Height = 0.25f; // a raised floor: both feet rise onto it, the pelvis stays
		level.Update(1.0f / 60.0f);
		player = level.GetSystem<SkeletalAnimationComponentManager>().Get(walker).Player;
		Test.Assert(player != null);
		level.Update(1.0f / 60.0f);
		let castsBefore = ground.Casts;
		Test.Assert(Math.Abs(FootWorldY(3) - 0.35f) < 1e-4f);
		Test.Assert(Math.Abs(FootWorldY(6) - 0.35f) < 1e-4f);
		// Each read above evaluated the player again: the hits were reused, no ray cast twice.
		Test.Assert(ground.Casts == castsBefore);
		level.Update(1.0f / 60.0f);
		player.GetSkinningMatrices();
		Test.Assert(ground.Casts == castsBefore + 2, "one per foot per frame");

		// A floor below the animation's: the pelvis drops to it (clamped at PelvisDropMax 0.3).
		ground.Height = -0.2f;
		for (int frame < 120)
			level.Update(1.0f / 60.0f);
		Test.Assert(Math.Abs(FootWorldY(3) - -0.1f) < 1e-3f);
		Test.Assert(Math.Abs(FootWorldY(0) - 0.8f) < 1e-3f);
	}

	/// The asset pack shape: the Foot is a child of the Root (Blender's IK target), the Shin has no
	/// child. A component naming Thigh, Shin, Foot puts the foot on its target and bends the leg
	/// to it.
	[Test]
	public static void AChainWhoseEndIsADetachedIkTargetBoneMovesItAndMeetsIt()
	{
		let skeleton = scope Skeleton(5);
		StringView[5] names = .("Root", "Hips", "Thigh", "Shin", "Foot");
		int32[5] parents = .(-1, 0, 1, 2, 0);
		Float3[5] offsets = .(.(0, 0, 0), .(0, 1, 0), .(0.15f, 0, 0), .(0, -0.45f, 0.02f), .(0.15f, 0.1f, 0));
		for (int32 i < 5)
		{
			let bone = skeleton.Bones[i];
			bone.Index = i;
			bone.Name.Set(names[i]);
			bone.ParentIndex = parents[i];
			bone.LocalBindPose.Position = offsets[i];
		}
		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();

		let level = scope Scene("detached");
		level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		let hero = level.CreateEntity("Hero");
		level.GetSystem<SkeletalAnimationComponentManager>().Add(hero).Skeleton.SetDirect(skeleton);
		let step = level.CreateEntity("Step");
		let at = Float3(0.25f, 0.3f, 0.2f);
		level.SetLocalTransform(step, .(at, .Identity, .(1, 1, 1)));
		let legIk = level.CreateEntity("LegIk");
		level.SetParent(legIk, hero);
		let legs = level.GetSystem<TwoBoneIkComponentManager>();
		let leg = legs.Add(legIk);
		leg.StartBone.Set("Thigh");
		leg.MidBone.Set("Shin");
		leg.EndBone.Set("Foot");
		leg.Target = EntityRef(level.GetEntityId(step));
		leg.FadeSeconds = 0.0f;

		level.Update(1.0f / 60.0f);
		level.Update(1.0f / 60.0f);
		Test.Assert(legs.Get(legIk).Runtime.Status == .Solving);
		let player = level.GetSystem<SkeletalAnimationComponentManager>().Get(hero).Player;
		player.GetSkinningMatrices();
		let cache = scope ModelPoseCache();
		cache.Build(skeleton, player.GetFinalPoses());
		Test.Assert(Length(InverseKinematics.Position(cache.At(4)) - at) < 1.0e-3f);
		// The shin's tip, where it met the foot in the bind pose (0.45 below the shin), meets it again.
		let tip = TransformPoint(.(0, -0.45f, -0.02f), cache.At(3));
		Test.Assert(Length(tip - at) < 1.0e-3f);
		Test.Assert(IkScene.Reached(level, legIk));
	}

	/// Player (the gameplay root) holds the IK; its child holds the animator (an imported model's
	/// prefab the game does not edit). Nothing at or above: the one animator below.
	[Test]
	public static void OnAGameplayRootItDrivesTheOneAnimatorBelowIt()
	{
		let log = new IkLog();
		InitGlobalLogger(log, true);
		defer ShutdownGlobalLogger();

		let s = scope Stage();
		let player = s.Level.CreateEntity("Player");
		let decoy = s.Level.CreateEntity("Hat"); // a child without an animator
		s.Level.SetParent(decoy, player);
		s.Level.SetParent(s.Rider, player);
		let target = s.Target("Step", .(6, 4, 0));
		let legs = s.Level.GetSystem<TwoBoneIkComponentManager>();
		let leg = legs.Add(player);
		leg.StartBone.Set("Thigh");
		leg.MidBone.Set("Shin");
		leg.EndBone.Set("Foot");
		leg.Target = EntityRef(s.Level.GetEntityId(target));
		leg.FadeSeconds = 0.0f;
		s.Tick();
		s.Tick();
		Test.Assert(legs.Get(player).Runtime.Status == .Solving);
		Test.Assert(legs.Get(player).Runtime.Animator == s.Rider);
		Test.Assert(Length(s.BoneWorld(3) - Float3(6, 4, 0)) < 1.0e-3f);
		Test.Assert(log.Lines == 0);

		// A second animated child (a pet, a held prop): which one is meant is no longer clear, and
		// child order must not decide it. The component turns off with one log line.
		let pet = s.Level.CreateEntity("Pet");
		s.Level.SetParent(pet, player);
		s.Level.GetSystem<SkeletalAnimationComponentManager>().Add(pet).Skeleton.SetDirect(s.Skeleton);
		for (int frame < 5)
			s.Tick();
		Test.Assert(legs.Get(player).Runtime.Status == .NoAnimator);
		Test.Assert(log.Lines == 1);
		Test.Assert(s.Player.Modifiers.IsEmpty);
	}
}
