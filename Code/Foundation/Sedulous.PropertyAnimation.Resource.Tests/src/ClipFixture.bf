using System;
using Sedulous.Core;
using Sedulous.PropertyAnimation;

namespace Sedulous.PropertyAnimation.Resource.Tests;

/// A representative clip: a vector track, a colour track and a rotation one, which between
/// them exercise every kind and the channel cursor's walk back.
static class ClipFixture
{
	public static PropertyAnimationClip Make()
	{
		let clip = new PropertyAnimationClip();

		let position = new PropertyTrack();
		position.ComponentType.Set("Transform");
		position.PropertyPath.Set("Position");
		position.Kind = .Float3;
		position.Channels[0].AddKey(.(0.0f, 0.0f, .Cubic, 1.0f, 2.0f));
		position.Channels[0].AddKey(.(2.0f, 20.0f));
		position.Channels[1].AddKey(.(0.0f, 5.0f));
		position.Channels[2].AddKey(.(0.0f, -1.0f, .Constant));
		position.Channels[2].AddKey(.(2.0f, 1.0f));
		clip.Tracks.Add(position);

		let color = new PropertyTrack();
		color.ComponentType.Set("Light");
		color.PropertyPath.Set("Light.Tint");
		color.Kind = .Color;
		for (int32 c < 4)
		{
			color.Channels[c].AddKey(.(0.0f, 0.0f));
			color.Channels[c].AddKey(.(1.0f, 0.25f * (float)(c + 1)));
		}
		clip.Tracks.Add(color);

		let rotation = new PropertyTrack();
		rotation.ComponentType.Set("Transform");
		rotation.PropertyPath.Set("Rotation");
		rotation.Kind = .Quat;
		rotation.QuatKeys.Add(.(0.0f, Quaternion.Identity));
		rotation.QuatKeys.Add(.(1.0f, Quaternion.FromAxisAngle(.(0, 1, 0), 1.0f)));
		clip.Tracks.Add(rotation);

		clip.Duration = clip.ComputeDuration();
		return clip;
	}
}
