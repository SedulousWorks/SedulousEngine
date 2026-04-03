namespace Sedulous.Animation.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;
using Sedulous.OpenDDL;

class PropertyAnimationClipTests
{
	// ==================== Construction ====================

	[Test]
	public static void Constructor_Default_EmptyName()
	{
		let clip = scope PropertyAnimationClip();
		Test.Assert(clip.Name.IsEmpty);
		Test.Assert(clip.Duration == 0.0f);
		Test.Assert(clip.IsLooping == false);
	}

	[Test]
	public static void Constructor_WithParams_SetsFields()
	{
		let clip = scope PropertyAnimationClip("TestClip", 2.5f, true);
		Test.Assert(clip.Name.Equals("TestClip"));
		Test.Assert(clip.Duration == 2.5f);
		Test.Assert(clip.IsLooping == true);
	}

	// ==================== Track Management ====================

	[Test]
	public static void AddFloatTrack_CreatesAndReturnsTrack()
	{
		let clip = scope PropertyAnimationClip("Test", 1.0f);
		let track = clip.AddFloatTrack("Light.Intensity");
		Test.Assert(track != null);
		Test.Assert(track.PropertyPath.Equals("Light.Intensity"));
		Test.Assert(clip.FloatTracks.Count == 1);
	}

	[Test]
	public static void AddVector3Track_CreatesAndReturnsTrack()
	{
		let clip = scope PropertyAnimationClip("Test", 1.0f);
		let track = clip.AddVector3Track("Transform.Position");
		Test.Assert(track != null);
		Test.Assert(track.PropertyPath.Equals("Transform.Position"));
		Test.Assert(clip.Vector3Tracks.Count == 1);
	}

	[Test]
	public static void AddQuaternionTrack_CreatesAndReturnsTrack()
	{
		let clip = scope PropertyAnimationClip("Test", 1.0f);
		let track = clip.AddQuaternionTrack("Transform.Rotation");
		Test.Assert(track != null);
		Test.Assert(clip.QuaternionTracks.Count == 1);
	}

	[Test]
	public static void AddMultipleTracks_AllStored()
	{
		let clip = scope PropertyAnimationClip("Test", 1.0f);
		clip.AddFloatTrack("A");
		clip.AddFloatTrack("B");
		clip.AddVector3Track("C");
		clip.AddQuaternionTrack("D");
		Test.Assert(clip.FloatTracks.Count == 2);
		Test.Assert(clip.Vector3Tracks.Count == 1);
		Test.Assert(clip.QuaternionTracks.Count == 1);
	}

	// ==================== ComputeDuration ====================

	[Test]
	public static void ComputeDuration_FromKeyframes()
	{
		let clip = scope PropertyAnimationClip("Test");
		let t1 = clip.AddFloatTrack("A");
		t1.AddKeyframe(0.0f, 0.0f);
		t1.AddKeyframe(1.5f, 1.0f);
		let t2 = clip.AddVector3Track("B");
		t2.AddKeyframe(0.0f, .Zero);
		t2.AddKeyframe(3.0f, .One);
		clip.ComputeDuration();
		Test.Assert(clip.Duration == 3.0f);
	}

	// ==================== SortAllKeyframes ====================

	[Test]
	public static void SortAllKeyframes_SortsAll()
	{
		let clip = scope PropertyAnimationClip("Test", 2.0f);
		let track = clip.AddFloatTrack("A");
		track.AddKeyframe(1.0f, 10.0f);
		track.AddKeyframe(0.0f, 0.0f);
		clip.SortAllKeyframes();
		Test.Assert(track.Keyframes[0].Time == 0.0f);
		Test.Assert(track.Keyframes[1].Time == 1.0f);
	}

	// ==================== Serialization Round-Trip ====================

	[Test]
	public static void Serialize_RoundTrip_FloatTrack()
	{
		// Create clip with float track
		let original = scope PropertyAnimationClip("FloatTest", 2.0f, true);
		let track = original.AddFloatTrack("Light.Intensity");
		track.Interpolation = .Linear;
		track.Easing = .EaseInOutCubic;
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(1.0f, 0.5f);
		track.AddKeyframe(2.0f, 1.0f);

		// Serialize
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		original.Serialize(writer);
		let output = scope String();
		writer.GetOutput(output);

		// Deserialize
		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope PropertyAnimationClip();
		loaded.Serialize(reader);

		// Verify
		Test.Assert(loaded.Name.Equals("FloatTest"));
		Test.Assert(loaded.Duration == 2.0f);
		Test.Assert(loaded.IsLooping == true);
		Test.Assert(loaded.FloatTracks.Count == 1);

		let loadedTrack = loaded.FloatTracks[0];
		Test.Assert(loadedTrack.PropertyPath.Equals("Light.Intensity"));
		Test.Assert(loadedTrack.Interpolation == .Linear);
		Test.Assert(loadedTrack.Easing == .EaseInOutCubic);
		Test.Assert(loadedTrack.Keyframes.Count == 3);
		Test.Assert(loadedTrack.Keyframes[0].Time == 0.0f);
		Test.Assert(loadedTrack.Keyframes[0].Value == 0.0f);
		Test.Assert(loadedTrack.Keyframes[1].Time == 1.0f);
		Test.Assert(Math.Abs(loadedTrack.Keyframes[1].Value - 0.5f) < 0.001f);
		Test.Assert(loadedTrack.Keyframes[2].Time == 2.0f);
		Test.Assert(Math.Abs(loadedTrack.Keyframes[2].Value - 1.0f) < 0.001f);
	}

