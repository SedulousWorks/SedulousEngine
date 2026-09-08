namespace Sedulous.Scene.Resource;

/// How a scene stream is encoded on disk.
///
/// A SOURCE is text, because a source is diffed and merged by people. A staged or cooked
/// product, and an in memory snapshot, is binary. One serialization path feeds both, so
/// the two encodings cannot describe different worlds.
enum SceneStreamEncoding : uint8
{
	Binary,
	Text
}
