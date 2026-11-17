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
	/// What is kept of a tool's output: its END, which is where a build's errors are, bounded so
	/// a runaway tool cannot fill memory. The first 64 KiB was kept, and an export's build showed
	/// only its start.
	private const int cMaxOutputBytes = 16 * 1024 * 1024;
	private const int cReadChunk = 4096;

	/// Runs `executable` with `arguments` and BLOCKS until it exits, capturing its combined
	/// standard output and standard error.
	///
	/// An explicit path, with no shell and no PATH search, and each argument passed whole.
	/// That is what makes it safe to hand a caller supplied path: nothing in it is
	/// interpreted.
	///
	/// With `timeoutMilliseconds` (negative: none), a run past it is killed with what it started,
	/// and the result says it TimedOut: there was no limit, so a hung tool held the cook for good.
	///
	/// For cook time tool invocations. Do NOT call it on a thread that must stay responsive.
	public static void Run(StringView executable, Span<StringView> arguments,
		ProcessResult outResult, int timeoutMilliseconds = -1)
	{
		outResult.ExitCode = -1;
		outResult.TimedOut = false;
		outResult.Output.Clear();

		// Beef joins the arguments into one command line, so each is quoted here: an
		// unquoted path with a space would otherwise arrive as two arguments.
		let commandLine = scope String();
		for (let argument in arguments)
		{
			if (!commandLine.IsEmpty)
				commandLine.Append(' ');
			AppendQuoted(commandLine, argument);
		}

		let startInfo = scope ProcessStartInfo();
		startInfo.SetFileName(executable);
		startInfo.SetArguments(commandLine);
		startInfo.UseShellExecute = false;
		startInfo.CreateNoWindow = true;
		startInfo.RedirectStandardOutput = true;
		startInfo.RedirectStandardError = true;

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

		let outputText = outResult.Output;
		let errorDrain = scope Thread(new [&errorStream, &errorText]() =>
			{
				Drain(errorStream, errorText);
			});
		let outputDrain = scope Thread(new [&outputStream, &outputText]() =>
			{
				Drain(outputStream, outputText);
			});
		errorDrain.Start(false);
		outputDrain.Start(false);

		// The wait is the timeout's: a child killed with what it started closes its pipes, and
		// the drains end with them.
		if (!process.WaitFor(timeoutMilliseconds))
		{
			process.Kill(-1, .KillChildren);
			process.WaitFor(-1);
			outResult.TimedOut = true;
		}
		outputDrain.Join();
		errorDrain.Join();

		// Appended rather than interleaved: two pipes cannot be merged after the fact, and a
		// caller wants the whole diagnostic, not its exact ordering.
		outResult.Output.Append(errorText);
		KeepTail(outResult.Output);

		if (!outResult.TimedOut)
			outResult.ExitCode = process.ExitCode;
	}

	/// Starts `executable` with `arguments` and returns without waiting: the child runs on its
	/// own, its output going where the parent's does. An explicit path, each argument passed
	/// whole, as Run's. False when it could not be started.
	public static bool Start(StringView executable, Span<StringView> arguments)
	{
		let commandLine = scope String();
		for (let argument in arguments)
		{
			if (!commandLine.IsEmpty)
				commandLine.Append(' ');
			AppendQuoted(commandLine, argument);
		}
		let startInfo = scope ProcessStartInfo();
		startInfo.SetFileName(executable);
		startInfo.SetArguments(commandLine);
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
			outText.Append(StringView((char8*)chunk.Ptr, read));
			// Bounded as it grows, at a chunk's cost: the oldest goes, the end is kept.
			if (outText.Length > (cMaxOutputBytes + (cMaxOutputBytes / 4)))
				KeepTail(outText);
			return true;
		case .Err:
			return false;
		}
	}

	/// The last cMaxOutputBytes of `text`, the rest before it dropped.
	private static void KeepTail(String text)
	{
		if (text.Length > cMaxOutputBytes)
			text.Remove(0, text.Length - cMaxOutputBytes);
	}

	/// Wraps an argument in quotes, escaping what a command line would otherwise eat.
	private static void AppendQuoted(String outCommandLine, StringView argument)
	{
		outCommandLine.Append('"');
		for (let c in argument)
		{
			if ((c == '"') || (c == '\\'))
				outCommandLine.Append('\\');
			outCommandLine.Append(c);
		}
		outCommandLine.Append('"');
	}
}
