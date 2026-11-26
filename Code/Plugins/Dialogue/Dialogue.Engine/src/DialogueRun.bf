using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Script;
using Sedulous.Input;
using Sedulous.Resource;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Sequence.Resource;
using Sedulous.Audio.Resource;
using Sedulous.Engine.Run;
using Sedulous.Engine.Behavior;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Render;
using Sedulous.Engine.Sequence;
using Sedulous.Engine.Script.Facades;
using Sedulous.Engine.GUI;
using Sedulous.GUI.Resources;

namespace Dialogue;

/// The run's own host for its runner: dialogue files and casts loaded through the application's
/// resources (each held while the run lives), flags and the resume record in the run's save,
/// `{Action}` filled from the player's bindings on the device in hand, and what the runner tells
/// the game published on the run's bus as DialogueLine, DialogueChoice, DialogueCommand and
/// DialogueEnded (a behavior's `on<Name>` hears them).
///
/// The staging is in the run's current scene. A speaker plays as an entity: the one the game bound
/// to it (Bind), else the level entity the cast names, else none (told once).
///   * `play`: the clip once over what the entity animates (the animation's one-shot).
///   * `sound`: the clip or cue through the run's audio, at the speaker's entity when named.
///   * `fade`: a claim on the scene's fade, over the sequences' own, held at full until a fade in.
///   * `sequence`: a play in the scene, each of its bindings named for a speaker filled with that
///     speaker's entity, and one named for no speaker with the level entity of its name; `and wait`
///     holds until it ends.
/// While a line shows, its speaker plays their talk clip (the cast's `Talk`), looping, and their
/// voice (the cast's `Voice`) once as it starts.
///
/// A run with no save (an editor page's) keeps flags and the resume record in a store of the
/// host's own, dropped with it. A preview (the dialogue page's) plays a file's text as it is edited
/// (SetDialogue) and stages in the scene it names (SetScene).
///
/// With the settings' `StockBox` on, the host shows what it tells the game in the plugin's own box
/// as well (DialogueStockBox), on the run's screen stack, and takes the player's advance and answers
/// from it.
class DialogueRunHost : IDialogueHost
{
	private struct Staged
	{
		public uint32 Token;
		public DialogueStepKind Kind;
		/// A one-shot's.
		public EntityHandle Entity;
		/// A sequence's.
		public uint32 Play;
	}

	private DialogueSettings mSettings; // BORROWED: the plugin's, which outlive the run
	private RunBase mRun; // BORROWED: the run holding the runner, which outlives it
	/// What this run loaded, held so it stays loaded while the run may read it again.
	private Dictionary<Guid, ResourceHold> mHolds = new .() ~ { for (let hold in _.Values) hold.Release(); delete _; };
	/// The game's bindings: a speaker's id, and the entity that plays them.
	private List<(String speaker, EntityHandle entity)> mBindings = new .() ~ { for (let binding in _) delete binding.speaker; delete _; };
	/// The speakers told to have no entity.
	private List<String> mUnplaced = new .() ~ DeleteContainerAndItems!(_);
	private List<Staged> mStaged = new .() ~ delete _;
	private uint32 mNextToken = 1;
	// The fade: its claim's scene, where it is and where it goes, and its token while it moves.
	private ScriptWeakRef mFadeScene;
	private Float4 mFadeColor = .(0.0f, 0.0f, 0.0f, 1.0f);
	private float mFadeAmount = 0.0f;
	private float mFadeFrom = 0.0f;
	private float mFadeTo = 0.0f;
	private float mFadeSeconds = 0.0f;
	private float mFadeTime = 0.0f;
	private uint32 mFadeToken = 0;
	private DialogueStockBox mBox ~ delete _;
	private DialogueRunner mRunner;
	// The speaker talking while their line shows.
	private ScriptWeakRef mTalkScene;
	private EntityHandle mTalker = .Invalid;
	/// The file SetDialogue replaces, and what plays in its place.
	private Guid mPreviewId = .();
	private DialogueResource mPreview = null ~ delete _;
	/// SetScene's.
	private ScriptWeakRef mScene;
	private bool mHasScene = false;
	private bool mShowBox = false;
	/// The store of a run with no save.
	private Dictionary<String, String> mScratch = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

	public this(DialogueSettings settings, RunBase run)
	{
		mSettings = settings;
		mRun = run;
		mBox = new .(settings);
	}

