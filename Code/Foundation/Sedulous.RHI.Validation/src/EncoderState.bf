namespace Sedulous.RHI.Validation;

/// Where a command encoder is in its life.
///
/// Most operations are only legal while plainly RECORDING. Inside a pass the encoder is
/// not: a copy, a barrier or a second BeginRenderPass issued there is invalid, and a
/// backend's response ranges from a validation error to undefined behaviour.
enum EncoderState
{
	Recording,
	InRenderPass,
	InComputePass,
	Finished
}
