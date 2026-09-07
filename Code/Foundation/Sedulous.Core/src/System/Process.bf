using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
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
		Drain(haveOutput ? standardOutput : null, haveError ? standardError : null,
			outResult.Output);

		process.WaitFor(-1);
		outResult.ExitCode = process.ExitCode;
	}

	/// Reads both pipes to their end, alternating so neither can fill while the other is
	/// being read.
	///
	/// The two are interleaved rather than read one after the other because a child writing
	/// heavily to the stream that is not being read would block forever. Alternating bounds
	/// that to one chunk of imbalance.
	private static void Drain(System.IO.FileStream standardOutput, System.IO.FileStream standardError, String outText)
	{
		var outputOpen = standardOutput != null;
		var errorOpen = standardError != null;
		let chunk = scope uint8[cReadChunk];

		while (outputOpen || errorOpen)
		{
			if (outputOpen)
				outputOpen = ReadChunk(standardOutput, chunk, outText);
			if (errorOpen)
				errorOpen = ReadChunk(standardError, chunk, outText);
		}
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
