using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// The grid half: the stats, the loop flag and the event table.
extension AnimationClipEditorPage
{
	private void RebuildGrid()
	{
		mGrid.Clear();
		if (mAsset == null)
			return;
		let source = mAsset.Source;

		mGrid.AddProperty(new StringEditor("Name", source.Name, null, "Clip"));
		mGrid.AddProperty(new StringEditor("Duration", scope $"{source.Duration} s", null, "Clip"));
		mGrid.AddProperty(new StringEditor("Tracks", scope $"{source.TrackBone.Count}", null, "Clip"));
		mGrid.AddProperty(new BoolEditor("Looping", source.IsLooping, new [=this](v) =>
			{
				mAsset.Source.IsLooping = v;
				CommitEdit("clip-loop");
			}, "Clip"));

		let eventCount = ClipSourceEdit.EventCount(source);
		for (int e < eventCount)
		{
			let cat = scope $"Event {e}";
			let index = e;
			mGrid.AddProperty(new FloatEditor("Time (s)", source.EventTime[e], 0.0, Math.Max(source.Duration, 0.0f), 0.01, 3, new [=this, =index](v) =>
				{
					let s = mAsset.Source;
					if (index < s.EventTime.Count)
					{
						s.EventTime[index] = (float)v;
						CommitEdit("event-time");
					}
				}, cat));
			mGrid.AddProperty(new StringEditor("Name", source.EventName[e], new [=this, =index](v) =>
				{
					let s = mAsset.Source;
					if (index < s.EventName.Count)
					{
						s.EventName[index].Set(v);
						CommitEdit("event-name");
					}
				}, cat));
			mGrid.AddProperty(new ButtonEditor("Remove Event", new [=this, =index]() =>
				{
					QueueStructural("del-event", new [=this, =index]() => { ClipSourceEdit.RemoveEvent(mAsset.Source, index); });
				}, cat));
		}
		mGrid.AddProperty(new ButtonEditor("+ Add Event", new [=this]() =>
			{
				// At the playhead.
				QueueStructural("add-event", new [=this]() => { ClipSourceEdit.AddEvent(mAsset.Source, mTime, "event"); });
			}, "Events"));
	}
}
