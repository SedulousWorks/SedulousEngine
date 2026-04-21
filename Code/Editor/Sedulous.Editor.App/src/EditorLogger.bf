namespace Sedulous.Editor.App;

using System;
using System.Collections;
using System.Threading;
using Sedulous.Core.Logging.Abstractions;

/// Listener interface for receiving log messages from EditorLogger.
interface IEditorLogListener
{
	void OnLogMessage(Sedulous.Core.Logging.Abstractions.LogLevel level, StringView message);
}

/// Logger that forwards messages to the console and notifies registered listeners.
/// Used as the application-wide logger so all engine output can be captured
/// by the editor's log UI.
class EditorLogger : BaseLogger
{
	private Monitor mListenerLock = new .() ~ delete _;
	private List<IEditorLogListener> mListeners = new .() ~ delete _;

	public this(Sedulous.Core.Logging.Abstractions.LogLevel minimumLogLevel = .Information)
		: base(minimumLogLevel)
	{
	}

	public void AddListener(IEditorLogListener listener)
	{
		using (mListenerLock.Enter())
			mListeners.Add(listener);
	}

	public void RemoveListener(IEditorLogListener listener)
	{
		using (mListenerLock.Enter())
			mListeners.Remove(listener);
	}

	protected override void LogMessage(Sedulous.Core.Logging.Abstractions.LogLevel logLevel, StringView message)
	{
		// Console output (with color)
		var original = Console.ForegroundColor;
		Console.ForegroundColor = GetConsoleColor(logLevel);
		Console.WriteLine(message);
		Console.ForegroundColor = original;

		// Notify listeners
		using (mListenerLock.Enter())
		{
			for (let listener in mListeners)
				listener.OnLogMessage(logLevel, message);
		}
	}

	private static ConsoleColor GetConsoleColor(Sedulous.Core.Logging.Abstractions.LogLevel level)
	{
		switch (level)
		{
		case .Trace:       return .White;
		case .Debug:       return .Gray;
		case .Information: return .Blue;
		case .Warning:     return .Yellow;
		case .Error:       return .Red;
		case .Critical:    return .DarkRed;
		default:           return .White;
		}
	}
}

/// Buffers log messages from EditorLogger (thread-safe) and flushes them
/// to a LogView on the main thread each frame. Retains all messages until
/// the LogView is connected, so early startup logs are not lost.
class EditorLogBuffer : IEditorLogListener
{
	private struct BufferedEntry
	{
		public Sedulous.Core.Logging.Abstractions.LogLevel Level;
		public String Message;
	}

	private Monitor mLock = new .() ~ delete _;
	private List<BufferedEntry> mPending = new .() ~ { for (var e in _) delete e.Message; delete _; };
	private LogView mLogView;

	/// Connect the LogView. On first call, flushes all buffered history.
	public void SetLogView(LogView logView)
	{
		mLogView = logView;
		Flush();
	}

	/// Called by EditorLogger from any thread.
	public void OnLogMessage(Sedulous.Core.Logging.Abstractions.LogLevel level, StringView message)
	{
		using (mLock.Enter())
		{
			BufferedEntry entry;
			entry.Level = level;
			entry.Message = new String(message);
			mPending.Add(entry);
		}
	}

	/// Drain buffered messages to the LogView. Call once per frame on main thread.
	public void Flush()
	{
		if (mLogView == null) return;

		using (mLock.Enter())
		{
			for (let entry in mPending)
			{
				mLogView.AddEntry(MapLevel(entry.Level), entry.Message);
				delete entry.Message;
			}
			mPending.Clear();
		}
	}

	private static LogView.LogLevel MapLevel(Sedulous.Core.Logging.Abstractions.LogLevel level)
	{
		switch (level)
		{
		case .Trace, .Debug: return .Debug;
		case .Information:   return .Info;
		case .Warning:       return .Warning;
		case .Error,
			 .Critical:      return .Error;
		default:             return .Info;
		}
	}
}
