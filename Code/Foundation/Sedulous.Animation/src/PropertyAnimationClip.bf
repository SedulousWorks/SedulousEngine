namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Serialization;

/// An animation clip that animates arbitrary properties via string-identified tracks.
public class PropertyAnimationClip : ISerializable
{
	/// Name of this animation clip.
	public String Name ~ delete _;

	/// Duration of the animation in seconds.
	public float Duration;

	/// Whether this animation should loop.
	public bool IsLooping;

	/// Float tracks.
	public List<PropertyAnimationTrack<float>> FloatTracks = new .() ~ DeleteContainerAndItems!(_);

	/// Vector2 tracks.
	public List<PropertyAnimationTrack<Vector2>> Vector2Tracks = new .() ~ DeleteContainerAndItems!(_);

	/// Vector3 tracks.
	public List<PropertyAnimationTrack<Vector3>> Vector3Tracks = new .() ~ DeleteContainerAndItems!(_);

	/// Vector4 tracks.
	public List<PropertyAnimationTrack<Vector4>> Vector4Tracks = new .() ~ DeleteContainerAndItems!(_);

	/// Quaternion tracks.
	public List<PropertyAnimationTrack<Quaternion>> QuaternionTracks = new .() ~ DeleteContainerAndItems!(_);

	public int32 SerializationVersion => 1;

	public this()
	{
		Name = new .();
	}

	public this(StringView name, float duration = 0, bool isLooping = false)
	{
		Name = new .(name);
		Duration = duration;
		IsLooping = isLooping;
	}

	/// Adds a float track for the given property path.
	public PropertyAnimationTrack<float> AddFloatTrack(StringView propertyPath)
	{
		let track = new PropertyAnimationTrack<float>(propertyPath);
		FloatTracks.Add(track);
		return track;
	}

	/// Adds a Vector2 track for the given property path.
	public PropertyAnimationTrack<Vector2> AddVector2Track(StringView propertyPath)
	{
		let track = new PropertyAnimationTrack<Vector2>(propertyPath);
		Vector2Tracks.Add(track);
		return track;
	}

	/// Adds a Vector3 track for the given property path.
	public PropertyAnimationTrack<Vector3> AddVector3Track(StringView propertyPath)
	{
		let track = new PropertyAnimationTrack<Vector3>(propertyPath);
		Vector3Tracks.Add(track);
		return track;
	}

	/// Adds a Vector4 track for the given property path.
	public PropertyAnimationTrack<Vector4> AddVector4Track(StringView propertyPath)
	{
		let track = new PropertyAnimationTrack<Vector4>(propertyPath);
		Vector4Tracks.Add(track);
		return track;
	}

	/// Adds a Quaternion track for the given property path.
	public PropertyAnimationTrack<Quaternion> AddQuaternionTrack(StringView propertyPath)
	{
		let track = new PropertyAnimationTrack<Quaternion>(propertyPath);
		QuaternionTracks.Add(track);
		return track;
	}

	/// Sorts all keyframes in all tracks by time.
	public void SortAllKeyframes()
	{
		for (let track in FloatTracks) track.SortKeyframes();
		for (let track in Vector2Tracks) track.SortKeyframes();
		for (let track in Vector3Tracks) track.SortKeyframes();
		for (let track in Vector4Tracks) track.SortKeyframes();
		for (let track in QuaternionTracks) track.SortKeyframes();
	}

	/// Computes the duration from the latest keyframe across all tracks.
	public void ComputeDuration()
	{
		Duration = 0;
		for (let track in FloatTracks) Duration = Math.Max(Duration, track.GetDuration());
		for (let track in Vector2Tracks) Duration = Math.Max(Duration, track.GetDuration());
		for (let track in Vector3Tracks) Duration = Math.Max(Duration, track.GetDuration());
		for (let track in Vector4Tracks) Duration = Math.Max(Duration, track.GetDuration());
		for (let track in QuaternionTracks) Duration = Math.Max(Duration, track.GetDuration());
	}

	// ---- Serialization ----

