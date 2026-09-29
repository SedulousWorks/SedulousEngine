using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The grid half: the stats, the loop flag and the event list.
extension AnimationClipEditorPage
{
	/// Event `index`'s section.
	public static void EventSection(int index, String outCategory)
	{
		outCategory.Clear();
		outCategory.AppendF("Event {}", index + 1);
	}

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

		// The events are a section list: the header's add icon places one at the playhead, and
		// each event is a section of its own with its remove icon.
		let eventCount = ClipSourceEdit.EventCount(source);
		let events = new ContainerListEditor("Events", "Events");
		events.ElementsAsSections = true;
		for (int e < eventCount)
			events.SlotNames.Add(new String(source.EventName[e]));
		events.OnAdd = new [=this]() =>
		{
			QueueStructural("add-event", new [=this]() => { ClipSourceEdit.AddEvent(mAsset.Source, mTime, "event"); });
		};
		mGrid.AddProperty(events);
		for (int e < eventCount)
		{
			let cat = EventSection(e, .. scope .());
			mGrid.SetCategoryParent(cat, "Events");
			let index = e;
			mGrid.SetCategoryHeaderActions(cat, ContainerListEditor.ElementActions(index, eventCount, null,
				new [=this](i) =>
				{
					QueueStructural("del-event", new [=this, =i]() => { ClipSourceEdit.RemoveEvent(mAsset.Source, i); });
				}));
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
		}
	}
}
