using System;
using Sedulous.Core;

namespace Sedulous.PropertyAnimation;

/// Deep copies, so the editor can snapshot a whole clip per undo step: the clip is small data.
extension PropertyAnimationClip
{
	public void CopyTo(PropertyAnimationClip other)
	{
		other.Duration = Duration;
		ClearAndDeleteItems(other.Tracks);
		for (let track in Tracks)
		{
			let copy = new PropertyTrack();
			track.CopyTo(copy);
			other.Tracks.Add(copy);
		}
	}

	public PropertyAnimationClip Clone()
	{
		let copy = new PropertyAnimationClip();
		CopyTo(copy);
		return copy;
	}
}

extension PropertyTrack
{
	public void CopyTo(PropertyTrack other)
	{
		other.ComponentType.Set(ComponentType);
		other.PropertyPath.Set(PropertyPath);
		other.Kind = Kind;
		for (int c < cMaxChannels)
		{
			other.Channels[c].Clear();
			for (let key in Channels[c].Keys)
				other.Channels[c].AddKey(key);
		}
		other.QuatKeys.Clear();
		other.QuatKeys.AddRange(QuatKeys);
	}
}
