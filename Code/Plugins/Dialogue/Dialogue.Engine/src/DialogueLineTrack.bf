using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Run;
using Sedulous.Sequence;

namespace Dialogue;

/// One line on the timeline: a speaker of the track's cast, a mood, and its text, written here or
/// taken by line id from a dialogue file.
[Reflect(.All)]
class DialogueLineSection
{
	[DisplayName("Start")]
	public float Start = 0.0f;
	[DisplayName("Length"), Description("Seconds on the timeline; the play holds at its end until the line is advanced")]
	public float Length = 2.0f;
	[DisplayName("Speaker"), Description("The speaker's id in the track's cast")]
	public String Speaker = new .() ~ delete _;
	/// Empty: the speaker's first.
	[DisplayName("Mood")]
	public String Mood = new .() ~ delete _;
	/// The line as written, `{Action}` and all, unless it comes from a dialogue file.
	[DisplayName("Text")]
	public String Text = new .() ~ delete _;
	[DisplayName("Dialogue File"), Description("A dialogue file to take the line from, by its line id, in place of the text")]
	public Ref<DialogueResource> Dialogue = .(Guid());
	[DisplayName("Line Id")]
	public String LineId = new .() ~ delete _;

	/// The line's text: the dialogue file's line `LineId` when one is named and loaded, else `Text`.
	public StringView ShownText
	{
		get
		{
			if (!LineId.IsEmpty)
			{
				if (let file = Dialogue.Get)
				{
					let found = file.Text(LineId);
					if (!found.IsEmpty)
						return found;
				}
			}
			return Text;
		}
	}
}

/// Lines of dialogue on a sequence's timeline, for a linear cutscene staged as a sequence rather
/// than as a conversation (Dialogue Lines in the sequence panel's Track menu). When the playhead
/// enters a section, the run's dialogue runner shows the line as it shows a conversation's; at the
/// section's end the play holds until the line is advanced (a track runner's hold), so the cutscene
/// waits for the player to read it. The editor's posing shows no lines. A line refused (a
/// conversation is playing) holds nothing.
[DisplayName("Dialogue Lines")]
[Reflect(.All)]
class DialogueLineTrack : SequenceTrack
{
	/// After what the lines stage has moved, before the events.
	public const int32 cOrder = 900;

	/// Whose speakers the lines name.
	[DisplayName("Cast")]
	public Ref<DialogueCastResource> Cast = .(Guid());
	/// By start.
	[DisplayName("Lines")]
	public List<DialogueLineSection> Sections = new .() ~ DeleteContainerAndItems!(_);

	public override float Duration
	{
		get
		{
			var last = 0.0f;
			for (let section in Sections)
				last = Math.Max(last, section.Start + section.Length);
			return last;
		}
	}

	public override int32 Order => cOrder;
	public override bool NeedsBinding => false;

	/// The section running at `time` (its end included); of two overlapping, the later; null
	/// between sections.
	public DialogueLineSection SectionAt(float time)
	{
		DialogueLineSection found = null;
		for (let section in Sections)
		{
			if ((time >= section.Start) && (time <= section.Start + section.Length) && ((found == null) || (section.Start >= found.Start)))
				found = section;
		}
		return found;
	}

	// === Editing: each line a section ===

	public override int SectionCount => Sections.Count;

	public override void GetSection(int index, out float start, out float length, String outLabel)
	{
		start = 0.0f;
		length = 0.0f;
		if (index >= Sections.Count)
			return;
		let section = Sections[index];
		start = section.Start;
		length = section.Length;
		if (!section.Speaker.IsEmpty)
			outLabel.AppendF("{}: ", section.Speaker);
		outLabel.Append(section.ShownText);
	}

	public override void SetSection(int index, float start, float length)
	{
		if (index >= Sections.Count)
			return;
		Sections[index].Start = Math.Max(0.0f, start);
		Sections[index].Length = Math.Max(0.0f, length);
	}

	public override void RemoveSection(int index)
	{
		if (index >= Sections.Count)
			return;
		delete Sections[index];
		Sections.RemoveAt(index);
	}

	/// A line of no text yet, two seconds long, at `time`.
	public override int AddSection(float time)
	{
		int at = 0;
		while ((at < Sections.Count) && (Sections[at].Start <= time))
			at++;
		let section = new DialogueLineSection();
		section.Start = Math.Max(0.0f, time);
		Sections.Insert(at, section);
		return at;
	}

	public override SequenceTrackRunner Begin(SequenceTrackContext context) => new LineRunner(this, context.Scene);

