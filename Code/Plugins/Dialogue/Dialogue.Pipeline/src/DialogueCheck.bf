using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Dialogue;

/// One of the project's dialogue assets: the name a conversation calls it by, and the asset.
[Reflect(.All), DisplayName("Dialogue Asset")]
class DialogueAssetEntry : ISerializable
{
	[DisplayName("Name"), Description("What a conversation calls the asset by: one word")]
	public String Name = new .() ~ delete _;
	[DisplayName("Asset")]
	public Guid Asset = .();

	public this() {}

	public this(StringView name, Guid asset)
	{
		Name.Set(name);
		Asset = asset;
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		SerializeValue(ar, "asset", ref Asset);
		ar.EndObject();
	}
}

/// The project's assets as the checks see them, by guid.
interface IDialogueAssets
{
	/// The name of the asset `id` into `outName`; nothing when there is none.
	void NameOf(Guid id, String outName);
	/// The type of the asset `id` ("AudioClipAsset") into `outType`; nothing when there is none.
	void TypeOf(Guid id, String outType);
}

/// The project's levels as the checks see them.
interface IDialogueLevels
{
	/// The names of the entities in the scene `level` (BORROWED, the implementation's); null when it
	/// does not load.
	List<String> EntityNames(Guid level);
}

/// What the checks read beyond the file itself. Everything it names is BORROWED.
class DialogueCheckInputs
{
	/// Null: the file names no cast.
	public List<DialogueSpeaker> Cast;
	/// Null: the file names no dialogue assets.
	public List<DialogueAssetEntry> DialogueAssets;
	/// The declared commands the file was parsed with.
	public Span<DialogueCommandForm> Commands;
	/// Names, or prefixes ending in `*`.
	public Span<String> ProvidedFlags;
	/// The project's other dialogue files: their conversation ids.
	public Span<String> OtherConversations;
	/// Their explicit (`#line:`) ids.
	public Span<String> OtherLineIds;
	/// The flags their `set` and `clear` write.
	public Span<String> OtherFlagsSet;
	/// Null: the assets' names and types are not checked.
	public IDialogueAssets Assets;
	/// The input maps' actions; null: the project has no input map.
	public List<String> Actions;
	/// Null: a level's entities are not checked.
	public IDialogueLevels Levels;
}

/// The cook's checks of a parsed dialogue file: what the parser cannot know, against the project.
static class DialogueChecks
{
	/// The asset types `sound` and `sequence` take.
	public static String[?] cSoundAssetTypes = .("AudioClipAsset", "SoundCueAsset");
	public static String[?] cSequenceAssetTypes = .("SequenceAsset");
	/// The asset types a conversation's level takes.
	public static String[?] cLevelAssetTypes = .("SceneDocument");

	/// Checks `parse` and adds every problem to it, by line; resolves the clips, sounds and
	/// sequences its steps name into their `Asset`.
	public static void CheckDialogue(DialogueParse parse, DialogueCheckInputs inputs)
	{
		let checker = scope Checker(parse, inputs);
		checker.Run();
		parse.SortProblems();
	}

	/// Whether `flag` is one of `provided`: named, or under a prefix written `prefix*`.
	public static bool IsProvidedFlag(StringView flag, Span<String> provided)
	{
		for (let entry in provided)
		{
			StringView name = entry;
			if (name.EndsWith("*") ? flag.StartsWith(name.Substring(0, name.Length - 1)) : (flag == name))
				return true;
		}
		return false;
	}

	/// What a parsed file contributes to the others' checks, appended to the lists (copies, the
	/// caller's to delete).
	public static void CollectDialogueFacts(DialogueParse parse, List<String> conversations, List<String> explicitLineIds,
		List<String> flagsSet, List<String> flagsRead)
	{
		for (let conversation in parse.Conversations)
		{
			if (!conversation.Id.IsEmpty)
				conversations.Add(new .(conversation.Id));
			for (let step in conversation.Steps)
			{
				if (((step.Kind == .Line) || (step.Kind == .Answer)) && !IsPositionalId(step.LineId, conversation.Id))
					explicitLineIds.Add(new .(step.LineId));
				else if (((step.Kind == .Set) || (step.Kind == .Clear)) && !Contains(flagsSet, step.Flag))
					flagsSet.Add(new .(step.Flag));
				else if ((step.Kind == .If) && !Contains(flagsRead, step.Flag))
					flagsRead.Add(new .(step.Flag));
			}
		}
	}

