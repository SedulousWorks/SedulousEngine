using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Editor.App;

/// What agents did through the editor's MCP host in this run, for the MCP panel and the status
/// bar. Each tools/call is one entry, added when the host reports it and updated as it finishes,
/// with its arguments, its answer, how long it took and whether its tool changes authored data;
/// between them sit the host's own events (it started, it stopped, a client connected). It is kept
/// in memory only, outlives the host's restarts, and is capped (the oldest trimmed).
class McpActivity
{
	public const int cMaxEntries = 500;

	public enum Kind : uint8
	{
		/// A tools/call.
		Call,
		/// The host's own: started, stopped, a client connected.
		Event,
	}

	public enum Outcome : uint8
	{
		Running,
		Done,
		Failed,
		/// Its caller went away, or the host stopped, before it answered.
		Abandoned,
		/// No tool ran: an unknown tool, or arguments its schema refuses.
		Refused,
	}

	public class Entry
	{
		/// This record's number, unique for the editor's run.
		public uint64 Id;
		public Kind Kind = .Call;
		public Outcome Outcome = .Done;
		/// A call's tool; an event's text.
		public String Tool = new .() ~ delete _;
		/// Compact JSON.
		public String Arguments = new .() ~ delete _;
		/// The answer's text: its JSON, or the error message.
		public String Result = new .() ~ delete _;
		/// Its tool creates, overwrites or deletes authored data.
		public bool Changes;
		/// When it started, in local seconds since 1970 (CivilTimeOf reads it).
		public int64 At;
		/// How long it took (so far, while running).
		public TimeSpan Elapsed;

		public bool IsCall => Kind == .Call;
	}

	private struct InFlight
	{
		/// The entry's.
		public uint64 Id;
		/// The server's.
		public uint64 Serial;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	private List<InFlight> mInFlight = new .() ~ delete _;
	private uint64 mNextId = 1;
	private uint64 mRevision = 0;

	/// Records one report of the host's server. `at` is the local time it arrived. Started and an
	/// at-once Finished add an entry; a later Finished or Abandoned updates its own.
	public void Record(ToolCallReport report, int64 at)
	{
		var entry = (report.Phase == .Started) ? null : FindRunning(report.Serial);
		if (entry == null)
		{
			if (report.Phase == .Abandoned)
				return; // never heard Started: nothing to close
			let added = new Entry();
			added.Kind = .Call;
			added.Tool.Set(report.Tool);
			if (report.Arguments != null)
				report.Arguments.ToString(added.Arguments);
			else
				added.Arguments.Set("{}");
			added.Changes = (report.Phase != .Refused) && report.Annotations.ChangesAuthoredData;
			added.At = at - (int64)report.Elapsed.TotalSeconds;
			entry = Add(added);
			var call = InFlight();
			call.Id = entry.Id;
			call.Serial = report.Serial;
			mInFlight.Add(call);
		}
		entry.Elapsed = report.Elapsed;
		switch (report.Phase)
		{
		case .Started:
			entry.Outcome = .Running;
			return; // stays running
		case .Finished:
			entry.Outcome = report.IsError ? .Failed : .Done;
			entry.Result.Set(report.Result);
		case .Abandoned:
			entry.Outcome = .Abandoned;
		case .Refused:
			entry.Outcome = .Refused;
			entry.Result.Set(report.Result);
		}
		ForgetRunning(entry.Id);
		mRevision++;
	}

	/// Records one of the host's own events ("Listening on 127.0.0.1:7405", "Stopped").
	public void RecordEvent(StringView text, int64 at)
	{
		let added = new Entry();
		added.Kind = .Event;
		added.Tool.Set(text);
		added.At = at;
		Add(added);
	}

	/// The host stopped: its calls still running end unanswered, and the stop is recorded. The
	/// server's serials start again with the next host, so none is kept.
	public void HostStopped(int64 at)
	{
		for (let call in mInFlight)
		{
			if (let entry = FindEntry(call.Id))
				entry.Outcome = .Abandoned;
		}
		mInFlight.Clear();
		RecordEvent("Stopped", at);
	}

	public void Clear()
	{
		ClearAndDeleteItems!(mEntries);
		mInFlight.Clear();
		mRevision++;
	}

	public int Count => mEntries.Count;
	/// The entries oldest first. BORROWED.
	public Entry this[int index] => mEntries[index];

	public Entry FindById(uint64 id) => FindEntry(id);

	/// The newest call still running, or null.
	public Entry RunningCall => mInFlight.IsEmpty ? null : FindEntry(mInFlight.Back.Id);

	/// The newest call, or null.
	public Entry LastCall
	{
		get
		{
			for (int i = mEntries.Count - 1; i >= 0; i--)
			{
				if (mEntries[i].IsCall)
					return mEntries[i];
			}
			return null;
		}
	}

	/// Changes with every record, so a view knows when to refresh.
	public uint64 Revision => mRevision;

	/// Summary cut at 160.
	public static void Summary(Entry entry, String outText) => Summary(entry, 160, outText);

	/// One line saying what a call was about, for its row, appended: a failure's or a refusal's
	/// first line, else its arguments as `name: value` pairs (strings bare, the rest as JSON), cut
	/// at `maxLength`.
	public static void Summary(Entry entry, int maxLength, String outText)
	{
		let text = scope String();
		if (!entry.IsCall)
			text.Set(entry.Tool);
		else if ((entry.Outcome == .Failed) || (entry.Outcome == .Refused))
		{
			let end = entry.Result.IndexOf('\n');
			text.Set((end < 0) ? StringView(entry.Result) : StringView(entry.Result, 0, end));
		}
		else
		{
			let parsed = JsonValue.Parse(entry.Arguments);
			defer delete parsed;
			if ((parsed != null) && parsed.IsObject)
			{
				for (int i < parsed.Count)
				{
					let key = parsed.KeyAt(i);
					let value = parsed.Get(key);
					if (!text.IsEmpty)
						text.Append(", ");
					text.Append(key);
					text.Append(": ");
					if (value.IsString)
						text.Append(value.AsString());
					else
						value.ToString(text);
					if (text.Length > maxLength)
						break;
				}
			}
		}
		if (text.Length > maxLength)
		{
			var cut = maxLength;
			while ((cut > 0) && (((uint8)text[cut] & 0xC0) == 0x80))
				cut--; // never inside a character
			text.RemoveToEnd(cut);
			text.Append("...");
		}
		outText.Append(text);
	}

	private Entry Add(Entry entry)
	{
		entry.Id = mNextId++;
		mEntries.Add(entry);
		while (mEntries.Count > cMaxEntries)
		{
			ForgetRunning(mEntries[0].Id);
			delete mEntries[0];
			mEntries.RemoveAt(0);
		}
		mRevision++;
		return entry;
	}

	private Entry FindEntry(uint64 id)
	{
		for (let entry in mEntries)
		{
			if (entry.Id == id)
				return entry;
		}
		return null;
	}

	private Entry FindRunning(uint64 serial)
	{
		for (let call in mInFlight)
		{
			if (call.Serial == serial)
				return FindEntry(call.Id);
		}
		return null;
	}

	private void ForgetRunning(uint64 id)
	{
		for (int i < mInFlight.Count)
		{
			if (mInFlight[i].Id == id)
			{
				mInFlight.RemoveAt(i);
				return;
			}
		}
	}
}