	public override void ResolveResources(ResourceManager manager)
	{
		Cast.Bind(manager);
		for (let section in Sections)
		{
			if (section.Dialogue.Id != .())
				section.Dialogue.Bind(manager);
		}
	}

	/// The sections as parallel lists. A damaged record (lists of different lengths) reads as no
	/// sections rather than wrong ones.
	public override void Serialize(ISerializer ar)
	{
		base.Serialize(ar);
		let reading = ar.Mode == .Read;
		var castId = Cast.Id;
		SerializeValue(ar, "cast", ref castId);
		let starts = scope List<float>();
		let lengths = scope List<float>();
		let speakers = scope List<String>();
		let moods = scope List<String>();
		let texts = scope List<String>();
		let dialogues = scope List<Guid>();
		let lineIds = scope List<String>();
		defer
		{
			ClearAndDeleteItems!(speakers);
			ClearAndDeleteItems!(moods);
			ClearAndDeleteItems!(texts);
			ClearAndDeleteItems!(lineIds);
		}
		if (!reading)
		{
			for (let section in Sections)
			{
				starts.Add(section.Start);
				lengths.Add(section.Length);
				speakers.Add(new .(section.Speaker));
				moods.Add(new .(section.Mood));
				texts.Add(new .(section.Text));
				dialogues.Add(section.Dialogue.Id);
				lineIds.Add(new .(section.LineId));
			}
		}
		ar.Key("sectionStart");
		SerializeList(ar, starts);
		ar.Key("sectionLength");
		SerializeList(ar, lengths);
		ar.Key("sectionSpeaker");
		SerializeList(ar, speakers);
		ar.Key("sectionMood");
		SerializeList(ar, moods);
		ar.Key("sectionText");
		SerializeList(ar, texts);
		ar.Key("sectionDialogue");
		SerializeList(ar, dialogues);
		ar.Key("sectionLineId");
		SerializeList(ar, lineIds);
		if (!reading)
			return;
		Cast.SetId(castId);
		ClearAndDeleteItems!(Sections);
		let count = starts.Count;
		if ((lengths.Count < count) || (speakers.Count < count) || (moods.Count < count) || (texts.Count < count) ||
			(dialogues.Count < count) || (lineIds.Count < count))
			return;
		for (int i < count)
		{
			let section = new DialogueLineSection();
			section.Start = starts[i];
			section.Length = lengths[i];
			section.Speaker.Set(speakers[i]);
			section.Mood.Set(moods[i]);
			section.Text.Set(texts[i]);
			section.Dialogue.SetId(dialogues[i]);
			section.LineId.Set(lineIds[i]);
			Sections.Add(section);
		}
	}

	/// Shows each section's line through the run's dialogue runner as the playhead enters it, and
	/// holds the play at its end while the line is shown.
	private class LineRunner : SequenceTrackRunner
	{
		/// BORROWED, both.
		private DialogueLineTrack mTrack;
		private Sedulous.Scene.Scene mScene;
		/// Whose line it is.
		private DialogueLineSection mSection = null;
		private uint32 mLine = 0;

		public this(DialogueLineTrack track, Sedulous.Scene.Scene scene)
		{
			mTrack = track;
			mScene = scene;
		}

		private DialogueRunService Runner => (mScene != null) ? RunServices.Get<DialogueRunService>(mScene.Run) : null;

		public override void Evaluate(SequenceStep step)
		{
			if (step.Preview)
				return; // the editor posing the scene shows no lines
			let section = mTrack.SectionAt(step.Time);
			if (section == mSection)
				return; // a line advanced inside its section is not shown again
			EndLine();
			mSection = section;
			let runner = Runner;
			if ((section != null) && (runner != null))
				mLine = runner.ShowLine(mTrack.Cast.Get, section.Speaker, section.Mood, section.ShownText, section.LineId);
		}

		public override void Release(bool restore)
		{
			EndLine();
			mSection = null;
		}

		public override float HoldTime(float after, float upTo)
		{
			var first = -1.0f;
			for (let section in mTrack.Sections)
			{
				let end = section.Start + section.Length;
				if ((end > after) && (end <= upTo) && ((first < 0.0f) || (end < first)))
					first = end;
			}
			return first;
		}

		public override bool IsHolding => Runner?.IsShowing(mLine) ?? false;

		private void EndLine()
		{
			if (mLine != 0)
				Runner?.EndLine(mLine);
			mLine = 0;
		}
	}
}
