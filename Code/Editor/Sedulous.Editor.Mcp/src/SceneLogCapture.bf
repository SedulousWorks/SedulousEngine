using System;
using System.Collections;
using Sedulous.Core.Logging;

namespace Sedulous.Editor.Mcp;

/// Listens to the global log for the span of a scene parse and keeps the warnings and
/// errors: the reader WARNS and skips an unknown component record rather than failing,
/// which is exactly what an agent validating a scene needs to hear.
///
/// Installed as a composite of whatever logger was global plus this one, and the previous
/// logger goes back with the ownership it had; nothing else logs differently meanwhile.
class SceneLogCapture : ILogger
{
	public List<String> Lines = new .() ~ DeleteContainerAndItems!(_);

	public LogLevel MinimumLogLevel { get; set; } = .Warning;
	public String Name { get; private set; } = new .("SceneLogCapture") ~ delete _;

	private ILogger mPrevious = null;
	private bool mPreviousOwned = false;
	private CompositeLogger mComposite = null;

	public void Log(LogLevel logLevel, StringView format, params Object[] args)
	{
		if ((logLevel < MinimumLogLevel) || (logLevel >= .None))
			return;
		let line = new String();
		line.AppendF(format, params args);
		Lines.Add(line);
	}

	/// Starts listening. Balanced by Stop, which puts the previous logger back.
	public void Start()
	{
		mPrevious = DetachGlobalLogger(out mPreviousOwned);
		mComposite = new CompositeLogger(.Trace, "SceneLogCapture");
		if (mPrevious != null)
			mComposite.Add(mPrevious);
		mComposite.Add(this);
		InitGlobalLogger(mComposite, false);
	}

	public void Stop()
	{
		if (mComposite == null)
			return;
		bool compositeOwned;
		DetachGlobalLogger(out compositeOwned);
		delete mComposite;
		mComposite = null;
		if (mPrevious != null)
			InitGlobalLogger(mPrevious, mPreviousOwned);
		mPrevious = null;
	}
}
