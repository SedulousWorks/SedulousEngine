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

	/// Runs `executable` with `arguments` and BLOCKS until it exits, capturing its combined
	/// output.
	///
	/// An explicit path, with no shell and no PATH search, and each argument passed whole
	/// with no splitting or globbing. That is what makes it safe to hand a caller-supplied
	/// path: nothing in it is interpreted.
	///
	/// For cook-time tool invocations. Do NOT call it on a thread that must stay responsive.
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

		// Captured through a temporary file because Beef attaches a stream rather than
		// handing back a pipe.
		let capturePath = scope String();
		Path.GetTempPath(capturePath);
		Path.InternalCombine(capturePath, scope $"sedulous_proc_{Platform.BfpProcess_GetCurrentId()}_{gCaptureCounter++}.txt");
		defer { File.Delete(capturePath).IgnoreError(); }

		{
			let startInfo = scope ProcessStartInfo();
			startInfo.SetFileName(executable);
			startInfo.SetArguments(commandLine);
			startInfo.UseShellExecute = false;
			startInfo.CreateNoWindow = true;
			startInfo.RedirectStandardOutput = true;
			startInfo.RedirectStandardError = true;

			// System.IO's stream, not Core's: SpawnedProcess attaches an IFileStream.
			let capture = scope System.IO.FileStream();
			if (capture.Create(capturePath, .Write, .Read) case .Err)
			{
				outResult.Output.Set("could not open a capture file for the child's output");
				return;
			}

			let process = scope SpawnedProcess();
			if (process.Start(startInfo) case .Err)
			{
				outResult.Output.Set("could not start ");
				outResult.Output.Append(executable);
				return;
			}
			// Both streams go to the same file, which is what makes the capture combined.
			process.AttachStandardOutput(capture).IgnoreError();
			process.AttachStandardError(capture).IgnoreError();

			process.WaitFor(-1);
			outResult.ExitCode = process.ExitCode;
		}

		ReadCapture(capturePath, outResult.Output);
	}

	private static void ReadCapture(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err)
			return;

		let length = Math.Min(bytes.Count, cMaxOutputBytes);
		if (length > 0)
			outText.Append(StringView((char8*)bytes.Ptr, length));
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

	private static int gCaptureCounter = 0;
}