	static bool Contains(Span<String> list, StringView value)
	{
		for (let item in list)
		{
			if (item == value)
				return true;
		}
		return false;
	}

	static bool Contains(List<String> list, StringView value) => Contains((Span<String>)list, value);

	/// An id the parser made from the line's place (`<conversation>.<n>`), not one written.
	static bool IsPositionalId(StringView id, StringView conversation)
	{
		if ((id.Length <= conversation.Length + 1) || !id.StartsWith(conversation) || (id[conversation.Length] != '.'))
			return false;
		for (int i = conversation.Length + 1; i < id.Length; i++)
		{
			if ((id[i] < '0') || (id[i] > '9'))
				return false;
		}
		return true;
	}

	static void Joined(List<String> words, String outText)
	{
		for (let word in words)
		{
			if (!outText.IsEmpty)
				outText.Append(", ");
			outText.Append(word);
		}
	}

	class Checker
	{
		DialogueParse mParse; // the caller's
		DialogueCheckInputs mInputs; // the caller's
		List<String> mConversations = new .() ~ DeleteContainerAndItems!(_);
		List<String> mLineIds = new .() ~ DeleteContainerAndItems!(_);
		List<String> mFlagsSet = new .() ~ DeleteContainerAndItems!(_);
		List<String> mFlagsRead = new .() ~ DeleteContainerAndItems!(_);
		bool mNoCastTold;
		bool mNoAssetsTold;
		bool mNoActionsTold;
		/// The conversation's level's entities, when it names one that loads (BORROWED).
		List<String> mEntities;
		StringView mLevelName;
		/// The entities a warning has named in this conversation.
		List<String> mEntitiesTold = new .() ~ DeleteContainerAndItems!(_);

		public this(DialogueParse parse, DialogueCheckInputs inputs)
		{
			mParse = parse;
			mInputs = inputs;
			CollectDialogueFacts(parse, mConversations, mLineIds, mFlagsSet, mFlagsRead);
		}

		public void Run()
		{
			for (let conversation in mParse.Conversations)
			{
				let header = conversation.Steps.IsEmpty ? (uint32)0 : conversation.Steps.Back.SourceLine;
				if (Contains(mInputs.OtherConversations, conversation.Id))
					Problem(header, scope $"another dialogue file has a conversation `{conversation.Id}`");
				Level(conversation, header);
				ClearAndDeleteItems!(mEntitiesTold);
				for (let step in conversation.Steps)
					Step(conversation, step);
				Reachability(conversation);
				mEntities = null;
			}
		}

		void Problem(uint32 line, StringView message, bool warning = false)
		{
			mParse.Problems.Add(new .(line, message, warning));
		}

		/// The speaker `id`, or null with the problem said (once, when there is no cast).
		DialogueSpeaker Speaker(StringView id, uint32 line)
		{
			if (mInputs.Cast == null)
			{
				if (!mNoCastTold)
				{
					Problem(line, "the dialogue file names no cast");
					mNoCastTold = true;
				}
				return null;
			}
			for (let speaker in mInputs.Cast)
			{
				if (speaker.Id == id)
					return speaker;
			}
			Problem(line, scope $"no speaker `{id}` in the cast");
			return null;
		}

