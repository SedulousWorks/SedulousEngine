using System;
using System.IO;

namespace Sedulous.Core.Logging;

/// Appends lines to a file.
///
/// Built on corlib's FileStream for now; when Core's own IO lands, that is the only
/// thing here that changes.
class FileLogger : BaseLogger
{
	private FileStream mFile = new .() ~ delete _;
	private bool mIsOpen;

	public this(StringView path, LogLevel minimumLogLevel,
		StringView name = Compiler.ProjectName, ILogFormatter formatter = null,
		bool ownsFormatter = false)
		: base(minimumLogLevel, name, formatter, ownsFormatter)
	{
		mIsOpen = mFile.Open(path, .OpenOrCreate, .Write, .Read) case .Ok;
		if (mIsOpen)
			mFile.Seek(0, .FromEnd);
	}

	public ~this()
	{
		if (mIsOpen)
			mFile.Close();
	}

	/// False when the path could not be opened. The logger then discards quietly rather
	/// than failing the caller, since a log that cannot write is not the caller's error
	/// to handle mid-frame.
	public bool IsOpen => mIsOpen;

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		if (!mIsOpen)
			return;
		let line = scope String(message);
		line.Append('\n');
		mFile.TryWrite(.((uint8*)line.Ptr, line.Length)).IgnoreError();
	}
}
