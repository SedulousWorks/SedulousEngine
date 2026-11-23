using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;

namespace Sedulous.PropertyAnimation.Tests;

/// A scene component with animatable properties, for the track targets.
[Reflect(.All)]
struct TrackLamp
{
	public float Intensity = 1.0f;
	public Float3 Offset = .(0.0f, 0.0f, 0.0f);
	public AnimLight Light = .();

	public this() {}
}

class TrackLampManager : ComponentManager<TrackLamp>
{
}

/// A track's target bound once on a scene, then read and written on any entity there: what the
/// animator, the sequencer and the editor's preview share, so none keeps its own copy.
class TrackTargetTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void ATargetResolvesOnceAndSaysWhyItCannot()
	{
		let scene = scope Sedulous.Scene.Scene("targets");
		let lamps = scene.AddSystem<TrackLampManager>();
		Test.Assert(scene.FindManagerByComponentName("TrackLamp") === lamps);
		Test.Assert(scene.FindManagerByComponentName("Nothing") == null);

		let target = scope TrackTarget();
		TrackTargets.Resolve(scene, "TrackLamp", "Intensity", target);
		Test.Assert(target.IsResolved && (target.Manager === lamps) && !target.IsTransform);
		TrackTargets.Resolve(scene, "Ghost", "Intensity", target);
		Test.Assert(target.Status == .UnknownComponent);
		TrackTargets.Resolve(scene, "TrackLamp", "Brightness", target);
		Test.Assert(target.Status == .UnknownProperty);

		// The kind checked against the property: a Float3 track on a float property never writes.
		let track = scope PropertyTrack();
		track.ComponentType.Set("TrackLamp");
		track.PropertyPath.Set("Intensity");
		track.Kind = .Float3;
		TrackTargets.Resolve(scene, track, target);
		Test.Assert(target.Status == .KindMismatch);
		track.Kind = .Float;
		TrackTargets.Resolve(scene, track, target);
		Test.Assert(target.IsResolved);
	}

	[Test]
	public static void ATargetReadsAndWritesAnyEntityWithTheComponentAndTheTransformThroughTheScene()
	{
		let scene = scope Sedulous.Scene.Scene("targets");
		let lamps = scene.AddSystem<TrackLampManager>();
		let lit = scene.CreateEntity("lit");
		let bare = scene.CreateEntity("bare");
		lamps.Add(lit).Intensity = 2.0f;

		let intensity = scope TrackTarget();
		TrackTargets.Resolve(scene, "TrackLamp", "Intensity", intensity);
		Test.Assert(Near(TrackTargets.Read(scene, intensity, lit).Scalar, 2.0f));
		Test.Assert(TrackTargets.Write(scene, intensity, lit, .FromFloat(5.0f)));
		Test.Assert(Near(lamps.Get(lit).Intensity, 5.0f));
		Test.Assert(!TrackTargets.Read(scene, intensity, bare).HasValue, "no such component on it");
		Test.Assert(!TrackTargets.Write(scene, intensity, bare, .FromFloat(5.0f)));

		// The transform is the scene's: written through SetLocalTransform, so its world follows.
		let position = scope TrackTarget();
		TrackTargets.Resolve(scene, TrackTargets.cTransform, "Position", position);
		Test.Assert(position.IsResolved && position.IsTransform);
		Test.Assert(TrackTargets.Write(scene, position, bare, .FromFloat3(.(1.0f, 2.0f, 3.0f))));
		scene.UpdateTransforms();
		let world = scene.GetWorldPosition(bare);
		Test.Assert(Near(world.X, 1.0f) && Near(world.Y, 2.0f) && Near(world.Z, 3.0f));
	}

	/// One player step: the track sampled over the live value, so a channel without keys keeps it.
	[Test]
	public static void ApplyingATrackKeepsTheChannelsItDoesNotDrive()
	{
		let scene = scope Sedulous.Scene.Scene("targets");
		let lamps = scene.AddSystem<TrackLampManager>();
		let lit = scene.CreateEntity("lit");
		lamps.Add(lit).Offset = .(7.0f, 8.0f, 9.0f);
		let track = scope PropertyTrack();
		track.ComponentType.Set("TrackLamp");
		track.PropertyPath.Set("Offset");
		track.Kind = .Float3;
		track.Channels[0].AddKey(.(0.0f, 0.0f));
		track.Channels[0].AddKey(.(1.0f, 10.0f));
		let target = scope TrackTarget();
		TrackTargets.Resolve(scene, track, target);
		Test.Assert(TrackTargets.Apply(scene, target, lit, track, 0.5f));
		let offset = lamps.Get(lit).Offset;
		Test.Assert(Near(offset.X, 5.0f) && Near(offset.Y, 8.0f) && Near(offset.Z, 9.0f), scope $"{offset.X} {offset.Y} {offset.Z}");
	}
}
