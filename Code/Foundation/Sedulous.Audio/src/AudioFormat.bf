namespace Sedulous.Audio;

/// PCM audio sample format.
enum AudioFormat
{
	/// Signed 16-bit integer samples.
	case Int16;
	/// Signed 32-bit integer samples.
	case Int32;
	/// 32-bit floating point samples.
	case Float32;

	/// Gets the size in bytes of a single sample in this format.
	public int32 BytesPerSample
	{
		get
		{
			switch (this)
			{
			case .Int16: return 2;
			case .Int32: return 4;
			case .Float32: return 4;
			}
		}
	}
}
