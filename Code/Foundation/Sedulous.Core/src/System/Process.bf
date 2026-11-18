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

	/// Starts `program` with `arguments` (each one whole) and leaves it running: it outlives this
	/// process, in a session of its own with none of this process's handles. A `program` that
	/// names no folder is searched on PATH; on Windows a .cmd or .bat found there runs through
	/// cmd.exe, since that is how most editors put themselves on PATH. True once it started, false
	/// when it could not be found or started. It does not wait for the program, so a thread that
	/// must stay responsive (the UI's, opening an outside editor) may call it. Start, by contrast,
	/// takes an explicit path and leaves its child tied to this process.
	public static bool LaunchDetached(StringView program, Span<StringView> arguments)
	{
		if (program.IsEmpty)
			return false;
#if BF_PLATFORM_WINDOWS
		return LaunchDetachedWindows(program, arguments);
#elif BF_PLATFORM_LINUX || BF_PLATFORM_ANDROID
		return LaunchDetachedPosix(program, arguments);
#else
		return false;
#endif
	}

#if BF_PLATFORM_WINDOWS
	private static bool LaunchDetachedWindows(StringView program, Span<StringView> arguments)
	{
		// CreateProcess's own search adds only .exe, and most editors put a .cmd on PATH (VS
		// Code's `code`, beside a `code` shell script for WSL that Windows cannot run), so the
		// program is found first, as an .exe, a .cmd or a .bat. A name with an extension is
		// searched as it is.
		let name = program.ToScopedNativeWChar!();
		char16[cMaxPath] found = ?;
		uint32 foundLength = 0;
		for (let suffix in StringView[?](".exe", ".cmd", ".bat"))
		{
			let wideSuffix = suffix.ToScopedNativeWChar!();
			foundLength = SearchPathW(null, name, wideSuffix, cMaxPath, &found[0], null);
			if ((foundLength != 0) && (foundLength < cMaxPath))
				break;
		}
		if ((foundLength == 0) || (foundLength >= cMaxPath))
			return false;
		let foundPath = scope String();
		foundPath.Append(&found[0]);
		let script = foundPath.EndsWith(".cmd", .OrdinalIgnoreCase) || foundPath.EndsWith(".bat", .OrdinalIgnoreCase);

		let line = scope String();
		if (script)
		{
			// cmd /s /c "<line>" takes everything between the outer quotes as the command, as is.
			char16[cMaxPath] system = ?;
			let systemLength = GetSystemDirectoryW(&system[0], cMaxPath);
			if ((systemLength == 0) || (systemLength + 9 > cMaxPath))
				return false;
			let shell = scope String();
			shell.Append(&system[0]);
			shell.Append("\\cmd.exe");
			AppendWindowsArgument(line, shell);
			line.Append(" /d /s /c \"");
		}
		AppendWindowsArgument(line, foundPath);
		for (let argument in arguments)
		{
			line.Append(' ');
			AppendWindowsArgument(line, argument);
		}
		if (script)
			line.Append('"');

		// No inherited handles, a process group of its own, and no console window for the cmd.exe
		// that runs a script. CreateProcess returns once the child starts; nothing waits on it.
		let command = line.ToScopedNativeWChar!();
		StartupInfo startup = default;
		startup.Size = sizeof(StartupInfo);
		ProcessInformation process = default;
		let flags = cCreateNewProcessGroup | (script ? cCreateNoWindow : 0);
		if (CreateProcessW(null, command, null, null, 0, flags, null, null, &startup, &process) == 0)
			return false;
		CloseHandle(process.Thread);
		CloseHandle(process.Process);
		return true;
	}

	/// One argument of a CreateProcess command line, which the callee parses again: quoted only
	/// when it needs it (empty, or holding whitespace or quotes). Quoting every one breaks callees
	/// that parse their own command line, notably cmd.exe, which does not take a quoted "/c".
	private static void AppendWindowsArgument(String outLine, StringView argument)
	{
		bool needsQuotes = argument.IsEmpty;
		for (let c in argument)
		{
			if ((c == ' ') || (c == '\t') || (c == '"'))
			{
				needsQuotes = true;
				break;
			}
		}
		if (!needsQuotes)
		{
			outLine.Append(argument);
			return;
		}
		outLine.Append('"');
		int i = 0;
		while (i < argument.Length)
		{
			let c = argument[i];
			if (c == '\\')
			{
				// A backslash run is literal unless it precedes the closing quote, where each one
				// is doubled so it is not read as escaping that quote.
				int slashes = 0;
				while ((i + slashes < argument.Length) && (argument[i + slashes] == '\\'))
					slashes++;
				let beforeClose = (i + slashes == argument.Length);
				outLine.Append('\\', slashes * (beforeClose ? 2 : 1));
				i += slashes;
				continue;
			}
			if (c == '"')
				outLine.Append('\\');
			outLine.Append(c);
			i++;
		}
		outLine.Append('"');
	}

	private const int32 cMaxPath = 260;
	private const uint32 cCreateNewProcessGroup = 0x00000200;
	private const uint32 cCreateNoWindow = 0x08000000;

	[CRepr]
	private struct StartupInfo
	{
		public uint32 Size;
		public char16* Reserved;
		public char16* Desktop;
		public char16* Title;
		public uint32 X, Y, XSize, YSize, XCountChars, YCountChars, FillAttribute, Flags;
		public uint16 ShowWindow;
		public uint16 Reserved2Size;
		public uint8* Reserved2;
		public void* StdInput;
		public void* StdOutput;
		public void* StdError;
	}

	[CRepr]
	private struct ProcessInformation
	{
		public void* Process;
		public void* Thread;
		public uint32 ProcessId;
		public uint32 ThreadId;
	}

	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern uint32 SearchPathW(char16* path, char16* fileName, char16* defaultExtension, uint32 bufferLength, char16* buffer, char16** filePart);
	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern uint32 GetSystemDirectoryW(char16* buffer, uint32 size);
	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern int32 CreateProcessW(char16* applicationName, char16* commandLine, void* processAttributes, void* threadAttributes, int32 inheritHandles, uint32 creationFlags, void* environment, char16* currentDirectory, StartupInfo* startupInfo, ProcessInformation* processInformation);
	[Import("kernel32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern int32 CloseHandle(void* handle);
#elif BF_PLATFORM_LINUX || BF_PLATFORM_ANDROID
	private static bool LaunchDetachedPosix(StringView program, Span<StringView> arguments)
	{
		// Everything the children use is built before the fork, so neither allocates.
		let programZ = scope String(program);
		let store = scope List<String>();
		defer { ClearAndDeleteItems!(store); }
		let argv = scope char8*[arguments.Length + 2];
		argv[0] = programZ.CStr();
		for (int i < arguments.Length)
		{
			let argument = new String(arguments[i]);
			store.Add(argument);
			argv[i + 1] = argument.CStr();
		}
		argv[arguments.Length + 1] = null;

		// The grandchild writes errno here when exec fails; a successful exec closes it (close on
		// exec), so the parent reads end of file.
		int32[2] execError = .(-1, -1);
		if (pipe2(&execError[0], cCloseOnExec) != 0)
			return false;
		// Double fork: the grandchild reparents to init, which reaps it, and the child is reaped here.
		let child = fork();
		if (child < 0)
		{
			close(execError[0]);
			close(execError[1]);
			return false;
		}
		if (child == 0)
		{
			let grandchild = fork();
			if (grandchild == 0)
			{
				setsid();
				let devnull = open("/dev/null", cReadWrite);
				if (devnull >= 0)
				{
					dup2(devnull, 0);
					dup2(devnull, 1);
					dup2(devnull, 2);
				}
				execvp(programZ.CStr(), &argv[0]);
				int32 error = *__errno_location();
				write(execError[1], &error, sizeof(int32));
				_exit(127);
			}
			if (grandchild < 0)
			{
				int32 error = *__errno_location();
				write(execError[1], &error, sizeof(int32));
			}
			_exit(0);
		}
		close(execError[1]);
		int32 status = 0;
		waitpid(child, &status, 0);
		int32 childError = 0;
		int got = 0;
		repeat
		{
			got = read(execError[0], &childError, sizeof(int32));
		}
		while ((got < 0) && (*__errno_location() == cInterrupted));
		close(execError[0]);
		return got == 0;
	}

	private const int32 cCloseOnExec = 0x80000;
	private const int32 cReadWrite = 2;
	private const int32 cInterrupted = 4;

	[CLink]
	private static extern int32 fork();
	[CLink]
	private static extern int32 setsid();
	[CLink]
	private static extern int32 pipe2(int32* fds, int32 flags);
	[CLink]
	private static extern int32 open(char8* path, int32 flags);
	[CLink]
	private static extern int32 dup2(int32 from, int32 to);
	[CLink]
	private static extern int32 close(int32 fd);
	[CLink]
	private static extern int read(int32 fd, void* buffer, uint count);
	[CLink]
	private static extern int write(int32 fd, void* buffer, uint count);
	[CLink]
	private static extern int32 execvp(char8* file, char8** argv);
	[CLink]
	private static extern int32 waitpid(int32 pid, int32* status, int32 options);
	[CLink]
	private static extern void _exit(int32 status);
#if BF_PLATFORM_ANDROID
	[LinkName("__errno")]
#else
	[CLink]
#endif
	private static extern int32* __errno_location();
#endif

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