		/// The dialogue asset `name`, when it is of one of `types`; nil, with the problem said,
		/// otherwise.
		Guid Asset(StringView name, Span<String> types, StringView what, uint32 line)
		{
			if (mInputs.DialogueAssets == null)
			{
				if (!mNoAssetsTold)
				{
					Problem(line, "the dialogue file names no dialogue assets");
					mNoAssetsTold = true;
				}
				return .();
			}
			for (let entry in mInputs.DialogueAssets)
			{
				if (entry.Name != name)
					continue;
				if (mInputs.Assets == null)
					return entry.Asset;
				let type = mInputs.Assets.TypeOf(entry.Asset, .. scope .());
				if (type.IsEmpty)
				{
					Problem(line, scope $"the dialogue asset `{name}` refers to no asset");
					return .();
				}
				for (let accepted in types)
				{
					if (type == accepted)
						return entry.Asset;
				}
				Problem(line, scope $"the dialogue asset `{name}` is of type {type}, which is no {what}");
				return .();
			}
			Problem(line, scope $"no dialogue asset `{name}`");
			return .();
		}

		/// The level a conversation names: its entities, which later steps check their names against.
		void Level(DialogueConversation conversation, uint32 header)
		{
			mEntities = null;
			mLevelName = conversation.Level;
			if (conversation.Level.IsEmpty)
				return;
			let level = Asset(conversation.Level, cLevelAssetTypes, "level", header);
			if ((level != .()) && (mInputs.Levels != null))
				mEntities = mInputs.Levels.EntityNames(level);
		}

		/// A warning when the conversation's level has no entity `name`: one spawned at play is not
		/// in the scene, so it may be there when the conversation plays.
		void Entity(StringView name, StringView whose, uint32 line)
		{
			if ((mEntities == null) || name.IsEmpty || Contains(mEntities, name) || Contains(mEntitiesTold, name))
				return;
			mEntitiesTold.Add(new .(name));
			Problem(line, scope $"no entity `{name}` ({whose}) in the level `{mLevelName}`, unless it is spawned at play", true);
		}

		/// The actions a line's or an answer's text names (`{Interact}`; `{{` is a brace).
		void Actions(StringView id, uint32 line)
		{
			StringView text = "";
			for (let entry in mParse.Lines)
			{
				if (entry.Id == id)
				{
					text = entry.Text;
					break;
				}
			}
			for (int i = 0; i < text.Length; i++)
			{
				if (text[i] != '{')
					continue;
				if ((i + 1 < text.Length) && (text[i + 1] == '{'))
				{
					i++;
					continue;
				}
				let close = text.IndexOf('}', i + 1);
				if (close < 0)
				{
					Problem(line, "a `{` with no `}`: an action is `{Name}`, a brace `{{`");
					return;
				}
				let action = text.Substring(i + 1, close - i - 1);
				if (mInputs.Actions == null)
				{
					if (!mNoActionsTold)
					{
						let braced = scope String("{");
						braced.Append(action);
						braced.Append('}');
						Problem(line, scope $"`{braced}` names an action, but the project has no input map");
						mNoActionsTold = true;
					}
				}
				else if (!Contains(mInputs.Actions, action))
				{
					Problem(line, scope $"no action `{action}` in the project's input maps");
				}
				i = close;
			}
		}

		void Step(DialogueConversation conversation, DialogueStep step)
		{
			switch (step.Kind)
			{
			case .Line, .Answer:
				if (step.Kind == .Line)
				{
					if (let speaker = Speaker(step.Speaker, step.SourceLine))
					{
						Entity(speaker.Entity, scope $"the speaker `{speaker.Id}`'s", step.SourceLine);
						if (!step.Mood.IsEmpty && (speaker.FindMood(step.Mood) == null))
						{
							let moods = scope String();
							for (let mood in speaker.Moods)
							{
								if (!moods.IsEmpty)
									moods.Append(", ");
								moods.Append(mood.Name);
							}
							Problem(step.SourceLine, scope $"`{step.Speaker}` has no mood `{step.Mood}` (has {(moods.IsEmpty ? "none" : moods)})");
						}
					}
				}
				Actions(step.LineId, step.SourceLine);
				if (!IsPositionalId(step.LineId, conversation.Id) && Contains(mInputs.OtherLineIds, step.LineId))
					Problem(step.SourceLine, scope $"another dialogue file has a line `#line:{step.LineId}`");
			case .Play:
				if (let speaker = Speaker(step.Speaker, step.SourceLine))
					Clip(speaker, step);
			case .Sound:
				if (!step.Speaker.IsEmpty)
					Speaker(step.Speaker, step.SourceLine);
				step.Asset = Asset(step.Name, cSoundAssetTypes, "sound", step.SourceLine);
			case .Sequence:
				step.Asset = Asset(step.Name, cSequenceAssetTypes, "sequence", step.SourceLine);
			case .Jump:
				if (!Contains(mConversations, step.Name) && !Contains(mInputs.OtherConversations, step.Name))
					Problem(step.SourceLine, scope $"no conversation `{step.Name}` to jump to");
			case .If:
				if (!Contains(mFlagsSet, step.Flag) && !Contains(mInputs.OtherFlagsSet, step.Flag) && !IsProvidedFlag(step.Flag, mInputs.ProvidedFlags))
					Problem(step.SourceLine, scope $"the flag `{step.Flag}` is read but nothing sets it, and the settings do not list it as provided");
			case .Command:
				Command(step);
			default:
				break;
			}
		}

