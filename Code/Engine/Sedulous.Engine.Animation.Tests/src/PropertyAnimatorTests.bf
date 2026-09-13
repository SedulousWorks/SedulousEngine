using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.PropertyAnimation;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation.Tests;

/// The property animator inside a scene: a clip drives a reflected property on the owning
/// entity's component over a tick sequence, the loop modes wrap, and a track that will not
/// resolve is disabled rather than retried or fatal.
class PropertyAnimatorTests
{
	private static bool Near(float a, float b, float epsilon = 1e-3f)
		=> Math.Abs(a - b) < epsilon;

	/// A clip driving the target's position from nought to ten over a second.
	private static PropertyAnimationClip MakePositionClip()
	{
		let clip = new PropertyAnimationClip();
		let track = new PropertyTrack();
		track.ComponentType.Set("AnimTarget");
		track.PropertyPath.Set("Position");
		track.Kind = .Float3;
		track.Channels[0].AddKey(CurveKey(0.0f, 0.0f));
		track.Channels[0].AddKey(CurveKey(1.0f, 10.0f));
		clip.Tracks.Add(track);
		clip.Duration = clip.ComputeDuration();
		return clip;
	}

	/// A kind that does not match the property's type would be a silent write failure every
	/// frame. It is disabled once instead, exactly as a failed resolve is.
	[Test]
	public static void AKindMismatchDisablesTheTrack()
	{
		let scene = scope Scene();
		let targets = scene.AddSystem<AnimTargetManager>();
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("Mover");
		let target = targets.Add(entity);
		target.Value = 42.0f;

		// A vector track pointed at the SCALAR, so the kind mismatches the leaf.
		let clip = scope PropertyAnimationClip();
		let track = new PropertyTrack();
		track.ComponentType.Set("AnimTarget");
		track.PropertyPath.Set("Value");
		track.Kind = .Float3;
		track.Channels[0].AddKey(CurveKey(0.0f, 0.0f));
		track.Channels[0].AddKey(CurveKey(1.0f, 10.0f));
		clip.Tracks.Add(track);
		clip.Duration = clip.ComputeDuration();

		let animator = animators.Add(entity);
		animator.Clip.SetDirect(clip);
		animator.AutoPlay = true;

		// Binding happens here, and the mismatch is caught with it.
		scene.Update(0.0f);
		Test.Assert(animator.Bindings.Count == 1);
		Test.Assert(animator.Bindings[0].Disabled);

		scene.Update(0.5f);
		// Never written.
		Test.Assert(Near(target.Value, 42.0f));
	}

	/// The entity's transform is baked into the scene rather than being a component, so a
	/// track names it specially and the write goes through the scene's setter: that is what
	/// flags the world matrix dirty.
	[Test]
	public static void ATransformTrackDrivesTheBakedSceneTransform()
	{
		let scene = scope Scene();
		// The transform is built in, so there is no target manager.
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("Mover");

		let clip = scope PropertyAnimationClip();
		let track = new PropertyTrack();
		track.ComponentType.Set("Transform");
		track.PropertyPath.Set("Position");
		track.Kind = .Float3;
		track.Channels[0].AddKey(CurveKey(0.0f, 0.0f));
		track.Channels[0].AddKey(CurveKey(1.0f, 10.0f));
		clip.Tracks.Add(track);
		clip.Duration = clip.ComputeDuration();

		let animator = animators.Add(entity);
		animator.Clip.SetDirect(clip);
		animator.AutoPlay = true;
		animator.LoopMode = .Loop;

		scene.Update(0.0f);
		Test.Assert(Near(scene.GetLocalTransform(entity).Position.X, 0.0f));
		scene.Update(0.5f);
		Test.Assert(Near(scene.GetLocalTransform(entity).Position.X, 5.0f));
		scene.Update(0.4f);
		Test.Assert(Near(scene.GetLocalTransform(entity).Position.X, 9.0f));
		// The write went through the setter, so the world matrix carries it once the scene's
		// own transform phase has run, which the update does.
		Test.Assert(Near(scene.GetWorldMatrix(entity).M[3][0], 9.0f));
	}

	[Test]
	public static void AVectorClipDrivesTheComponentOverTicks()
	{
		let scene = scope Scene();
		let targets = scene.AddSystem<AnimTargetManager>();
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("Mover");
		let target = targets.Add(entity);

		let clip = MakePositionClip();
		defer delete clip;
		let animator = animators.Add(entity);
		// A direct runtime object: there is no resource manager in this test.
		animator.Clip.SetDirect(clip);
		animator.AutoPlay = true;

		// The first tick binds and starts at the top.
		scene.Update(0.0f);
		Test.Assert(Near(target.Position.X, 0.0f));

		scene.Update(0.5f);
		Test.Assert(Near(target.Position.X, 5.0f));

		scene.Update(0.4f);
		Test.Assert(Near(target.Position.X, 9.0f));

		// Past the end it LOOPS back round.
		scene.Update(0.2f);
		Test.Assert(Near(target.Position.X, 1.0f, 0.05f));
	}

	[Test]
	public static void OnceStopsAtTheEndAndHoldsThere()
	{
		let scene = scope Scene();
		let targets = scene.AddSystem<AnimTargetManager>();
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("Once");
		targets.Add(entity);

		let clip = MakePositionClip();
		defer delete clip;
		let animator = animators.Add(entity);
		animator.Clip.SetDirect(clip);
		animator.LoopMode = .Once;

		scene.Update(0.0f);
		// Way past the end.
		scene.Update(2.0f);
		Test.Assert(Near(targets.Get(entity).Position.X, 10.0f));
		Test.Assert(!animator.Playing);

		// A further tick holds the end value.
		scene.Update(1.0f);
		Test.Assert(Near(targets.Get(entity).Position.X, 10.0f));
	}

