using System;

namespace Sedulous.Core;

/// What running a child process produced.
///
/// The exit code distinguishes three outcomes rather than two: a code of zero is success, a
/// positive code is a tool that ran and refused, and a negative code means the process could
/// not be started at all. A caller needs the middle case separated from the last, because a
/// tool's own diagnostic is worth reporting and "could not run it" is a different bug.
class ProcessResult
{
	/// Zero or more is the child's exit code; less than zero means it never ran.
	public int ExitCode = -1;
	/// The child's combined standard output and standard error, capped.
	public String Output = new String() ~ delete _;

	/// Whether the process started and exited on its own.
	public bool Ran => ExitCode >= 0;
	/// Whether it exited successfully.
	public bool Ok => ExitCode == 0;
}
