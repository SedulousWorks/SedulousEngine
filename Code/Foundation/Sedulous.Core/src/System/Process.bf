using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Threading;
using Sedulous.Core.IO;

namespace Sedulous.Core;

/// Running a child process to completion.
static class Process
{
	/// Cook diagnostics are small, and this caps a runaway tool without truncating a real
	/// error.
	private const int cMaxOutputBytes = 64 * 1024;
	private const int cReadChunk = 4096;
	/// How long RunStreaming waits for a line before it asks its cancel check again.
	private const int cCancelPollMs = 50;

	/// Runs `executable` with `arguments` and BLOCKS until it exits, capturing its combined
	/// standard output and standard error.
	///
	/// An explicit path, with no shell and no PATH search, and each argument passed whole.
	/// That is what makes it safe to hand a caller supplied path: nothing in it is
	/// interpreted.
	///
	/// For cook time tool invocations. Do NOT call it on a thread that must stay responsive.
	public static void Run(StringView executable, Span<StringView> arguments,
		ProcessResult outResult)
	{
		outResult.ExitCode = -1;
		outResult.Output.Clear();

		let startInfo = scope ProcessStartInfo();
		Redirected(executable, arguments, startInfo);

		let process = scope SpawnedProcess();
		if (process.Start(startInfo) case .Err)
		{
			// The exit code stays negative, which is how a caller tells "could not start it"
			// from "ran and refused".
			outResult.Output.AppendF("could not start {}", executable);
			return;
		}

		// The attached streams READ the child's pipes; they are not a redirect into a file.
		let standardOutput = scope System.IO.FileStream();
		let standardError = scope System.IO.FileStream();
		let haveOutput = process.AttachStandardOutput(standardOutput) case .Ok;
		let haveError = process.AttachStandardError(standardError) case .Ok;

		// Drained BEFORE waiting: a child that fills its pipe blocks until someone reads,
		// and waiting first would deadlock against exactly the tool whose diagnostic is
		// wanted.
		//
		// CONCURRENTLY, one thread per pipe, because these reads BLOCK. Reading them by
		// turns instead deadlocks the moment a child writes hard to one and stays silent on
		// the other: the turn to read the quiet pipe never returns, and the busy one fills.
		// Pointing both of the child's descriptors at ONE pipe would avoid this, but Beef's
		// process API gives two, so they get drained in parallel to the same effect. tint is
		// the specimen - it prints whole shaders to stdout and nothing to stderr, and hung the
		// cook on the first file bigger than a pipe buffer.
		let errorText = scope String();
		let errorStream = haveError ? standardError : null;
		let outputStream = haveOutput ? standardOutput : null;

		let errorDrain = scope Thread(new [&errorStream, &errorText]() =>
			{
				Drain(errorStream, errorText);
			});
		errorDrain.Start(false);
		Drain(outputStream, outResult.Output);
		errorDrain.Join();

		// Appended rather than interleaved: two pipes cannot be merged after the fact, and a
		// caller wants the whole diagnostic, not its exact ordering.
		if (!errorText.IsEmpty)
		{
			let room = cMaxOutputBytes - outResult.Output.Length;
			if (room > 0)
				outResult.Output.Append(errorText, 0, Math.Min(errorText.Length, room));
		}

		process.WaitFor(-1);
		outResult.ExitCode = process.ExitCode;
	}

