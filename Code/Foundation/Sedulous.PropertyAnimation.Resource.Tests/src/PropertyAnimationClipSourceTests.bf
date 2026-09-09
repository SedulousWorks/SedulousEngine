using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.PropertyAnimation;
using Sedulous.PropertyAnimation.Resource;

namespace Sedulous.PropertyAnimation.Resource.Tests;

/// The cooked clip's wire: flatten, serialize, read back, rebuild.
class PropertyAnimationClipSourceTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// The counts pin the flattening's SHAPE: three tracks, seven channel entries, which is
	/// three plus four plus none, thirteen scalar keys and two rotation keys.
	[Test]
	public static void FlatteningLaysTheClipOutFlat()
	{
		let clip = scope PropertyAnimationClip();
		let made = ClipFixture.Make();
		defer delete made;

		let source = scope PropertyAnimationClipSource();
		PropertyAnimationClipSource.FromClip(made, source);

		Test.Assert(source.TrackKind.Count == 3);
		Test.Assert(source.ChannelKeyStart.Count == 7);
		Test.Assert(source.ChannelKeyCount.Count == 7);
		Test.Assert(source.KeyTime.Count == 13);
		Test.Assert(source.QuatValue.Count == 2);
		Test.Assert(source.TrackQuatStart.Count == 3);

		// Silence the unused warning on the empty clip above.
		Test.Assert(clip.Tracks.IsEmpty);
	}

	[Test]
	public static void TheWireRoundTripsThroughTheSerializer()
	{
		let original = ClipFixture.Make();
		defer delete original;

		let source = scope PropertyAnimationClipSource();
		PropertyAnimationClipSource.FromClip(original, source);

		let stream = scope MemoryStream();
		{
			ISerializable writable = source;
			let writer = scope BinarySerializer(stream, .Write);
			writable.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);

		let restored = scope PropertyAnimationClipSource();
		{
			ISerializable readable = restored;
			let reader = scope BinarySerializer(stream, .Read);
			readable.Serialize(reader);
			Test.Assert(reader.IsOk);
		}

		let rebuilt = scope PropertyAnimationClip();
		restored.FillClip(rebuilt);

		Test.Assert(rebuilt.Tracks.Count == original.Tracks.Count);
		Test.Assert(Near(rebuilt.Duration, original.Duration));

		Test.Assert(rebuilt.Tracks[0].ComponentType == "Transform");
		Test.Assert(rebuilt.Tracks[0].PropertyPath == "Position");
		Test.Assert(rebuilt.Tracks[0].Kind == .Float3);
		Test.Assert(rebuilt.Tracks[1].PropertyPath == "Light.Tint");
		Test.Assert(rebuilt.Tracks[2].Kind == .Quat);

		// The clip is IDENTICAL where it counts: what it samples to, across every kind.
		let times = float[5](0.0f, 0.5f, 1.0f, 1.5f, 2.0f);
		for (let time in times)
		{
			let a = original.Tracks[0].Sample(time).Vector;
			let b = rebuilt.Tracks[0].Sample(time).Vector;
			Test.Assert(Near(a.X, b.X));
			Test.Assert(Near(a.Y, b.Y));
			Test.Assert(Near(a.Z, b.Z));

			let ca = original.Tracks[1].Sample(time).Color;
			let cb = rebuilt.Tracks[1].Sample(time).Color;
			Test.Assert(Near(ca.R, cb.R));
			Test.Assert(Near(ca.A, cb.A));

			let qa = original.Tracks[2].Sample(time).Rotation;
			let qb = rebuilt.Tracks[2].Sample(time).Rotation;
			Test.Assert(Near(qa.W, qb.W));
			Test.Assert(Near(qa.Y, qb.Y));
		}
	}

	/// The interpolation mode and the tangents survive, rather than quietly becoming linear
	/// with none.
	[Test]
	public static void AKeysShapeSurvivesTheWire()
	{
		let original = ClipFixture.Make();
		defer delete original;

		let source = scope PropertyAnimationClipSource();
		PropertyAnimationClipSource.FromClip(original, source);

		let rebuilt = scope PropertyAnimationClip();
		source.FillClip(rebuilt);

		let keys = rebuilt.Tracks[0].Channels[0].Keys;
		Test.Assert(keys.Count == 2);
		Test.Assert(keys[0].Interpolation == .Cubic);
		Test.Assert(Near(keys[0].TangentOut, 2.0f));
		Test.Assert(rebuilt.Tracks[0].Channels[2].Keys[0].Interpolation == .Constant);
	}

	/// A malformed record yields a partial but SAFE clip: every index is bounded against the
	/// pool it reads from, so a claim of ninety nine keys over an empty pool produces none
	/// rather than reading past the end.
	[Test]
	public static void AMalformedRecordReadsNothingItDoesNotHave()
	{
		let source = scope PropertyAnimationClipSource();
		source.TrackKind.Add((uint8)TrackValueKind.Float3);
		source.TrackComponent.Add(new String("C"));
		source.TrackPath.Add(new String("p"));
		source.ChannelKeyStart.Add(0);
		source.ChannelKeyCount.Add(99);

		let clip = scope PropertyAnimationClip();
		source.FillClip(clip);

		Test.Assert(clip.Tracks.Count == 1);
		Test.Assert(clip.Tracks[0].Channels[0].KeyCount == 0);
	}

	/// An out of range kind byte would make the channel count wrong and desynchronise the
	/// cursor for every LATER track, so it reads as a float instead.
	[Test]
	public static void AnUnknownKindReadsAsASingleChannel()
	{
		let source = scope PropertyAnimationClipSource();
		source.TrackKind.Add(200);
		source.TrackKind.Add((uint8)TrackValueKind.Float);
		source.TrackComponent.Add(new String("A"));
		source.TrackComponent.Add(new String("B"));
		source.TrackPath.Add(new String("a"));
		source.TrackPath.Add(new String("b"));

		source.ChannelKeyStart.Add(0);
		source.ChannelKeyCount.Add(1);
		source.ChannelKeyStart.Add(1);
		source.ChannelKeyCount.Add(1);
		source.KeyTime.Add(0.0f);
		source.KeyValue.Add(1.0f);
		source.KeyTime.Add(0.0f);
		source.KeyValue.Add(2.0f);

		let clip = scope PropertyAnimationClip();
		source.FillClip(clip);

		Test.Assert(clip.Tracks.Count == 2);
		Test.Assert(clip.Tracks[0].Kind == .Float);
		// The SECOND track still got its own key, the cursor having stayed in step.
		Test.Assert(Near(clip.Tracks[0].Sample(0.0f).Scalar, 1.0f));
		Test.Assert(Near(clip.Tracks[1].Sample(0.0f).Scalar, 2.0f));
	}

	/// A rotation track's keys are only read for a rotation track, so a stray run against a
	/// scalar one is ignored rather than mixed in.
	[Test]
	public static void RotationKeysAreOnlyReadForARotationTrack()
	{
		let source = scope PropertyAnimationClipSource();
		source.TrackKind.Add((uint8)TrackValueKind.Float);
		source.TrackComponent.Add(new String("C"));
		source.TrackPath.Add(new String("p"));
		source.ChannelKeyStart.Add(0);
		source.ChannelKeyCount.Add(0);
		source.TrackQuatStart.Add(0);
		source.TrackQuatCount.Add(1);
		source.QuatTime.Add(0.0f);
		source.QuatValue.Add(.(0, 1, 0, 0));

		let clip = scope PropertyAnimationClip();
		source.FillClip(clip);

		Test.Assert(clip.Tracks.Count == 1);
		Test.Assert(clip.Tracks[0].QuatKeys.IsEmpty);
	}

	/// Filling REPLACES what the clip held, rather than appending to it.
	[Test]
	public static void FillingReplacesTheClipsTracks()
	{
		let original = ClipFixture.Make();
		defer delete original;

		let source = scope PropertyAnimationClipSource();
		PropertyAnimationClipSource.FromClip(original, source);

		let clip = scope PropertyAnimationClip();
		source.FillClip(clip);
		source.FillClip(clip);

		Test.Assert(clip.Tracks.Count == 3);
	}
}
