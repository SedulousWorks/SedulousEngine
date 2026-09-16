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
		// Raptor has no such problem because it points both of the child's descriptors at a
		// SINGLE pipe; Beef's process API gives two, so they get drained in parallel to the
		// same effect. tint is the specimen - it prints whole shaders to stdout and nothing
		// to stderr, and hung the cook on the first file bigger than a pipe buffer.
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