	/// The runner the stock box advances and answers (BORROWED: the one holding this host).
	public void SetRunner(DialogueRunner runner) => mRunner = runner;
	public DialogueStockBox Box => mBox;

	/// Loads `resource` (TAKEN) for the dialogue file `id` in place of its cooked form (a preview of
	/// its text as it is edited); null goes back to the cooked one.
	public void SetDialogue(Guid id, DialogueResource resource)
	{
		if (mPreview != resource)
			delete mPreview;
		mPreviewId = id;
		mPreview = resource;
	}

	/// Shows the stock box whatever the settings say (a preview).
	public void ShowStockBox(bool show) => mShowBox = show;

	/// Stages in `scene` rather than the run's current scene (null: the run's again).
	public void SetScene(Scene scene)
	{
		mScene = (scene != null) ? scene.TakeScriptWeak() : default;
		mHasScene = scene != null;
	}

	private bool BoxOn => mShowBox || mSettings.StockBox;

	public ~this()
	{
		StopTalking();
		ReleaseFade();
	}

	private ResourceManager Resources => (Find(typeof(ResourceSource)) as ResourceSource)?.Manager;
	private Scene CurrentScene => mHasScene ? (mScene.Resolve() as Scene) : mRun.Get<ApplicationRun>()?.CurrentScene;

	/// Plays the speaker `speaker` as `entity` in what follows (invalid: the cast's again).
	public void Bind(StringView speaker, EntityHandle entity)
	{
		for (int i < mBindings.Count)
		{
			if (mBindings[i].speaker != speaker)
				continue;
			if (entity.IsAssigned)
			{
				mBindings[i].entity = entity;
			}
			else
			{
				delete mBindings[i].speaker;
				mBindings.RemoveAt(i);
			}
			return;
		}
		if (entity.IsAssigned)
			mBindings.Add((new String(speaker), entity));
	}

	// Whether the game bound `speaker`.
	private bool IsBound(StringView speaker)
	{
		for (let binding in mBindings)
		{
			if (binding.speaker == speaker)
				return true;
		}
		return false;
	}

	// The entity that plays `speaker` (`entry` its cast entry, null for none) in `scene`: the
	// game's binding, else the entity the cast names; invalid, told once, when none.
	private EntityHandle EntityOf(Scene scene, StringView speaker, DialogueSpeaker entry)
	{
		for (let binding in mBindings)
		{
			if ((binding.speaker == speaker) && scene.IsValid(binding.entity))
				return binding.entity;
		}
		if ((entry != null) && !entry.Entity.IsEmpty)
		{
			let entity = scene.FindEntityByName(entry.Entity);
			if (entity.IsAssigned)
				return entity;
		}
		for (let told in mUnplaced)
		{
			if (told == speaker)
				return .Invalid;
		}
		mUnplaced.Add(new .(speaker));
		GlobalLog(.Warning, "Dialogue: the speaker `{}` has no entity in the scene: bind one or name one in the cast", speaker);
		return .Invalid;
	}

	// The service the run's scripts would find of type `type`: the run's, then the application's.
	private Object Find(Type type)
	{
		if (let scripts = mRun.Get<BehaviorRunHost>())
			return scripts.FindService(type);
		return mRun.FindService(type);
	}

	private T Load<T>(Guid id) where T : class
	{
		let resources = Resources;
		if ((resources == null) || (id == .()))
			return null;
		let proxy = resources.Bind<T>(id);
		let handle = proxy.Handle;
		if ((handle != null) && !mHolds.ContainsKey(id))
			mHolds[id] = new ResourceHold(handle);
		return proxy.Get;
	}

	public DialogueResource LoadDialogue(Guid id)
	{
		if ((mPreview != null) && (id == mPreviewId))
			return mPreview;
		return Load<DialogueResource>(id);
	}
	public DialogueCastResource LoadCast(Guid id) => Load<DialogueCastResource>(id);

	public bool ReadFlag(StringView key)
	{
		let save = mRun.Get<RunSave>();
		if (save == null)
			return Scratch(key) == "true";
		return save.Values.GetBool(key, false);
	}

	public void WriteFlag(StringView key, bool on)
	{
		let save = mRun.Get<RunSave>();
		if (save == null)
			WriteScratch(key, on ? "true" : "false");
		else if (save.Values.SetBool(key, on))
			save.MarkChanged();
	}