	public SerializationResult Serialize(Serializer s)
	{
		if (s.IsWriting)
			return SerializeWrite(s);
		else
			return SerializeRead(s);
	}

	private SerializationResult SerializeWrite(Serializer s)
	{
		String name = scope String(Name);
		s.String("name", name);

		float duration = Duration;
		s.Float("duration", ref duration);

		bool isLooping = IsLooping;
		s.Bool("isLooping", ref isLooping);

		WriteFloatTracks(s);
		WriteVector2Tracks(s);
		WriteVector3Tracks(s);
		WriteVector4Tracks(s);
		WriteQuaternionTracks(s);

		return .Ok;
	}

	private void WriteTrackHeader(Serializer s, PropertyAnimationTrackBase track, int32 kfCount)
	{
		String path = scope String(track.PropertyPath);
		s.String("propertyPath", path);

		int32 interpInt = (int32)track.Interpolation;
		s.Int32("interpolation", ref interpInt);

		int32 easingInt = (int32)track.Easing;
		s.Int32("easing", ref easingInt);

		int32 count = kfCount;
		s.Int32("keyframeCount", ref count);
	}

	private void WriteFloatTracks(Serializer s)
	{
		int32 trackCount = (int32)FloatTracks.Count;
		s.Int32("floatTracksCount", ref trackCount);
		for (int32 i = 0; i < trackCount; i++)
		{
			let track = FloatTracks[i];
			s.BeginObject(scope $"floatTracks{i}");
			WriteTrackHeader(s, track, (int32)track.Keyframes.Count);
			if (track.Keyframes.Count > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				for (let kf in track.Keyframes)
				{
					times.Add(kf.Time);
					values.Add(kf.Value);
				}
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);
			}
			s.EndObject();
		}
	}

	private void WriteVector2Tracks(Serializer s)
	{
		int32 trackCount = (int32)Vector2Tracks.Count;
		s.Int32("vector2TracksCount", ref trackCount);
		for (int32 i = 0; i < trackCount; i++)
		{
			let track = Vector2Tracks[i];
			s.BeginObject(scope $"vector2Tracks{i}");
			WriteTrackHeader(s, track, (int32)track.Keyframes.Count);
			if (track.Keyframes.Count > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				for (let kf in track.Keyframes)
				{
					times.Add(kf.Time);
					values.Add(kf.Value.X);
					values.Add(kf.Value.Y);
				}
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);
			}
			s.EndObject();
		}
	}

	private void WriteVector3Tracks(Serializer s)
	{
		int32 trackCount = (int32)Vector3Tracks.Count;
		s.Int32("vector3TracksCount", ref trackCount);
		for (int32 i = 0; i < trackCount; i++)
		{
			let track = Vector3Tracks[i];
			s.BeginObject(scope $"vector3Tracks{i}");
			WriteTrackHeader(s, track, (int32)track.Keyframes.Count);
			if (track.Keyframes.Count > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				for (let kf in track.Keyframes)
				{
					times.Add(kf.Time);
					values.Add(kf.Value.X);
					values.Add(kf.Value.Y);
					values.Add(kf.Value.Z);
				}
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);
			}
			s.EndObject();
		}
	}

	private void WriteVector4Tracks(Serializer s)
	{
		int32 trackCount = (int32)Vector4Tracks.Count;
		s.Int32("vector4TracksCount", ref trackCount);
		for (int32 i = 0; i < trackCount; i++)
		{
			let track = Vector4Tracks[i];
			s.BeginObject(scope $"vector4Tracks{i}");
			WriteTrackHeader(s, track, (int32)track.Keyframes.Count);
			if (track.Keyframes.Count > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				for (let kf in track.Keyframes)
				{
					times.Add(kf.Time);
					values.Add(kf.Value.X);
					values.Add(kf.Value.Y);
					values.Add(kf.Value.Z);
					values.Add(kf.Value.W);
				}
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);
			}
			s.EndObject();
		}
	}

	private void WriteQuaternionTracks(Serializer s)
	{
		int32 trackCount = (int32)QuaternionTracks.Count;
		s.Int32("quaternionTracksCount", ref trackCount);
		for (int32 i = 0; i < trackCount; i++)
		{
			let track = QuaternionTracks[i];
			s.BeginObject(scope $"quaternionTracks{i}");
			WriteTrackHeader(s, track, (int32)track.Keyframes.Count);
			if (track.Keyframes.Count > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				for (let kf in track.Keyframes)
				{
					times.Add(kf.Time);
					values.Add(kf.Value.X);
					values.Add(kf.Value.Y);
					values.Add(kf.Value.Z);
					values.Add(kf.Value.W);
				}
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);
			}
			s.EndObject();
		}
	}

	private SerializationResult SerializeRead(Serializer s)
	{
		Name.Clear();
		s.String("name", Name);

		s.Float("duration", ref Duration);
		s.Bool("isLooping", ref IsLooping);

		// Float tracks
		DeserializeTracks(s, "floatTracks", FloatTracks, 1);
		// Vector2 tracks
		DeserializeTracks(s, "vector2Tracks", Vector2Tracks, 2);
		// Vector3 tracks
		DeserializeTracks(s, "vector3Tracks", Vector3Tracks, 3);
		// Vector4 tracks
		DeserializeTracks(s, "vector4Tracks", Vector4Tracks, 4);
		// Quaternion tracks
		DeserializeQuaternionTracks(s, "quaternionTracks");

		return .Ok;
	}

	private void DeserializeTracks(Serializer s, StringView sectionName, List<PropertyAnimationTrack<float>> tracks, int32 componentCount)
	{
		int32 trackCount = 0;
		s.Int32(scope $"{sectionName}Count", ref trackCount);

		for (int32 i = 0; i < trackCount; i++)
		{
			s.BeginObject(scope $"{sectionName}{i}");

			let path = scope String();
			s.String("propertyPath", path);

			int32 interpInt = 0;
			s.Int32("interpolation", ref interpInt);

			int32 easingInt = 0;
			s.Int32("easing", ref easingInt);

			let track = new PropertyAnimationTrack<float>(path);
			track.Interpolation = (InterpolationMode)interpInt;
			track.Easing = (EasingType)easingInt;

			int32 kfCount = 0;
			s.Int32("keyframeCount", ref kfCount);

			if (kfCount > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);

				for (int32 k = 0; k < kfCount; k++)
				{
					float time = k < times.Count ? times[k] : 0;
					float value = k < values.Count ? values[k] : 0;
					track.AddKeyframe(time, value);
				}
			}

			tracks.Add(track);
			s.EndObject();
		}
	}

	private void DeserializeTracks(Serializer s, StringView sectionName, List<PropertyAnimationTrack<Vector2>> tracks, int32 componentCount)
	{
		int32 trackCount = 0;
		s.Int32(scope $"{sectionName}Count", ref trackCount);

		for (int32 i = 0; i < trackCount; i++)
		{
			s.BeginObject(scope $"{sectionName}{i}");

			let path = scope String();
			s.String("propertyPath", path);

			int32 interpInt = 0;
			s.Int32("interpolation", ref interpInt);

			int32 easingInt = 0;
			s.Int32("easing", ref easingInt);

			let track = new PropertyAnimationTrack<Vector2>(path);
			track.Interpolation = (InterpolationMode)interpInt;
			track.Easing = (EasingType)easingInt;

			int32 kfCount = 0;
			s.Int32("keyframeCount", ref kfCount);

			if (kfCount > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);

				for (int32 k = 0; k < kfCount; k++)
				{
					float time = k < times.Count ? times[k] : 0;
					int32 baseIdx = k * 2;
					Vector2 value = .Zero;
					if (baseIdx + 1 < values.Count)
						value = .(values[baseIdx], values[baseIdx + 1]);
					track.AddKeyframe(time, value);
				}
			}

			tracks.Add(track);
			s.EndObject();
		}
	}

	private void DeserializeTracks(Serializer s, StringView sectionName, List<PropertyAnimationTrack<Vector3>> tracks, int32 componentCount)
	{
		int32 trackCount = 0;
		s.Int32(scope $"{sectionName}Count", ref trackCount);

		for (int32 i = 0; i < trackCount; i++)
		{
			s.BeginObject(scope $"{sectionName}{i}");

			let path = scope String();
			s.String("propertyPath", path);

			int32 interpInt = 0;
			s.Int32("interpolation", ref interpInt);

			int32 easingInt = 0;
			s.Int32("easing", ref easingInt);

			let track = new PropertyAnimationTrack<Vector3>(path);
			track.Interpolation = (InterpolationMode)interpInt;
			track.Easing = (EasingType)easingInt;

			int32 kfCount = 0;
			s.Int32("keyframeCount", ref kfCount);

			if (kfCount > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);

				for (int32 k = 0; k < kfCount; k++)
				{
					float time = k < times.Count ? times[k] : 0;
					int32 baseIdx = k * 3;
					Vector3 value = .Zero;
					if (baseIdx + 2 < values.Count)
						value = .(values[baseIdx], values[baseIdx + 1], values[baseIdx + 2]);
					track.AddKeyframe(time, value);
				}
			}

			tracks.Add(track);
			s.EndObject();
		}
	}

	private void DeserializeTracks(Serializer s, StringView sectionName, List<PropertyAnimationTrack<Vector4>> tracks, int32 componentCount)
	{
		int32 trackCount = 0;
		s.Int32(scope $"{sectionName}Count", ref trackCount);

		for (int32 i = 0; i < trackCount; i++)
		{
			s.BeginObject(scope $"{sectionName}{i}");

			let path = scope String();
			s.String("propertyPath", path);

			int32 interpInt = 0;
			s.Int32("interpolation", ref interpInt);

			int32 easingInt = 0;
			s.Int32("easing", ref easingInt);

			let track = new PropertyAnimationTrack<Vector4>(path);
			track.Interpolation = (InterpolationMode)interpInt;
			track.Easing = (EasingType)easingInt;

			int32 kfCount = 0;
			s.Int32("keyframeCount", ref kfCount);

			if (kfCount > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);

				for (int32 k = 0; k < kfCount; k++)
				{
					float time = k < times.Count ? times[k] : 0;
					int32 baseIdx = k * 4;
					Vector4 value = .Zero;
					if (baseIdx + 3 < values.Count)
						value = .(values[baseIdx], values[baseIdx + 1], values[baseIdx + 2], values[baseIdx + 3]);
					track.AddKeyframe(time, value);
				}
			}

			tracks.Add(track);
			s.EndObject();
		}
	}

	private void DeserializeQuaternionTracks(Serializer s, StringView sectionName)
	{
		int32 trackCount = 0;
		s.Int32(scope $"{sectionName}Count", ref trackCount);

		for (int32 i = 0; i < trackCount; i++)
		{
			s.BeginObject(scope $"{sectionName}{i}");

			let path = scope String();
			s.String("propertyPath", path);

			int32 interpInt = 0;
			s.Int32("interpolation", ref interpInt);

			int32 easingInt = 0;
			s.Int32("easing", ref easingInt);

			let track = new PropertyAnimationTrack<Quaternion>(path);
			track.Interpolation = (InterpolationMode)interpInt;
			track.Easing = (EasingType)easingInt;

			int32 kfCount = 0;
			s.Int32("keyframeCount", ref kfCount);

			if (kfCount > 0)
			{
				let times = scope List<float>();
				let values = scope List<float>();
				s.ArrayFloat("times", times);
				s.ArrayFloat("values", values);

				for (int32 k = 0; k < kfCount; k++)
				{
					float time = k < times.Count ? times[k] : 0;
					int32 baseIdx = k * 4;
					Quaternion value = .Identity;
					if (baseIdx + 3 < values.Count)
						value = Quaternion(values[baseIdx], values[baseIdx + 1], values[baseIdx + 2], values[baseIdx + 3]);
					track.AddKeyframe(time, value);
				}
			}

			QuaternionTracks.Add(track);
			s.EndObject();
		}
	}
}
