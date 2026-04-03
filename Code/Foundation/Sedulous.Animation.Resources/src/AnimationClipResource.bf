using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Core.Mathematics;
using Sedulous.Animation;

namespace Sedulous.Animation.Resources;

/// CPU-side animation clip resource for skeletal animation.
/// Can be shared between multiple AnimationPlayers.
class AnimationClipResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("animationclip");

	private AnimationClip mClip;
	private bool mOwnsClip;

	/// The underlying animation clip data.
	public AnimationClip Clip => mClip;

	/// Duration of the animation in seconds.
	public float Duration => mClip?.Duration ?? 0;

	/// Number of position tracks.
	public int PositionTrackCount => mClip?.PositionTracks?.Count ?? 0;

	/// Number of rotation tracks.
	public int RotationTrackCount => mClip?.RotationTracks?.Count ?? 0;

	/// Number of scale tracks.
	public int ScaleTrackCount => mClip?.ScaleTracks?.Count ?? 0;

	public this()
	{
		mClip = null;
		mOwnsClip = false;
	}

	public this(AnimationClip clip, bool ownsClip = false)
	{
		mClip = clip;
		mOwnsClip = ownsClip;
		if (clip != null && Name.IsEmpty)
			Name.Set(clip.Name);
	}

	public ~this()
	{
		if (mOwnsClip && mClip != null)
			delete mClip;
	}

	/// Sets the animation clip. Takes ownership if ownsClip is true.
	public void SetClip(AnimationClip clip, bool ownsClip = false)
	{
		if (mOwnsClip && mClip != null)
			delete mClip;
		mClip = clip;
		mOwnsClip = ownsClip;
	}

	// ---- Serialization ----

	public override int32 SerializationVersion => FileVersion;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
		{
			if (mClip == null)
				return .InvalidData;

			// Write clip name
			String clipName = scope String(mClip.Name);
			s.String("clipName", clipName);

			// Write duration
			float duration = mClip.Duration;
			s.Float("duration", ref duration);

			// Write looping flag
			bool isLooping = mClip.IsLooping;
			s.Bool("isLooping", ref isLooping);

			// Serialize position tracks
			int32 posTrackCount = (int32)mClip.PositionTracks.Count;
			s.Int32("positionTrackCount", ref posTrackCount);
			for (int32 t = 0; t < posTrackCount; t++)
			{
				let track = mClip.PositionTracks[t];
				s.BeginObject(scope $"posTrack{t}");

				int32 boneIndex = track.BoneIndex;
				s.Int32("boneIndex", ref boneIndex);

				int32 interpInt = (int32)track.Interpolation;
				s.Int32("interpolation", ref interpInt);

				int32 keyframeCount = (int32)track.Keyframes.Count;
				s.Int32("keyframeCount", ref keyframeCount);

				if (keyframeCount > 0)
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

			// Serialize rotation tracks
			int32 rotTrackCount = (int32)mClip.RotationTracks.Count;
			s.Int32("rotationTrackCount", ref rotTrackCount);
			for (int32 t = 0; t < rotTrackCount; t++)
			{
				let track = mClip.RotationTracks[t];
				s.BeginObject(scope $"rotTrack{t}");

				int32 boneIndex = track.BoneIndex;
				s.Int32("boneIndex", ref boneIndex);

				int32 interpInt = (int32)track.Interpolation;
				s.Int32("interpolation", ref interpInt);

				int32 keyframeCount = (int32)track.Keyframes.Count;
				s.Int32("keyframeCount", ref keyframeCount);

				if (keyframeCount > 0)
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

			// Serialize scale tracks
			int32 scaleTrackCount = (int32)mClip.ScaleTracks.Count;
			s.Int32("scaleTrackCount", ref scaleTrackCount);
			for (int32 t = 0; t < scaleTrackCount; t++)
			{
				let track = mClip.ScaleTracks[t];
				s.BeginObject(scope $"scaleTrack{t}");

				int32 boneIndex = track.BoneIndex;
				s.Int32("boneIndex", ref boneIndex);

				int32 interpInt = (int32)track.Interpolation;
				s.Int32("interpolation", ref interpInt);

				int32 keyframeCount = (int32)track.Keyframes.Count;
				s.Int32("keyframeCount", ref keyframeCount);

				if (keyframeCount > 0)
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
		else
		{
			// Read clip name
			String clipName = scope String();
			s.String("clipName", clipName);

			// Read duration
			float duration = 0;
			s.Float("duration", ref duration);

			// Read looping flag
			bool isLooping = false;
			s.Bool("isLooping", ref isLooping);

			// Create new clip
			let clip = new AnimationClip(clipName, duration, isLooping);

			// Deserialize position tracks
			int32 posTrackCount = 0;
			s.Int32("positionTrackCount", ref posTrackCount);
			for (int32 t = 0; t < posTrackCount; t++)
			{
				s.BeginObject(scope $"posTrack{t}");

				int32 boneIndex = 0;
				s.Int32("boneIndex", ref boneIndex);

				int32 interpInt = 0;
				s.Int32("interpolation", ref interpInt);

				let track = clip.GetOrCreatePositionTrack(boneIndex);
				track.Interpolation = (InterpolationMode)interpInt;

				int32 keyframeCount = 0;
				s.Int32("keyframeCount", ref keyframeCount);

				if (keyframeCount > 0)
				{
					let times = scope List<float>();
					let values = scope List<float>();
					s.ArrayFloat("times", times);
					s.ArrayFloat("values", values);

					for (int32 k = 0; k < keyframeCount; k++)
					{
						float time = k < times.Count ? times[k] : 0;
						int32 baseIdx = k * 3;
						Vector3 value = .Zero;
						if (baseIdx + 2 < values.Count)
							value = .(values[baseIdx], values[baseIdx + 1], values[baseIdx + 2]);
						track.AddKeyframe(time, value);
					}
				}

				s.EndObject();
			}

			// Deserialize rotation tracks
			int32 rotTrackCount = 0;
			s.Int32("rotationTrackCount", ref rotTrackCount);
			for (int32 t = 0; t < rotTrackCount; t++)
			{
				s.BeginObject(scope $"rotTrack{t}");

				int32 boneIndex = 0;
				s.Int32("boneIndex", ref boneIndex);

				int32 interpInt = 0;
				s.Int32("interpolation", ref interpInt);

				let track = clip.GetOrCreateRotationTrack(boneIndex);
				track.Interpolation = (InterpolationMode)interpInt;

				int32 keyframeCount = 0;
				s.Int32("keyframeCount", ref keyframeCount);

				if (keyframeCount > 0)
				{
					let times = scope List<float>();
					let values = scope List<float>();
					s.ArrayFloat("times", times);
					s.ArrayFloat("values", values);

					for (int32 k = 0; k < keyframeCount; k++)
					{
						float time = k < times.Count ? times[k] : 0;
						int32 baseIdx = k * 4;
						Quaternion value = .Identity;
						if (baseIdx + 3 < values.Count)
							value = Quaternion(values[baseIdx], values[baseIdx + 1], values[baseIdx + 2], values[baseIdx + 3]);
						track.AddKeyframe(time, value);
					}
				}

				s.EndObject();
			}

			// Deserialize scale tracks
			int32 scaleTrackCount = 0;
			s.Int32("scaleTrackCount", ref scaleTrackCount);
			for (int32 t = 0; t < scaleTrackCount; t++)
			{
				s.BeginObject(scope $"scaleTrack{t}");

				int32 boneIndex = 0;
				s.Int32("boneIndex", ref boneIndex);

				int32 interpInt = 0;
				s.Int32("interpolation", ref interpInt);

				let track = clip.GetOrCreateScaleTrack(boneIndex);
				track.Interpolation = (InterpolationMode)interpInt;

				int32 keyframeCount = 0;
				s.Int32("keyframeCount", ref keyframeCount);

				if (keyframeCount > 0)
				{
					let times = scope List<float>();
					let values = scope List<float>();
					s.ArrayFloat("times", times);
					s.ArrayFloat("values", values);

					for (int32 k = 0; k < keyframeCount; k++)
					{
						float time = k < times.Count ? times[k] : 0;
						int32 baseIdx = k * 3;
						Vector3 value = .(1, 1, 1);
						if (baseIdx + 2 < values.Count)
							value = .(values[baseIdx], values[baseIdx + 1], values[baseIdx + 2]);
						track.AddKeyframe(time, value);
					}
				}

				s.EndObject();
			}

			// Set the clip
			SetClip(clip, true);
		}

		return .Ok;
	}

}
