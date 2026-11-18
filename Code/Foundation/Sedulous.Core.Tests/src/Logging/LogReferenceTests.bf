using System;
using System.Collections;
using Sedulous.Core.Logging;

namespace Sedulous.Core.Tests;

/// A line carries its references to the loggers that keep them; the others get the text.
class LogReferenceTests
{
	/// Keeps the references it is handed, and counts the lines that came without any.
	private class Keeper : ILogger
	{
		public LogLevel MinimumLogLevel { get; set; } = .Trace;
		public String Name { get; } = "Keeper";
		public int Plain = 0;
		public String Message = new .() ~ delete _;
		public List<LogReference> References = new .() ~ DeleteContainerAndItems!(_);

		public void Log(LogLevel logLevel, StringView format, params Object[] args)
		{
			Plain++;
			Message..Clear().AppendF(format, params args);
		}

		public void LogReferenced(LogLevel logLevel, Span<LogReference> references, StringView format, params Object[] args)
		{
			Message..Clear().AppendF(format, params args);
			for (let reference in references)
				References.Add(reference.Clone());
		}
	}

	[Test]
	public static void ALineCarriesItsReferencesToTheLoggersThatKeepThemOthersGetTheText()
	{
		let keeper = scope Keeper();
		let ring = scope RingLogger(4, .Trace);
		let composite = scope CompositeLogger(.Trace);
		composite.Add(keeper);
		composite.Add(ring);
		let previous = DetachGlobalLogger(let previousOwned);
		InitGlobalLogger(composite);
		defer
		{
			DetachGlobalLogger(let ours);
			if (previous != null)
				InitGlobalLogger(previous, previousOwned);
		}

		let id = Guid.Parse("0e9b3a52-1c1f-4c2e-9d3b-5a7f1e2d3c4b").Value;
		let asset = LogReference.ForAsset(id);
		defer delete asset;
		GlobalLogAt(.Warning, asset, "Cook: {} did not cook", "Crate");
		let source = LogReference.ForSource("/p/Code/Player.as", 12, 4);
		defer delete source;
		LogReference[1] carried = .(source);
		GlobalLogReferenced(.Error, carried, "Script: bad {}", 1);
		GlobalLog(.Warning, "Cook: plain");

		Test.Assert(keeper.References.Count == 2);
		Test.Assert(keeper.References[0].Kind == LogReference.Asset);
		Test.Assert(keeper.References[0].Field(0) == "0e9b3a52-1c1f-4c2e-9d3b-5a7f1e2d3c4b");
		Test.Assert(keeper.References[0].Length == 0); // attached: the whole line
		Test.Assert(keeper.References[1].Kind == LogReference.Source);
		Test.Assert(keeper.References[1].Field(0) == "/p/Code/Player.as");
		Test.Assert(keeper.References[1].Field(1) == "12");
		Test.Assert(keeper.References[1].Field(2) == "4");
		Test.Assert(keeper.References[1].Field(3).IsEmpty);
		Test.Assert(keeper.Plain == 1); // the line without references
		Test.Assert(keeper.Message == "Cook: plain");
		// The ring keeps the text of each, without the references.
		Test.Assert(ring.Count == 3);
		Test.Assert(ring.GetMessage(0, .. scope .()).Contains("Cook: Crate did not cook"));
		Test.Assert(ring.GetMessage(1, .. scope .()).Contains("Script: bad 1"));

		// A source reference with no line or column leaves both empty.
		let bare = LogReference.ForSource("a.as");
		defer delete bare;
		Test.Assert(bare.Field(1).IsEmpty && bare.Field(2).IsEmpty);
	}
}