	public void ReadText(StringView key, String outText)
	{
		if (let save = mRun.Get<RunSave>())
			outText.Append(save.Values.GetText(key, ""));
		else
			outText.Append(Scratch(key));
	}

	public void WriteText(StringView key, StringView text)
	{
		let save = mRun.Get<RunSave>();
		if (save == null)
		{
			WriteScratch(key, text);
			return;
		}
		if (text.IsEmpty ? save.Values.Remove(key) : save.Values.SetText(key, text))
			save.MarkChanged();
	}

	// The store of a run with no save: `key`'s value, empty when it has none.
	private StringView Scratch(StringView key)
	{
		if (mScratch.TryGetAlt(key, ?, let value))
			return value;
		return "";
	}

	// Sets `key` to `value` in the store of a run with no save (empty removes it).
	private void WriteScratch(StringView key, StringView value)
	{
		if (mScratch.TryGetAlt(key, let stored, let current))
		{
			if (value.IsEmpty)
			{
				mScratch.Remove(stored);
				delete stored;
				delete current;
			}
			else
				current.Set(value);
			return;
		}
		if (!value.IsEmpty)
			mScratch[new .(key)] = new .(value);
	}

	public void ActionLabel(StringView action, String outLabel)
	{
		let runtime = Find(typeof(ActionRuntime)) as ActionRuntime;
		if (runtime == null)
			return;
		let kinds = Find(typeof(InputKindTracker)) as InputKindTracker;
		let kind = (kinds != null) ? kinds.Kind : InputKind.Pointer;
		if (let binding = ShownBinding.For(runtime, action, "", kind))
			BindingNames.DescribeBinding(binding, outLabel);
	}

	public uint32 Stage(DialogueStep step, DialogueCastResource cast)
	{
		let scene = CurrentScene;
		if (scene == null)
			return 0;
		switch (step.Kind)
		{
		case .Play:
			let entity = EntityOf(scene, step.Speaker, cast?.Find(step.Speaker));
			if (!entity.IsAssigned || (step.Asset == .()))
				return 0;
			if (mTalker == entity)
				mTalker = .Invalid; // the clip takes over from the talk
			SceneFacades.Resolve<AnimationFacade>(scene).PlayOneShot(entity, step.Asset);
			let token = mNextToken++;
			Staged staged = .();
			staged.Token = token;
			staged.Kind = step.Kind;
			staged.Entity = entity;
			mStaged.Add(staged);
			return token;
		case .Sound:
			let resources = Resources;
			let audio = Find(typeof(AudioFacade)) as AudioFacade;
			if ((resources == null) || (audio == null) || (step.Asset == .()))
				return 0;
			let instance = resources.Database.GetInstance(step.Asset);
			let cue = (instance != null) && (instance.TypeName == typeof(SoundCueSource).GetFullName(.. scope .()));
			let at = step.Speaker.IsEmpty ? EntityHandle.Invalid : EntityOf(scene, step.Speaker, cast?.Find(step.Speaker));
			if (at.IsAssigned)
			{
				let position = scene.GetWorldPosition(at);
				if (cue)
					audio.PlayCue3D(step.Asset, position);
				else
					audio.PlayOneShot3D(step.Asset, position);
			}
			else if (cue)
			{
				audio.PlayCue(step.Asset);
			}
			else
			{
				audio.PlayOneShot(step.Asset);
			}
			return 0; // a sound never holds the conversation
		case .Fade:
			mFadeScene = scene.TakeScriptWeak();
			mFadeColor = step.HasColor ? step.Color : mSettings.FadeColor;
			// A fade in from nothing held starts at full: a conversation that opens on one.
			mFadeFrom = (step.FadeIn && (mFadeAmount <= 0.0f)) ? 1.0f : mFadeAmount;
			mFadeTo = step.FadeIn ? 0.0f : 1.0f;
			mFadeSeconds = (step.Seconds >= 0.0f) ? step.Seconds : mSettings.FadeSeconds;
			mFadeTime = 0.0f;
			mFadeToken = mNextToken++;
			UpdateFade(0.0f);
			return mFadeToken;
		case .Sequence:
			let system = scene.GetSystem<SequenceSystem>();
			let sequence = Load<SequenceResource>(step.Asset);
			if ((system == null) || (sequence == null))
			{
				GlobalLog(.Warning, "Dialogue: sequence: `{}` did not load", step.Name);
				return 0;
			}
			// Each of its bindings named for a speaker is that speaker's entity; one named for no
			// speaker is the level entity of its name (a prop the scene moves: a cart, a door).
			let filled = scope List<(StringView name, EntityHandle entity)>();
			for (let binding in sequence.Sequence.Bindings)
			{
				let speaker = cast?.Find(binding.Name);
				let entity = ((speaker != null) || IsBound(binding.Name)) ? EntityOf(scene, binding.Name, speaker) : scene.FindEntityByName(binding.Name);
				if (entity.IsAssigned)
					filled.Add((binding.Name, entity));
			}
			let play = system.Play(sequence, step.Asset, .Release, .Invalid, mHolds.GetValueOrDefault(step.Asset)?.Handle,
				scope (running) =>
				{
					for (let binding in filled)
						running.Bind(binding.name, binding.entity);
				});
			let token = mNextToken++;
			Staged staged = .();
			staged.Token = token;
			staged.Kind = step.Kind;
			staged.Play = play;
			mStaged.Add(staged);
			return token;
		default:
			return 0;
		}
	}

