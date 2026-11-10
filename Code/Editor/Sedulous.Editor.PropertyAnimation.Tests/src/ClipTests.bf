using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.PropertyAnimation;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// The property animation panel's UI-free half: the
/// track seeds; the clip document over a scratch project (its own history, its unsaved mark following
/// the history to where it was saved, a gesture one step or nothing); the clip as the dopesheet's and
/// the curve view's source (its channels and paths, keys moved, deleted and inserted, each one step);
/// the preview (the entity posed, what it held put back, never a step of anyone's); the transport's
/// clock.
class ClipTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Math.Abs(a - b) <= epsilon;

	private static CurveKey Key(float time, float value)
	{
		var key = CurveKey(time, value, .Linear);
		key.TangentMode = .Broken;
		return key;
	}

	/// A Float3 track on `component`'s Position, one key a channel at 0 (OWNED by the caller).
	private static PropertyTrack Float3Track(StringView component, float x, float y, float z)
	{
		let track = new PropertyTrack();
		track.ComponentType.Set(component);
		track.PropertyPath.Set("Position");
		track.Kind = .Float3;
		track.Channels[0].AddKey(Key(0.0f, x));
		track.Channels[1].AddKey(Key(0.0f, y));
		track.Channels[2].AddKey(Key(0.0f, z));
		return track;
	}

	/// A scratch project holding one clip, "Bounce", read into a document.
	private class Bed
	{
		public String Dir = new .("scratch_clip_document_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public ClipDocument Document;
		public Guid Clip;
		public int Changes = 0;

		public this()
		{
			PropertyAnimationPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = PropertyAnimationCreators.CreateClip(Project.SourceDb.RootGroup, "Bounce");
			Test.Assert(instance != null);
			Clip = instance.Id;
			Document = new ClipDocument(Context);
			Document.OnChanged = new [=this] () => { Changes++; };
			Test.Assert(Document.Load(Clip));
		}

		public ~this()
		{
			delete Document;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// `track` (taken) added as one step.
		public void AddTrack(PropertyTrack track)
		{
			Document.Edit("test", scope [&] (clip) => { clip.Tracks.Add(track); });
		}
	}

	[Test]
	public static void TheSeedsTheFourAnimatableKindsNestedLeavesByTheirPathsNothingElse()
	{
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(float)) == .Float);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(Float3)) == .Float3);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(Color)) == .Color);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(Quaternion)) == .Quat);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(int32)) == null);

		let collected = scope List<AnimatablePropertyInfo>();
		defer { ClearAndDeleteItems!(collected); }
		AnimatableProperties.Collect(typeof(TestComp), collected);
		Test.Assert(collected.Count == 4, "Position, Rotation, Intensity, Light.Tint: not Flags");
		bool tint = false;
		for (let seed in collected)
			tint = tint || ((seed.PropertyPath == "Light.Tint") && (seed.Kind == .Color));
		Test.Assert(tint);

		// An entity's: its transform's three first, then its components'.
		let scene = scope Scene("seeds");
		let manager = scene.AddSystem<ComponentManager<PreviewComp>>();
		let e = scene.CreateEntity("e");
		manager.Add(e);
		let preview = scope ClipPreview(scene);
		let seeds = scope List<AnimatablePropertyInfo>();
		defer { ClearAndDeleteItems!(seeds); }
		preview.TrackSeeds(scene.GetEntityId(e), seeds);
		Test.Assert(seeds.Count == 4);
		Test.Assert(seeds[0].ComponentType == "Transform");
		Test.Assert(seeds[1].Kind == .Quat);
		Test.Assert(seeds[3].ComponentType == "PreviewComp");
		let none = scope List<AnimatablePropertyInfo>();
		preview.TrackSeeds(.Empty, none);
		Test.Assert(none.IsEmpty);
	}

	[Test]
	public static void TheDocumentItsOwnHistoryUnsavedUntilBackWhereItWasSavedAGestureOneStepOrNothing()
	{
		let bed = scope Bed();
		Test.Assert(bed.Document.HasClip);
		Test.Assert(bed.Document.Name == "Bounce");
		Test.Assert(!bed.Document.IsDirty);

		bed.AddTrack(Float3Track("PreviewComp", 1.0f, 2.0f, 3.0f));
		Test.Assert(bed.Document.Clip.Tracks.Count == 1);
		Test.Assert(bed.Document.IsDirty);
		bed.Document.Commands.Undo();
		Test.Assert(bed.Document.Clip.Tracks.IsEmpty);
		Test.Assert(!bed.Document.IsDirty, "back where it was loaded");
		bed.Document.Commands.Redo();
		Test.Assert(bed.Document.IsDirty);

		// Saved, then read back: the track kept.
		Test.Assert(bed.Document.Save() case .Ok);
		Test.Assert(!bed.Document.IsDirty);
		let again = scope ClipDocument(bed.Context);
		Test.Assert(again.Load(bed.Clip));
		Test.Assert(again.Clip.Tracks.Count == 1);
		Test.Assert(Near(again.Clip.Tracks[0].Channels[1].Evaluate(0.0f), 2.0f));

		// Below the save, a new step: the save is off the history, unsaved even back there.
		bed.Document.Commands.Undo();
		Test.Assert(bed.Document.IsDirty);
		bed.AddTrack(Float3Track("PreviewComp", 0.0f, 0.0f, 0.0f));
		bed.Document.Commands.Undo();
		Test.Assert(bed.Document.IsDirty);

		// A gesture: live, then one step; cancelled, nothing.
		bed.Document.Commands.Redo();
		let steps = bed.Document.Commands.Count;
		bed.Document.BeginGesture();
		bed.Document.GestureClip.Tracks[0].Channels[0].Keys[0].Value = 9.0f;
		bed.Document.PreviewGesture();
		Test.Assert(Near(bed.Document.Clip.Tracks[0].Channels[0].Evaluate(0.0f), 9.0f));
		bed.Document.CommitGesture("test");
		Test.Assert(bed.Document.Commands.Count == steps + 1);
		bed.Document.BeginGesture();
		bed.Document.GestureClip.Tracks[0].Channels[0].Keys[0].Value = 4.0f;
		bed.Document.CancelGesture();
		Test.Assert(Near(bed.Document.Clip.Tracks[0].Channels[0].Evaluate(0.0f), 9.0f));
		Test.Assert(bed.Document.Commands.Count == steps + 1);

		// Its length covers its keys.
		bed.Document.Edit("test", scope (clip) => { clip.Tracks[0].Channels[0].AddKey(Key(3.0f, 1.0f)); });
		Test.Assert(Near(bed.Document.Length, 3.0f));
		Test.Assert(bed.Changes > 0);

		bed.Document.Close();
		Test.Assert(!bed.Document.HasClip);
		Test.Assert(!bed.Document.IsDirty);
	}

	[Test]
	public static void TheSourceAChannelPerCurveAndPerRotationKeysMovedDeletedAndInsertedEachOneStep()
	{
		let bed = scope Bed();
		let source = scope ClipSource(bed.Document);
		delete bed.Document.OnChanged;
		bed.Document.OnChanged = new [=source] () => { source.Refresh(); };
		bed.AddTrack(Float3Track("Transform", 1.0f, 2.0f, 3.0f));
		let spin = new PropertyTrack();
		spin.ComponentType.Set("Transform");
		spin.PropertyPath.Set("Rotation");
		spin.Kind = .Quat;
		spin.QuatKeys.Add(QuatKey(0.0f, .Identity));
		spin.QuatKeys.Add(QuatKey(1.0f, .Identity));
		bed.AddTrack(spin);

		Test.Assert(source.ChannelCount == 4);
		Test.Assert(source.GetChannelPath(0, .. scope .()) == "Transform.Position.x");
		Test.Assert(source.GetChannelPath(2, .. scope .()) == "Transform.Position.z");
		Test.Assert(source.GetChannelPath(3, .. scope .()) == "Transform.Rotation");
		let times = scope List<float>();
		source.GetKeyTimes(3, times);
		Test.Assert((times.Count == 2) && Near(times[1], 1.0f));

		// A move previewed from where the keys were, then one step; the key's new place told.
		bed.AddTrack(Float3Track("PreviewComp", 0.0f, 0.0f, 0.0f)); // channels 4..6
		bed.Document.Edit("test", scope (clip) => { clip.Tracks[2].Channels[0].AddKey(Key(1.0f, 5.0f)); });
		let steps = bed.Document.Commands.Count;
		source.BeginKeysMove();
		TimelineKeyRef[1] first = .(.(4, 0));
		let moved = scope List<TimelineKeyRef>();
		source.PreviewKeysMove(first, 2.0f, moved);
		Test.Assert((moved.Count == 1) && (moved[0].Index == 1), "past the key at 1 s");
		source.PreviewKeysMove(first, 0.5f, moved);
		Test.Assert(moved[0].Index == 0, "each preview from the start");
		source.CommitKeysMove();
		Test.Assert(bed.Document.Commands.Count == steps + 1);
		source.GetKeyTimes(4, times);
		Test.Assert(Near(times[0], 0.5f));
		bed.Document.Commands.Undo();
		source.GetKeyTimes(4, times);
		Test.Assert(Near(times[0], 0.0f));

		// Deleted: one step; none there, nothing.
		TimelineKeyRef[1] rotationFirst = .(.(3, 0));
		Test.Assert(source.DeleteKeys(rotationFirst));
		Test.Assert(bed.Document.Clip.Tracks[1].QuatKeys.Count == 1);
		TimelineKeyRef[1] nowhere = .(.(3, 9));
		Test.Assert(!source.DeleteKeys(nowhere));

		// Inserted: the clip's value there; on an empty channel, the application's.
		Test.Assert(source.InsertKey(4, 0.5f, var made));
		Test.Assert(made.Index == 1);
		Test.Assert(Near(bed.Document.Clip.Tracks[2].Channels[0].Keys[1].Value, 2.5f), "halfway 0 -> 5");
		source.CurrentValue = new (track) => Sedulous.PropertyAnimation.PropertyValue.FromFloat3(.(7.0f, 8.0f, 9.0f));
		bed.Document.Edit("test", scope (clip) => { clip.Tracks[2].Channels[1].Clear(); });
		Test.Assert(source.InsertKey(5, 1.0f, out made));
		Test.Assert(Near(bed.Document.Clip.Tracks[2].Channels[1].Keys[0].Value, 8.0f));

		// The curve view: the shown tracks' scalar curves, never a rotation's.
		int[2] shown = .(0, 1);
		source.ShowTracks(shown);
		Test.Assert(source.CurveCount == 3);
		let info = scope CurveInfo();
		source.GetCurveInfo(1, info);
		Test.Assert(info.Name == "Transform.Position.y");
		source.BeginKeysEdit();
		CurveKey[1] dragged = .(Key(0.0f, 4.0f));
		source.PreviewKeys(1, dragged);
		source.CommitKeysEdit();
		Test.Assert(Near(bed.Document.Clip.Tracks[0].Channels[1].Evaluate(0.0f), 4.0f));
		bed.Document.Commands.Undo();
		Test.Assert(Near(bed.Document.Clip.Tracks[0].Channels[1].Evaluate(0.0f), 2.0f));
		// The document outlives the source's hook: let go of it before the source goes.
		DeleteAndNullify!(bed.Document.OnChanged);
	}

	[Test]
	public static void ThePreviewTheEntityPosedWhatItHeldPutBackKeptAgainWhenTheTracksChange()
	{
		let scene = scope Scene("preview");
		let manager = scene.AddSystem<ComponentManager<PreviewComp>>();
		let e = scene.CreateEntity("e");
		manager.Add(e).Position = .(5.0f, 6.0f, 7.0f);
		scene.SetLocalPosition(e, .(1.0f, 1.0f, 1.0f));
		let id = scene.GetEntityId(e);

		let clip = scope PropertyAnimationClip();
		clip.Tracks.Add(Float3Track("PreviewComp", 100.0f, 200.0f, 300.0f));
		let preview = scope ClipPreview(scene);
		preview.Pose(id, clip, 0.5f);
		Test.Assert(preview.IsPosing);
		Test.Assert(Near(manager.Get(e).Position.Y, 200.0f));
		Test.Assert(Near(preview.Read(id, "PreviewComp", "Position").Vector.Z, 300.0f));

		// A transform track added: the preview keeps the transform as it was too.
		clip.Tracks.Add(Float3Track("Transform", 9.0f, 9.0f, 9.0f));
		preview.Pose(id, clip, 0.5f);
		Test.Assert(Near(scene.GetLocalTransform(e).Position.X, 9.0f));
		preview.Stop();
		Test.Assert(!preview.IsPosing);
		Test.Assert(Near(manager.Get(e).Position.X, 5.0f));
		Test.Assert(Near(scene.GetLocalTransform(e).Position.X, 1.0f));

		// No such entity: nothing posed.
		preview.Pose(.Empty, clip, 0.0f);
		Test.Assert(!preview.IsPosing);
	}

	[Test]
	public static void TheTransportPlaysFromWhereItStandsWrapsWhenLoopingElseStopsAtTheEnd()
	{
		let transport = scope ClipTransport();
		Test.Assert(!transport.Advance(0.1f, 2.0f), "stopped");
		transport.Play(2.0f);
		Test.Assert(transport.IsPlaying);
		Test.Assert(transport.Advance(1.5f, 2.0f));
		Test.Assert(transport.Advance(1.0f, 2.0f));
		Test.Assert(Near(transport.Time, 0.5f), "wrapped");
		transport.Pause();
		Test.Assert(transport.IsPaused);
		Test.Assert(!transport.Advance(1.0f, 2.0f));
		transport.SetLooping(false);
		transport.Play(2.0f);
		Test.Assert(transport.Advance(3.0f, 2.0f));
		Test.Assert(Near(transport.Time, 2.0f));
		Test.Assert(!transport.IsPlaying);
		transport.Play(2.0f); // at the end: from the start
		Test.Assert(Near(transport.Time, 0.0f));
		transport.Stop();
		Test.Assert(!transport.IsPlaying);
	}
}
