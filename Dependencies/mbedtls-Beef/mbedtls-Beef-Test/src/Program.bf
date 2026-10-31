using System;
using mbedtls_Beef;

namespace mbedtls_Beef_Test;

/// Drives the binding against the real library: the crypto starts (twice, answering the same),
/// the version is the vendored release, and SHA-256 of "abc" is FIPS 180-2's test vector, which
/// proves the PSA layer compiled, linked and runs.
class Program
{
	static int Run()
	{
		if ((mbedtlsc_start() == 0) || (mbedtlsc_start() == 0))
		{
			Console.WriteLine("FAIL: the crypto library did not start");
			return 1;
		}

		let version = StringView(mbedtlsc_version());
		Console.WriteLine("Mbed TLS {}", version);
		if (version != "4.2.0")
		{
			Console.WriteLine("FAIL: expected the vendored 4.2.0");
			return 1;
		}

		uint8[3] input = .((.)'a', (.)'b', (.)'c');
		uint8[32] digest = default;
		if (mbedtlsc_sha256(&input[0], 3, &digest[0]) == 0)
		{
			Console.WriteLine("FAIL: SHA-256 did not hash");
			return 1;
		}
		let hex = scope String();
		for (let b in digest)
			hex.AppendF("{0:x2}", b);
		if (hex != "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
		{
			Console.WriteLine("FAIL: SHA-256 of \"abc\" was {}", hex);
			return 1;
		}

		Console.WriteLine("mbedtls-Beef: the crypto started and hashed.");
		return 0;
	}

	public static int Main(String[] args) => Run();
}
