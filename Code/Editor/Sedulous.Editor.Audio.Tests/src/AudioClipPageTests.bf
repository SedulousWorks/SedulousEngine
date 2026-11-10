using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio.Tests;

/// The audio clip page over its markup (Data/Editor/AudioClipPage.xml) and a scratch project, with
/// no host (no audio engine: nothing plays): the source read into its waveform and facts, the
/// transport bound to the playback actions, an option an undo step the audition follows, and a
/// missing source said in the waveform's place.
class AudioClipPageTests
{
	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A project with half a second of stereo at 8 kHz ("tone.wav") under a clip ("Tone"), and a
	/// clip over a file that is not there ("Gone").
	class Bed
	{
		public String Dir = new .("scratch_audio_clip_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Tone;
		public Instance Gone;

		public this()
		{
			AudioPipeline.RegisterAll(); // read back by its type, as the editor registers it
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let samples = scope List<int16>();
			samples.Resize(8000); // 4000 frames of two channels
			for (int i < samples.Count)
				samples[i] = (((i / 8) % 2) == 0) ? (int16)20000 : (int16)-20000;
			let wav = scope List<uint8>();
			Test.Assert(AudioCodec.EncodeWav(samples, 2, 8000, wav));
			Test.Assert(WriteFile(PathJoin(Project.SourcesRoot(.. scope .()), "tone.wav", .. scope .()), wav) case .Ok);
			let type = typeof(AudioClipAsset).GetFullName(.. scope .());
			Tone = Project.SourceDb.RootGroup.CreateInstance("Tone", type);
			Gone = Project.SourceDb.RootGroup.CreateInstance("Gone", type);
			Test.Assert((Tone != null) && (Gone != null));
			let asset = scope AudioClipAsset();
			asset.FileName.Set("tone.wav");
			Test.Assert(Tone.WriteObject(asset) case .Ok);
			asset.FileName.Set("gone.wav");
			Test.Assert(Gone.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it.
		public AudioClipEditorPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new AudioClipEditorPage(Context, services, instance);
		}
	}

	[Test]
	public static void RegisteredForTheClip()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		AudioEditor.Register(context, none);
		let found = context.Pages.FindFactory(typeof(AudioClipAsset));
		Test.Assert(found != null);
		Test.Assert(found.PrimaryType == typeof(AudioClipAsset));
	}

	[Test]
	public static void TheSourceReadIntoItsWaveformAndFactsTheTransportThePlaybackActions()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Tone);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Clip != null);
		Test.Assert(page.Clip.Channels == 2);
		Test.Assert(page.Clip.SampleRate == 8000);
		Test.Assert(page.Clip.FrameCount == 4000);
		Test.Assert(page.Waveform != null);
		Test.Assert(page.Waveform.Peaks.Length == AudioClipEditorPage.cPeakBuckets);
		Test.Assert(page.Waveform.Peaks[0] > 0.5f, "a loud tone throughout");
		Test.Assert(page.Fact("Channels", .. scope .()) == "Stereo");
		Test.Assert(page.Fact("Sample Rate", .. scope .()) == "8000 Hz");
		Test.Assert(page.Fact("Length", .. scope .()) == "0.50 s (4000 frames)");
		Test.Assert(page.State == "Stopped");
		Test.Assert(!page.CanPlay, "no audio engine here");
		Test.Assert(!page.IsPlaying);
		IPlaybackPage playback = page;
		Test.Assert(playback != null, "what the playback actions run over");
		let play = page.Content.FindElement("audio-play") as ButtonBase;
		Test.Assert((play != null) && (play.CheckedIcon == "Editor/Icons/pause.svg"), "Play shows Pause while it plays");

		page.SetAuditionVolume(2.0f);
		Test.Assert(Math.Abs(page.AuditionVolume - 1.0f) < 1e-5f, "0 to 1");
		page.SetAuditionVolume(0.25f);
		Test.Assert(Math.Abs(page.AuditionVolume - 0.25f) < 1e-5f);
	}

	[Test]
	public static void AnOptionIsOneUndoStepAndTheAuditionFollowsIt()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Tone);
		defer delete page;
		Test.Assert(page.Clip != null);
		Test.Assert(!page.Clip.Loop);
		page.Edit("Loop", PropertyWrite(Sedulous.GUI.Variant(true)));
		Test.Assert(page.IsDirty);
		Test.Assert(page.Clip.Loop, "the next play loops");
		page.Commands.Undo();
		Test.Assert(!page.Clip.Loop);
	}

	[Test]
	public static void AMissingSourceSaidInTheWaveformsPlace()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Gone);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Clip == null);
		Test.Assert(!page.CanPlay);
		let empty = page.Content.FindElement("audio-empty");
		let stage = page.Content.FindElement("audio-stage");
		Test.Assert((empty != null) && (stage != null));
		Test.Assert(empty.Displayed);
		Test.Assert(!stage.Displayed);
		let why = page.Content.FindElement("audio-empty-text") as Sedulous.GUI.Label;
		Test.Assert(why != null);
		Test.Assert(why.Text == "gone.wav is missing or did not decode.");
	}
}
