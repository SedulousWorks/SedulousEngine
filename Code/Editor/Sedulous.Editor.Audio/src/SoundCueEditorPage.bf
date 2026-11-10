using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Engine.Audio;
using Sedulous.Runtime.Client;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// A sound cue on the GUI from its markup (Data/Editor/SoundCuePage.xml). The cue on the grid: how
/// it picks (at random never the same twice running, at
/// random, or in order), its pitch and volume ranges, then its variants, a list as every page's (the
/// count with Add, each element under it, removed and moved from its menu; eight at most), each a
/// clip (an asset slot) and its weight. A variant added has no clip until one is picked, then joins
/// the cue; a clip cleared takes it out. On the asset the variants are kept in order from the first
/// slot (a gap closes: the resolver skips empty slots, so the cue plays the same). Each change to
/// the cue is one undo step, where the old page kept its own blob commands. The kit's transport auditions it as the
/// game plays it: the runtime's resolver picks the variant (its weights, its no repeat, its order)
/// and the pitch and volume within the ranges, played through the runtime's audio engine; what it
/// picked is said beside the transport. A cue with no clip says so.
class SoundCueEditorPage : AssetObjectPage, IPlaybackPage
{
	public const String cMarkupPath = "Editor/SoundCuePage.xml";

	private struct RangeRow
	{
		public StringView Path;
		public StringView Shown;

		public this(StringView path, StringView shown)
		{
			Path = path;
			Shown = shown;
		}
	}

	private static readonly RangeRow[4] cRanges = .(.("pitchMin", "Pitch Min"), .("pitchMax", "Pitch Max"), .("volumeMin", "Volume Min"), .("volumeMax", "Volume Max"));