		void Clip(DialogueSpeaker speaker, DialogueStep step)
		{
			if (mInputs.Assets == null)
				return;
			let names = scope List<String>();
			defer { ClearAndDeleteItems!(names); }
			for (let clip in speaker.Clips)
			{
				let name = new String();
				mInputs.Assets.NameOf(clip, name);
				if (name == step.Name)
				{
					delete name;
					step.Asset = clip;
					return;
				}
				if (name.IsEmpty)
					delete name;
				else
					names.Add(name);
			}
			let has = scope String();
			if (names.IsEmpty)
				has.Append("none");
			else
				Joined(names, has);
			Problem(step.SourceLine, scope $"`{step.Speaker}` has no clip `{step.Name}` (has {has})");
		}

		void Command(DialogueStep step)
		{
			DialogueCommandForm form = null;
			for (let candidate in mInputs.Commands)
			{
				if (candidate.Name == step.Name)
				{
					form = candidate;
					break;
				}
			}
			if (form == null)
				return; // the parser matched it, so the file was parsed with other commands
			for (let argument in step.Arguments)
			{
				if (!argument.Present)
					continue;
				for (let part in form.Parts)
				{
					if (part.Literal || (part.Name != argument.Name))
						continue;
					if (part.Kind == .Speaker)
					{
						Speaker(argument.Text, step.SourceLine);
					}
					else if (part.Kind == .Entity)
					{
						Entity(argument.Text, scope $"`{step.Name}`'s {argument.Name}", step.SourceLine);
					}
					else if (part.Kind == .Asset)
					{
						String[1] types = .(part.AssetType);
						argument.Asset = Asset(argument.Text, types, part.AssetType, step.SourceLine);
					}
				}
			}
		}

		/// Statements nothing reaches: after a jump, or behind an answer's skip.
		void Reachability(DialogueConversation conversation)
		{
			let steps = conversation.Steps;
			let reached = scope bool[steps.Count];
			let pending = scope List<int>();
			pending.Add(0);
			void Visit(int at)
			{
				if ((at >= 0) && (at < steps.Count))
					pending.Add(at);
			}
			while (!pending.IsEmpty)
			{
				let at = pending.PopBack();
				if ((at >= steps.Count) || reached[at])
					continue;
				reached[at] = true;
				let step = steps[at];
				switch (step.Kind)
				{
				case .Skip, .Answer:
					Visit(step.Next);
				case .If:
					Visit(step.Next);
					Visit(at + 1);
				case .Choice:
					for (int a = 1; a <= step.Count; a++)
						Visit(at + a);
				case .Jump, .End:
					break;
				default:
					Visit(at + 1);
				}
			}
			uint32 told = 0;
			for (int i < steps.Count)
			{
				let kind = steps[i].Kind;
				if (reached[i] || (kind == .Skip) || (kind == .End) || (kind == .Answer) || (steps[i].SourceLine == told))
					continue;
				told = steps[i].SourceLine;
				Problem(told, "nothing reaches this statement", true);
			}
		}
	}
}
