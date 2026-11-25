using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Resource;
using Sedulous.Run;
using Sedulous.Engine.Run;
using Sedulous.Engine.Behavior;

namespace Dialogue;

/// The run's own host for its runner: dialogue files and casts loaded through the application's
/// resources (each held while the run lives), flags and the resume record in the run's save,
/// `{Action}` filled from the player's bindings on the device in hand, and what the runner tells
/// the game published on the run's bus as DialogueLine, DialogueChoice, DialogueCommand and
/// DialogueEnded (a behavior's `on<Name>` hears them).
class DialogueRunHost : IDialogueHost
{
	private RunBase mRun; // BORROWED: the run holding the runner, which outlives it
	/// What this run loaded, held so it stays loaded while the run may read it again.
	private Dictionary<Guid, ResourceHold> mHolds = new .() ~ { for (let hold in _.Values) hold.Release(); delete _; };

	public this(RunBase run)
	{
		mRun = run;
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
		let resources = (Find(typeof(ResourceSource)) as ResourceSource)?.Manager;
		if ((resources == null) || (id == .()))
			return null;
		let proxy = resources.Bind<T>(id);
		let handle = proxy.Handle;
		if ((handle != null) && !mHolds.ContainsKey(id))
			mHolds[id] = new ResourceHold(handle);
		return proxy.Get;
	}

	public DialogueResource LoadDialogue(Guid id) => Load<DialogueResource>(id);
	public DialogueCastResource LoadCast(Guid id) => Load<DialogueCastResource>(id);

	public bool ReadFlag(StringView key)
	{
		let save = mRun.Get<RunSave>();
		return (save != null) && save.Values.GetBool(key, false);
	}

	public void WriteFlag(StringView key, bool on)
	{
		let save = mRun.Get<RunSave>();
		if ((save != null) && save.Values.SetBool(key, on))
			save.MarkChanged();
	}

	public void ReadText(StringView key, String outText)
	{
		if (let save = mRun.Get<RunSave>())
			outText.Append(save.Values.GetText(key, ""));
	}

	public void WriteText(StringView key, StringView text)
	{
		let save = mRun.Get<RunSave>();
		if (save == null)
			return;
		if (text.IsEmpty ? save.Values.Remove(key) : save.Values.SetText(key, text))
			save.MarkChanged();
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

	/// The staging comes with the run's scene; until then nothing is staged, and nothing waits on it.
	public uint32 Stage(DialogueStep step, DialogueCastResource cast) => 0;
	public bool IsStaging(uint32 token) => false;

	public void OnLine(DialogueLineNotice notice) => Publish(DialogueEvents.Line, notice);
	public void OnChoice(DialogueChoiceNotice notice) => Publish(DialogueEvents.Choice, notice);
	public void OnCommand(DialogueCommandNotice notice) => Publish(DialogueEvents.Command, notice);
	public void OnEnded(DialogueEndedNotice notice) => Publish(DialogueEvents.Ended, notice);

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
		mRunHost = new .(run);
		mHost = mRunHost;
	}
}

/// The contribution that gives every run its runner.
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

	/// The contribution, reading `settings` (the plugin's, which outlive it).
	public static RunServiceContribution Contribution(DialogueSettings settings)
	{
		sSettings = settings;
		return .("dialogue", typeof(DialogueRunService), => Install);
	}
}