	/// Runs `executable` with `arguments` and BLOCKS until it exits, handing each line of its
	/// standard output and standard error to `onLine` as it arrives: what a caller needs to show
	/// a long build as it runs, which Run (all of it at the end) cannot.
	///
	/// No shell and no PATH search, each argument passed whole, as Run's. `onLine` is called on
	/// the calling thread only, one line at a time, without its line ending; the two pipes are
	/// read side by side, so their lines come in the order they arrived, as far as two pipes
	/// can tell. A line with no ending is handed on once it reaches cMaxOutputBytes.
	///
	/// `cancelled` is asked between lines, and at least every cCancelPollMs while the child is
	/// silent: once it says true, the child and every process under it (a build's compiler and
	/// linker) are killed, the lines already read are still handed on, and the result is
	/// Cancelled. Otherwise the child's exit code, or NotFound when it could not be started.
	public static Result<int, ErrorCode> RunStreaming(StringView executable, Span<StringView> arguments,
		delegate void(StringView line) onLine, delegate bool() cancelled = null)
	{
		let startInfo = scope ProcessStartInfo();
		Redirected(executable, arguments, startInfo);

		let process = scope SpawnedProcess();
		if (process.Start(startInfo) case .Err)
			return .Err(.NotFound);

		let standardOutput = scope System.IO.FileStream();
		let standardError = scope System.IO.FileStream();
		let outputStream = (process.AttachStandardOutput(standardOutput) case .Ok) ? standardOutput : null;
		let errorStream = (process.AttachStandardError(standardError) case .Ok) ? standardError : null;

		// One reader per pipe, for Run's reason: the reads block, and a child busy on one pipe
		// would otherwise stall behind a read of the quiet one. The readers only queue lines;
		// this thread hands them on, so `onLine` never runs on two threads at once.
		let queue = scope LineQueue();
		queue.Open = 2;
		let outputReader = scope Thread(new [&outputStream, &queue]() =>
			{
				ReadLines(outputStream, queue);
			});
		let errorReader = scope Thread(new [&errorStream, &queue]() =>
			{
				ReadLines(errorStream, queue);
			});
		outputReader.Start(false);
		errorReader.Start(false);

		bool killed = false;
		let lines = scope List<String>();
		while (queue.Take(lines))
		{
			for (let line in lines)
				onLine(line);
			let quiet = lines.IsEmpty;
			ClearAndDeleteItems!(lines);
			if (!killed && (cancelled != null) && cancelled())
			{
				// The children too: killing BeefBuild alone leaves its linker holding the pipes
				// open, and the readers would wait on it.
				process.Kill(1, .KillChildren);
				killed = true;
			}
			if (quiet)
				queue.Arrived.WaitFor(cCancelPollMs);
		}
		outputReader.Join();
		errorReader.Join();

		process.WaitFor(-1);
		if (killed)
			return .Err(.Cancelled);
		return .Ok(process.ExitCode);
	}

	/// RunStreaming, cancelled through `cancel` (null never cancels).
	public static Result<int, ErrorCode> RunStreaming(StringView executable, Span<StringView> arguments,
		delegate void(StringView line) onLine, CancelToken cancel)
	{
		return RunStreaming(executable, arguments, onLine, scope () => CancelToken.Requested(cancel));
	}

	/// Starts `executable` with `arguments` and returns without waiting: the child runs on its
	/// own, its output going where the parent's does. An explicit path, each argument passed
	/// whole, as Run's. False when it could not be started.
	public static bool Start(StringView executable, Span<StringView> arguments)
	{
		let startInfo = scope ProcessStartInfo();
		startInfo.SetFileName(executable);
		startInfo.SetArguments(QuotedArguments(arguments, .. scope .()));
		startInfo.UseShellExecute = false;
		let process = scope SpawnedProcess();
		return process.Start(startInfo) case .Ok;
	}

	/// Reads ONE pipe to its end.
	///
	/// Its own caller runs a second copy of this on another thread for the other pipe; see
	/// Run for why they cannot share one.
	private static void Drain(System.IO.FileStream stream, String outText)
	{
		if (stream == null)
			return;

		let chunk = scope uint8[cReadChunk];
		while (ReadChunk(stream, chunk, outText)) {}
	}

	/// Appends one chunk, returning whether the stream still has more.
	private static bool ReadChunk(System.IO.FileStream stream, Span<uint8> chunk, String outText)
	{
		switch (stream.TryRead(chunk))
		{
		case .Ok(let read):
			if (read <= 0)
				return false;
			// Capped rather than truncated mid-read: the cap exists to bound a runaway
			// tool, and the first 64 KiB is where a real diagnostic is.
			let room = cMaxOutputBytes - outText.Length;
			if (room > 0)
				outText.Append(StringView((char8*)chunk.Ptr, Math.Min(read, room)));
			return true;
		case .Err:
			return false;
		}
	}

	/// The lines of a streamed run: each pipe's reader adds them under the lock, and the caller
	/// takes them on its own thread.
	private class LineQueue
	{
		public Monitor Lock = new .() ~ delete _;
		public List<String> Lines = new .() ~ DeleteContainerAndItems!(_);
		/// Set at each line and at each pipe's end, so the caller's wait ends early.
		public WaitEvent Arrived = new .() ~ delete _;
		/// The pipes still being read, under Lock.
		public int Open;

