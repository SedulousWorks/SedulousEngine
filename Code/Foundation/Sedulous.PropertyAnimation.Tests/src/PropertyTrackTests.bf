using System;
using Sedulous.Core;
using Sedulous.PropertyAnimation;

namespace Sedulous.PropertyAnimation.Tests;

/// Sampling the tracks.
class PropertyTrackTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void AScalarTrackSamplesItsOneChannel()
	{
		let track = scope PropertyTrack();
		track.Kind = .Float;
		track.Channels[0].AddKey(.(0.0f, 0.0f));
		track.Channels[0].AddKey(.(1.0f, 10.0f));

		Test.Assert(Near(track.Sample(0.0f).Scalar, 0.0f));
		Test.Assert(Near(track.Sample(0.5f).Scalar, 5.0f));
		Test.Assert(Near(track.Sample(1.0f).Scalar, 10.0f));
		Test.Assert(Near(track.Duration, 1.0f));
	}

	[Test]
	public static void AVectorTrackSamplesEachChannelSeparately()
	{
		let track = scope PropertyTrack();
		track.Kind = .Float3;
		track.Channels[0].AddKey(.(0.0f, 0.0f));
		track.Channels[0].AddKey(.(2.0f, 20.0f));
		// One key alone holds its value throughout.
		track.Channels[1].AddKey(.(0.0f, 5.0f));
		track.Channels[2].AddKey(.(0.0f, -1.0f));
		track.Channels[2].AddKey(.(2.0f, 1.0f));

		let value = track.Sample(1.0f).Vector;
		Test.Assert(Near(value.X, 10.0f));
		Test.Assert(Near(value.Y, 5.0f));
		Test.Assert(Near(value.Z, 0.0f));
		Test.Assert(Near(track.Duration, 2.0f));
	}

	[Test]
	public static void AColourTrackSamplesAllFourChannels()
	{
		let track = scope PropertyTrack();
		track.Kind = .Color;
		for (int32 c < 4)
		{
			track.Channels[c].AddKey(.(0.0f, 0.0f));
			track.Channels[c].AddKey(.(1.0f, (float)(c + 1) * 0.25f));
		}

		let value = track.Sample(1.0f).Color;
		Test.Assert(Near(value.R, 0.25f));
		Test.Assert(Near(value.G, 0.50f));
		Test.Assert(Near(value.B, 0.75f));
		Test.Assert(Near(value.A, 1.00f));
	}

	/// The rotation is interpolated along the SHORTER arc, not per component: interpolating
	/// the components independently does not describe a rotation between two orientations.
	[Test]
	public static void ARotationTrackInterpolatesBetweenItsKeys()
	{
		let track = scope PropertyTrack();
		track.Kind = .Quat;
		track.QuatKeys.Add(.(0.0f, Quaternion.Identity));
		let quarterTurn = Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), 1.57079633f);
		track.QuatKeys.Add(.(1.0f, quarterTurn));

		let start = track.Sample(0.0f).Rotation;
		Test.Assert(Near(start.W, 1.0f));

		let middle = track.Sample(0.5f).Rotation;
		Test.Assert(middle.Y > 0.0f);
		// Between the two, rather than at either end.
		Test.Assert(middle.Y < quarterTurn.Y);
		Test.Assert(middle.W < 1.0f);
		Test.Assert(Near(track.Duration, 1.0f));
	}

	[Test]
	public static void ARotationTrackClampsToItsEnds()
	{
		let track = scope PropertyTrack();
		track.Kind = .Quat;
		let quarterTurn = Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), 1.57079633f);
		track.QuatKeys.Add(.(1.0f, Quaternion.Identity));
		track.QuatKeys.Add(.(2.0f, quarterTurn));

		Test.Assert(Near(track.Sample(-5.0f).Rotation.W, 1.0f));
		Test.Assert(Near(track.Sample(99.0f).Rotation.Y, quarterTurn.Y));
	}

	[Test]
	public static void ARotationTrackWithNoKeysIsTheIdentity()
	{
		let track = scope PropertyTrack();
		track.Kind = .Quat;
		Test.Assert(track.SampleQuat(0.5f) == Quaternion.Identity);
		Test.Assert(track.Duration == 0.0f);
	}

	/// An EMPTY CHANNEL does not drive its component: without this, an entity animated only in
	/// one axis would be teleported to nought in the other two.
	[Test]
	public static void AnEmptyChannelKeepsTheCurrentValue()
	{
		let track = scope PropertyTrack();
		track.Kind = .Float3;
		track.Channels[0].AddKey(.(0.0f, 0.0f));
		track.Channels[0].AddKey(.(1.0f, 10.0f));

		let merged = track.SampleMerged(0.5f, PropertyValue.FromFloat3(.(5.0f, 6.0f, 7.0f)));
		Test.Assert(Near(merged.Vector.X, 5.0f));
		Test.Assert(Near(merged.Vector.Y, 6.0f));
		Test.Assert(Near(merged.Vector.Z, 7.0f));
	}

	[Test]
	public static void ATrackWithEveryChannelEmptyWritesNothingNew()
	{
		let track = scope PropertyTrack();
		track.Kind = .Float3;

		let merged = track.SampleMerged(0.5f, PropertyValue.FromFloat3(.(1.0f, 2.0f, 3.0f)));
		Test.Assert(Near(merged.Vector.X, 1.0f));
		Test.Assert(Near(merged.Vector.Y, 2.0f));
		Test.Assert(Near(merged.Vector.Z, 3.0f));
	}

	/// A target that could not be read at all leaves the empty channels at nought, there being
	/// no live value to keep.
	[Test]
	public static void AnUnreadableTargetFallsBackToNought()
	{
		let track = scope PropertyTrack();
		track.Kind = .Float3;
		track.Channels[0].AddKey(.(0.0f, 0.0f));
		track.Channels[0].AddKey(.(1.0f, 10.0f));

		let merged = track.SampleMerged(1.0f, PropertyValue.Empty);
		Test.Assert(Near(merged.Vector.X, 10.0f));
		Test.Assert(Near(merged.Vector.Y, 0.0f));
		Test.Assert(Near(merged.Vector.Z, 0.0f));
	}

	[Test]
	public static void AMergedRotationWithNoKeysKeepsTheCurrentOne()
	{
		let track = scope PropertyTrack();
		track.Kind = .Quat;

		let current = PropertyValue.FromQuaternion(
			Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), 0.5f));
		let merged = track.SampleMerged(0.5f, current);
		Test.Assert(Near(merged.Rotation.X, current.Rotation.X));
		Test.Assert(Near(merged.Rotation.W, current.Rotation.W));
	}

	[Test]
	public static void AKindKnowsHowManyChannelsItDrives()
	{
		Test.Assert(TrackValueKind.Float.ChannelCount == 1);
		Test.Assert(TrackValueKind.Float3.ChannelCount == 3);
		Test.Assert(TrackValueKind.Color.ChannelCount == 4);
		// A rotation uses its own keys rather than curves.
		Test.Assert(TrackValueKind.Quat.ChannelCount == 0);
	}

	[Test]
	public static void AClipIsAsLongAsItsLongestTrack()
	{
		let clip = scope PropertyAnimationClip();

		let first = new PropertyTrack();
		first.Kind = .Float;
		first.Channels[0].AddKey(.(0.0f, 0.0f));
		first.Channels[0].AddKey(.(1.5f, 1.0f));
		clip.Tracks.Add(first);

		let second = new PropertyTrack();
		second.Kind = .Float;
		second.Channels[0].AddKey(.(0.0f, 0.0f));
		second.Channels[0].AddKey(.(3.0f, 1.0f));
		clip.Tracks.Add(second);

		Test.Assert(Near(clip.ComputeDuration(), 3.0f));
	}
}
