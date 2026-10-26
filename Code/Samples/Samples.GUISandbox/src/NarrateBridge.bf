using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.GUI;

namespace Samples.GUISandbox;

/// --narrate: a bridge that speaks to the console as a screen reader would aloud: each focus
/// change (what it reached, what it is, its value and states) and each announcement.
class NarrateBridge : IAccessibilityBridge
{
	/// Copies of the nodes the updates sent, by id (the bridge keeps what it needs).
	private Dictionary<uint64, AccessNode> mNodes = new .() ~ DeleteDictionaryAndValues!(_);
	private uint64 mFocus = 0;

	public bool IsListening => true;

	public void Update(AccessTreeUpdate update)
	{
		if (update.Full)
		{
			for (let node in mNodes.Values)
				delete node;
			mNodes.Clear();
		}
		for (let node in update.Nodes)
		{
			if (mNodes.TryGetValue(node.Id, var known))
			{
				known.Set(node);
				continue;
			}
			let copy = new AccessNode();
			copy.Set(node);
			mNodes[node.Id] = copy;
		}
		if (update.Focus == mFocus)
			return;
		mFocus = update.Focus;
		if (!mNodes.TryGetValue(update.Focus, var focused) || (focused.Role == .Window))
			return;
		let line = scope String();
		line.Append(focused.Name.IsEmpty ? "(no name)" : focused.Name);
		line.AppendF(", {}", AccessRoleName(focused.Role));
		if (!focused.Value.IsEmpty)
			line.AppendF(", {}", focused.Value);
		if ((focused.PositionInSet > 0) && (focused.SetSize > 0)) // "3 of 100000"
			line.AppendF(", {} of {}", focused.PositionInSet, focused.SetSize);
		if (focused.Level > 0)
			line.AppendF(", level {}", focused.Level);
		if (focused.Has(AccessSelected))
			line.Append(", selected");
		if (focused.Has(AccessChecked))
			line.Append(", checked");
		if (focused.Has(AccessCollapsed))
			line.Append(", collapsed");
		if (focused.Has(AccessExpanded))
			line.Append(", expanded");
		if (focused.Has(AccessDisabled))
			line.Append(", dimmed");
		if (!focused.Description.IsEmpty)
			line.AppendF(". {}", focused.Description);
		Console.WriteLine("narrate: {}", line);
	}

	public void Announce(StringView text, AnnouncePriority priority)
	{
		Console.WriteLine("narrate ({}): {}", (priority == .Assertive) ? "now" : "next", text);
	}
}

/// What warned or erred while the sweep ran: a logger beside the application's, counting.
class SweepLog : ILogger
{
	public uint32 Problems = 0;

	public LogLevel MinimumLogLevel { get; set; } = .Warning;
	public String Name { get; private set; } = new .("GUISandbox sweep") ~ delete _;

	public void Log(LogLevel logLevel, StringView format, params Object[] args)
	{
		if ((logLevel >= .Warning) && (logLevel < .None))
			Problems++;
	}
}