		public void Add(StringView line)
		{
			using (Lock.Enter())
				Lines.Add(new .(line));
			Arrived.Set();
		}

		/// A reader's pipe has ended.
		public void Close()
		{
			using (Lock.Enter())
				Open--;
			Arrived.Set();
		}

		/// Moves the lines waiting into `outLines` (the caller's). False once every pipe has ended
		/// and nothing is left.
		public bool Take(List<String> outLines)
		{
			using (Lock.Enter())
			{
				outLines.AddRange(Lines);
				Lines.Clear();
				return (Open > 0) || !outLines.IsEmpty;
			}
		}
	}

	/// Reads ONE pipe to its end (none for null), queueing each line without its ending, then
	/// says the pipe has ended.
	private static void ReadLines(System.IO.FileStream stream, LineQueue queue)
	{
		let pending = scope String();
		if (stream != null)
		{
			let chunk = scope uint8[cReadChunk];
			while (true)
			{
				int read = 0;
				if (stream.TryRead(chunk) case .Ok(let count))
					read = count;
				if (read <= 0)
					break;
				pending.Append(StringView((char8*)chunk.Ptr, read));
				int start = 0;
				while (true)
				{
					let end = pending.IndexOf('\n', start);
					if (end < 0)
						break;
					var length = end - start;
					if ((length > 0) && (pending[end - 1] == '\r'))
						length--;
					queue.Add(StringView(pending, start, length));
					start = end + 1;
				}
				pending.Remove(0, start);
				// A line that never ends is handed on in pieces: a runaway child must not grow
				// this without bound.
				if (pending.Length >= cMaxOutputBytes)
				{
					queue.Add(pending);
					pending.Clear();
				}
			}
		}
		if (!pending.IsEmpty)
			queue.Add(pending);
		queue.Close();
	}

	/// How Run and RunStreaming start a child: no shell, no window, both its outputs piped back.
	private static void Redirected(StringView executable, Span<StringView> arguments, ProcessStartInfo startInfo)
	{
		startInfo.SetFileName(executable);
		startInfo.SetArguments(QuotedArguments(arguments, .. scope .()));
		startInfo.UseShellExecute = false;
		startInfo.CreateNoWindow = true;
		startInfo.RedirectStandardOutput = true;
		startInfo.RedirectStandardError = true;
	}

	/// The arguments as one command line. Beef joins the arguments into one, so each is quoted
	/// here: an unquoted path with a space would otherwise arrive as two arguments.
	private static void QuotedArguments(Span<StringView> arguments, String outCommandLine)
	{
		for (let argument in arguments)
		{
			if (!outCommandLine.IsEmpty)
				outCommandLine.Append(' ');
			AppendQuoted(outCommandLine, argument);
		}
	}

	/// Wraps an argument in quotes, escaping what the child's argument splitting would otherwise
	/// eat. On Windows that is the command line's rule: a quote is escaped, and a run of
	/// backslashes is doubled only where a quote follows it (the argument's own, or the closing
	/// one). Elsewhere the runtime splits the line itself and turns only `\"` back into a quote,
	/// keeping every other backslash as written, so only quotes are escaped there; a backslash just
	/// before an argument's end cannot be passed there, as it reads as an escaped quote.
	private static void AppendQuoted(String outCommandLine, StringView argument)
	{
		outCommandLine.Append('"');
#if BF_PLATFORM_WINDOWS
		int backslashes = 0;
		for (let c in argument)
		{
			if (c == '\\')
			{
				backslashes++;
				continue;
			}
			// Doubled before a quote, so the quote's own escape stands alone.
			outCommandLine.Append('\\', (c == '"') ? (backslashes * 2 + 1) : backslashes);
			backslashes = 0;
			outCommandLine.Append(c);
		}
		outCommandLine.Append('\\', backslashes * 2);
#else
		for (let c in argument)
		{
			if (c == '"')
				outCommandLine.Append('\\');
			outCommandLine.Append(c);
		}
#endif
		outCommandLine.Append('"');
	}
}