	/// A clip with bad tracks keeps playing its good ones.
	[Test]
	public static void ATrackToAMissingComponentOrPropertyIsDisabledRatherThanFatal()
	{
		let scene = scope Scene();
		let targets = scene.AddSystem<AnimTargetManager>();
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("Mixed");
		let target = targets.Add(entity);

		let clip = scope PropertyAnimationClip();
		{
			let good = new PropertyTrack();
			good.ComponentType.Set("AnimTarget");
			good.PropertyPath.Set("Value");
			good.Kind = .Float;
			good.Channels[0].AddKey(CurveKey(0.0f, 0.0f));
			good.Channels[0].AddKey(CurveKey(1.0f, 8.0f));
			clip.Tracks.Add(good);

			let badProperty = new PropertyTrack();
			badProperty.ComponentType.Set("AnimTarget");
			badProperty.PropertyPath.Set("nonesuch");
			badProperty.Kind = .Float;
			clip.Tracks.Add(badProperty);

			let badComponent = new PropertyTrack();
			badComponent.ComponentType.Set("NoSuchComponent");
			badComponent.PropertyPath.Set("x");
			badComponent.Kind = .Float;
			clip.Tracks.Add(badComponent);
		}
		clip.Duration = clip.ComputeDuration();

		let animator = animators.Add(entity);
		animator.Clip.SetDirect(clip);

		scene.Update(0.0f);
		// Must not fall over despite the two bad tracks.
		scene.Update(0.5f);
		Test.Assert(Near(target.Value, 4.0f));
	}

	/// The playback operations drive the clock; the manager's tick applies it.
	[Test]
	public static void PlayPauseStopAndSetTimeDriveTheClock()
	{
		let scene = scope Scene();
		let targets = scene.AddSystem<AnimTargetManager>();
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("Driven");
		let target = targets.Add(entity);

		let clip = MakePositionClip();
		defer delete clip;
		let animator = animators.Add(entity);
		animator.Clip.SetDirect(clip);
		// Driven by the calls below rather than by automatic playback.
		animator.AutoPlay = false;

		// The first tick binds but stays stopped.
		scene.Update(0.0f);
		Test.Assert(!animator.Playing);
		Test.Assert(Near(target.Position.X, 0.0f));

		animator.Play();
		Test.Assert(animator.Playing);
		scene.Update(0.5f);
		Test.Assert(Near(target.Position.X, 5.0f));

		// A pause freezes the clock, so the value holds across ticks.
		animator.Pause();
		Test.Assert(!animator.Playing);
		scene.Update(0.5f);
		Test.Assert(Near(target.Position.X, 5.0f));

		// Setting the time and resuming jumps the clock.
		animator.Time = 0.8f;
		animator.Resume();
		scene.Update(0.0f);
		Test.Assert(Near(target.Position.X, 8.0f));

		animator.Stop();
		Test.Assert(!animator.Playing);
		Test.Assert(Near(animator.Time, 0.0f));
	}

	/// An inactive entity does not advance, and toggling it freezes and resumes exactly.
	[Test]
	public static void AnInactiveEntityNeverAdvances()
	{
		let scene = scope Scene();
		let targets = scene.AddSystem<AnimTargetManager>();
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("Frozen");
		let target = targets.Add(entity);

		let clip = MakePositionClip();
		defer delete clip;
		let animator = animators.Add(entity);
		animator.Clip.SetDirect(clip);
		animator.AutoPlay = true;

		// Inactive from the FIRST tick: no binding and no writes.
		scene.SetActive(entity, false);
		scene.Update(0.5f);
		scene.Update(0.5f);
		Test.Assert(Near(target.Position.X, 0.0f));

		// Activation binds and starts from the top: nothing advanced while it was dark.
		scene.SetActive(entity, true);
		scene.Update(0.0f);
		scene.Update(0.5f);
		Test.Assert(Near(target.Position.X, 5.0f));

		// Deactivated mid clip: the time FREEZES.
		scene.SetActive(entity, false);
		scene.Update(0.3f);
		Test.Assert(Near(target.Position.X, 5.0f));

		// And it resumes from where it froze.
		scene.SetActive(entity, true);
		scene.Update(0.4f);
		Test.Assert(Near(target.Position.X, 9.0f));
	}

	/// Animation must not advance in a scene that is not simulating, which is an editor's edit
	/// mode. Scenes simulate by default, so this is opt out only.
	[Test]
	public static void ANonSimulatingSceneFreezesTheAnimator()
	{
		let scene = scope Scene();
		let targets = scene.AddSystem<AnimTargetManager>();
		let animators = scene.AddSystem<PropertyAnimatorComponentManager>();

		let entity = scene.CreateEntity("EditFrozen");
		let target = targets.Add(entity);

		let clip = MakePositionClip();
		defer delete clip;
		let animator = animators.Add(entity);
		animator.Clip.SetDirect(clip);
		animator.AutoPlay = true;

		// Edit mode: never binds, never advances, never writes.
		scene.SetSimulationEnabled(false);
		scene.Update(0.5f);
		scene.Update(0.5f);
		Test.Assert(Near(target.Position.X, 0.0f));

		scene.SetSimulationEnabled(true);
		scene.Update(0.0f);
		scene.Update(0.5f);
		Test.Assert(Near(target.Position.X, 5.0f));

		// Back to edit mode mid clip: frozen where it was.
		scene.SetSimulationEnabled(false);
		scene.Update(0.4f);
		Test.Assert(Near(target.Position.X, 5.0f));
	}
}