	/// Through the runtime context's audio (none in a test).
	private AuditionVoice mVoice ~ delete _;
	/// The rows; the base's sections let go of them first (ClearSections).
	private Sedulous.GUI.PropertyBag mCueRows = null;
	private Sedulous.GUI.PropertyBag mVariantRows = null;
	/// Variants added and given no clip yet: each one's weight (the cue holds none without a clip).
	private List<float> mPending = new .() ~ delete _;
	/// The variants' clips read for auditioning, by their assets' ids. Owned; after the voice.
	private Dictionary<Guid, AudioClip> mClips = new .() ~ DeleteDictionaryAndValues!(_);
	private Sedulous.Core.Random mRandom = .();
	private int32 mLastVariant = -1;
	private uint32 mSequence = 0;
	/// What the last play picked, said beside the transport.
	private String mPicked = new .() ~ delete _;
	/// The markup's: the tree holds it.
	private Sedulous.GUI.Label mState = null;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(SoundCueAsset), cMarkupPath)
	{
		HideAssetRows(); // the cue's fields are a fixed bank of slots: its rows are the page's
		let host = Services.Host;
		mVoice = new AuditionVoice((host != null) ? host.Subsystems.GetSubsystem<AudioSubsystem>() : null);
		mState = Find<Sedulous.GUI.Label>("cue-state");
		BuildRows();
		BindAction(Find<ButtonBase>("cue-restart"), "playback.restart");
		BindAction(Find<ButtonBase>("cue-play"), "playback.play");
		BindAction(Find<ButtonBase>("cue-stop"), "playback.stop");
		ShowRows();
		ShowState("stopped", "Stopped");
	}

	public ~this()
	{
		StopAudition();
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		DeleteRows();
	}

	public override void OnClose() => StopAudition();

	// === IPlaybackPage ===

	public bool CanPlay => (VariantCount > 0) && mVoice.HasEngine;
	public bool IsPlaying => mVoice.IsPlaying;

	public void Play()
	{
		if (!mVoice.IsActive)
		{
			StartAudition();
			return;
		}
		mVoice.SetPaused(false);
		ShowState("playing", mPicked);
	}

	public void Pause()
	{
		if (!mVoice.IsPlaying)
			return;
		mVoice.SetPaused(true);
		ShowState("paused", scope String()..AppendF("Paused: {}", mPicked));
	}

	public void Stop() => StopAudition();
	public void Restart() => StartAudition();

	// === For tests ===

	public Sedulous.GUI.PropertyBag CueRows => mCueRows;
	public Sedulous.GUI.PropertyBag VariantRows => mVariantRows;
	public StringView State => (mState != null) ? mState.Text : default;

	/// How many variants hold a clip.
	public int VariantCount
	{
		get
		{
			int count = 0;
			if (let cue = Cue)
			{
				for (let slot in cue.Slots)
				{
					if (!slot.ClipId.IsNil)
						count++;
				}
			}
			return count;
		}
	}

	/// An edit of a row as the grid commits one (`rows` one of the page's bags).
	public void EditRow(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		rows.SetValue(path, 0, value); // as the grid's commit leaves it
		Committed(rows, path, value);
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt); // the bar, the transport with it, each frame
		if (mVoice.IsActive && !mVoice.Poll(let cursor))
			StopAudition(); // played out, or its voice taken
	}

	protected override void OnObjectChanged()
	{
		ShowRows();
	}

	private SoundCueAsset Cue => ObjectAs<SoundCueAsset>();

	/// The rows' values from the cue: the variants with a clip, then those added and given no clip
	/// yet (the page's own).
	private void ShowRows()
	{
		let cue = Cue;
		if ((cue == null) || (mCueRows == null))
			return;
		mCueRows.SetValue("mode", 0, Sedulous.GUI.Variant((int64)cue.Mode));
		mCueRows.SetValue("pitchMin", 0, Sedulous.GUI.Variant((double)cue.PitchMin));
		mCueRows.SetValue("pitchMax", 0, Sedulous.GUI.Variant((double)cue.PitchMax));
		mCueRows.SetValue("volumeMin", 0, Sedulous.GUI.Variant((double)cue.VolumeMin));
		mCueRows.SetValue("volumeMax", 0, Sedulous.GUI.Variant((double)cue.VolumeMax));
		let variants = VariantsOf(cue, .. scope .());
		let room = SoundCueAsset.cSlotCount - variants.Count;
		while (mPending.Count > room)
			mPending.PopBack();
		let count = variants.Count + mPending.Count;
		mVariantRows.ResizeList("variants", 0, count);
		let path = scope String();
		let text = scope String();
		for (int i < count)
		{
			let kept = i < variants.Count;
			path.Clear();
			path.AppendF("variants.{}.clip", i);
			text.Clear();
			if (kept)
				variants[i].Clip.ToString(text);
			mVariantRows.SetValue(path, 0, Sedulous.GUI.Variant(text));
			path.Clear();
			path.AppendF("variants.{}.weight", i);
			mVariantRows.SetValue(path, 0, Sedulous.GUI.Variant((double)(kept ? variants[i].Weight : mPending[i - variants.Count])));
		}
		SetNotice("empty", variants.IsEmpty ? "This cue has no clip: add a variant and pick its clip, or nothing plays." : "");
	}

	/// The rows, made once: the cue's, then its variants as a list.
	private void BuildRows()
	{
		mCueRows = new Sedulous.GUI.PropertyBag();
		mVariantRows = new Sedulous.GUI.PropertyBag();
		let mode = mCueRows.Add("mode", .Enum);
		mode.DisplayName.Set("Picks");
		mode.Description.Set("How a play picks its variant: at random but never the one before, at random, or each in turn");
		mode.AddChoice("At random, never twice running", (int64)SoundCueMode.RandomNoRepeat);
		mode.AddChoice("At random", (int64)SoundCueMode.Random);
		mode.AddChoice("In order", (int64)SoundCueMode.Sequential);
		for (let range in cRanges)
		{
			let info = mCueRows.Add(range.Path, .Float);
			info.DisplayName.Set(range.Shown);
			info.HasRange = true;
			info.Min = 0.0;
			info.Max = 4.0;
			info.Step = 0.01;
			info.Hint.Set("slider");
		}
		// A list as every page's: the count with Add (eight at most), a variant a clip and its weight.
		let list = mVariantRows.AddList("variants", .Group, .());
		list.DisplayName.Set("Variants");
		list.Description.Set("What a play picks from: each a clip, picked against the others by its weight");
		list.MaxCount = (uint32)SoundCueAsset.cSlotCount;
		if (let clip = mVariantRows.AddElementField("variants", "clip", .Reference, Sedulous.GUI.Variant("")))
		{
			clip.DisplayName.Set("Clip");
			clip.ReferenceType = typeof(AudioClip);
		}
		if (let weight = mVariantRows.AddElementField("variants", "weight", .Float, Sedulous.GUI.Variant(1.0)))
		{
			weight.DisplayName.Set("Weight");
			weight.Description.Set("How often it is picked against the others' weights");
			weight.HasRange = true;
			weight.Min = 0.0;
			weight.Max = 100.0;
			weight.Step = 0.1;
		}
		for (let rows in Sedulous.GUI.PropertyBag[2](mCueRows, mVariantRows))
		{
			rows.SetOnCommit(new [=this, =rows] (commit) =>
				{
					if (!commit.After.IsEmpty)
						Committed(rows, commit.Path, commit.After[0]);
				});
			rows.PropertiesChanged(); // Add told the grid before the rows' names were set
		}
		mVariantRows.SetOnListEdited(new [=this] (path, edit) => { ListEdited(edit); });
		AddSection("cue", "Cue", mCueRows);
		AddSection("variants", "Variants", mVariantRows);
	}

	/// The two sections' rows let go; the grid let go of them first (ClearSections).
	private void DeleteRows()
	{
		DeleteAndNullify!(mCueRows);
		DeleteAndNullify!(mVariantRows);
	}

	private void Committed(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		if (Cue == null)
			return;
		if (rows === mCueRows)
		{
			if (path == "mode")
			{
				let mode = (uint8)Math.Clamp(value.AsInt, 0, 2);
				EditWhole("edit_soundcue", scope [&] (object) => { ((SoundCueAsset)object).Mode = mode; });
				return;
			}
			let range = (float)value.AsFloat;
			EditWhole("edit_soundcue", scope [&] (object) =>
				{
					let cue = (SoundCueAsset)object;
					if (path == "pitchMin")
						cue.PitchMin = range;
					else if (path == "pitchMax")
						cue.PitchMax = range;
					else if (path == "volumeMin")
						cue.VolumeMin = range;
					else if (path == "volumeMax")
						cue.VolumeMax = range;
				});
			return;
		}
		let element = ElementOf(path);
		if (element < 0)
			return;
		let kept = VariantsOf(Cue, .. scope .()).Count;
		if (path.EndsWith(".clip"))
		{
			let clip = GuidOf(value.AsString);
			if (element < kept)
			{
				// Its clip picked again, or cleared: a cleared one leaves the cue, its row kept to fill.
				if (clip.IsNil)
					mPending.Insert(0, 1.0f);
				EditVariants(scope [&] (variants) =>
					{
						if (clip.IsNil)
							variants.RemoveAt(element);
						else
							variants[element].Clip = clip;
					});
			}
			else if (!clip.IsNil && (element - kept < mPending.Count))
			{
				// A variant added and now given its clip joins the cue, with the weight it was given.
				let weight = mPending[element - kept];
				mPending.RemoveAt(element - kept);
				EditVariants(scope [&] (variants) => { variants.Add(.(clip, weight)); });
			}
			return;
		}
		if (path.EndsWith(".weight"))
		{
			let weight = (float)Math.Max(0.0, value.AsFloat);
			if (element < kept)
				EditVariants(scope [&] (variants) => { variants[element].Weight = weight; });
			else if (element - kept < mPending.Count)
				mPending[element - kept] = weight; // kept until it has a clip
		}
	}

	/// A list edit the grid made (Add, a removal, a move), as the cue's: one undo step, or the
	/// page's own while a variant has no clip.
	private void ListEdited(ListEdit edit)
	{
		let cue = Cue;
		if (cue == null)
			return;
		let kept = VariantsOf(cue, .. scope .()).Count;
		switch (edit.Kind)
		{
		case .Insert:
			// Added at the end with no clip yet: the page's until a clip is picked (no step: the cue
			// has not changed).
			mPending.Add(1.0f);
		case .Remove:
			let index = edit.Index;
			if (index < kept)
				EditVariants(scope [&] (variants) => { variants.RemoveAt(index); });
			else if (index - kept < mPending.Count)
				mPending.RemoveAt(index - kept);
		case .Move:
			let from = edit.Index;
			let to = edit.To;
			if ((from < kept) && (to < kept))
			{
				EditVariants(scope [&] (variants) =>
					{
						let moved = variants[from];
						variants.RemoveAt(from);
						variants.Insert(to, moved);
					});
			}
		}
		ShowRows(); // the list as the cue and the page hold it (a move past those with a clip goes back)
	}

	/// One change to the cue's variants as a list, packed back from the first slot: one undo step.
	private void EditVariants(delegate void(List<CueVariant> variants) change)
	{
		EditWhole("edit_soundcue", scope [&] (object) =>
			{
				let cue = (SoundCueAsset)object;
				let variants = VariantsOf(cue, .. scope .());
				change(variants);
				SetVariants(cue, variants);
			});
	}

	/// Variant `slot`'s clip, read for auditioning (kept by its asset's id); null when it has none.
	private AudioClip SlotClip(int slot)
	{
		let cue = Cue;
		let id = (cue != null) ? cue.Slots[slot].ClipId : Guid.Empty;
		if (id.IsNil || (Context.Project == null))
			return null;
		if (mClips.TryGetValue(id, let kept))
			return kept;
		let instance = Context.Project.SourceDb.GetInstance(id);
		let object = (instance != null) ? instance.ReadObject() : null;
		defer delete object;
		let clip = Audition.ReadClip(Context.Project, object as AudioClipAsset, let metadata);
		if (clip != null)
			mClips[id] = clip;
		return clip;
	}

	private void StartAudition()
	{
		StopAudition();
		let cue = Cue;
		if ((cue == null) || !CanPlay)
			return;
		// As the game resolves it: the runtime's own resolver over the same weights and ranges.
		let resolved = scope SoundCue();
		resolved.Mode = (SoundCueMode)cue.Mode;
		resolved.PitchMin = cue.PitchMin;
		resolved.PitchMax = cue.PitchMax;
		resolved.VolumeMin = cue.VolumeMin;
		resolved.VolumeMax = cue.VolumeMax;
		for (int slot < cue.Slots.Count)
			resolved.Variants.Add(.(SlotClip(slot), cue.Slots[slot].Weight));
		let pick = SoundCue.Resolve(resolved, ref mRandom, mLastVariant, ref mSequence);
		if (pick.VariantIndex < 0)
		{
			ShowState("faulted", "No variant could play: its clips are missing or did not decode");
			return;
		}
		mLastVariant = pick.VariantIndex;
		var parameters = AudioPlayParams();
		parameters.Pitch = pick.Pitch;
		parameters.Volume = pick.Volume;
		if (!mVoice.Start(resolved.Variants[pick.VariantIndex].Clip, parameters))
		{
			ShowState("faulted", "No voice: the audio engine did not start one");
			return;
		}
		// Which variant, counted as the grid shows them.
		int shown = 0;
		for (int slot = 0; slot <= pick.VariantIndex; slot++)
		{
			if (!cue.Slots[slot].ClipId.IsNil)
				shown++;
		}
		mPicked.Clear();
		mPicked.AppendF("Variant {}, pitch {:F2}, volume {:F2}", shown, pick.Pitch, pick.Volume);
		ShowState("playing", mPicked);
	}

	private void StopAudition()
	{
		if (mVoice != null)
			mVoice.Stop();
		ShowState("stopped", "Stopped");
	}

	private void ShowState(StringView state, StringView text)
	{
		Audition.ShowTransportState(mState, state, text);
	}

	/// A variant as the list shows it: a clip and its weight.
	private struct CueVariant
	{
		public Guid Clip;
		public float Weight;

		public this(Guid clip, float weight)
		{
			Clip = clip;
			Weight = weight;
		}
	}

	// The cue's variants packed in order (the list the grid shows), into `outVariants`.
	private static void VariantsOf(SoundCueAsset cue, List<CueVariant> outVariants)
	{
		for (let slot in cue.Slots)
		{
			if (!slot.ClipId.IsNil)
				outVariants.Add(.(slot.ClipId, slot.Weight));
		}
	}

	// Writes `variants` back from the first slot on, the rest emptied (a gap between variants
	// closes: the resolver skips empty slots, so the cue plays the same).
	private static void SetVariants(SoundCueAsset cue, List<CueVariant> variants)
	{
		for (int slot < cue.Slots.Count)
		{
			let used = slot < variants.Count;
			cue.Slots[slot].ClipId = used ? variants[slot].Clip : .Empty;
			cue.Slots[slot].Weight = used ? variants[slot].Weight : 1.0f;
		}
	}

	// The element a path names ("variants.2.weight": 2); -1 when it names none.
	private static int ElementOf(StringView path)
	{
		let element = ParentPropertyPath(path);
		if (ParentPropertyPath(element) != "variants")
			return -1;
		if (int.Parse(element.Substring(9)) case .Ok(let index))
			return (index >= 0) ? index : -1;
		return -1;
	}

	private static Guid GuidOf(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		if (!trimmed.IsEmpty && (Guid.Parse(trimmed) case .Ok(let id)))
			return id;
		return .();
	}
}
