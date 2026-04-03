using System;
namespace Sedulous.Core;

/// <summary>
/// Contains methods for enforcing code contracts and establishing invariants.
/// </summary>
static class Contract
{
	/// <summary>
	/// Throws an <see cref="ArgumentOutOfRangeException"/> if the specified condition is false.
	/// </summary>
	/// <param name="condition">The condition to evaluate.</param>
	/// <param name="message">An optional message to pass to the thrown exception.</param>
	[Inline]
	public static void EnsureRange(bool condition, String message)
	{
	    if (!condition)
	        Runtime.ArgumentOutOfRangeError(message);
	}

	/// <summary>
	/// Throws an <see cref="ArgumentNullException"/> if the specified object is <see langword="null"/>.
	/// </summary>
	/// <typeparam name="T">The type of object to evaluate for nullity.</typeparam>
	/// <param name="argument">The object to evaluate for nullity.</param>
	/// <param name="message">The exception message.</param>
	[Inline]
	public static void Require<T>(T argument, String message) where T : class
	{
	    if (argument == null)
	        Runtime.ArgumentNullError(message);
	}
}