using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Engine.Audio;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// The sound cue page: a row per slot (the clip, its weight), the pick mode and the pitch
/// and volume jitter, and an audition that resolves a variant the way the runtime does.
/// Every edit is a whole asset snapshot command; Discard reverts to the saved bytes.
class SoundCueEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private AudioSubsystem mAudio = null;
	private String mTitle = new .() ~ delete _;
	/// The page's own copy of the asset.
	private SoundCueAsset mAsset = new .() ~ delete _;
	private Sedulous.Core.Random mRng = .();
	private int32 mLastVariant = -1;
	private uint32 mSequentialCursor = 0;
	private VoiceHandle mVoice = .();
	private bool mPaused = false;
	private String mPickText = new .() ~ delete _;
	/// Clips loaded for audition, by asset id.
	private Dictionary<Guid, AudioClip> mClipCache = new .() ~ DeleteDictionaryAndValues!(_);
	/// The last saved state, what Discard reverts to.
	private List<uint8> mSavedBlob = new .() ~ delete _;
	/// The "before" of the next edit command.
	private List<uint8> mUndoBaseline = new .() ~ delete _;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	private Label[SoundCueAsset.cSlotCount] mSlotLabels = .();
	private NumericField[SoundCueAsset.cSlotCount] mWeightFields = .();
	private List<NumericField> mJitterFields = new .() ~ delete _;
	private Button mModeButton = null;
	private Button mPauseButton = null;
	private Label mStatus = null;
	/// The persistent draft hint for an empty cue.
	private Label mEmptyHint = null;

	public this(EditorContext context, IApplicationHost host, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		mAudio = (host != null) ? host.Context.GetSubsystem<AudioSubsystem>() : null;
		let object = instance.ReadObject();
		if (let asset = object as SoundCueAsset)
			SoundCueAssetEdit.CopyTo(asset, mAsset);
		delete object;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6.0f;
		mToolbar = new PageToolbar(this);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mToolbar, match);

		for (int i < SoundCueAsset.cSlotCount)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 6.0f;
			mSlotLabels[i] = new Label("(empty)");
			mSlotLabels[i].FontSize.Value = 13.0f;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(mSlotLabels[i], grow);
			let slot = i;
			let pick = new Button("Pick...");
			pick.OnClick.Add(new [=this, =slot](btn) => { PickClip(slot); });
			row.AddView(pick);
			let clear = new Button("Clear");
			clear.OnClick.Add(new [=this, =slot](btn) =>
				{
					mAsset.Slots[slot].ClipId = .();
					RefreshSlot(slot);
					CommitEdit("");
				});
			row.AddView(clear);
			let weightLabel = new Label("weight");
			weightLabel.FontSize.Value = 12.0f;
			var center = LayoutStyle();
			center.AlignSelf = .Center;
			row.AddView(weightLabel, center);
			mWeightFields[i] = new NumericField();
			mWeightFields[i].SetMin(0.0);
			mWeightFields[i].SetMax(100.0);
			mWeightFields[i].SetValue(mAsset.Slots[i].Weight);
			mWeightFields[i].OnValueChanged.Add(new [=this, =slot](field, value) =>
				{
					mAsset.Slots[slot].Weight = (float)value;
					CommitEdit(scope $"weight{slot}");
				});
			row.AddView(mWeightFields[i]);
			column.AddView(row, match);
		}
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 6.0f;
			mModeButton = new Button("");
			mModeButton.OnClick.Add(new [=this](btn) =>
				{
					mAsset.Mode = (uint8)((mAsset.Mode + 1) % 3);
					RefreshModeButton();
					CommitEdit("");
				});
			row.AddView(mModeButton);
			AddJitterField(row, "pitch min", &mAsset.PitchMin);
			AddJitterField(row, "pitch max", &mAsset.PitchMax);
			AddJitterField(row, "vol min", &mAsset.VolumeMin);
			AddJitterField(row, "vol max", &mAsset.VolumeMax);
			column.AddView(row, match);
		}
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 6.0f;
			let play = new Button("Audition");
			play.OnClick.Add(new [=this](btn) => { Audition(); });
			row.AddView(play);
			mPauseButton = new Button("Pause");
			mPauseButton.OnClick.Add(new [=this](btn) => { TogglePause(); });
			row.AddView(mPauseButton);
			let stop = new Button("Stop");
			stop.OnClick.Add(new [=this](btn) => { StopAudition(); });
			row.AddView(stop);
			mStatus = new Label("");
			mStatus.FontSize.Value = 12.0f;
			var center = LayoutStyle();
			center.AlignSelf = .Center;
			row.AddView(mStatus, center);
			column.AddView(row, match);
		}
		mEmptyHint = new Label("");
		mEmptyHint.FontSize.Value = 12.0f;
		mEmptyHint.TextColor.Value = Color(0.9f, 0.75f, 0.35f, 1.0f);
		column.AddView(mEmptyHint, match);
		column.AddRef();
		mContent = column;
		for (int i < SoundCueAsset.cSlotCount)
			RefreshSlot(i);
		RefreshModeButton();
		SoundCueAssetEdit.Snapshot(mAsset, mSavedBlob); // what Discard reverts to
		mUndoBaseline.AddRange(mSavedBlob); // and the first edit command's before
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public SoundCueAsset Asset => mAsset;

	private AudioEngine Engine => (mAudio != null) ? mAudio.Engine : null;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
		let engine = Engine;
		if ((engine == null) || !mVoice.IsValid)
			return;
		VoiceStatus status = ?;
		if (engine.GetVoiceStatus(mVoice, out status) && status.Playing)
			mStatus.SetText(scope $"{mPickText}  |  {status.CursorSeconds:F1} s");
		else
		{
			mVoice = .();
			mStatus.SetText(mPickText);
		}
	}

	public override Result<void, ErrorCode> Save()
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(InstanceId) : null;
		if (instance == null)
			return .Err(.NotFound);
		let written = instance.WriteObject(mAsset);
		if (written case .Ok)
		{
			ClearDirty();
			SoundCueAssetEdit.Snapshot(mAsset, mSavedBlob); // Discard now reverts to this
			mContext.RequestCook(false);
		}
		return written;
	}

	/// Restores a snapshot, the undo and redo path; every widget re-pulls.
	public void ApplyAssetBlob(List<uint8> blob)
	{
		if (!SoundCueAssetEdit.Apply(mAsset, blob))
			return;
		for (int i < SoundCueAsset.cSlotCount)
		{
			mWeightFields[i].SetValue(mAsset.Slots[i].Weight);
			RefreshSlot(i);
		}
		RefreshModeButton();
		float[4] jitter = .(mAsset.PitchMin, mAsset.PitchMax, mAsset.VolumeMin, mAsset.VolumeMax);
		for (int i = 0; (i < mJitterFields.Count) && (i < 4); i++)
			mJitterFields[i].SetValue(jitter[i]);
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob); // the next edit diffs from here
		MarkDirty();
	}

	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		SoundCueAssetEdit.Snapshot(mAsset, after);
		Commands.Execute(new EditSoundCueCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();
	}

	/// Back to the last saved state, dropping the undo history that predates it.
	public override void DiscardChanges()
	{
		ApplyAssetBlob(mSavedBlob);
		Commands.Clear();
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(mSavedBlob);
		ClearDirty();
	}

	public override void OnClose()
	{
		let engine = Engine;
		if ((engine != null) && mVoice.IsValid)
			engine.Stop(mVoice);
	}

	/// A labelled jitter number writing straight into the asset; a scrub coalesces under
	/// the label as its key.
	private void AddJitterField(FlexLayout row, StringView label, float* target)
	{
		let text = new Label(label);
		text.FontSize.Value = 12.0f;
		var center = LayoutStyle();
		center.AlignSelf = .Center;
		row.AddView(text, center);
		let field = new NumericField();
		field.SetMin(0.0);
		field.SetMax(4.0);
		field.SetDecimalPlaces(2);
		field.SetValue(*target);
		let key = new String(label);
		field.OnValueChanged.Add(new [=this, =target, =key](numeric, value) =>
			{
				*target = (float)value;
				CommitEdit(key);
			} ~ delete key);
		row.AddView(field);
		mJitterFields.Add(field);
	}

	private void PickClip(int slot)
	{
		let ctx = (mContent != null) ? mContent.Context : null;
		if (ctx == null)
			return;
		let picker = new AssetPickerDialog(mContext, scope StringView[]("AudioClipAsset"));
		picker.OnPicked = new [=this, =slot](id) =>
			{
				mAsset.Slots[slot].ClipId = id;
				RefreshSlot(slot);
				CommitEdit("");
			};
		picker.Show(ctx);
	}

	private void RefreshSlot(int slot)
	{
		let id = mAsset.Slots[slot].ClipId;
		if (id.IsNil || (mContext.Project == null))
			mSlotLabels[slot].SetText("(empty)");
		else
		{
			let clip = mContext.Project.SourceDb.GetInstance(id);
			mSlotLabels[slot].SetText((clip != null) ? clip.GetPath(.. scope .()) : "(missing)");
		}
		RefreshEmptyHint();
	}

	private void RefreshEmptyHint()
	{
		if (mEmptyHint != null)
			mEmptyHint.SetText(SoundCueAssetEdit.HasAnyClip(mAsset) ? "" : "Empty cue - assign at least one clip.");
	}

	private void RefreshModeButton() => mModeButton.SetText(SoundCueAssetEdit.ModeLabel(mAsset.Mode));

	/// Resolves a variant as the runtime would and plays it; a repeat restarts rather than
	/// stacking voices.
	private void Audition()
	{
		let engine = Engine;
		if (engine == null)
			return;
		StopAudition();
		let cue = scope SoundCue();
		cue.Mode = (SoundCueMode)mAsset.Mode;
		cue.PitchMin = mAsset.PitchMin;
		cue.PitchMax = mAsset.PitchMax;
		cue.VolumeMin = mAsset.VolumeMin;
		cue.VolumeMax = mAsset.VolumeMax;
		for (int i < SoundCueAsset.cSlotCount)
			cue.Variants.Add(.(LoadSlotClip(i), mAsset.Slots[i].Weight));
		let pick = SoundCue.Resolve(cue, ref mRng, mLastVariant, ref mSequentialCursor);
		if (pick.VariantIndex < 0)
		{
			mStatus.SetText("No playable variant.");
			return;
		}
		mLastVariant = pick.VariantIndex;
		var parameters = AudioPlayParams();
		parameters.Pitch = pick.Pitch;
		parameters.Volume = pick.Volume;
		parameters.AllowDedupe = false;
		mVoice = engine.Play(cue.Variants[pick.VariantIndex].Clip, parameters);
		mPickText.Clear();
		mPickText.AppendF("slot {}  pitch {:F2}  vol {:F2}", pick.VariantIndex, pick.Pitch, pick.Volume);
		mStatus.SetText(mPickText);
	}

	private void StopAudition()
	{
		let engine = Engine;
		if ((engine != null) && mVoice.IsValid)
			engine.Stop(mVoice);
		mVoice = .();
		mPaused = false;
		if (mPauseButton != null)
			mPauseButton.SetText("Pause");
	}

	private void TogglePause()
	{
		let engine = Engine;
		if ((engine == null) || !mVoice.IsValid)
			return;
		mPaused = !mPaused;
		engine.SetPaused(mVoice, mPaused);
		if (mPauseButton != null)
			mPauseButton.SetText(mPaused ? "Resume" : "Pause");
	}

	/// The slot's clip, loaded once and cached for the page's life.
	private AudioClip LoadSlotClip(int slot)
	{
		let id = mAsset.Slots[slot].ClipId;
		if (id.IsNil || (mContext.Project == null))
			return null;
		if (mClipCache.TryGetValue(id, let cached))
			return cached;
		let instance = mContext.Project.SourceDb.GetInstance(id);
		let object = (instance != null) ? instance.ReadObject() : null;
		defer delete object;
		let clip = AudioClipLoader.Load(mContext, object as AudioClipAsset);
		if (clip != null)
			mClipCache[id] = clip;
		return clip;
	}
}
