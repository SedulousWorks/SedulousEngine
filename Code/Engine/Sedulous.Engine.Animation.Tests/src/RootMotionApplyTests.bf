using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Scene;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Engine.Animation.Tests;

/// Applying root motion (root-motion.md P2): Entity mode walks and turns the entity through a
/// moved and turned parent, or a named gameplay root; Ignore leaves it; Script holds the world
/// delta; Character mode walks the character above it and lets it go with one zero move; a
/// version 1 animator record reads with root motion off.
class RootMotionApplyTests
{
	private static bool Near(float a, float b, float relative)
		=> Math.Abs(a - b) <= Math.Max(relative * Math.Max(Math.Abs(a), Math.Abs(b)), 1e-5f);

	/// A clip that walks `metres` a second along +Z and turns `turn` radians a second.
	private static void Walking(AnimationClip clip, float metres, float turn = 0.0f)
	{
		clip.Duration = 1.0f;
		clip.IsLooping = true;
		clip.RootMotion.Horizontal = true;
		clip.RootMotion.Yaw = turn != 0.0f;
		for (int i <= 20)
		{
			let t = (float)i / 20.0f;
			clip.RootMotion.Times.Add(t);
			clip.RootMotion.Positions.Add(.(0, 0, metres * t));
			clip.RootMotion.Yaws.Add(turn * t);
		}
		clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 0, 0));
		clip.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 0, 0));
	}

	private class Stage
	{
		public AnimationClip Clip = new .("Walk") ~ delete _;
		public Skeleton Skeleton = new .(1);
		public Scene Level = new .("rm");
		public EntityHandle Parent;
		public EntityHandle Walker;

		public this(float metres, float turn, RootMotionMode mode)
		{
			Walking(Clip, metres, turn);
			Skeleton.Bones[0].Index = 0;
			Skeleton.Bones[0].ParentIndex = -1;
			Skeleton.FindRootBones();
			Skeleton.BuildChildIndices();
			Level.AddSystem<MeshComponentManager>();
			AnimationScene.AddAnimationSceneManagers(Level);
			// A parent moved and turned a quarter: the walker's travel must come out in the world.
			Parent = Level.CreateEntity("Herd");
			Level.SetLocalTransform(Parent, .(.(10, 0, 0), Quaternion.FromAxisAngle(.(0, 1, 0), HalfPi), .(1, 1, 1)));
			Walker = Level.CreateEntity("Dog");
			Level.SetParent(Walker, Parent);
			let a = Level.GetSystem<SkeletalAnimationComponentManager>().Add(Walker);
			a.Skeleton.SetDirect(Skeleton);
			a.Clip.SetDirect(Clip);
			a.RootMotion = mode;
			Level.UpdateTransforms();
		}

		public ~this()
		{
			// The scene first: its animator borrows the skeleton and the clip.
			delete Level;
			delete Skeleton;
		}

		public void Run(float seconds, float dt = 1.0f / 30.0f)
		{
			for (var t = 0.0f; t < seconds - 1.0e-4f; t += dt)
				Level.Update(dt);
		}

		public SkeletalAnimationComponent* Animator => Level.GetSystem<SkeletalAnimationComponentManager>().Get(Walker);
	}

	[Test]
	public static void EntityModeWalksTheEntityByItsClipThroughItsParentOverManyLoops()
	{
		let s = scope Stage(2.0f, 0.0f, .Entity);
		let start = s.Level.GetWorldPosition(s.Walker);
		s.Run(3.0f);
		let moved = s.Level.GetWorldPosition(s.Walker) - start;
		// Three loops: 6 m along the walker's +Z, which the parent's quarter turn points along +X.
		Test.Assert(Near(Length(moved), 6.0f, 1e-3f));
		Test.Assert(Near(moved.X, 6.0f, 1e-3f));
	}

	/// The model (the animator) is a child of the gameplay root; moving the animator's own entity
	/// would walk the model away from the root and its logic.
	[Test]
	public static void EntityModeMovesANamedGameplayRootTheModelRidingAlongUnderIt()
	{
		let s = scope Stage(2.0f, 0.0f, .Entity);
		s.Animator.RootMotionTarget = EntityRef(s.Level.GetEntityId(s.Parent));
		let root = s.Level.GetWorldPosition(s.Parent);
		s.Run(1.0f);
		Test.Assert(Near(Length(s.Level.GetWorldPosition(s.Parent) - root), 2.0f, 1e-3f));
		Test.Assert(Length(s.Level.GetLocalTransform(s.Walker).Position) < 1.0e-6f, "the model stayed put under it");
	}

	[Test]
	public static void EntityModeTurnsWithATurnClip()
	{
		let s = scope Stage(0.0f, HalfPi, .Entity);
		s.Run(2.0f);
		let forward = RotateVector(s.Level.GetLocalTransform(s.Walker).Rotation, .(0, 0, 1));
		Test.Assert(Near(forward.Z, -1.0f, 1e-3f), "a half turn in two seconds");
	}

	[Test]
	public static void IgnoreLeavesTheEntityWhereItWasAndScriptHoldsTheWorldDelta()
	{
		{
			let ignore = scope Stage(2.0f, 0.0f, .Ignore);
			let before = ignore.Level.GetWorldPosition(ignore.Walker);
			ignore.Run(1.0f);
			Test.Assert(Length(ignore.Level.GetWorldPosition(ignore.Walker) - before) < 1.0e-6f);
		}
		let script = scope Stage(3.0f, 0.0f, .Script);
		let still = script.Level.GetWorldPosition(script.Walker);
		script.Run(0.5f, 0.1f);
		Test.Assert(Length(script.Level.GetWorldPosition(script.Walker) - still) < 1.0e-6f, "moved nothing");
		let tick = script.Animator.RootMotionState.WorldTranslation;
		Test.Assert(Near(tick.X, 0.3f, 1e-3f), "3 m/s for 0.1 s, the parent turning +Z to +X");
		Test.Assert(Math.Abs(tick.Z) < 1.0e-4f);
		Test.Assert(script.Animator.RootMotionState.Yaw == 0.0f);
	}

	/// The scene's character capability, as physics provides it, recording what it was told.
	private class Characters : SceneSystem, ISceneCharacterMotion
	{
		public EntityHandle Character = .Invalid;
		public Float3 Last = .(0, 0, 0);
		public int Moves = 0;
		public bool WrongEntity = false;

		public override ISceneCharacterMotion AsCharacterMotion => this;
		public bool HasCharacter(EntityHandle entity) => entity == Character;
		public void MoveCharacter(EntityHandle entity, Float3 velocity)
		{
			WrongEntity = WrongEntity || (entity != Character);
			Last = velocity;
			Moves++;
		}
	}

	[Test]
	public static void CharacterModeWalksTheCharacterAboveItAndLetsItGo()
	{
		let s = scope Stage(2.0f, 0.5f, .Character);
		let characters = s.Level.AddSystem<Characters>();
		characters.Character = s.Parent; // the character is the walker's parent
		s.Run(0.5f, 0.1f);
		Test.Assert(characters.Moves == 5);
		Test.Assert(!characters.WrongEntity);
		Test.Assert(Near(Length(characters.Last), 2.0f, 0.01f), "m/s, horizontal");
		Test.Assert(characters.Last.Y == 0.0f);
		// The character turns with the clip, from its quarter turn by half a second at 0.5 rad/s.
		let facing = RotateVector(s.Level.GetLocalTransform(s.Parent).Rotation, .(0, 0, 1));
		Test.Assert(Near(Atan2(facing.X, facing.Z), HalfPi + 0.25f, 1e-3f));

		// Ignore: one zero move, then nothing more.
		s.Animator.RootMotion = .Ignore;
		s.Run(0.1f, 0.1f);
		Test.Assert(characters.Moves == 6);
		Test.Assert(Length(characters.Last) == 0.0f);
		s.Run(0.3f, 0.1f);
		Test.Assert(characters.Moves == 6);

		// Back on, then a script switches it to Script mode: one zero move again.
		s.Animator.RootMotion = .Character;
		s.Run(0.1f, 0.1f);
		let walking = characters.Moves;
		Test.Assert(Length(characters.Last) > 1.0f);
		s.Animator.RootMotion = .Script;
		s.Run(0.2f, 0.1f);
		Test.Assert(characters.Moves == walking + 1);
		Test.Assert(Length(characters.Last) == 0.0f);

		// Back on, then the animator removed: one zero move as it goes.
		s.Animator.RootMotion = .Character;
		s.Run(0.1f, 0.1f);
		Test.Assert(Length(characters.Last) > 1.0f);
		s.Level.GetSystem<SkeletalAnimationComponentManager>().Remove(s.Walker);
		Test.Assert(Length(characters.Last) == 0.0f);
	}

	[Test]
	public static void AVersionOneAnimatorRecordReadsWithRootMotionOff()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><object><string name=\"skeleton\">00000000-0000-0000-0000-000000000000</string>"
			+ "<string name=\"clip\">00000000-0000-0000-0000-000000000000</string>"
			+ "<f32 name=\"speed\">1.5</f32><f32 name=\"startTime\">0</f32><bool name=\"autoPlay\">true</bool>"
			+ "<array name=\"meshEntities\" count=\"0\"/></object></root>") == .Ok);
		let reader = scope XmlSerializer(document);
		SerializedDataVersion[1] chain = .(.(0, 1));
		reader.PushVersionScope(chain);
		var c = SkeletalAnimationComponent();
		c.MeshEntities = scope .();
		reader.BeginObject();
		c.Serialize(reader);
		reader.EndObject();
		reader.PopVersionScope();
		Test.Assert(reader.IsOk, "no rootMotion field asked of a version 1 record");
		Test.Assert(Near(c.Speed, 1.5f, 1e-5f));
		Test.Assert(c.RootMotion == .Ignore);
	}
}