	public bool IsStaging(uint32 token)
	{
		if ((token != 0) && (token == mFadeToken))
			return true;
		for (int i < mStaged.Count)
		{
			if (mStaged[i].Token != token)
				continue;
			bool going = false;
			if (let scene = CurrentScene)
			{
				if (mStaged[i].Kind == .Play)
				{
					going = scene.IsValid(mStaged[i].Entity) && SceneFacades.Resolve<AnimationFacade>(scene).IsPlayingOneShot(mStaged[i].Entity);
				}
				else if (let system = scene.GetSystem<SequenceSystem>())
				{
					let play = system.Find(mStaged[i].Play);
					going = (play != null) && !play.IsFinished;
				}
			}
			if (!going)
				mStaged.RemoveAt(i);
			return going;
		}
		return false;
	}

	/// The fade's clock, then the stock box's: its typing, and what the player pressed in it.
	public void Update(float deltaTime)
	{
		UpdateFade(deltaTime);
		if (!BoxOn || !mBox.IsShown || (mRunner == null))
			return;
		bool pressed = false;
		if (let input = Find(typeof(ActionRuntime)) as ActionRuntime)
			pressed = input.WasPressed(input.Resolve(mSettings.AdvanceAction));
		let request = mBox.Update(deltaTime, pressed);
		if (request.Choose >= 0)
			mRunner.Choose(request.Choose);
		else if (request.Advance)
			mRunner.Advance();
	}

	// The box's sheet: the project's (`StockBoxSheet`) when it loads, else the plugin's.
	private void BoxSheet(String outCss)
	{
		if (mSettings.StockBoxSheet != .())
		{
			if (let sheet = Load<GuiStyleSheet>(mSettings.StockBoxSheet))
			{
				outCss.Append(sheet.Css);
				return;
			}
		}
		outCss.Append(DialogueStockBox.cSheet);
	}

	// The GUI and the run's screen stack the box goes on; false when there are none.
	private bool BoxPlace(out GuiSubsystem gui, out Sedulous.GUI.ScreenStack stack)
	{
		gui = mRun.Get<BehaviorRunHost>()?.Subsystems?.GetSubsystem<GuiSubsystem>();
		stack = gui?.ScreensFor(mRun);
		return stack != null;
	}

	private void UpdateFade(float deltaTime)
	{
		if (mFadeToken == 0)
			return;
		mFadeTime += deltaTime;
		let t = (mFadeSeconds > 0.0f) ? Math.Min(1.0f, mFadeTime / mFadeSeconds) : 1.0f;
		mFadeAmount = mFadeFrom + (mFadeTo - mFadeFrom) * t;
		if (t >= 1.0f)
			mFadeToken = 0;
		let post = (mFadeScene.Resolve() as Scene)?.GetSystem<PostProcessSystem>();
		if (post == null)
			return;
		if ((mFadeAmount <= 0.0f) && (mFadeToken == 0))
		{
			post.FadeClaims.Release(this); // faded in: nothing held
			return;
		}
		// Over the sequences' fades: what a conversation fades to holds until it fades in again.
		post.FadeClaims.Claim(this, uint64.MaxValue, ScreenFade(Color(mFadeColor.X, mFadeColor.Y, mFadeColor.Z, mFadeColor.W), mFadeAmount));
	}

