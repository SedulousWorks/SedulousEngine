using System;
using System.Collections;

namespace Sedulous.Mcp;

/// Lines in, lines out. The transport for tests and for embedding a server in a process that
/// already has its own I/O.
class InMemoryTransport : ITransport
{
	private List<String> mInput = new .() ~ DeleteContainerAndItems!(_);
	private int mCursor = 0;
	private List<String> mOutput = new .() ~ DeleteContainerAndItems!(_);

	/// Queues an inbound line. Copied, so the caller keeps its own.
	public void Push(StringView line) => mInput.Add(new String(line));

	public bool ReadLine(String outLine)
	{
		if (mCursor >= mInput.Count)
			return false;

		outLine.Set(mInput[mCursor]);
		mCursor++;
		return true;
	}

	public void WriteLine(StringView line) => mOutput.Add(new String(line));

	public int OutputCount => mOutput.Count;

	/// One captured line, BORROWED.
	public StringView Output(int index) => mOutput[index];
}
