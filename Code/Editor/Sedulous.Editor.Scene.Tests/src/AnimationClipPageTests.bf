using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Scene.Tests;

/// The clip page's headless halves: the event table edits, the undo snapshot and the
/// preview rig preference.
class AnimationClipPageTests
{
	private static AnimationClipAsset Walk()
	{
		let clip = scope AnimationClip("Walk", 1.5f, true);
		let asset = new AnimationClipAsset();
		AnimationClipSource.FromClip(clip, asset.Source);
		return asset;
	}

	[Test]
	public static void EventsAddRemoveAndStayParallel()
	{
		let asset = Walk();
		defer delete asset;
		let source = asset.Source;
		Test.Assert(ClipSourceEdit.EventCount(source) == 0);

		ClipSourceEdit.AddEvent(source, 0.25f, "step");
		ClipSourceEdit.AddEvent(source, 1.0f, "step");
		Test.Assert(ClipSourceEdit.EventCount(source) == 2);
		Test.Assert((source.EventTime[1] == 1.0f) && (source.EventName[1] == "step"));

		// Out of range is refused; the first goes and the second slides down.
		Test.Assert(!ClipSourceEdit.RemoveEvent(source, 2));
		Test.Assert(!ClipSourceEdit.RemoveEvent(source, -1));
		Test.Assert(ClipSourceEdit.RemoveEvent(source, 0));
		Test.Assert((ClipSourceEdit.EventCount(source) == 1) && (source.EventTime[0] == 1.0f));

		// Uneven arrays, as an older source can have, are padded rather than tripped over.
		source.EventTime.Add(1.25f);
		source.EventTime.Add(1.4f);
		Test.Assert(ClipSourceEdit.EventCount(source) == 3);
		Test.Assert(source.EventName.Count == 3);
		Test.Assert(source.EventName[2].IsEmpty);
		source.EventName.Add(new String("late"));
		ClipSourceEdit.NormalizeEvents(source);
		Test.Assert((source.EventTime.Count == 4) && (source.EventTime[3] == 0.0f));
	}

	[Test]
	public static void SnapshotRestoresTheLoopFlagAndTheEventTable()
	{
		AnimationPipeline.RegisterAll();
		let asset = Walk();
		defer delete asset;
		let before = scope List<uint8>();
		ClipSourceEdit.Snapshot(asset, before);
		Test.Assert(before.Count > 0);
		// Applying what is already there is a no-op.
		Test.Assert(!ClipSourceEdit.Apply(asset, before));

		asset.Source.IsLooping = false;
		ClipSourceEdit.AddEvent(asset.Source, 0.5f, "plant");
		let after = scope List<uint8>();
		ClipSourceEdit.Snapshot(asset, after);

		Test.Assert(ClipSourceEdit.Apply(asset, before));
		Test.Assert(asset.Source.IsLooping);
		Test.Assert(asset.Source.EventTime.Count == 0);
		Test.Assert(asset.Source.EventName.Count == 0);
		Test.Assert(asset.Source.Duration == 1.5f);

		Test.Assert(ClipSourceEdit.Apply(asset, after));
		Test.Assert(!asset.Source.IsLooping);
		Test.Assert((asset.Source.EventTime.Count == 1) && (asset.Source.EventName[0] == "plant"));
	}

	[Test]
	public static void ThePreviewRigRoundTripsThroughTheSettingsStore()
	{
		SceneEditorSerializables.RegisterAll();
		let clipA = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let clipB = Guid(3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);
		let rig = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);
		let mesh = Guid(7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8);

		let store = scope Settings();
		Guid skeleton = .();
		Guid meshOut = .();
		Test.Assert(!ClipPreviewPrefs.Load(store, clipA, ref skeleton, ref meshOut));
		Test.Assert(ClipPreviewPrefs.Save(store, clipA, rig, mesh));
		Test.Assert(ClipPreviewPrefs.Save(store, clipB, rig, .()));
		Test.Assert(!ClipPreviewPrefs.Save(store, Guid(), rig, mesh));
		Test.Assert(!ClipPreviewPrefs.Save(null, clipA, rig, mesh));
		Test.Assert(ClipPreviewPrefs.Load(store, clipA, ref skeleton, ref meshOut));
		Test.Assert((skeleton == rig) && (meshOut == mesh));
		Test.Assert(ClipPreviewPrefs.Load(store, clipB, ref skeleton, ref meshOut));
		Test.Assert((skeleton == rig) && meshOut.IsNil);

		// A second save updates in place.
		Test.Assert(ClipPreviewPrefs.Save(store, clipA, .(), mesh));
		Test.Assert(store.Section<ClipPreviewSettings>().Prefs.Count == 2);

		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(ClipPreviewPrefs.Load(loaded, clipA, ref skeleton, ref meshOut));
		Test.Assert(skeleton.IsNil && (meshOut == mesh));
	}
}