	private void ReleaseFade()
	{
		if (let post = (mFadeScene.Resolve() as Scene)?.GetSystem<PostProcessSystem>())
			post.FadeClaims.Release(this);
		mFadeToken = 0;
		mFadeAmount = 0.0f;
	}

	private void StopTalking()
	{
		let scene = mTalkScene.Resolve() as Scene;
		if ((scene != null) && mTalker.IsAssigned && scene.IsValid(mTalker))
			SceneFacades.Resolve<AnimationFacade>(scene).StopOneShot(mTalker);
		mTalker = .Invalid;
	}

	public void OnLine(DialogueLineNotice notice, DialogueSpeaker speaker)
	{
		StopTalking();
		if ((speaker != null) && (speaker.Voice != .()))
			(Find(typeof(AudioFacade)) as AudioFacade)?.PlayOneShot(speaker.Voice);
		if (BoxOn && BoxPlace(let gui, let stack))
			mBox.ShowLine(gui, stack, BoxSheet(.. scope .()), notice, speaker);
		let scene = CurrentScene;
		if ((scene != null) && (speaker != null) && (speaker.Talk != .()))
		{
			let entity = EntityOf(scene, notice.Speaker, speaker);
			if (entity.IsAssigned)
			{
				SceneFacades.Resolve<AnimationFacade>(scene).PlayOneShot(entity, speaker.Talk, 1.0f, 0.2f, 0.2f, -1);
				mTalkScene = scene.TakeScriptWeak();
				mTalker = entity;
			}
		}
		Publish(DialogueEvents.Line, notice);
	}

	public void OnLineEnded() => StopTalking();
	public void OnChoice(DialogueChoiceNotice notice)
	{
		if (BoxOn && BoxPlace(let gui, let stack))
			mBox.ShowChoice(gui, stack, BoxSheet(.. scope .()), notice);
		Publish(DialogueEvents.Choice, notice);
	}
	public void OnCommand(DialogueCommandNotice notice)
	{
		// An entity argument is looked for in the run's scene, as it is now.
		if (let scene = CurrentScene)
			notice.Scene = scene.TakeScriptWeak();
		Publish(DialogueEvents.Command, notice);
	}
	public void OnEnded(DialogueEndedNotice notice)
	{
		mBox.Hide();
		Publish(DialogueEvents.Ended, notice);
	}

	// The bus owns the notice from here, and deletes it once delivered.
	private void Publish<T>(StringView name, T notice) where T : class
	{
		mRun.Events.Publish(StringHash(name), Variant.Create(notice, true));
	}
}

/// The runner a run holds, with the run's host (`run.Get<DialogueRunService>()`).
class DialogueRunService : DialogueRunner
{
	private DialogueRunHost mRunHost ~ delete _;

	public this(DialogueSettings settings, RunBase run) : base(settings, null)
	{
		mRunHost = new .(settings, run);
		mRunHost.SetRunner(this);
		mHost = mRunHost;
	}

	/// The stock box (for tests).
	public DialogueStockBox Box => mRunHost.Box;
	/// The run's host, for a preview's hooks (SetDialogue, SetScene, ShowStockBox).
	public DialogueRunHost Host => mRunHost;

	/// Plays the speaker `speaker` as `entity` (invalid: the cast's entity again).
	public void Bind(StringView speaker, EntityHandle entity) => mRunHost.Bind(speaker, entity);
}

/// The contributions that give every run its runner, and its `Dialogue` script service.
static class DialogueRun
{
	// The plugin's settings, which the contribution's install reads: set as the contribution is
	// made, and read only while it is installed, which ends as the plugin unloads.
	private static DialogueSettings sSettings;

	private static void Install(RunBase run)
	{
		if (sSettings != null)
			run.Add(new DialogueRunService(sSettings, run));
	}

	/// The runner's contribution, reading `settings` (the plugin's, which outlive it).
	public static RunServiceContribution Contribution(DialogueSettings settings)
	{
		sSettings = settings;
		return .("dialogue", typeof(DialogueRunService), => Install);
	}

	private static void InstallFacade(RunBase run) => run.Add(new DialogueFacade(run));

	/// The `Dialogue` script service's contribution: each run's, reaching its runner.
	public static RunServiceContribution FacadeContribution => .("dialogue.facade", typeof(DialogueFacade), => InstallFacade);
}
