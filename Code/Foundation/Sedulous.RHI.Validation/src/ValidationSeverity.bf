namespace Sedulous.RHI.Validation;

/// How much a validation message matters.
///
/// The split is about CONSEQUENCE, not confidence. An Error names usage that is wrong and
/// whose result is undefined on some backend; a Warning names usage that is legal but
/// almost certainly a mistake, such as a draw of no vertices.
enum ValidationSeverity
{
	Info,
	Warning,
	Error
}
