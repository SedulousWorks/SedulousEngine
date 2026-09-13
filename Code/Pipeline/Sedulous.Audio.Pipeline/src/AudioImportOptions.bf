using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Audio.Pipeline;

/// What the import dialog offers for an audio file.
///
/// All toggles. The streaming one is a FORCE rather than the whole story: the import computes
/// a default from the probed file, and this can only turn it on.
class AudioImportOptions : ImportOptions
{
	public bool Stream = false;
	public bool ForceMono = false;
	public bool Loop = false;
	public bool TrimTrailingSilence = false;
	public bool Normalize = false;

	public override void GetToggles(List<ImportToggle> outToggles)
	{
		outToggles.Add(.("Stream",
			"Decode on the fly at runtime, which anything over ten seconds or two megabytes does anyway",
			&Stream));
		outToggles.Add(.("Force mono",
			"Downmix to one channel at cook, which is what a positioned sound wants", &ForceMono));
		outToggles.Add(.("Loop",
			"Loop by default when played. A wave file's own loop points are detected regardless",
			&Loop));
		outToggles.Add(.("Trim trailing silence", "Drop the silent tail at cook",
			&TrimTrailingSilence));
		outToggles.Add(.("Normalize", "Peak normalise, leaving a decibel of headroom", &Normalize));
	}
}