	[Test]
	public static void Serialize_RoundTrip_Vector3Track()
	{
		let original = scope PropertyAnimationClip("PosTest", 1.0f);
		let track = original.AddVector3Track("Transform.Position");
		track.AddKeyframe(0.0f, Vector3(0, 0, 0));
		track.AddKeyframe(1.0f, Vector3(10, 20, 30));

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		original.Serialize(writer);
		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope PropertyAnimationClip();
		loaded.Serialize(reader);

		Test.Assert(loaded.Vector3Tracks.Count == 1);
		let lt = loaded.Vector3Tracks[0];
		Test.Assert(lt.PropertyPath.Equals("Transform.Position"));
		Test.Assert(lt.Keyframes.Count == 2);
		Test.Assert(Math.Abs(lt.Keyframes[1].Value.X - 10.0f) < 0.001f);
		Test.Assert(Math.Abs(lt.Keyframes[1].Value.Y - 20.0f) < 0.001f);
		Test.Assert(Math.Abs(lt.Keyframes[1].Value.Z - 30.0f) < 0.001f);
	}

	[Test]
	public static void Serialize_RoundTrip_QuaternionTrack()
	{
		let original = scope PropertyAnimationClip("RotTest", 1.0f);
		let track = original.AddQuaternionTrack("Transform.Rotation");
		track.AddKeyframe(0.0f, Quaternion.Identity);
		let rot = Quaternion.CreateFromYawPitchRoll(Math.PI_f / 2, 0, 0);
		track.AddKeyframe(1.0f, rot);

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		original.Serialize(writer);
		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope PropertyAnimationClip();
		loaded.Serialize(reader);

		Test.Assert(loaded.QuaternionTracks.Count == 1);
		let lt = loaded.QuaternionTracks[0];
		Test.Assert(lt.Keyframes.Count == 2);
		// Verify quaternion values match
		let loadedRot = lt.Keyframes[1].Value;
		let dot = Math.Abs(loadedRot.X * rot.X + loadedRot.Y * rot.Y + loadedRot.Z * rot.Z + loadedRot.W * rot.W);
		Test.Assert(dot > 0.999f);
	}

	[Test]
	public static void Serialize_RoundTrip_MultipleTracks()
	{
		let original = scope PropertyAnimationClip("MultiTest", 3.0f, true);
		original.AddFloatTrack("Light.Intensity").AddKeyframe(0.0f, 1.0f);
		original.AddVector2Track("UV.Offset").AddKeyframe(0.0f, Vector2(0, 0));
		original.AddVector3Track("Transform.Position").AddKeyframe(0.0f, Vector3.Zero);
		original.AddVector4Track("Color").AddKeyframe(0.0f, Vector4(1, 1, 1, 1));
		original.AddQuaternionTrack("Transform.Rotation").AddKeyframe(0.0f, Quaternion.Identity);

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		original.Serialize(writer);
		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope PropertyAnimationClip();
		loaded.Serialize(reader);

		Test.Assert(loaded.Name.Equals("MultiTest"));
		Test.Assert(loaded.Duration == 3.0f);
		Test.Assert(loaded.IsLooping == true);
		Test.Assert(loaded.FloatTracks.Count == 1);
		Test.Assert(loaded.Vector2Tracks.Count == 1);
		Test.Assert(loaded.Vector3Tracks.Count == 1);
		Test.Assert(loaded.Vector4Tracks.Count == 1);
		Test.Assert(loaded.QuaternionTracks.Count == 1);
	}

	[Test]
	public static void Serialize_RoundTrip_EmptyClip()
	{
		let original = scope PropertyAnimationClip("Empty", 0.0f);

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		original.Serialize(writer);
		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope PropertyAnimationClip();
		loaded.Serialize(reader);

		Test.Assert(loaded.Name.Equals("Empty"));
		Test.Assert(loaded.FloatTracks.Count == 0);
		Test.Assert(loaded.Vector3Tracks.Count == 0);
		Test.Assert(loaded.QuaternionTracks.Count == 0);
	}

	[Test]
	public static void Serialize_RoundTrip_EasingPreserved()
	{
		let original = scope PropertyAnimationClip("EasingTest", 1.0f);
		let track = original.AddFloatTrack("Test");
		track.Easing = .EaseInOutBounce;
		track.Interpolation = .Step;
		track.AddKeyframe(0.0f, 0.0f);

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		original.Serialize(writer);
		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope PropertyAnimationClip();
		loaded.Serialize(reader);

		Test.Assert(loaded.FloatTracks[0].Easing == .EaseInOutBounce);
		Test.Assert(loaded.FloatTracks[0].Interpolation == .Step);
	}
}
