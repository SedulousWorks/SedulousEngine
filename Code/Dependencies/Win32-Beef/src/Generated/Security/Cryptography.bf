using Win32.Foundation;
using Win32.System.Registry;
using Win32.Security;
using Win32.System.Com;
using System;

namespace Win32.Security.Cryptography;

#region Constants
public static
{
	public const int32 CERT_COMPARE_SHIFT = 16;
	public const uint32 BCRYPT_OBJECT_ALIGNMENT = 16;
	public const String BCRYPT_KDF_HASH = "HASH";
	public const String BCRYPT_KDF_HMAC = "HMAC";
	public const String BCRYPT_KDF_TLS_PRF = "TLS_PRF";
	public const String BCRYPT_KDF_SP80056A_CONCAT = "SP800_56A_CONCAT";
	public const String BCRYPT_KDF_RAW_SECRET = "TRUNCATE";
	public const String BCRYPT_KDF_HKDF = "HKDF";
	public const uint32 KDF_HASH_ALGORITHM = 0;
	public const uint32 KDF_SECRET_PREPEND = 1;
	public const uint32 KDF_SECRET_APPEND = 2;
	public const uint32 KDF_HMAC_KEY = 3;
	public const uint32 KDF_TLS_PRF_LABEL = 4;
	public const uint32 KDF_TLS_PRF_SEED = 5;
	public const uint32 KDF_SECRET_HANDLE = 6;
	public const uint32 KDF_TLS_PRF_PROTOCOL = 7;
	public const uint32 KDF_ALGORITHMID = 8;
	public const uint32 KDF_PARTYUINFO = 9;
	public const uint32 KDF_PARTYVINFO = 10;
	public const uint32 KDF_SUPPPUBINFO = 11;
	public const uint32 KDF_SUPPPRIVINFO = 12;
	public const uint32 KDF_LABEL = 13;
	public const uint32 KDF_CONTEXT = 14;
	public const uint32 KDF_SALT = 15;
	public const uint32 KDF_ITERATION_COUNT = 16;
	public const uint32 KDF_GENERIC_PARAMETER = 17;
	public const uint32 KDF_KEYBITLENGTH = 18;
	public const uint32 KDF_HKDF_SALT = 19;
	public const uint32 KDF_HKDF_INFO = 20;
	public const uint32 KDF_USE_SECRET_AS_HMAC_KEY_FLAG = 1;
	public const uint32 BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO_VERSION = 1;
	public const uint32 BCRYPT_AUTH_MODE_CHAIN_CALLS_FLAG = 1;
	public const uint32 BCRYPT_AUTH_MODE_IN_PROGRESS_FLAG = 2;
	public const String BCRYPT_OPAQUE_KEY_BLOB = "OpaqueKeyBlob";
	public const String BCRYPT_KEY_DATA_BLOB = "KeyDataBlob";
	public const String BCRYPT_AES_WRAP_KEY_BLOB = "Rfc3565KeyWrapBlob";
	public const String BCRYPT_OBJECT_LENGTH = "ObjectLength";
	public const String BCRYPT_ALGORITHM_NAME = "AlgorithmName";
	public const String BCRYPT_PROVIDER_HANDLE = "ProviderHandle";
	public const String BCRYPT_CHAINING_MODE = "ChainingMode";
	public const String BCRYPT_BLOCK_LENGTH = "BlockLength";
	public const String BCRYPT_KEY_LENGTH = "KeyLength";
	public const String BCRYPT_KEY_OBJECT_LENGTH = "KeyObjectLength";
	public const String BCRYPT_KEY_STRENGTH = "KeyStrength";
	public const String BCRYPT_KEY_LENGTHS = "KeyLengths";
	public const String BCRYPT_BLOCK_SIZE_LIST = "BlockSizeList";
	public const String BCRYPT_EFFECTIVE_KEY_LENGTH = "EffectiveKeyLength";
	public const String BCRYPT_HASH_LENGTH = "HashDigestLength";
	public const String BCRYPT_HASH_OID_LIST = "HashOIDList";
	public const String BCRYPT_PADDING_SCHEMES = "PaddingSchemes";
	public const String BCRYPT_SIGNATURE_LENGTH = "SignatureLength";
	public const String BCRYPT_HASH_BLOCK_LENGTH = "HashBlockLength";
	public const String BCRYPT_AUTH_TAG_LENGTH = "AuthTagLength";
	public const String BCRYPT_PRIMITIVE_TYPE = "PrimitiveType";
	public const String BCRYPT_IS_KEYED_HASH = "IsKeyedHash";
	public const String BCRYPT_IS_REUSABLE_HASH = "IsReusableHash";
	public const String BCRYPT_MESSAGE_BLOCK_LENGTH = "MessageBlockLength";
	public const String BCRYPT_PUBLIC_KEY_LENGTH = "PublicKeyLength";
	public const String BCRYPT_PCP_PLATFORM_TYPE_PROPERTY = "PCP_PLATFORM_TYPE";
	public const String BCRYPT_PCP_PROVIDER_VERSION_PROPERTY = "PCP_PROVIDER_VERSION";
	public const String BCRYPT_MULTI_OBJECT_LENGTH = "MultiObjectLength";
	public const String BCRYPT_IS_IFX_TPM_WEAK_KEY = "IsIfxTpmWeakKey";
	public const String BCRYPT_HKDF_HASH_ALGORITHM = "HkdfHashAlgorithm";
	public const String BCRYPT_HKDF_SALT_AND_FINALIZE = "HkdfSaltAndFinalize";
	public const String BCRYPT_HKDF_PRK_AND_FINALIZE = "HkdfPrkAndFinalize";
	public const String BCRYPT_INITIALIZATION_VECTOR = "IV";
	public const String BCRYPT_CHAIN_MODE_NA = "ChainingModeN/A";
	public const String BCRYPT_CHAIN_MODE_CBC = "ChainingModeCBC";
	public const String BCRYPT_CHAIN_MODE_ECB = "ChainingModeECB";
	public const String BCRYPT_CHAIN_MODE_CFB = "ChainingModeCFB";
	public const String BCRYPT_CHAIN_MODE_CCM = "ChainingModeCCM";
	public const String BCRYPT_CHAIN_MODE_GCM = "ChainingModeGCM";
	public const uint32 BCRYPT_SUPPORTED_PAD_ROUTER = 1;
	public const uint32 BCRYPT_SUPPORTED_PAD_PKCS1_ENC = 2;
	public const uint32 BCRYPT_SUPPORTED_PAD_PKCS1_SIG = 4;
	public const uint32 BCRYPT_SUPPORTED_PAD_OAEP = 8;
	public const uint32 BCRYPT_SUPPORTED_PAD_PSS = 16;
	public const uint32 BCRYPT_BLOCK_PADDING = 1;
	public const uint32 BCRYPT_GENERATE_IV = 32;
	public const uint32 BCRYPT_PAD_PKCS1_OPTIONAL_HASH_OID = 16;
	public const uint32 BCRYPTBUFFER_VERSION = 0;
	public const String BCRYPT_PUBLIC_KEY_BLOB = "PUBLICBLOB";
	public const String BCRYPT_PRIVATE_KEY_BLOB = "PRIVATEBLOB";
	public const String BCRYPT_RSAPUBLIC_BLOB = "RSAPUBLICBLOB";
	public const String BCRYPT_RSAPRIVATE_BLOB = "RSAPRIVATEBLOB";
	public const String LEGACY_RSAPUBLIC_BLOB = "CAPIPUBLICBLOB";
	public const String LEGACY_RSAPRIVATE_BLOB = "CAPIPRIVATEBLOB";
	public const String BCRYPT_RSAFULLPRIVATE_BLOB = "RSAFULLPRIVATEBLOB";
	public const String BCRYPT_GLOBAL_PARAMETERS = "SecretAgreementParam";
	public const String BCRYPT_PRIVATE_KEY = "PrivKeyVal";
	public const String BCRYPT_ECCPUBLIC_BLOB = "ECCPUBLICBLOB";
	public const String BCRYPT_ECCPRIVATE_BLOB = "ECCPRIVATEBLOB";
	public const String BCRYPT_ECCFULLPUBLIC_BLOB = "ECCFULLPUBLICBLOB";
	public const String BCRYPT_ECCFULLPRIVATE_BLOB = "ECCFULLPRIVATEBLOB";
	public const String SSL_ECCPUBLIC_BLOB = "SSLECCPUBLICBLOB";
	public const uint32 BCRYPT_ECDH_PUBLIC_P256_MAGIC = 827016005;
	public const uint32 BCRYPT_ECDH_PRIVATE_P256_MAGIC = 843793221;
	public const uint32 BCRYPT_ECDH_PUBLIC_P384_MAGIC = 860570437;
	public const uint32 BCRYPT_ECDH_PRIVATE_P384_MAGIC = 877347653;
	public const uint32 BCRYPT_ECDH_PUBLIC_P521_MAGIC = 894124869;
	public const uint32 BCRYPT_ECDH_PRIVATE_P521_MAGIC = 910902085;
	public const uint32 BCRYPT_ECDH_PUBLIC_GENERIC_MAGIC = 1347109701;
	public const uint32 BCRYPT_ECDH_PRIVATE_GENERIC_MAGIC = 1447772997;
	public const uint32 BCRYPT_ECDSA_PUBLIC_P256_MAGIC = 827540293;
	public const uint32 BCRYPT_ECDSA_PRIVATE_P256_MAGIC = 844317509;
	public const uint32 BCRYPT_ECDSA_PUBLIC_P384_MAGIC = 861094725;
	public const uint32 BCRYPT_ECDSA_PRIVATE_P384_MAGIC = 877871941;
	public const uint32 BCRYPT_ECDSA_PUBLIC_P521_MAGIC = 894649157;
	public const uint32 BCRYPT_ECDSA_PRIVATE_P521_MAGIC = 911426373;
	public const uint32 BCRYPT_ECDSA_PUBLIC_GENERIC_MAGIC = 1346650949;
	public const uint32 BCRYPT_ECDSA_PRIVATE_GENERIC_MAGIC = 1447314245;
	public const uint32 BCRYPT_ECC_FULLKEY_BLOB_V1 = 1;
	public const String BCRYPT_DH_PUBLIC_BLOB = "DHPUBLICBLOB";
	public const String BCRYPT_DH_PRIVATE_BLOB = "DHPRIVATEBLOB";
	public const String LEGACY_DH_PUBLIC_BLOB = "CAPIDHPUBLICBLOB";
	public const String LEGACY_DH_PRIVATE_BLOB = "CAPIDHPRIVATEBLOB";
	public const String BCRYPT_DH_PARAMETERS = "DHParameters";
	public const uint32 BCRYPT_DH_PARAMETERS_MAGIC = 1297107012;
	public const String BCRYPT_DSA_PUBLIC_BLOB = "DSAPUBLICBLOB";
	public const String BCRYPT_DSA_PRIVATE_BLOB = "DSAPRIVATEBLOB";
	public const String LEGACY_DSA_PUBLIC_BLOB = "CAPIDSAPUBLICBLOB";
	public const String LEGACY_DSA_PRIVATE_BLOB = "CAPIDSAPRIVATEBLOB";
	public const String LEGACY_DSA_V2_PUBLIC_BLOB = "V2CAPIDSAPUBLICBLOB";
	public const String LEGACY_DSA_V2_PRIVATE_BLOB = "V2CAPIDSAPRIVATEBLOB";
	public const uint32 BCRYPT_DSA_PUBLIC_MAGIC_V2 = 843206724;
	public const uint32 BCRYPT_DSA_PRIVATE_MAGIC_V2 = 844517444;
	public const uint32 BCRYPT_KEY_DATA_BLOB_MAGIC = 1296188491;
	public const uint32 BCRYPT_KEY_DATA_BLOB_VERSION1 = 1;
	public const String BCRYPT_DSA_PARAMETERS = "DSAParameters";
	public const uint32 BCRYPT_DSA_PARAMETERS_MAGIC = 1297109828;
	public const uint32 BCRYPT_DSA_PARAMETERS_MAGIC_V2 = 843927620;
	public const String BCRYPT_ECC_PARAMETERS = "ECCParameters";
	public const String BCRYPT_ECC_CURVE_NAME = "ECCCurveName";
	public const String BCRYPT_ECC_CURVE_NAME_LIST = "ECCCurveNameList";
	public const uint32 BCRYPT_ECC_PARAMETERS_MAGIC = 1346585413;
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP160R1 = "brainpoolP160r1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP160T1 = "brainpoolP160t1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP192R1 = "brainpoolP192r1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP192T1 = "brainpoolP192t1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP224R1 = "brainpoolP224r1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP224T1 = "brainpoolP224t1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP256R1 = "brainpoolP256r1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP256T1 = "brainpoolP256t1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP320R1 = "brainpoolP320r1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP320T1 = "brainpoolP320t1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP384R1 = "brainpoolP384r1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP384T1 = "brainpoolP384t1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP512R1 = "brainpoolP512r1";
	public const String BCRYPT_ECC_CURVE_BRAINPOOLP512T1 = "brainpoolP512t1";
	public const String BCRYPT_ECC_CURVE_25519 = "curve25519";
	public const String BCRYPT_ECC_CURVE_EC192WAPI = "ec192wapi";
	public const String BCRYPT_ECC_CURVE_NISTP192 = "nistP192";
	public const String BCRYPT_ECC_CURVE_NISTP224 = "nistP224";
	public const String BCRYPT_ECC_CURVE_NISTP256 = "nistP256";
	public const String BCRYPT_ECC_CURVE_NISTP384 = "nistP384";
	public const String BCRYPT_ECC_CURVE_NISTP521 = "nistP521";
	public const String BCRYPT_ECC_CURVE_NUMSP256T1 = "numsP256t1";
	public const String BCRYPT_ECC_CURVE_NUMSP384T1 = "numsP384t1";
	public const String BCRYPT_ECC_CURVE_NUMSP512T1 = "numsP512t1";
	public const String BCRYPT_ECC_CURVE_SECP160K1 = "secP160k1";
	public const String BCRYPT_ECC_CURVE_SECP160R1 = "secP160r1";
	public const String BCRYPT_ECC_CURVE_SECP160R2 = "secP160r2";
	public const String BCRYPT_ECC_CURVE_SECP192K1 = "secP192k1";
	public const String BCRYPT_ECC_CURVE_SECP192R1 = "secP192r1";
	public const String BCRYPT_ECC_CURVE_SECP224K1 = "secP224k1";
	public const String BCRYPT_ECC_CURVE_SECP224R1 = "secP224r1";
	public const String BCRYPT_ECC_CURVE_SECP256K1 = "secP256k1";
	public const String BCRYPT_ECC_CURVE_SECP256R1 = "secP256r1";
	public const String BCRYPT_ECC_CURVE_SECP384R1 = "secP384r1";
	public const String BCRYPT_ECC_CURVE_SECP521R1 = "secP521r1";
	public const String BCRYPT_ECC_CURVE_WTLS7 = "wtls7";
	public const String BCRYPT_ECC_CURVE_WTLS9 = "wtls9";
	public const String BCRYPT_ECC_CURVE_WTLS12 = "wtls12";
	public const String BCRYPT_ECC_CURVE_X962P192V1 = "x962P192v1";
	public const String BCRYPT_ECC_CURVE_X962P192V2 = "x962P192v2";
	public const String BCRYPT_ECC_CURVE_X962P192V3 = "x962P192v3";
	public const String BCRYPT_ECC_CURVE_X962P239V1 = "x962P239v1";
	public const String BCRYPT_ECC_CURVE_X962P239V2 = "x962P239v2";
	public const String BCRYPT_ECC_CURVE_X962P239V3 = "x962P239v3";
	public const String BCRYPT_ECC_CURVE_X962P256V1 = "x962P256v1";
	public const String MS_PRIMITIVE_PROVIDER = "Microsoft Primitive Provider";
	public const String MS_PLATFORM_CRYPTO_PROVIDER = "Microsoft Platform Crypto Provider";
	public const String BCRYPT_RSA_ALGORITHM = "RSA";
	public const String BCRYPT_RSA_SIGN_ALGORITHM = "RSA_SIGN";
	public const String BCRYPT_DH_ALGORITHM = "DH";
	public const String BCRYPT_DSA_ALGORITHM = "DSA";
	public const String BCRYPT_RC2_ALGORITHM = "RC2";
	public const String BCRYPT_RC4_ALGORITHM = "RC4";
	public const String BCRYPT_AES_ALGORITHM = "AES";
	public const String BCRYPT_DES_ALGORITHM = "DES";
	public const String BCRYPT_DESX_ALGORITHM = "DESX";
	public const String BCRYPT_3DES_ALGORITHM = "3DES";
	public const String BCRYPT_3DES_112_ALGORITHM = "3DES_112";
	public const String BCRYPT_MD2_ALGORITHM = "MD2";
	public const String BCRYPT_MD4_ALGORITHM = "MD4";
	public const String BCRYPT_MD5_ALGORITHM = "MD5";
	public const String BCRYPT_SHA1_ALGORITHM = "SHA1";
	public const String BCRYPT_SHA256_ALGORITHM = "SHA256";
	public const String BCRYPT_SHA384_ALGORITHM = "SHA384";
	public const String BCRYPT_SHA512_ALGORITHM = "SHA512";
	public const String BCRYPT_AES_GMAC_ALGORITHM = "AES-GMAC";
	public const String BCRYPT_AES_CMAC_ALGORITHM = "AES-CMAC";
	public const String BCRYPT_ECDSA_P256_ALGORITHM = "ECDSA_P256";
	public const String BCRYPT_ECDSA_P384_ALGORITHM = "ECDSA_P384";
	public const String BCRYPT_ECDSA_P521_ALGORITHM = "ECDSA_P521";
	public const String BCRYPT_ECDH_P256_ALGORITHM = "ECDH_P256";
	public const String BCRYPT_ECDH_P384_ALGORITHM = "ECDH_P384";
	public const String BCRYPT_ECDH_P521_ALGORITHM = "ECDH_P521";
	public const String BCRYPT_RNG_ALGORITHM = "RNG";
	public const String BCRYPT_RNG_FIPS186_DSA_ALGORITHM = "FIPS186DSARNG";
	public const String BCRYPT_RNG_DUAL_EC_ALGORITHM = "DUALECRNG";
	public const String BCRYPT_SP800108_CTR_HMAC_ALGORITHM = "SP800_108_CTR_HMAC";
	public const String BCRYPT_SP80056A_CONCAT_ALGORITHM = "SP800_56A_CONCAT";
	public const String BCRYPT_PBKDF2_ALGORITHM = "PBKDF2";
	public const String BCRYPT_CAPI_KDF_ALGORITHM = "CAPI_KDF";
	public const String BCRYPT_TLS1_1_KDF_ALGORITHM = "TLS1_1_KDF";
	public const String BCRYPT_TLS1_2_KDF_ALGORITHM = "TLS1_2_KDF";
	public const String BCRYPT_ECDSA_ALGORITHM = "ECDSA";
	public const String BCRYPT_ECDH_ALGORITHM = "ECDH";
	public const String BCRYPT_XTS_AES_ALGORITHM = "XTS-AES";
	public const String BCRYPT_HKDF_ALGORITHM = "HKDF";
	public const String BCRYPT_CHACHA20_POLY1305_ALGORITHM = "CHACHA20_POLY1305";
	public const uint32 BCRYPT_KEY_DERIVATION_INTERFACE = 7;
	public const BCRYPT_ALG_HANDLE BCRYPT_MD2_ALG_HANDLE = 1;
	public const BCRYPT_ALG_HANDLE BCRYPT_MD4_ALG_HANDLE = 17;
	public const BCRYPT_ALG_HANDLE BCRYPT_MD5_ALG_HANDLE = 33;
	public const BCRYPT_ALG_HANDLE BCRYPT_SHA1_ALG_HANDLE = 49;
	public const BCRYPT_ALG_HANDLE BCRYPT_SHA256_ALG_HANDLE = 65;
	public const BCRYPT_ALG_HANDLE BCRYPT_SHA384_ALG_HANDLE = 81;
	public const BCRYPT_ALG_HANDLE BCRYPT_SHA512_ALG_HANDLE = 97;
	public const BCRYPT_ALG_HANDLE BCRYPT_RC4_ALG_HANDLE = 113;
	public const BCRYPT_ALG_HANDLE BCRYPT_RNG_ALG_HANDLE = 129;
	public const BCRYPT_ALG_HANDLE BCRYPT_HMAC_MD5_ALG_HANDLE = 145;
	public const BCRYPT_ALG_HANDLE BCRYPT_HMAC_SHA1_ALG_HANDLE = 161;
	public const BCRYPT_ALG_HANDLE BCRYPT_HMAC_SHA256_ALG_HANDLE = 177;
	public const BCRYPT_ALG_HANDLE BCRYPT_HMAC_SHA384_ALG_HANDLE = 193;
	public const BCRYPT_ALG_HANDLE BCRYPT_HMAC_SHA512_ALG_HANDLE = 209;
	public const BCRYPT_ALG_HANDLE BCRYPT_RSA_ALG_HANDLE = 225;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDSA_ALG_HANDLE = 241;
	public const BCRYPT_ALG_HANDLE BCRYPT_AES_CMAC_ALG_HANDLE = 257;
	public const BCRYPT_ALG_HANDLE BCRYPT_AES_GMAC_ALG_HANDLE = 273;
	public const BCRYPT_ALG_HANDLE BCRYPT_HMAC_MD2_ALG_HANDLE = 289;
	public const BCRYPT_ALG_HANDLE BCRYPT_HMAC_MD4_ALG_HANDLE = 305;
	public const BCRYPT_ALG_HANDLE BCRYPT_3DES_CBC_ALG_HANDLE = 321;
	public const BCRYPT_ALG_HANDLE BCRYPT_3DES_ECB_ALG_HANDLE = 337;
	public const BCRYPT_ALG_HANDLE BCRYPT_3DES_CFB_ALG_HANDLE = 353;
	public const BCRYPT_ALG_HANDLE BCRYPT_3DES_112_CBC_ALG_HANDLE = 369;
	public const BCRYPT_ALG_HANDLE BCRYPT_3DES_112_ECB_ALG_HANDLE = 385;
	public const BCRYPT_ALG_HANDLE BCRYPT_3DES_112_CFB_ALG_HANDLE = 401;
	public const BCRYPT_ALG_HANDLE BCRYPT_AES_CBC_ALG_HANDLE = 417;
	public const BCRYPT_ALG_HANDLE BCRYPT_AES_ECB_ALG_HANDLE = 433;
	public const BCRYPT_ALG_HANDLE BCRYPT_AES_CFB_ALG_HANDLE = 449;
	public const BCRYPT_ALG_HANDLE BCRYPT_AES_CCM_ALG_HANDLE = 465;
	public const BCRYPT_ALG_HANDLE BCRYPT_AES_GCM_ALG_HANDLE = 481;
	public const BCRYPT_ALG_HANDLE BCRYPT_DES_CBC_ALG_HANDLE = 497;
	public const BCRYPT_ALG_HANDLE BCRYPT_DES_ECB_ALG_HANDLE = 513;
	public const BCRYPT_ALG_HANDLE BCRYPT_DES_CFB_ALG_HANDLE = 529;
	public const BCRYPT_ALG_HANDLE BCRYPT_DESX_CBC_ALG_HANDLE = 545;
	public const BCRYPT_ALG_HANDLE BCRYPT_DESX_ECB_ALG_HANDLE = 561;
	public const BCRYPT_ALG_HANDLE BCRYPT_DESX_CFB_ALG_HANDLE = 577;
	public const BCRYPT_ALG_HANDLE BCRYPT_RC2_CBC_ALG_HANDLE = 593;
	public const BCRYPT_ALG_HANDLE BCRYPT_RC2_ECB_ALG_HANDLE = 609;
	public const BCRYPT_ALG_HANDLE BCRYPT_RC2_CFB_ALG_HANDLE = 625;
	public const BCRYPT_ALG_HANDLE BCRYPT_DH_ALG_HANDLE = 641;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDH_ALG_HANDLE = 657;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDH_P256_ALG_HANDLE = 673;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDH_P384_ALG_HANDLE = 689;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDH_P521_ALG_HANDLE = 705;
	public const BCRYPT_ALG_HANDLE BCRYPT_DSA_ALG_HANDLE = 721;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDSA_P256_ALG_HANDLE = 737;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDSA_P384_ALG_HANDLE = 753;
	public const BCRYPT_ALG_HANDLE BCRYPT_ECDSA_P521_ALG_HANDLE = 769;
	public const BCRYPT_ALG_HANDLE BCRYPT_RSA_SIGN_ALG_HANDLE = 785;
	public const BCRYPT_ALG_HANDLE BCRYPT_CAPI_KDF_ALG_HANDLE = 801;
	public const BCRYPT_ALG_HANDLE BCRYPT_PBKDF2_ALG_HANDLE = 817;
	public const BCRYPT_ALG_HANDLE BCRYPT_SP800108_CTR_HMAC_ALG_HANDLE = 833;
	public const BCRYPT_ALG_HANDLE BCRYPT_SP80056A_CONCAT_ALG_HANDLE = 849;
	public const BCRYPT_ALG_HANDLE BCRYPT_TLS1_1_KDF_ALG_HANDLE = 865;
	public const BCRYPT_ALG_HANDLE BCRYPT_TLS1_2_KDF_ALG_HANDLE = 881;
	public const BCRYPT_ALG_HANDLE BCRYPT_XTS_AES_ALG_HANDLE = 897;
	public const BCRYPT_ALG_HANDLE BCRYPT_HKDF_ALG_HANDLE = 913;
	public const BCRYPT_ALG_HANDLE BCRYPT_CHACHA20_POLY1305_ALG_HANDLE = 929;
	public const uint32 BCRYPT_CAPI_AES_FLAG = 16;
	public const uint32 BCRYPT_MULTI_FLAG = 64;
	public const uint32 BCRYPT_TLS_CBC_HMAC_VERIFY_FLAG = 4;
	public const uint32 BCRYPT_BUFFERS_LOCKED_FLAG = 64;
	public const uint32 BCRYPT_EXTENDED_KEYSIZE = 128;
	public const uint32 BCRYPT_ENABLE_INCOMPATIBLE_FIPS_CHECKS = 256;
	public const uint32 BCRYPT_KEY_DERIVATION_OPERATION = 64;
	public const uint32 BCRYPT_PUBLIC_KEY_FLAG = 1;
	public const uint32 BCRYPT_PRIVATE_KEY_FLAG = 2;
	public const uint32 BCRYPT_NO_KEY_VALIDATION = 8;
	public const uint32 BCRYPT_KEY_VALIDATION_RANGE = 16;
	public const uint32 BCRYPT_KEY_VALIDATION_RANGE_AND_ORDER = 24;
	public const uint32 BCRYPT_KEY_VALIDATION_REGENERATE = 32;
	public const uint32 BCRYPT_RNG_USE_ENTROPY_IN_BUFFER = 1;
	public const uint32 BCRYPT_USE_SYSTEM_PREFERRED_RNG = 2;
	public const uint32 BCRYPT_HASH_INTERFACE_MAJORVERSION_2 = 2;
	public const uint32 CRYPT_OVERWRITE = 1;
	public const uint32 CRYPT_PRIORITY_TOP = 0;
	public const uint32 CRYPT_PRIORITY_BOTTOM = 4294967295;
	public const String CRYPT_DEFAULT_CONTEXT = "Default";
	public const String wszXMLNS_DIGSIG = "http://www.w3.org/2000/09/xmldsig#";
	public const String wszXMLNS_DIGSIG_SignatureProperties = "http://www.w3.org/2000/09/xmldsig#SignatureProperties";
	public const String wszXMLNS_DIGSIG_Id = "Id";
	public const String wszURI_XMLNS_DIGSIG_BASE64 = "http://www.w3.org/2000/09/xmldsig#base64";
	public const String wszURI_XMLNS_DIGSIG_SHA1 = "http://www.w3.org/2000/09/xmldsig#sha1";
	public const String wszURI_XMLNS_DIGSIG_SHA256 = "http://www.w3.org/2001/04/xmlenc#sha256";
	public const String wszURI_XMLNS_DIGSIG_SHA384 = "http://www.w3.org/2001/04/xmldsig-more#sha384";
	public const String wszURI_XMLNS_DIGSIG_SHA512 = "http://www.w3.org/2001/04/xmlenc#sha512";
	public const String wszURI_XMLNS_DIGSIG_RSA_SHA1 = "http://www.w3.org/2000/09/xmldsig#rsa-sha1";
	public const String wszURI_XMLNS_DIGSIG_DSA_SHA1 = "http://www.w3.org/2000/09/xmldsig#dsa-sha1";
	public const String wszURI_XMLNS_DIGSIG_RSA_SHA256 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256";
	public const String wszURI_XMLNS_DIGSIG_RSA_SHA384 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384";
	public const String wszURI_XMLNS_DIGSIG_RSA_SHA512 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512";
	public const String wszURI_XMLNS_DIGSIG_ECDSA_SHA1 = "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha1";
	public const String wszURI_XMLNS_DIGSIG_ECDSA_SHA256 = "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256";
	public const String wszURI_XMLNS_DIGSIG_ECDSA_SHA384 = "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha384";
	public const String wszURI_XMLNS_DIGSIG_ECDSA_SHA512 = "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha512";
	public const String wszURI_XMLNS_DIGSIG_HMAC_SHA1 = "http://www.w3.org/2000/09/xmldsig#hmac-sha1";
	public const String wszURI_XMLNS_DIGSIG_HMAC_SHA256 = "http://www.w3.org/2001/04/xmldsig-more#hmac-sha256";
	public const String wszURI_XMLNS_DIGSIG_HMAC_SHA384 = "http://www.w3.org/2001/04/xmldsig-more#hmac-sha384";
	public const String wszURI_XMLNS_DIGSIG_HMAC_SHA512 = "http://www.w3.org/2001/04/xmldsig-more#hmac-sha512";
	public const String wszURI_CANONICALIZATION_C14N = "http://www.w3.org/TR/2001/REC-xml-c14n-20010315";
	public const String wszURI_CANONICALIZATION_C14NC = "http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments";
	public const String wszURI_CANONICALIZATION_EXSLUSIVE_C14N = "http://www.w3.org/2001/10/xml-exc-c14n#";
	public const String wszURI_CANONICALIZATION_EXSLUSIVE_C14NC = "http://www.w3.org/2001/10/xml-exc-c14n#WithComments";
	public const String wszURI_TRANSFORM_XPATH = "http://www.w3.org/TR/1999/REC-xpath-19991116";
	public const String wszURI_XMLNS_TRANSFORM_BASE64 = "http://www.w3.org/2000/09/xmldsig#base64";
	public const String wszURI_XMLNS_TRANSFORM_ENVELOPED = "http://www.w3.org/2000/09/xmldsig#enveloped-signature";
	public const uint32 CRYPT_XML_BLOB_MAX = 2147483640;
	public const uint32 CRYPT_XML_ID_MAX = 256;
	public const uint32 CRYPT_XML_SIGNATURES_MAX = 16;
	public const uint32 CRYPT_XML_TRANSFORM_MAX = 16;
	public const uint32 CRYPT_XML_SIGNATURE_VALUE_MAX = 2048;
	public const uint32 CRYPT_XML_DIGEST_VALUE_MAX = 128;
	public const uint32 CRYPT_XML_OBJECTS_MAX = 256;
	public const uint32 CRYPT_XML_REFERENCES_MAX = 32760;
	public const HRESULT CRYPT_XML_E_BASE = -2146885376;
	public const HRESULT CRYPT_XML_E_LARGE = -2146885375;
	public const HRESULT CRYPT_XML_E_TOO_MANY_TRANSFORMS = -2146885374;
	public const HRESULT CRYPT_XML_E_ENCODING = -2146885373;
	public const HRESULT CRYPT_XML_E_ALGORITHM = -2146885372;
	public const HRESULT CRYPT_XML_E_TRANSFORM = -2146885371;
	public const HRESULT CRYPT_XML_E_HANDLE = -2146885370;
	public const HRESULT CRYPT_XML_E_OPERATION = -2146885369;
	public const HRESULT CRYPT_XML_E_UNRESOLVED_REFERENCE = -2146885368;
	public const HRESULT CRYPT_XML_E_INVALID_DIGEST = -2146885367;
	public const HRESULT CRYPT_XML_E_INVALID_SIGNATURE = -2146885366;
	public const HRESULT CRYPT_XML_E_HASH_FAILED = -2146885365;
	public const HRESULT CRYPT_XML_E_SIGN_FAILED = -2146885364;
	public const HRESULT CRYPT_XML_E_VERIFY_FAILED = -2146885363;
	public const HRESULT CRYPT_XML_E_TOO_MANY_SIGNATURES = -2146885362;
	public const HRESULT CRYPT_XML_E_INVALID_KEYVALUE = -2146885361;
	public const HRESULT CRYPT_XML_E_UNEXPECTED_XML = -2146885360;
	public const HRESULT CRYPT_XML_E_SIGNER = -2146885359;
	public const HRESULT CRYPT_XML_E_NON_UNIQUE_ID = -2146885358;
	public const HRESULT CRYPT_XML_E_LAST = -2146885358;
	public const uint32 CRYPT_XML_FLAG_ALWAYS_RETURN_ENCODED_OBJECT = 1073741824;
	public const uint32 CRYPT_XML_FLAG_ENFORCE_ID_NCNAME_FORMAT = 536870912;
	public const uint32 CRYPT_XML_FLAG_ENFORCE_ID_NAME_FORMAT = 134217728;
	public const uint32 CRYPT_XML_FLAG_ECDSA_DSIG11 = 67108864;
	public const uint32 CRYPT_XML_STATUS_NO_ERROR = 0;
	public const uint32 CRYPT_XML_FLAG_ADD_OBJECT_CREATE_COPY = 1;
	public const uint32 CRYPT_XML_FLAG_CREATE_REFERENCE_AS_OBJECT = 1;
	public const uint32 CRYPT_XML_DIGEST_REFERENCE_DATA_TRANSFORMED = 1;
	public const uint32 CRYPT_XML_ALGORITHM_INFO_FIND_BY_URI = 1;
	public const uint32 CRYPT_XML_ALGORITHM_INFO_FIND_BY_NAME = 2;
	public const uint32 CRYPT_XML_ALGORITHM_INFO_FIND_BY_CNG_ALGID = 3;
	public const uint32 CRYPT_XML_ALGORITHM_INFO_FIND_BY_CNG_SIGN_ALGID = 4;
	public const String szFORCE_KEY_PROTECTION = "ForceKeyProtection";
	public const uint32 dwFORCE_KEY_PROTECTION_DISABLED = 0;
	public const uint32 dwFORCE_KEY_PROTECTION_USER_SELECT = 1;
	public const uint32 dwFORCE_KEY_PROTECTION_HIGH = 2;
	public const uint32 CRYPTPROTECT_PROMPT_ON_UNPROTECT = 1;
	public const uint32 CRYPTPROTECT_PROMPT_ON_PROTECT = 2;
	public const uint32 CRYPTPROTECT_PROMPT_RESERVED = 4;
	public const uint32 CRYPTPROTECT_PROMPT_STRONG = 8;
	public const uint32 CRYPTPROTECT_PROMPT_REQUIRE_STRONG = 16;
	public const uint32 CRYPTPROTECT_UI_FORBIDDEN = 1;
	public const uint32 CRYPTPROTECT_LOCAL_MACHINE = 4;
	public const uint32 CRYPTPROTECT_CRED_SYNC = 8;
	public const uint32 CRYPTPROTECT_AUDIT = 16;
	public const uint32 CRYPTPROTECT_NO_RECOVERY = 32;
	public const uint32 CRYPTPROTECT_VERIFY_PROTECTION = 64;
	public const uint32 CRYPTPROTECT_CRED_REGENERATE = 128;
	public const uint32 CRYPTPROTECT_FIRST_RESERVED_FLAGVAL = 268435455;
	public const uint32 CRYPTPROTECT_LAST_RESERVED_FLAGVAL = 4294967295;
	public const uint32 CRYPTPROTECTMEMORY_BLOCK_SIZE = 16;
	public const uint32 CRYPTPROTECTMEMORY_SAME_PROCESS = 0;
	public const uint32 CRYPTPROTECTMEMORY_CROSS_PROCESS = 1;
	public const uint32 CRYPTPROTECTMEMORY_SAME_LOGON = 2;
	public const uint32 NCRYPT_MAX_KEY_NAME_LENGTH = 512;
	public const uint32 NCRYPT_MAX_ALG_ID_LENGTH = 512;
	public const String MS_KEY_STORAGE_PROVIDER = "Microsoft Software Key Storage Provider";
	public const String MS_SMART_CARD_KEY_STORAGE_PROVIDER = "Microsoft Smart Card Key Storage Provider";
	public const String MS_PLATFORM_KEY_STORAGE_PROVIDER = "Microsoft Platform Crypto Provider";
	public const String MS_NGC_KEY_STORAGE_PROVIDER = "Microsoft Passport Key Storage Provider";
	public const String TPM_RSA_SRK_SEAL_KEY = "MICROSOFT_PCP_KSP_RSA_SEAL_KEY_3BD1C4BF-004E-4E2F-8A4D-0BF633DCB074";
	public const String NCRYPT_RSA_ALGORITHM = "RSA";
	public const String NCRYPT_RSA_SIGN_ALGORITHM = "RSA_SIGN";
	public const String NCRYPT_DH_ALGORITHM = "DH";
	public const String NCRYPT_DSA_ALGORITHM = "DSA";
	public const String NCRYPT_MD2_ALGORITHM = "MD2";
	public const String NCRYPT_MD4_ALGORITHM = "MD4";
	public const String NCRYPT_MD5_ALGORITHM = "MD5";
	public const String NCRYPT_SHA1_ALGORITHM = "SHA1";
	public const String NCRYPT_SHA256_ALGORITHM = "SHA256";
	public const String NCRYPT_SHA384_ALGORITHM = "SHA384";
	public const String NCRYPT_SHA512_ALGORITHM = "SHA512";
	public const String NCRYPT_ECDSA_P256_ALGORITHM = "ECDSA_P256";
	public const String NCRYPT_ECDSA_P384_ALGORITHM = "ECDSA_P384";
	public const String NCRYPT_ECDSA_P521_ALGORITHM = "ECDSA_P521";
	public const String NCRYPT_ECDH_P256_ALGORITHM = "ECDH_P256";
	public const String NCRYPT_ECDH_P384_ALGORITHM = "ECDH_P384";
	public const String NCRYPT_ECDH_P521_ALGORITHM = "ECDH_P521";
	public const String NCRYPT_AES_ALGORITHM = "AES";
	public const String NCRYPT_RC2_ALGORITHM = "RC2";
	public const String NCRYPT_3DES_ALGORITHM = "3DES";
	public const String NCRYPT_DES_ALGORITHM = "DES";
	public const String NCRYPT_DESX_ALGORITHM = "DESX";
	public const String NCRYPT_3DES_112_ALGORITHM = "3DES_112";
	public const String NCRYPT_SP800108_CTR_HMAC_ALGORITHM = "SP800_108_CTR_HMAC";
	public const String NCRYPT_SP80056A_CONCAT_ALGORITHM = "SP800_56A_CONCAT";
	public const String NCRYPT_PBKDF2_ALGORITHM = "PBKDF2";
	public const String NCRYPT_CAPI_KDF_ALGORITHM = "CAPI_KDF";
	public const String NCRYPT_ECDSA_ALGORITHM = "ECDSA";
	public const String NCRYPT_ECDH_ALGORITHM = "ECDH";
	public const String NCRYPT_KEY_STORAGE_ALGORITHM = "KEY_STORAGE";
	public const String NCRYPT_HMAC_SHA256_ALGORITHM = "HMAC-SHA256";
	public const uint32 NCRYPT_KEY_DERIVATION_INTERFACE = 7;
	public const uint32 NCRYPT_KEY_PROTECTION_INTERFACE = 65540;
	public const String NCRYPT_RSA_ALGORITHM_GROUP = "RSA";
	public const String NCRYPT_DH_ALGORITHM_GROUP = "DH";
	public const String NCRYPT_DSA_ALGORITHM_GROUP = "DSA";
	public const String NCRYPT_ECDSA_ALGORITHM_GROUP = "ECDSA";
	public const String NCRYPT_ECDH_ALGORITHM_GROUP = "ECDH";
	public const String NCRYPT_AES_ALGORITHM_GROUP = "AES";
	public const String NCRYPT_RC2_ALGORITHM_GROUP = "RC2";
	public const String NCRYPT_DES_ALGORITHM_GROUP = "DES";
	public const String NCRYPT_KEY_DERIVATION_GROUP = "KEY_DERIVATION";
	public const uint32 NCRYPTBUFFER_VERSION = 0;
	public const uint32 NCRYPTBUFFER_EMPTY = 0;
	public const uint32 NCRYPTBUFFER_DATA = 1;
	public const uint32 NCRYPTBUFFER_PROTECTION_DESCRIPTOR_STRING = 3;
	public const uint32 NCRYPTBUFFER_PROTECTION_FLAGS = 4;
	public const uint32 NCRYPTBUFFER_SSL_CLIENT_RANDOM = 20;
	public const uint32 NCRYPTBUFFER_SSL_SERVER_RANDOM = 21;
	public const uint32 NCRYPTBUFFER_SSL_HIGHEST_VERSION = 22;
	public const uint32 NCRYPTBUFFER_SSL_CLEAR_KEY = 23;
	public const uint32 NCRYPTBUFFER_SSL_KEY_ARG_DATA = 24;
	public const uint32 NCRYPTBUFFER_SSL_SESSION_HASH = 25;
	public const uint32 NCRYPTBUFFER_PKCS_OID = 40;
	public const uint32 NCRYPTBUFFER_PKCS_ALG_OID = 41;
	public const uint32 NCRYPTBUFFER_PKCS_ALG_PARAM = 42;
	public const uint32 NCRYPTBUFFER_PKCS_ALG_ID = 43;
	public const uint32 NCRYPTBUFFER_PKCS_ATTRS = 44;
	public const uint32 NCRYPTBUFFER_PKCS_KEY_NAME = 45;
	public const uint32 NCRYPTBUFFER_PKCS_SECRET = 46;
	public const uint32 NCRYPTBUFFER_CERT_BLOB = 47;
	public const uint32 NCRYPTBUFFER_CLAIM_IDBINDING_NONCE = 48;
	public const uint32 NCRYPTBUFFER_CLAIM_KEYATTESTATION_NONCE = 49;
	public const uint32 NCRYPTBUFFER_KEY_PROPERTY_FLAGS = 50;
	public const uint32 NCRYPTBUFFER_ATTESTATIONSTATEMENT_BLOB = 51;
	public const uint32 NCRYPTBUFFER_ATTESTATION_CLAIM_TYPE = 52;
	public const uint32 NCRYPTBUFFER_ATTESTATION_CLAIM_CHALLENGE_REQUIRED = 53;
	public const uint32 NCRYPTBUFFER_VSM_KEY_ATTESTATION_CLAIM_RESTRICTIONS = 54;
	public const uint32 NCRYPTBUFFER_ECC_CURVE_NAME = 60;
	public const uint32 NCRYPTBUFFER_ECC_PARAMETERS = 61;
	public const uint32 NCRYPTBUFFER_TPM_SEAL_PASSWORD = 70;
	public const uint32 NCRYPTBUFFER_TPM_SEAL_POLICYINFO = 71;
	public const uint32 NCRYPTBUFFER_TPM_SEAL_TICKET = 72;
	public const uint32 NCRYPTBUFFER_TPM_SEAL_NO_DA_PROTECTION = 73;
	public const uint32 NCRYPTBUFFER_TPM_PLATFORM_CLAIM_PCR_MASK = 80;
	public const uint32 NCRYPTBUFFER_TPM_PLATFORM_CLAIM_NONCE = 81;
	public const uint32 NCRYPTBUFFER_TPM_PLATFORM_CLAIM_STATIC_CREATE = 82;
	public const uint32 NCRYPT_CIPHER_NO_PADDING_FLAG = 0;
	public const uint32 NCRYPT_CIPHER_BLOCK_PADDING_FLAG = 1;
	public const uint32 NCRYPT_CIPHER_OTHER_PADDING_FLAG = 2;
	public const uint32 NCRYPT_PLATFORM_ATTEST_MAGIC = 1146110288;
	public const uint32 NCRYPT_KEY_ATTEST_MAGIC = 1146110283;
	public const uint32 NCRYPT_CLAIM_AUTHORITY_ONLY = 1;
	public const uint32 NCRYPT_CLAIM_SUBJECT_ONLY = 2;
	public const uint32 NCRYPT_CLAIM_WEB_AUTH_SUBJECT_ONLY = 258;
	public const uint32 NCRYPT_CLAIM_AUTHORITY_AND_SUBJECT = 3;
	public const uint32 NCRYPT_CLAIM_VSM_KEY_ATTESTATION_STATEMENT = 4;
	public const uint32 NCRYPT_CLAIM_UNKNOWN = 4096;
	public const uint32 NCRYPT_CLAIM_PLATFORM = 65536;
	public const uint32 NCRYPT_ISOLATED_KEY_FLAG_CREATED_IN_ISOLATION = 1;
	public const uint32 NCRYPT_ISOLATED_KEY_FLAG_IMPORT_ONLY = 2;
	public const uint32 NCRYPT_ISOLATED_KEY_ATTESTED_ATTRIBUTES_V0 = 0;
	public const uint32 NCRYPT_ISOLATED_KEY_ATTESTED_ATTRIBUTES_CURRENT_VERSION = 0;
	public const uint32 NCRYPT_VSM_KEY_ATTESTATION_STATEMENT_V0 = 0;
	public const uint32 NCRYPT_VSM_KEY_ATTESTATION_STATEMENT_CURRENT_VERSION = 0;
	public const uint32 NCRYPT_VSM_KEY_ATTESTATION_CLAIM_RESTRICTIONS_V0 = 0;
	public const uint32 NCRYPT_VSM_KEY_ATTESTATION_CLAIM_RESTRICTIONS_CURRENT_VERSION = 0;
	public const uint32 NCRYPT_EXPORTED_ISOLATED_KEY_HEADER_V0 = 0;
	public const uint32 NCRYPT_EXPORTED_ISOLATED_KEY_HEADER_CURRENT_VERSION = 0;
	public const uint32 NCRYPT_TPM_PLATFORM_ATTESTATION_STATEMENT_V0 = 0;
	public const uint32 NCRYPT_TPM_PLATFORM_ATTESTATION_STATEMENT_CURRENT_VERSION = 0;
	public const uint32 NCRYPT_PAD_CIPHER_FLAG = 16;
	public const uint32 NCRYPT_ATTESTATION_FLAG = 32;
	public const uint32 NCRYPT_SEALING_FLAG = 256;
	public const uint32 NCRYPT_DO_NOT_FINALIZE_FLAG = 1024;
	public const uint32 NCRYPT_EXPORT_LEGACY_FLAG = 2048;
	public const uint32 NCRYPT_IGNORE_DEVICE_STATE_FLAG = 4096;
	public const uint32 NCRYPT_TREAT_NIST_AS_GENERIC_ECC_FLAG = 8192;
	public const uint32 NCRYPT_NO_CACHED_PASSWORD = 16384;
	public const uint32 NCRYPT_PROTECT_TO_LOCAL_SYSTEM = 32768;
	public const uint32 NCRYPT_PREFER_VIRTUAL_ISOLATION_FLAG = 65536;
	public const uint32 NCRYPT_USE_VIRTUAL_ISOLATION_FLAG = 131072;
	public const uint32 NCRYPT_USE_PER_BOOT_KEY_FLAG = 262144;
	public const uint32 NCRYPT_KEY_DERIVATION_OPERATION = 64;
	public const uint32 NCRYPT_AUTHORITY_KEY_FLAG = 256;
	public const String NCRYPT_NAME_PROPERTY = "Name";
	public const String NCRYPT_UNIQUE_NAME_PROPERTY = "Unique Name";
	public const String NCRYPT_ALGORITHM_PROPERTY = "Algorithm Name";
	public const String NCRYPT_LENGTH_PROPERTY = "Length";
	public const String NCRYPT_LENGTHS_PROPERTY = "Lengths";
	public const String NCRYPT_BLOCK_LENGTH_PROPERTY = "Block Length";
	public const String NCRYPT_PUBLIC_LENGTH_PROPERTY = "PublicKeyLength";
	public const String NCRYPT_SIGNATURE_LENGTH_PROPERTY = "SignatureLength";
	public const String NCRYPT_CHAINING_MODE_PROPERTY = "Chaining Mode";
	public const String NCRYPT_AUTH_TAG_LENGTH = "AuthTagLength";
	public const String NCRYPT_UI_POLICY_PROPERTY = "UI Policy";
	public const String NCRYPT_EXPORT_POLICY_PROPERTY = "Export Policy";
	public const String NCRYPT_WINDOW_HANDLE_PROPERTY = "HWND Handle";
	public const String NCRYPT_USE_CONTEXT_PROPERTY = "Use Context";
	public const String NCRYPT_IMPL_TYPE_PROPERTY = "Impl Type";
	public const String NCRYPT_KEY_USAGE_PROPERTY = "Key Usage";
	public const String NCRYPT_KEY_TYPE_PROPERTY = "Key Type";
	public const String NCRYPT_VERSION_PROPERTY = "Version";
	public const String NCRYPT_SECURITY_DESCR_SUPPORT_PROPERTY = "Security Descr Support";
	public const String NCRYPT_SECURITY_DESCR_PROPERTY = "Security Descr";
	public const String NCRYPT_USE_COUNT_ENABLED_PROPERTY = "Enabled Use Count";
	public const String NCRYPT_USE_COUNT_PROPERTY = "Use Count";
	public const String NCRYPT_LAST_MODIFIED_PROPERTY = "Modified";
	public const String NCRYPT_MAX_NAME_LENGTH_PROPERTY = "Max Name Length";
	public const String NCRYPT_ALGORITHM_GROUP_PROPERTY = "Algorithm Group";
	public const String NCRYPT_DH_PARAMETERS_PROPERTY = "DHParameters";
	public const String NCRYPT_ECC_PARAMETERS_PROPERTY = "ECCParameters";
	public const String NCRYPT_ECC_CURVE_NAME_PROPERTY = "ECCCurveName";
	public const String NCRYPT_ECC_CURVE_NAME_LIST_PROPERTY = "ECCCurveNameList";
	public const String NCRYPT_USE_VIRTUAL_ISOLATION_PROPERTY = "Virtual Iso";
	public const String NCRYPT_USE_PER_BOOT_KEY_PROPERTY = "Per Boot Key";
	public const String NCRYPT_PROVIDER_HANDLE_PROPERTY = "Provider Handle";
	public const String NCRYPT_PIN_PROPERTY = "SmartCardPin";
	public const String NCRYPT_READER_PROPERTY = "SmartCardReader";
	public const String NCRYPT_SMARTCARD_GUID_PROPERTY = "SmartCardGuid";
	public const String NCRYPT_CERTIFICATE_PROPERTY = "SmartCardKeyCertificate";
	public const String NCRYPT_PIN_PROMPT_PROPERTY = "SmartCardPinPrompt";
	public const String NCRYPT_USER_CERTSTORE_PROPERTY = "SmartCardUserCertStore";
	public const String NCRYPT_ROOT_CERTSTORE_PROPERTY = "SmartcardRootCertStore";
	public const String NCRYPT_SECURE_PIN_PROPERTY = "SmartCardSecurePin";
	public const String NCRYPT_ASSOCIATED_ECDH_KEY = "SmartCardAssociatedECDHKey";
	public const String NCRYPT_SCARD_PIN_ID = "SmartCardPinId";
	public const String NCRYPT_SCARD_PIN_INFO = "SmartCardPinInfo";
	public const String NCRYPT_READER_ICON_PROPERTY = "SmartCardReaderIcon";
	public const String NCRYPT_KDF_SECRET_VALUE = "KDFKeySecret";
	public const String NCRYPT_DISMISS_UI_TIMEOUT_SEC_PROPERTY = "SmartCardDismissUITimeoutSeconds";
	public const String NCRYPT_PCP_PLATFORM_TYPE_PROPERTY = "PCP_PLATFORM_TYPE";
	public const String NCRYPT_PCP_PROVIDER_VERSION_PROPERTY = "PCP_PROVIDER_VERSION";
	public const String NCRYPT_PCP_EKPUB_PROPERTY = "PCP_EKPUB";
	public const String NCRYPT_PCP_EKCERT_PROPERTY = "PCP_EKCERT";
	public const String NCRYPT_PCP_EKNVCERT_PROPERTY = "PCP_EKNVCERT";
	public const String NCRYPT_PCP_RSA_EKPUB_PROPERTY = "PCP_RSA_EKPUB";
	public const String NCRYPT_PCP_RSA_EKCERT_PROPERTY = "PCP_RSA_EKCERT";
	public const String NCRYPT_PCP_RSA_EKNVCERT_PROPERTY = "PCP_RSA_EKNVCERT";
	public const String NCRYPT_PCP_ECC_EKPUB_PROPERTY = "PCP_ECC_EKPUB";
	public const String NCRYPT_PCP_ECC_EKCERT_PROPERTY = "PCP_ECC_EKCERT";
	public const String NCRYPT_PCP_ECC_EKNVCERT_PROPERTY = "PCP_ECC_EKNVCERT";
	public const String NCRYPT_PCP_SRKPUB_PROPERTY = "PCP_SRKPUB";
	public const String NCRYPT_PCP_PCRTABLE_PROPERTY = "PCP_PCRTABLE";
	public const String NCRYPT_PCP_CHANGEPASSWORD_PROPERTY = "PCP_CHANGEPASSWORD";
	public const String NCRYPT_PCP_PASSWORD_REQUIRED_PROPERTY = "PCP_PASSWORD_REQUIRED";
	public const String NCRYPT_PCP_USAGEAUTH_PROPERTY = "PCP_USAGEAUTH";
	public const String NCRYPT_PCP_MIGRATIONPASSWORD_PROPERTY = "PCP_MIGRATIONPASSWORD";
	public const String NCRYPT_PCP_EXPORT_ALLOWED_PROPERTY = "PCP_EXPORT_ALLOWED";
	public const String NCRYPT_PCP_STORAGEPARENT_PROPERTY = "PCP_STORAGEPARENT";
	public const String NCRYPT_PCP_PROVIDERHANDLE_PROPERTY = "PCP_PROVIDERMHANDLE";
	public const String NCRYPT_PCP_PLATFORMHANDLE_PROPERTY = "PCP_PLATFORMHANDLE";
	public const String NCRYPT_PCP_PLATFORM_BINDING_PCRMASK_PROPERTY = "PCP_PLATFORM_BINDING_PCRMASK";
	public const String NCRYPT_PCP_PLATFORM_BINDING_PCRDIGESTLIST_PROPERTY = "PCP_PLATFORM_BINDING_PCRDIGESTLIST";
	public const String NCRYPT_PCP_PLATFORM_BINDING_PCRDIGEST_PROPERTY = "PCP_PLATFORM_BINDING_PCRDIGEST";
	public const String NCRYPT_PCP_KEY_USAGE_POLICY_PROPERTY = "PCP_KEY_USAGE_POLICY";
	public const String NCRYPT_PCP_RSA_SCHEME_PROPERTY = "PCP_RSA_SCHEME";
	public const String NCRYPT_PCP_TPM12_IDBINDING_PROPERTY = "PCP_TPM12_IDBINDING";
	public const String NCRYPT_PCP_TPM12_IDBINDING_DYNAMIC_PROPERTY = "PCP_TPM12_IDBINDING_DYNAMIC";
	public const String NCRYPT_PCP_TPM12_IDACTIVATION_PROPERTY = "PCP_TPM12_IDACTIVATION";
	public const String NCRYPT_PCP_KEYATTESTATION_PROPERTY = "PCP_TPM12_KEYATTESTATION";
	public const String NCRYPT_PCP_ALTERNATE_KEY_STORAGE_LOCATION_PROPERTY = "PCP_ALTERNATE_KEY_STORAGE_LOCATION";
	public const String NCRYPT_PCP_PLATFORM_BINDING_PCRALGID_PROPERTY = "PCP_PLATFORM_BINDING_PCRALGID";
	public const String NCRYPT_PCP_HMAC_AUTH_POLICYREF = "PCP_HMAC_AUTH_POLICYREF";
	public const String NCRYPT_PCP_HMAC_AUTH_POLICYINFO = "PCP_HMAC_AUTH_POLICYINFO";
	public const String NCRYPT_PCP_HMAC_AUTH_NONCE = "PCP_HMAC_AUTH_NONCE";
	public const String NCRYPT_PCP_HMAC_AUTH_SIGNATURE = "PCP_HMAC_AUTH_SIGNATURE";
	public const String NCRYPT_PCP_HMAC_AUTH_TICKET = "PCP_HMAC_AUTH_TICKET";
	public const String NCRYPT_PCP_NO_DA_PROTECTION_PROPERTY = "PCP_NO_DA_PROTECTION";
	public const String NCRYPT_PCP_TPM_MANUFACTURER_ID_PROPERTY = "PCP_TPM_MANUFACTURER_ID";
	public const String NCRYPT_PCP_TPM_FW_VERSION_PROPERTY = "PCP_TPM_FW_VERSION";
	public const String NCRYPT_PCP_TPM2BNAME_PROPERTY = "PCP_TPM2BNAME";
	public const String NCRYPT_PCP_TPM_VERSION_PROPERTY = "PCP_TPM_VERSION";
	public const String NCRYPT_PCP_RAW_POLICYDIGEST_PROPERTY = "PCP_RAW_POLICYDIGEST";
	public const String NCRYPT_PCP_KEY_CREATIONHASH_PROPERTY = "PCP_KEY_CREATIONHASH";
	public const String NCRYPT_PCP_KEY_CREATIONTICKET_PROPERTY = "PCP_KEY_CREATIONTICKET";
	public const String NCRYPT_PCP_RSA_SCHEME_HASH_ALG_PROPERTY = "PCP_RSA_SCHEME_HASH_ALG";
	public const String NCRYPT_PCP_TPM_IFX_RSA_KEYGEN_PROHIBITED_PROPERTY = "PCP_TPM_IFX_RSA_KEYGEN_PROHIBITED";
	public const String NCRYPT_PCP_TPM_IFX_RSA_KEYGEN_VULNERABILITY_PROPERTY = "PCP_TPM_IFX_RSA_KEYGEN_VULNERABILITY";
	public const uint32 IFX_RSA_KEYGEN_VUL_NOT_AFFECTED = 0;
	public const uint32 IFX_RSA_KEYGEN_VUL_AFFECTED_LEVEL_1 = 1;
	public const uint32 IFX_RSA_KEYGEN_VUL_AFFECTED_LEVEL_2 = 2;
	public const String NCRYPT_PCP_SESSIONID_PROPERTY = "PCP_SESSIONID";
	public const String NCRYPT_PCP_PSS_SALT_SIZE_PROPERTY = "PSS Salt Size";
	public const uint32 NCRYPT_TPM_PSS_SALT_SIZE_UNKNOWN = 0;
	public const uint32 NCRYPT_TPM_PSS_SALT_SIZE_MAXIMUM = 1;
	public const uint32 NCRYPT_TPM_PSS_SALT_SIZE_HASHSIZE = 2;
	public const String NCRYPT_PCP_INTERMEDIATE_CA_EKCERT_PROPERTY = "PCP_INTERMEDIATE_CA_EKCERT";
	public const String NCRYPT_PCP_PCRTABLE_ALGORITHM_PROPERTY = "PCP_PCRTABLE_ALGORITHM";
	public const String NCRYPT_PCP_SYMMETRIC_KEYBITS_PROPERTY = "PCP_SYMMETRIC_KEYBITS";
	public const uint32 NCRYPT_TPM_PAD_PSS_IGNORE_SALT = 32;
	public const uint32 NCRYPT_TPM12_PROVIDER = 65536;
	public const uint32 NCRYPT_PCP_SIGNATURE_KEY = 1;
	public const uint32 NCRYPT_PCP_ENCRYPTION_KEY = 2;
	public const uint32 NCRYPT_PCP_STORAGE_KEY = 4;
	public const uint32 NCRYPT_PCP_IDENTITY_KEY = 8;
	public const uint32 NCRYPT_PCP_HMACVERIFICATION_KEY = 16;
	public const String NCRYPT_SCARD_NGC_KEY_NAME = "SmartCardNgcKeyName";
	public const String NCRYPT_INITIALIZATION_VECTOR = "IV";
	public const String NCRYPT_CHANGEPASSWORD_PROPERTY = "PCP_CHANGEPASSWORD";
	public const String NCRYPT_ALTERNATE_KEY_STORAGE_LOCATION_PROPERTY = "PCP_ALTERNATE_KEY_STORAGE_LOCATION";
	public const String NCRYPT_KEY_ACCESS_POLICY_PROPERTY = "Key Access Policy";
	public const uint32 NCRYPT_MAX_PROPERTY_NAME = 64;
	public const uint32 NCRYPT_MAX_PROPERTY_DATA = 1048576;
	public const uint32 NCRYPT_ALLOW_EXPORT_FLAG = 1;
	public const uint32 NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG = 2;
	public const uint32 NCRYPT_ALLOW_ARCHIVING_FLAG = 4;
	public const uint32 NCRYPT_ALLOW_PLAINTEXT_ARCHIVING_FLAG = 8;
	public const uint32 NCRYPT_IMPL_HARDWARE_FLAG = 1;
	public const uint32 NCRYPT_IMPL_SOFTWARE_FLAG = 2;
	public const uint32 NCRYPT_IMPL_REMOVABLE_FLAG = 8;
	public const uint32 NCRYPT_IMPL_HARDWARE_RNG_FLAG = 16;
	public const uint32 NCRYPT_IMPL_VIRTUAL_ISOLATION_FLAG = 32;
	public const uint32 NCRYPT_ALLOW_DECRYPT_FLAG = 1;
	public const uint32 NCRYPT_ALLOW_SIGNING_FLAG = 2;
	public const uint32 NCRYPT_ALLOW_KEY_AGREEMENT_FLAG = 4;
	public const uint32 NCRYPT_ALLOW_KEY_IMPORT_FLAG = 8;
	public const uint32 NCRYPT_ALLOW_ALL_USAGES = 16777215;
	public const uint32 NCRYPT_UI_PROTECT_KEY_FLAG = 1;
	public const uint32 NCRYPT_UI_FORCE_HIGH_PROTECTION_FLAG = 2;
	public const uint32 NCRYPT_UI_FINGERPRINT_PROTECTION_FLAG = 4;
	public const uint32 NCRYPT_UI_APPCONTAINER_ACCESS_MEDIUM_FLAG = 8;
	public const String NCRYPT_PIN_CACHE_FREE_APPLICATION_TICKET_PROPERTY = "PinCacheFreeApplicationTicket";
	public const String NCRYPT_PIN_CACHE_FLAGS_PROPERTY = "PinCacheFlags";
	public const uint32 NCRYPT_PIN_CACHE_DISABLE_DPL_FLAG = 1;
	public const String NCRYPT_PIN_CACHE_APPLICATION_TICKET_PROPERTY = "PinCacheApplicationTicket";
	public const String NCRYPT_PIN_CACHE_APPLICATION_IMAGE_PROPERTY = "PinCacheApplicationImage";
	public const String NCRYPT_PIN_CACHE_APPLICATION_STATUS_PROPERTY = "PinCacheApplicationStatus";
	public const String NCRYPT_PIN_CACHE_PIN_PROPERTY = "PinCachePin";
	public const String NCRYPT_PIN_CACHE_IS_GESTURE_REQUIRED_PROPERTY = "PinCacheIsGestureRequired";
	public const uint32 NCRYPT_PIN_CACHE_REQUIRE_GESTURE_FLAG = 1;
	public const uint32 NCRYPT_PIN_CACHE_APPLICATION_TICKET_BYTE_LENGTH = 90;
	public const String NCRYPT_PIN_CACHE_CLEAR_PROPERTY = "PinCacheClear";
	public const uint32 NCRYPT_PIN_CACHE_CLEAR_FOR_CALLING_PROCESS_OPTION = 1;
	public const uint32 NCRYPT_KEY_ACCESS_POLICY_VERSION = 1;
	public const uint32 NCRYPT_ALLOW_SILENT_KEY_ACCESS = 1;
	public const uint32 NCRYPT_CIPHER_KEY_BLOB_MAGIC = 1380470851;
	public const uint32 NCRYPT_KDF_KEY_BLOB_MAGIC = 826688587;
	public const uint32 NCRYPT_PROTECTED_KEY_BLOB_MAGIC = 1263817296;
	public const String NCRYPT_CIPHER_KEY_BLOB = "CipherKeyBlob";
	public const String NCRYPT_KDF_KEY_BLOB = "KDFKeyBlob";
	public const String NCRYPT_PROTECTED_KEY_BLOB = "ProtectedKeyBlob";
	public const String NCRYPT_TPM_LOADABLE_KEY_BLOB = "PcpTpmProtectedKeyBlob";
	public const uint32 NCRYPT_TPM_LOADABLE_KEY_BLOB_MAGIC = 1297371211;
	public const String NCRYPT_PKCS7_ENVELOPE_BLOB = "PKCS7_ENVELOPE";
	public const String NCRYPT_PKCS8_PRIVATE_KEY_BLOB = "PKCS8_PRIVATEKEY";
	public const String NCRYPT_OPAQUETRANSPORT_BLOB = "OpaqueTransport";
	public const String NCRYPT_ISOLATED_KEY_ENVELOPE_BLOB = "ISOLATED_KEY_ENVELOPE";
	public const String NCRYPT_DESCR_DELIMITER_OR = "OR";
	public const String NCRYPT_DESCR_DELIMITER_AND = "AND";
	public const String NCRYPT_DESCR_EQUAL = "=";
	public const String MS_KEY_PROTECTION_PROVIDER = "Microsoft Key Protection Provider";
	public const String NCRYPT_KEY_PROTECTION_ALGORITHM_SID = "SID";
	public const String NCRYPT_KEY_PROTECTION_ALGORITHM_LOCAL = "LOCAL";
	public const String NCRYPT_KEY_PROTECTION_LOCAL_LOGON = "logon";
	public const String NCRYPT_KEY_PROTECTION_LOCAL_USER = "user";
	public const String NCRYPT_KEY_PROTECTION_LOCAL_MACHINE = "machine";
	public const String NCRYPT_KEY_PROTECTION_ALGORITHM_SDDL = "SDDL";
	public const String NCRYPT_KEY_PROTECTION_ALGORITHM_WEBCREDENTIALS = "WEBCREDENTIALS";
	public const String NCRYPT_KEY_PROTECTION_ALGORITHM_LOCKEDCREDENTIALS = "LOCKEDCREDENTIALS";
	public const String NCRYPT_KEY_PROTECTION_ALGORITHM_CERTIFICATE = "CERTIFICATE";
	public const String NCRYPT_KEY_PROTECTION_CERT_HASHID = "HashId";
	public const String NCRYPT_KEY_PROTECTION_CERT_CERTBLOB = "CertBlob";
	public const uint32 NCRYPT_NAMED_DESCRIPTOR_FLAG = 1;
	public const uint32 NCRYPT_PROTECTION_INFO_TYPE_DESCRIPTOR_STRING = 1;
	public const uint32 ALG_CLASS_ANY = 0;
	public const uint32 ALG_CLASS_SIGNATURE = 8192;
	public const uint32 ALG_CLASS_MSG_ENCRYPT = 16384;
	public const uint32 ALG_CLASS_DATA_ENCRYPT = 24576;
	public const uint32 ALG_CLASS_HASH = 32768;
	public const uint32 ALG_CLASS_KEY_EXCHANGE = 40960;
	public const uint32 ALG_CLASS_ALL = 57344;
	public const uint32 ALG_TYPE_ANY = 0;
	public const uint32 ALG_TYPE_DSS = 512;
	public const uint32 ALG_TYPE_RSA = 1024;
	public const uint32 ALG_TYPE_BLOCK = 1536;
	public const uint32 ALG_TYPE_STREAM = 2048;
	public const uint32 ALG_TYPE_DH = 2560;
	public const uint32 ALG_TYPE_SECURECHANNEL = 3072;
	public const uint32 ALG_TYPE_ECDH = 3584;
	public const uint32 ALG_TYPE_THIRDPARTY = 4096;
	public const uint32 ALG_SID_ANY = 0;
	public const uint32 ALG_SID_THIRDPARTY_ANY = 0;
	public const uint32 ALG_SID_RSA_ANY = 0;
	public const uint32 ALG_SID_RSA_PKCS = 1;
	public const uint32 ALG_SID_RSA_MSATWORK = 2;
	public const uint32 ALG_SID_RSA_ENTRUST = 3;
	public const uint32 ALG_SID_RSA_PGP = 4;
	public const uint32 ALG_SID_DSS_ANY = 0;
	public const uint32 ALG_SID_DSS_PKCS = 1;
	public const uint32 ALG_SID_DSS_DMS = 2;
	public const uint32 ALG_SID_ECDSA = 3;
	public const uint32 ALG_SID_DES = 1;
	public const uint32 ALG_SID_3DES = 3;
	public const uint32 ALG_SID_DESX = 4;
	public const uint32 ALG_SID_IDEA = 5;
	public const uint32 ALG_SID_CAST = 6;
	public const uint32 ALG_SID_SAFERSK64 = 7;
	public const uint32 ALG_SID_SAFERSK128 = 8;
	public const uint32 ALG_SID_3DES_112 = 9;
	public const uint32 ALG_SID_CYLINK_MEK = 12;
	public const uint32 ALG_SID_RC5 = 13;
	public const uint32 ALG_SID_AES_128 = 14;
	public const uint32 ALG_SID_AES_192 = 15;
	public const uint32 ALG_SID_AES_256 = 16;
	public const uint32 ALG_SID_AES = 17;
	public const uint32 ALG_SID_SKIPJACK = 10;
	public const uint32 ALG_SID_TEK = 11;
	public const uint32 CRYPT_MODE_CBCI = 6;
	public const uint32 CRYPT_MODE_CFBP = 7;
	public const uint32 CRYPT_MODE_OFBP = 8;
	public const uint32 CRYPT_MODE_CBCOFM = 9;
	public const uint32 CRYPT_MODE_CBCOFMI = 10;
	public const uint32 ALG_SID_RC2 = 2;
	public const uint32 ALG_SID_RC4 = 1;
	public const uint32 ALG_SID_SEAL = 2;
	public const uint32 ALG_SID_DH_SANDF = 1;
	public const uint32 ALG_SID_DH_EPHEM = 2;
	public const uint32 ALG_SID_AGREED_KEY_ANY = 3;
	public const uint32 ALG_SID_KEA = 4;
	public const uint32 ALG_SID_ECDH = 5;
	public const uint32 ALG_SID_ECDH_EPHEM = 6;
	public const uint32 ALG_SID_MD2 = 1;
	public const uint32 ALG_SID_MD4 = 2;
	public const uint32 ALG_SID_MD5 = 3;
	public const uint32 ALG_SID_SHA = 4;
	public const uint32 ALG_SID_SHA1 = 4;
	public const uint32 ALG_SID_MAC = 5;
	public const uint32 ALG_SID_RIPEMD = 6;
	public const uint32 ALG_SID_RIPEMD160 = 7;
	public const uint32 ALG_SID_SSL3SHAMD5 = 8;
	public const uint32 ALG_SID_HMAC = 9;
	public const uint32 ALG_SID_TLS1PRF = 10;
	public const uint32 ALG_SID_HASH_REPLACE_OWF = 11;
	public const uint32 ALG_SID_SHA_256 = 12;
	public const uint32 ALG_SID_SHA_384 = 13;
	public const uint32 ALG_SID_SHA_512 = 14;
	public const uint32 ALG_SID_SSL3_MASTER = 1;
	public const uint32 ALG_SID_SCHANNEL_MASTER_HASH = 2;
	public const uint32 ALG_SID_SCHANNEL_MAC_KEY = 3;
	public const uint32 ALG_SID_PCT1_MASTER = 4;
	public const uint32 ALG_SID_SSL2_MASTER = 5;
	public const uint32 ALG_SID_TLS1_MASTER = 6;
	public const uint32 ALG_SID_SCHANNEL_ENC_KEY = 7;
	public const uint32 ALG_SID_ECMQV = 1;
	public const uint32 ALG_SID_EXAMPLE = 80;
	public const uint32 SIGNATURE_RESOURCE_NUMBER = 666;
	public const uint32 CRYPT_VERIFYCONTEXT = 4026531840;
	public const uint32 CRYPT_NEWKEYSET = 8;
	public const uint32 CRYPT_DELETEKEYSET = 16;
	public const uint32 CRYPT_SILENT = 64;
	public const uint32 CRYPT_DEFAULT_CONTAINER_OPTIONAL = 128;
	public const uint32 CRYPT_UPDATE_KEY = 8;
	public const uint32 CRYPT_USER_PROTECTED_STRONG = 1048576;
	public const uint32 RSA1024BIT_KEY = 67108864;
	public const uint32 CRYPT_SERVER = 1024;
	public const uint32 KEY_LENGTH_MASK = 4294901760;
	public const uint32 CRYPT_DECRYPT_RSA_NO_PADDING_CHECK = 32;
	public const uint32 CRYPT_SECRETDIGEST = 1;
	public const uint32 CRYPT_OWF_REPL_LM_HASH = 1;
	public const uint32 CRYPT_LITTLE_ENDIAN = 1;
	public const uint32 CRYPT_NOHASHOID = 1;
	public const uint32 CRYPT_TYPE2_FORMAT = 2;
	public const uint32 CRYPT_X931_FORMAT = 4;
	public const uint32 CRYPT_MACHINE_DEFAULT = 1;
	public const uint32 CRYPT_USER_DEFAULT = 2;
	public const uint32 CRYPT_DELETE_DEFAULT = 4;
	public const uint32 SIMPLEBLOB = 1;
	public const uint32 PUBLICKEYBLOB = 6;
	public const uint32 PRIVATEKEYBLOB = 7;
	public const uint32 PLAINTEXTKEYBLOB = 8;
	public const uint32 OPAQUEKEYBLOB = 9;
	public const uint32 PUBLICKEYBLOBEX = 10;
	public const uint32 SYMMETRICWRAPKEYBLOB = 11;
	public const uint32 KEYSTATEBLOB = 12;
	public const uint32 CRYPT_USERDATA = 1;
	public const uint32 KP_IV = 1;
	public const uint32 KP_PADDING = 3;
	public const uint32 KP_MODE = 4;
	public const uint32 KP_MODE_BITS = 5;
	public const uint32 KP_P = 11;
	public const uint32 KP_G = 12;
	public const uint32 KP_Q = 13;
	public const uint32 KP_X = 14;
	public const uint32 KP_Y = 15;
	public const uint32 KP_RA = 16;
	public const uint32 KP_RB = 17;
	public const uint32 KP_INFO = 18;
	public const uint32 KP_EFFECTIVE_KEYLEN = 19;
	public const uint32 KP_SCHANNEL_ALG = 20;
	public const uint32 KP_CLIENT_RANDOM = 21;
	public const uint32 KP_SERVER_RANDOM = 22;
	public const uint32 KP_RP = 23;
	public const uint32 KP_PRECOMP_MD5 = 24;
	public const uint32 KP_PRECOMP_SHA = 25;
	public const uint32 KP_CLEAR_KEY = 27;
	public const uint32 KP_PUB_EX_LEN = 28;
	public const uint32 KP_PUB_EX_VAL = 29;
	public const uint32 KP_KEYVAL = 30;
	public const uint32 KP_ADMIN_PIN = 31;
	public const uint32 KP_KEYEXCHANGE_PIN = 32;
	public const uint32 KP_SIGNATURE_PIN = 33;
	public const uint32 KP_PREHASH = 34;
	public const uint32 KP_ROUNDS = 35;
	public const uint32 KP_OAEP_PARAMS = 36;
	public const uint32 KP_CMS_KEY_INFO = 37;
	public const uint32 KP_CMS_DH_KEY_INFO = 38;
	public const uint32 KP_PUB_PARAMS = 39;
	public const uint32 KP_VERIFY_PARAMS = 40;
	public const uint32 KP_HIGHEST_VERSION = 41;
	public const uint32 KP_PIN_ID = 43;
	public const uint32 KP_PIN_INFO = 44;
	public const uint32 PKCS5_PADDING = 1;
	public const uint32 RANDOM_PADDING = 2;
	public const uint32 ZERO_PADDING = 3;
	public const uint32 CRYPT_MODE_CBC = 1;
	public const uint32 CRYPT_MODE_ECB = 2;
	public const uint32 CRYPT_MODE_OFB = 3;
	public const uint32 CRYPT_MODE_CFB = 4;
	public const uint32 CRYPT_MODE_CTS = 5;
	public const uint32 CRYPT_ENCRYPT = 1;
	public const uint32 CRYPT_DECRYPT = 2;
	public const uint32 CRYPT_EXPORT = 4;
	public const uint32 CRYPT_READ = 8;
	public const uint32 CRYPT_WRITE = 16;
	public const uint32 CRYPT_MAC = 32;
	public const uint32 CRYPT_EXPORT_KEY = 64;
	public const uint32 CRYPT_IMPORT_KEY = 128;
	public const uint32 CRYPT_ARCHIVE = 256;
	public const uint32 HP_ALGID = 1;
	public const uint32 HP_HASHSIZE = 4;
	public const uint32 HP_TLS1PRF_LABEL = 6;
	public const uint32 HP_TLS1PRF_SEED = 7;
	public const uint32 CRYPT_FAILED = 0;
	public const uint32 CRYPT_SUCCEED = 1;
	public const uint32 PP_ENUMALGS = 1;
	public const uint32 PP_ENUMCONTAINERS = 2;
	public const uint32 PP_IMPTYPE = 3;
	public const uint32 PP_NAME = 4;
	public const uint32 PP_VERSION = 5;
	public const uint32 PP_CONTAINER = 6;
	public const uint32 PP_CHANGE_PASSWORD = 7;
	public const uint32 PP_CERTCHAIN = 9;
	public const uint32 PP_KEY_TYPE_SUBTYPE = 10;
	public const uint32 PP_PROVTYPE = 16;
	public const uint32 PP_KEYSTORAGE = 17;
	public const uint32 PP_APPLI_CERT = 18;
	public const uint32 PP_SYM_KEYSIZE = 19;
	public const uint32 PP_SESSION_KEYSIZE = 20;
	public const uint32 PP_ENUMALGS_EX = 22;
	public const uint32 PP_ENUMMANDROOTS = 25;
	public const uint32 PP_ENUMELECTROOTS = 26;
	public const uint32 PP_KEYSET_TYPE = 27;
	public const uint32 PP_ADMIN_PIN = 31;
	public const uint32 PP_SIG_KEYSIZE_INC = 34;
	public const uint32 PP_KEYX_KEYSIZE_INC = 35;
	public const uint32 PP_UNIQUE_CONTAINER = 36;
	public const uint32 PP_SGC_INFO = 37;
	public const uint32 PP_KEYSPEC = 39;
	public const uint32 PP_ENUMEX_SIGNING_PROT = 40;
	public const uint32 PP_CRYPT_COUNT_KEY_USE = 41;
	public const uint32 PP_SMARTCARD_GUID = 45;
	public const uint32 PP_SMARTCARD_READER_ICON = 47;
	public const uint32 CRYPT_FIRST = 1;
	public const uint32 CRYPT_NEXT = 2;
	public const uint32 CRYPT_SGC_ENUM = 4;
	public const uint32 CRYPT_IMPL_HARDWARE = 1;
	public const uint32 CRYPT_IMPL_SOFTWARE = 2;
	public const uint32 CRYPT_IMPL_MIXED = 3;
	public const uint32 CRYPT_IMPL_UNKNOWN = 4;
	public const uint32 CRYPT_IMPL_REMOVABLE = 8;
	public const uint32 CRYPT_SEC_DESCR = 1;
	public const uint32 CRYPT_PSTORE = 2;
	public const uint32 CRYPT_UI_PROMPT = 4;
	public const uint32 CRYPT_FLAG_PCT1 = 1;
	public const uint32 CRYPT_FLAG_SSL2 = 2;
	public const uint32 CRYPT_FLAG_SSL3 = 4;
	public const uint32 CRYPT_FLAG_TLS1 = 8;
	public const uint32 CRYPT_FLAG_IPSEC = 16;
	public const uint32 CRYPT_FLAG_SIGNING = 32;
	public const uint32 CRYPT_SGC = 1;
	public const uint32 CRYPT_FASTSGC = 2;
	public const uint32 PP_CONTEXT_INFO = 11;
	public const uint32 PP_DISMISS_PIN_UI_SEC = 49;
	public const uint32 PROV_RSA_FULL = 1;
	public const uint32 PROV_RSA_SIG = 2;
	public const uint32 PROV_DSS = 3;
	public const uint32 PROV_FORTEZZA = 4;
	public const uint32 PROV_MS_EXCHANGE = 5;
	public const uint32 PROV_SSL = 6;
	public const uint32 PROV_RSA_SCHANNEL = 12;
	public const uint32 PROV_DSS_DH = 13;
	public const uint32 PROV_EC_ECDSA_SIG = 14;
	public const uint32 PROV_EC_ECNRA_SIG = 15;
	public const uint32 PROV_EC_ECDSA_FULL = 16;
	public const uint32 PROV_EC_ECNRA_FULL = 17;
	public const uint32 PROV_DH_SCHANNEL = 18;
	public const uint32 PROV_SPYRUS_LYNKS = 20;
	public const uint32 PROV_RNG = 21;
	public const uint32 PROV_INTEL_SEC = 22;
	public const uint32 PROV_REPLACE_OWF = 23;
	public const uint32 PROV_RSA_AES = 24;
	public const uint32 PROV_STT_MER = 7;
	public const uint32 PROV_STT_ACQ = 8;
	public const uint32 PROV_STT_BRND = 9;
	public const uint32 PROV_STT_ROOT = 10;
	public const uint32 PROV_STT_ISS = 11;
	public const String MS_DEF_PROV_A = "Microsoft Base Cryptographic Provider v1.0";
	public const String MS_DEF_PROV_W = "Microsoft Base Cryptographic Provider v1.0";
	public const String MS_DEF_PROV = "Microsoft Base Cryptographic Provider v1.0";
	public const String MS_ENHANCED_PROV_A = "Microsoft Enhanced Cryptographic Provider v1.0";
	public const String MS_ENHANCED_PROV_W = "Microsoft Enhanced Cryptographic Provider v1.0";
	public const String MS_ENHANCED_PROV = "Microsoft Enhanced Cryptographic Provider v1.0";
	public const String MS_STRONG_PROV_A = "Microsoft Strong Cryptographic Provider";
	public const String MS_STRONG_PROV_W = "Microsoft Strong Cryptographic Provider";
	public const String MS_STRONG_PROV = "Microsoft Strong Cryptographic Provider";
	public const String MS_DEF_RSA_SIG_PROV_A = "Microsoft RSA Signature Cryptographic Provider";
	public const String MS_DEF_RSA_SIG_PROV_W = "Microsoft RSA Signature Cryptographic Provider";
	public const String MS_DEF_RSA_SIG_PROV = "Microsoft RSA Signature Cryptographic Provider";
	public const String MS_DEF_RSA_SCHANNEL_PROV_A = "Microsoft RSA SChannel Cryptographic Provider";
	public const String MS_DEF_RSA_SCHANNEL_PROV_W = "Microsoft RSA SChannel Cryptographic Provider";
	public const String MS_DEF_RSA_SCHANNEL_PROV = "Microsoft RSA SChannel Cryptographic Provider";
	public const String MS_DEF_DSS_PROV_A = "Microsoft Base DSS Cryptographic Provider";
	public const String MS_DEF_DSS_PROV_W = "Microsoft Base DSS Cryptographic Provider";
	public const String MS_DEF_DSS_PROV = "Microsoft Base DSS Cryptographic Provider";
	public const String MS_DEF_DSS_DH_PROV_A = "Microsoft Base DSS and Diffie-Hellman Cryptographic Provider";
	public const String MS_DEF_DSS_DH_PROV_W = "Microsoft Base DSS and Diffie-Hellman Cryptographic Provider";
	public const String MS_DEF_DSS_DH_PROV = "Microsoft Base DSS and Diffie-Hellman Cryptographic Provider";
	public const String MS_ENH_DSS_DH_PROV_A = "Microsoft Enhanced DSS and Diffie-Hellman Cryptographic Provider";
	public const String MS_ENH_DSS_DH_PROV_W = "Microsoft Enhanced DSS and Diffie-Hellman Cryptographic Provider";
	public const String MS_ENH_DSS_DH_PROV = "Microsoft Enhanced DSS and Diffie-Hellman Cryptographic Provider";
	public const String MS_DEF_DH_SCHANNEL_PROV_A = "Microsoft DH SChannel Cryptographic Provider";
	public const String MS_DEF_DH_SCHANNEL_PROV_W = "Microsoft DH SChannel Cryptographic Provider";
	public const String MS_DEF_DH_SCHANNEL_PROV = "Microsoft DH SChannel Cryptographic Provider";
	public const String MS_SCARD_PROV_A = "Microsoft Base Smart Card Crypto Provider";
	public const String MS_SCARD_PROV_W = "Microsoft Base Smart Card Crypto Provider";
	public const String MS_SCARD_PROV = "Microsoft Base Smart Card Crypto Provider";
	public const String MS_ENH_RSA_AES_PROV_A = "Microsoft Enhanced RSA and AES Cryptographic Provider";
	public const String MS_ENH_RSA_AES_PROV_W = "Microsoft Enhanced RSA and AES Cryptographic Provider";
	public const String MS_ENH_RSA_AES_PROV_XP_A = "Microsoft Enhanced RSA and AES Cryptographic Provider (Prototype)";
	public const String MS_ENH_RSA_AES_PROV_XP_W = "Microsoft Enhanced RSA and AES Cryptographic Provider (Prototype)";
	public const String MS_ENH_RSA_AES_PROV_XP = "Microsoft Enhanced RSA and AES Cryptographic Provider (Prototype)";
	public const String MS_ENH_RSA_AES_PROV = "Microsoft Enhanced RSA and AES Cryptographic Provider";
	public const uint32 MAXUIDLEN = 64;
	public const String EXPO_OFFLOAD_REG_VALUE = "ExpoOffload";
	public const String EXPO_OFFLOAD_FUNC_NAME = "OffloadModExpo";
	public const String szKEY_CRYPTOAPI_PRIVATE_KEY_OPTIONS = "Software\\Policies\\Microsoft\\Cryptography";
	public const String szKEY_CACHE_ENABLED = "CachePrivateKeys";
	public const String szKEY_CACHE_SECONDS = "PrivateKeyLifetimeSeconds";
	public const String szPRIV_KEY_CACHE_MAX_ITEMS = "PrivKeyCacheMaxItems";
	public const uint32 cPRIV_KEY_CACHE_MAX_ITEMS_DEFAULT = 20;
	public const String szPRIV_KEY_CACHE_PURGE_INTERVAL_SECONDS = "PrivKeyCachePurgeIntervalSeconds";
	public const uint32 cPRIV_KEY_CACHE_PURGE_INTERVAL_SECONDS_DEFAULT = 86400;
	public const uint32 CUR_BLOB_VERSION = 2;
	public const uint32 SCHANNEL_MAC_KEY = 0;
	public const uint32 SCHANNEL_ENC_KEY = 1;
	public const uint32 INTERNATIONAL_USAGE = 1;
	public const String szOID_RSA = "1.2.840.113549";
	public const String szOID_PKCS = "1.2.840.113549.1";
	public const String szOID_RSA_HASH = "1.2.840.113549.2";
	public const String szOID_RSA_ENCRYPT = "1.2.840.113549.3";
	public const String szOID_PKCS_1 = "1.2.840.113549.1.1";
	public const String szOID_PKCS_2 = "1.2.840.113549.1.2";
	public const String szOID_PKCS_3 = "1.2.840.113549.1.3";
	public const String szOID_PKCS_4 = "1.2.840.113549.1.4";
	public const String szOID_PKCS_5 = "1.2.840.113549.1.5";
	public const String szOID_PKCS_6 = "1.2.840.113549.1.6";
	public const String szOID_PKCS_7 = "1.2.840.113549.1.7";
	public const String szOID_PKCS_8 = "1.2.840.113549.1.8";
	public const String szOID_PKCS_9 = "1.2.840.113549.1.9";
	public const String szOID_PKCS_10 = "1.2.840.113549.1.10";
	public const String szOID_PKCS_12 = "1.2.840.113549.1.12";
	public const String szOID_RSA_RSA = "1.2.840.113549.1.1.1";
	public const String szOID_RSA_MD2RSA = "1.2.840.113549.1.1.2";
	public const String szOID_RSA_MD4RSA = "1.2.840.113549.1.1.3";
	public const String szOID_RSA_MD5RSA = "1.2.840.113549.1.1.4";
	public const String szOID_RSA_SHA1RSA = "1.2.840.113549.1.1.5";
	public const String szOID_RSA_SETOAEP_RSA = "1.2.840.113549.1.1.6";
	public const String szOID_RSAES_OAEP = "1.2.840.113549.1.1.7";
	public const String szOID_RSA_MGF1 = "1.2.840.113549.1.1.8";
	public const String szOID_RSA_PSPECIFIED = "1.2.840.113549.1.1.9";
	public const String szOID_RSA_SSA_PSS = "1.2.840.113549.1.1.10";
	public const String szOID_RSA_SHA256RSA = "1.2.840.113549.1.1.11";
	public const String szOID_RSA_SHA384RSA = "1.2.840.113549.1.1.12";
	public const String szOID_RSA_SHA512RSA = "1.2.840.113549.1.1.13";
	public const String szOID_RSA_DH = "1.2.840.113549.1.3.1";
	public const String szOID_RSA_data = "1.2.840.113549.1.7.1";
	public const String szOID_RSA_signedData = "1.2.840.113549.1.7.2";
	public const String szOID_RSA_envelopedData = "1.2.840.113549.1.7.3";
	public const String szOID_RSA_signEnvData = "1.2.840.113549.1.7.4";
	public const String szOID_RSA_digestedData = "1.2.840.113549.1.7.5";
	public const String szOID_RSA_hashedData = "1.2.840.113549.1.7.5";
	public const String szOID_RSA_encryptedData = "1.2.840.113549.1.7.6";
	public const String szOID_RSA_emailAddr = "1.2.840.113549.1.9.1";
	public const String szOID_RSA_unstructName = "1.2.840.113549.1.9.2";
	public const String szOID_RSA_contentType = "1.2.840.113549.1.9.3";
	public const String szOID_RSA_messageDigest = "1.2.840.113549.1.9.4";
	public const String szOID_RSA_signingTime = "1.2.840.113549.1.9.5";
	public const String szOID_RSA_counterSign = "1.2.840.113549.1.9.6";
	public const String szOID_RSA_challengePwd = "1.2.840.113549.1.9.7";
	public const String szOID_RSA_unstructAddr = "1.2.840.113549.1.9.8";
	public const String szOID_RSA_extCertAttrs = "1.2.840.113549.1.9.9";
	public const String szOID_RSA_certExtensions = "1.2.840.113549.1.9.14";
	public const String szOID_RSA_SMIMECapabilities = "1.2.840.113549.1.9.15";
	public const String szOID_RSA_preferSignedData = "1.2.840.113549.1.9.15.1";
	public const String szOID_TIMESTAMP_TOKEN = "1.2.840.113549.1.9.16.1.4";
	public const String szOID_RFC3161_counterSign = "1.3.6.1.4.1.311.3.3.1";
	public const String szOID_RSA_SMIMEalg = "1.2.840.113549.1.9.16.3";
	public const String szOID_RSA_SMIMEalgESDH = "1.2.840.113549.1.9.16.3.5";
	public const String szOID_RSA_SMIMEalgCMS3DESwrap = "1.2.840.113549.1.9.16.3.6";
	public const String szOID_RSA_SMIMEalgCMSRC2wrap = "1.2.840.113549.1.9.16.3.7";
	public const String szOID_RSA_MD2 = "1.2.840.113549.2.2";
	public const String szOID_RSA_MD4 = "1.2.840.113549.2.4";
	public const String szOID_RSA_MD5 = "1.2.840.113549.2.5";
	public const String szOID_RSA_RC2CBC = "1.2.840.113549.3.2";
	public const String szOID_RSA_RC4 = "1.2.840.113549.3.4";
	public const String szOID_RSA_DES_EDE3_CBC = "1.2.840.113549.3.7";
	public const String szOID_RSA_RC5_CBCPad = "1.2.840.113549.3.9";
	public const String szOID_ANSI_X942 = "1.2.840.10046";
	public const String szOID_ANSI_X942_DH = "1.2.840.10046.2.1";
	public const String szOID_X957 = "1.2.840.10040";
	public const String szOID_X957_DSA = "1.2.840.10040.4.1";
	public const String szOID_X957_SHA1DSA = "1.2.840.10040.4.3";
	public const String szOID_ECC_PUBLIC_KEY = "1.2.840.10045.2.1";
	public const String szOID_ECC_CURVE_P256 = "1.2.840.10045.3.1.7";
	public const String szOID_ECC_CURVE_P384 = "1.3.132.0.34";
	public const String szOID_ECC_CURVE_P521 = "1.3.132.0.35";
	public const String szOID_ECC_CURVE_BRAINPOOLP160R1 = "1.3.36.3.3.2.8.1.1.1";
	public const String szOID_ECC_CURVE_BRAINPOOLP160T1 = "1.3.36.3.3.2.8.1.1.2";
	public const String szOID_ECC_CURVE_BRAINPOOLP192R1 = "1.3.36.3.3.2.8.1.1.3";
	public const String szOID_ECC_CURVE_BRAINPOOLP192T1 = "1.3.36.3.3.2.8.1.1.4";
	public const String szOID_ECC_CURVE_BRAINPOOLP224R1 = "1.3.36.3.3.2.8.1.1.5";
	public const String szOID_ECC_CURVE_BRAINPOOLP224T1 = "1.3.36.3.3.2.8.1.1.6";
	public const String szOID_ECC_CURVE_BRAINPOOLP256R1 = "1.3.36.3.3.2.8.1.1.7";
	public const String szOID_ECC_CURVE_BRAINPOOLP256T1 = "1.3.36.3.3.2.8.1.1.8";
	public const String szOID_ECC_CURVE_BRAINPOOLP320R1 = "1.3.36.3.3.2.8.1.1.9";
	public const String szOID_ECC_CURVE_BRAINPOOLP320T1 = "1.3.36.3.3.2.8.1.1.10";
	public const String szOID_ECC_CURVE_BRAINPOOLP384R1 = "1.3.36.3.3.2.8.1.1.11";
	public const String szOID_ECC_CURVE_BRAINPOOLP384T1 = "1.3.36.3.3.2.8.1.1.12";
	public const String szOID_ECC_CURVE_BRAINPOOLP512R1 = "1.3.36.3.3.2.8.1.1.13";
	public const String szOID_ECC_CURVE_BRAINPOOLP512T1 = "1.3.36.3.3.2.8.1.1.14";
	public const String szOID_ECC_CURVE_EC192WAPI = "1.2.156.11235.1.1.2.1";
	public const String szOID_CN_ECDSA_SHA256 = "1.2.156.11235.1.1.1";
	public const String szOID_ECC_CURVE_NISTP192 = "1.2.840.10045.3.1.1";
	public const String szOID_ECC_CURVE_NISTP224 = "1.3.132.0.33";
	public const String szOID_ECC_CURVE_NISTP256 = "1.2.840.10045.3.1.7";
	public const String szOID_ECC_CURVE_NISTP384 = "1.3.132.0.34";
	public const String szOID_ECC_CURVE_NISTP521 = "1.3.132.0.35";
	public const String szOID_ECC_CURVE_SECP160K1 = "1.3.132.0.9";
	public const String szOID_ECC_CURVE_SECP160R1 = "1.3.132.0.8";
	public const String szOID_ECC_CURVE_SECP160R2 = "1.3.132.0.30";
	public const String szOID_ECC_CURVE_SECP192K1 = "1.3.132.0.31";
	public const String szOID_ECC_CURVE_SECP192R1 = "1.2.840.10045.3.1.1";
	public const String szOID_ECC_CURVE_SECP224K1 = "1.3.132.0.32";
	public const String szOID_ECC_CURVE_SECP224R1 = "1.3.132.0.33";
	public const String szOID_ECC_CURVE_SECP256K1 = "1.3.132.0.10";
	public const String szOID_ECC_CURVE_SECP256R1 = "1.2.840.10045.3.1.7";
	public const String szOID_ECC_CURVE_SECP384R1 = "1.3.132.0.34";
	public const String szOID_ECC_CURVE_SECP521R1 = "1.3.132.0.35";
	public const String szOID_ECC_CURVE_WTLS7 = "1.3.132.0.30";
	public const String szOID_ECC_CURVE_WTLS9 = "2.23.43.1.4.9";
	public const String szOID_ECC_CURVE_WTLS12 = "1.3.132.0.33";
	public const String szOID_ECC_CURVE_X962P192V1 = "1.2.840.10045.3.1.1";
	public const String szOID_ECC_CURVE_X962P192V2 = "1.2.840.10045.3.1.2";
	public const String szOID_ECC_CURVE_X962P192V3 = "1.2.840.10045.3.1.3";
	public const String szOID_ECC_CURVE_X962P239V1 = "1.2.840.10045.3.1.4";
	public const String szOID_ECC_CURVE_X962P239V2 = "1.2.840.10045.3.1.5";
	public const String szOID_ECC_CURVE_X962P239V3 = "1.2.840.10045.3.1.6";
	public const String szOID_ECC_CURVE_X962P256V1 = "1.2.840.10045.3.1.7";
	public const String szOID_ECDSA_SHA1 = "1.2.840.10045.4.1";
	public const String szOID_ECDSA_SPECIFIED = "1.2.840.10045.4.3";
	public const String szOID_ECDSA_SHA256 = "1.2.840.10045.4.3.2";
	public const String szOID_ECDSA_SHA384 = "1.2.840.10045.4.3.3";
	public const String szOID_ECDSA_SHA512 = "1.2.840.10045.4.3.4";
	public const String szOID_NIST_AES128_CBC = "2.16.840.1.101.3.4.1.2";
	public const String szOID_NIST_AES192_CBC = "2.16.840.1.101.3.4.1.22";
	public const String szOID_NIST_AES256_CBC = "2.16.840.1.101.3.4.1.42";
	public const String szOID_NIST_AES128_WRAP = "2.16.840.1.101.3.4.1.5";
	public const String szOID_NIST_AES192_WRAP = "2.16.840.1.101.3.4.1.25";
	public const String szOID_NIST_AES256_WRAP = "2.16.840.1.101.3.4.1.45";
	public const String szOID_DH_SINGLE_PASS_STDDH_SHA1_KDF = "1.3.133.16.840.63.0.2";
	public const String szOID_DH_SINGLE_PASS_STDDH_SHA256_KDF = "1.3.132.1.11.1";
	public const String szOID_DH_SINGLE_PASS_STDDH_SHA384_KDF = "1.3.132.1.11.2";
	public const String szOID_DS = "2.5";
	public const String szOID_DSALG = "2.5.8";
	public const String szOID_DSALG_CRPT = "2.5.8.1";
	public const String szOID_DSALG_HASH = "2.5.8.2";
	public const String szOID_DSALG_SIGN = "2.5.8.3";
	public const String szOID_DSALG_RSA = "2.5.8.1.1";
	public const String szOID_OIW = "1.3.14";
	public const String szOID_OIWSEC = "1.3.14.3.2";
	public const String szOID_OIWSEC_md4RSA = "1.3.14.3.2.2";
	public const String szOID_OIWSEC_md5RSA = "1.3.14.3.2.3";
	public const String szOID_OIWSEC_md4RSA2 = "1.3.14.3.2.4";
	public const String szOID_OIWSEC_desECB = "1.3.14.3.2.6";
	public const String szOID_OIWSEC_desCBC = "1.3.14.3.2.7";
	public const String szOID_OIWSEC_desOFB = "1.3.14.3.2.8";
	public const String szOID_OIWSEC_desCFB = "1.3.14.3.2.9";
	public const String szOID_OIWSEC_desMAC = "1.3.14.3.2.10";
	public const String szOID_OIWSEC_rsaSign = "1.3.14.3.2.11";
	public const String szOID_OIWSEC_dsa = "1.3.14.3.2.12";
	public const String szOID_OIWSEC_shaDSA = "1.3.14.3.2.13";
	public const String szOID_OIWSEC_mdc2RSA = "1.3.14.3.2.14";
	public const String szOID_OIWSEC_shaRSA = "1.3.14.3.2.15";
	public const String szOID_OIWSEC_dhCommMod = "1.3.14.3.2.16";
	public const String szOID_OIWSEC_desEDE = "1.3.14.3.2.17";
	public const String szOID_OIWSEC_sha = "1.3.14.3.2.18";
	public const String szOID_OIWSEC_mdc2 = "1.3.14.3.2.19";
	public const String szOID_OIWSEC_dsaComm = "1.3.14.3.2.20";
	public const String szOID_OIWSEC_dsaCommSHA = "1.3.14.3.2.21";
	public const String szOID_OIWSEC_rsaXchg = "1.3.14.3.2.22";
	public const String szOID_OIWSEC_keyHashSeal = "1.3.14.3.2.23";
	public const String szOID_OIWSEC_md2RSASign = "1.3.14.3.2.24";
	public const String szOID_OIWSEC_md5RSASign = "1.3.14.3.2.25";
	public const String szOID_OIWSEC_sha1 = "1.3.14.3.2.26";
	public const String szOID_OIWSEC_dsaSHA1 = "1.3.14.3.2.27";
	public const String szOID_OIWSEC_dsaCommSHA1 = "1.3.14.3.2.28";
	public const String szOID_OIWSEC_sha1RSASign = "1.3.14.3.2.29";
	public const String szOID_OIWDIR = "1.3.14.7.2";
	public const String szOID_OIWDIR_CRPT = "1.3.14.7.2.1";
	public const String szOID_OIWDIR_HASH = "1.3.14.7.2.2";
	public const String szOID_OIWDIR_SIGN = "1.3.14.7.2.3";
	public const String szOID_OIWDIR_md2 = "1.3.14.7.2.2.1";
	public const String szOID_OIWDIR_md2RSA = "1.3.14.7.2.3.1";
	public const String szOID_INFOSEC = "2.16.840.1.101.2.1";
	public const String szOID_INFOSEC_sdnsSignature = "2.16.840.1.101.2.1.1.1";
	public const String szOID_INFOSEC_mosaicSignature = "2.16.840.1.101.2.1.1.2";
	public const String szOID_INFOSEC_sdnsConfidentiality = "2.16.840.1.101.2.1.1.3";
	public const String szOID_INFOSEC_mosaicConfidentiality = "2.16.840.1.101.2.1.1.4";
	public const String szOID_INFOSEC_sdnsIntegrity = "2.16.840.1.101.2.1.1.5";
	public const String szOID_INFOSEC_mosaicIntegrity = "2.16.840.1.101.2.1.1.6";
	public const String szOID_INFOSEC_sdnsTokenProtection = "2.16.840.1.101.2.1.1.7";
	public const String szOID_INFOSEC_mosaicTokenProtection = "2.16.840.1.101.2.1.1.8";
	public const String szOID_INFOSEC_sdnsKeyManagement = "2.16.840.1.101.2.1.1.9";
	public const String szOID_INFOSEC_mosaicKeyManagement = "2.16.840.1.101.2.1.1.10";
	public const String szOID_INFOSEC_sdnsKMandSig = "2.16.840.1.101.2.1.1.11";
	public const String szOID_INFOSEC_mosaicKMandSig = "2.16.840.1.101.2.1.1.12";
	public const String szOID_INFOSEC_SuiteASignature = "2.16.840.1.101.2.1.1.13";
	public const String szOID_INFOSEC_SuiteAConfidentiality = "2.16.840.1.101.2.1.1.14";
	public const String szOID_INFOSEC_SuiteAIntegrity = "2.16.840.1.101.2.1.1.15";
	public const String szOID_INFOSEC_SuiteATokenProtection = "2.16.840.1.101.2.1.1.16";
	public const String szOID_INFOSEC_SuiteAKeyManagement = "2.16.840.1.101.2.1.1.17";
	public const String szOID_INFOSEC_SuiteAKMandSig = "2.16.840.1.101.2.1.1.18";
	public const String szOID_INFOSEC_mosaicUpdatedSig = "2.16.840.1.101.2.1.1.19";
	public const String szOID_INFOSEC_mosaicKMandUpdSig = "2.16.840.1.101.2.1.1.20";
	public const String szOID_INFOSEC_mosaicUpdatedInteg = "2.16.840.1.101.2.1.1.21";
	public const String szOID_NIST_sha256 = "2.16.840.1.101.3.4.2.1";
	public const String szOID_NIST_sha384 = "2.16.840.1.101.3.4.2.2";
	public const String szOID_NIST_sha512 = "2.16.840.1.101.3.4.2.3";
	public const String szOID_COMMON_NAME = "2.5.4.3";
	public const String szOID_SUR_NAME = "2.5.4.4";
	public const String szOID_DEVICE_SERIAL_NUMBER = "2.5.4.5";
	public const String szOID_COUNTRY_NAME = "2.5.4.6";
	public const String szOID_LOCALITY_NAME = "2.5.4.7";
	public const String szOID_STATE_OR_PROVINCE_NAME = "2.5.4.8";
	public const String szOID_STREET_ADDRESS = "2.5.4.9";
	public const String szOID_ORGANIZATION_NAME = "2.5.4.10";
	public const String szOID_ORGANIZATIONAL_UNIT_NAME = "2.5.4.11";
	public const String szOID_TITLE = "2.5.4.12";
	public const String szOID_DESCRIPTION = "2.5.4.13";
	public const String szOID_SEARCH_GUIDE = "2.5.4.14";
	public const String szOID_BUSINESS_CATEGORY = "2.5.4.15";
	public const String szOID_POSTAL_ADDRESS = "2.5.4.16";
	public const String szOID_POSTAL_CODE = "2.5.4.17";
	public const String szOID_POST_OFFICE_BOX = "2.5.4.18";
	public const String szOID_PHYSICAL_DELIVERY_OFFICE_NAME = "2.5.4.19";
	public const String szOID_TELEPHONE_NUMBER = "2.5.4.20";
	public const String szOID_TELEX_NUMBER = "2.5.4.21";
	public const String szOID_TELETEXT_TERMINAL_IDENTIFIER = "2.5.4.22";
	public const String szOID_FACSIMILE_TELEPHONE_NUMBER = "2.5.4.23";
	public const String szOID_X21_ADDRESS = "2.5.4.24";
	public const String szOID_INTERNATIONAL_ISDN_NUMBER = "2.5.4.25";
	public const String szOID_REGISTERED_ADDRESS = "2.5.4.26";
	public const String szOID_DESTINATION_INDICATOR = "2.5.4.27";
	public const String szOID_PREFERRED_DELIVERY_METHOD = "2.5.4.28";
	public const String szOID_PRESENTATION_ADDRESS = "2.5.4.29";
	public const String szOID_SUPPORTED_APPLICATION_CONTEXT = "2.5.4.30";
	public const String szOID_MEMBER = "2.5.4.31";
	public const String szOID_OWNER = "2.5.4.32";
	public const String szOID_ROLE_OCCUPANT = "2.5.4.33";
	public const String szOID_SEE_ALSO = "2.5.4.34";
	public const String szOID_USER_PASSWORD = "2.5.4.35";
	public const String szOID_USER_CERTIFICATE = "2.5.4.36";
	public const String szOID_CA_CERTIFICATE = "2.5.4.37";
	public const String szOID_AUTHORITY_REVOCATION_LIST = "2.5.4.38";
	public const String szOID_CERTIFICATE_REVOCATION_LIST = "2.5.4.39";
	public const String szOID_CROSS_CERTIFICATE_PAIR = "2.5.4.40";
	public const String szOID_GIVEN_NAME = "2.5.4.42";
	public const String szOID_INITIALS = "2.5.4.43";
	public const String szOID_DN_QUALIFIER = "2.5.4.46";
	public const String szOID_DOMAIN_COMPONENT = "0.9.2342.19200300.100.1.25";
	public const String szOID_PKCS_12_FRIENDLY_NAME_ATTR = "1.2.840.113549.1.9.20";
	public const String szOID_PKCS_12_LOCAL_KEY_ID = "1.2.840.113549.1.9.21";
	public const String szOID_PKCS_12_KEY_PROVIDER_NAME_ATTR = "1.3.6.1.4.1.311.17.1";
	public const String szOID_LOCAL_MACHINE_KEYSET = "1.3.6.1.4.1.311.17.2";
	public const String szOID_PKCS_12_EXTENDED_ATTRIBUTES = "1.3.6.1.4.1.311.17.3";
	public const String szOID_PKCS_12_PROTECTED_PASSWORD_SECRET_BAG_TYPE_ID = "1.3.6.1.4.1.311.17.4";
	public const String szOID_KEYID_RDN = "1.3.6.1.4.1.311.10.7.1";
	public const String szOID_EV_RDN_LOCALE = "1.3.6.1.4.1.311.60.2.1.1";
	public const String szOID_EV_RDN_STATE_OR_PROVINCE = "1.3.6.1.4.1.311.60.2.1.2";
	public const String szOID_EV_RDN_COUNTRY = "1.3.6.1.4.1.311.60.2.1.3";
	public const uint32 CERT_RDN_TYPE_MASK = 255;
	public const uint32 CERT_RDN_FLAGS_MASK = 4278190080;
	public const uint32 CERT_RDN_ENABLE_T61_UNICODE_FLAG = 2147483648;
	public const uint32 CERT_RDN_ENABLE_UTF8_UNICODE_FLAG = 536870912;
	public const uint32 CERT_RDN_FORCE_UTF8_UNICODE_FLAG = 268435456;
	public const uint32 CERT_RDN_DISABLE_CHECK_TYPE_FLAG = 1073741824;
	public const uint32 CERT_RDN_DISABLE_IE4_UTF8_FLAG = 16777216;
	public const uint32 CERT_RDN_ENABLE_PUNYCODE_FLAG = 33554432;
	public const String CERT_RSA_PUBLIC_KEY_OBJID = "1.2.840.113549.1.1.1";
	public const String CERT_DEFAULT_OID_PUBLIC_KEY_SIGN = "1.2.840.113549.1.1.1";
	public const String CERT_DEFAULT_OID_PUBLIC_KEY_XCHG = "1.2.840.113549.1.1.1";
	public const uint32 CRYPT_ECC_PRIVATE_KEY_INFO_v1 = 1;
	public const uint32 CERT_V1 = 0;
	public const uint32 CERT_V2 = 1;
	public const uint32 CERT_V3 = 2;
	public const uint32 CERT_INFO_VERSION_FLAG = 1;
	public const uint32 CERT_INFO_SERIAL_NUMBER_FLAG = 2;
	public const uint32 CERT_INFO_SIGNATURE_ALGORITHM_FLAG = 3;
	public const uint32 CERT_INFO_ISSUER_FLAG = 4;
	public const uint32 CERT_INFO_NOT_BEFORE_FLAG = 5;
	public const uint32 CERT_INFO_NOT_AFTER_FLAG = 6;
	public const uint32 CERT_INFO_SUBJECT_FLAG = 7;
	public const uint32 CERT_INFO_SUBJECT_PUBLIC_KEY_INFO_FLAG = 8;
	public const uint32 CERT_INFO_ISSUER_UNIQUE_ID_FLAG = 9;
	public const uint32 CERT_INFO_SUBJECT_UNIQUE_ID_FLAG = 10;
	public const uint32 CERT_INFO_EXTENSION_FLAG = 11;
	public const uint32 CRL_V1 = 0;
	public const uint32 CRL_V2 = 1;
	public const uint32 CERT_BUNDLE_CERTIFICATE = 0;
	public const uint32 CERT_BUNDLE_CRL = 1;
	public const uint32 CERT_REQUEST_V1 = 0;
	public const uint32 CERT_KEYGEN_REQUEST_V1 = 0;
	public const uint32 CTL_V1 = 0;
	public const uint32 CERT_ENCODING_TYPE_MASK = 65535;
	public const uint32 CMSG_ENCODING_TYPE_MASK = 4294901760;
	public const uint32 CRYPT_ASN_ENCODING = 1;
	public const uint32 CRYPT_NDR_ENCODING = 2;
	public const uint32 X509_NDR_ENCODING = 2;
	public const uint32 PKCS_7_NDR_ENCODING = 131072;
	public const uint32 CRYPT_FORMAT_STR_MULTI_LINE = 1;
	public const uint32 CRYPT_FORMAT_STR_NO_HEX = 16;
	public const uint32 CRYPT_FORMAT_SIMPLE = 1;
	public const uint32 CRYPT_FORMAT_X509 = 2;
	public const uint32 CRYPT_FORMAT_OID = 4;
	public const uint32 CRYPT_FORMAT_RDN_SEMICOLON = 256;
	public const uint32 CRYPT_FORMAT_RDN_CRLF = 512;
	public const uint32 CRYPT_FORMAT_RDN_UNQUOTE = 1024;
	public const uint32 CRYPT_FORMAT_RDN_REVERSE = 2048;
	public const uint32 CRYPT_FORMAT_COMMA = 4096;
	public const uint32 CRYPT_FORMAT_SEMICOLON = 256;
	public const uint32 CRYPT_FORMAT_CRLF = 512;
	public const uint32 CRYPT_ENCODE_NO_SIGNATURE_BYTE_REVERSAL_FLAG = 8;
	public const uint32 CRYPT_UNICODE_NAME_ENCODE_FORCE_UTF8_UNICODE_FLAG = 268435456;
	public const uint32 CRYPT_SORTED_CTL_ENCODE_HASHED_SUBJECT_IDENTIFIER_FLAG = 65536;
	public const uint32 CRYPT_ENCODE_ENABLE_UTF8PERCENT_FLAG = 262144;
	public const uint32 CRYPT_DECODE_NOCOPY_FLAG = 1;
	public const uint32 CRYPT_DECODE_TO_BE_SIGNED_FLAG = 2;
	public const uint32 CRYPT_DECODE_SHARE_OID_STRING_FLAG = 4;
	public const uint32 CRYPT_DECODE_NO_SIGNATURE_BYTE_REVERSAL_FLAG = 8;
	public const uint32 CRYPT_DECODE_ALLOC_FLAG = 32768;
	public const uint32 CRYPT_UNICODE_NAME_DECODE_DISABLE_IE4_UTF8_FLAG = 16777216;
	public const uint32 CRYPT_DECODE_ENABLE_PUNYCODE_FLAG = 33554432;
	public const uint32 CRYPT_DECODE_ENABLE_UTF8PERCENT_FLAG = 67108864;
	public const uint32 CRYPT_ENCODE_DECODE_NONE = 0;
	public const PSTR X509_CERT = (PSTR)(void*)1;
	public const PSTR X509_CERT_TO_BE_SIGNED = (PSTR)(void*)2;
	public const PSTR X509_CERT_CRL_TO_BE_SIGNED = (PSTR)(void*)3;
	public const PSTR X509_CERT_REQUEST_TO_BE_SIGNED = (PSTR)(void*)4;
	public const PSTR X509_EXTENSIONS = (PSTR)(void*)5;
	public const PSTR X509_NAME_VALUE = (PSTR)(void*)6;
	public const PSTR X509_NAME = (PSTR)(void*)7;
	public const PSTR X509_PUBLIC_KEY_INFO = (PSTR)(void*)8;
	public const PSTR X509_AUTHORITY_KEY_ID = (PSTR)(void*)9;
	public const PSTR X509_KEY_ATTRIBUTES = (PSTR)(void*)10;
	public const PSTR X509_KEY_USAGE_RESTRICTION = (PSTR)(void*)11;
	public const PSTR X509_ALTERNATE_NAME = (PSTR)(void*)12;
	public const PSTR X509_BASIC_CONSTRAINTS = (PSTR)(void*)13;
	public const PSTR X509_KEY_USAGE = (PSTR)(void*)14;
	public const PSTR X509_BASIC_CONSTRAINTS2 = (PSTR)(void*)15;
	public const PSTR X509_CERT_POLICIES = (PSTR)(void*)16;
	public const PSTR PKCS_UTC_TIME = (PSTR)(void*)17;
	public const PSTR PKCS_TIME_REQUEST = (PSTR)(void*)18;
	public const PSTR RSA_CSP_PUBLICKEYBLOB = (PSTR)(void*)19;
	public const PSTR X509_UNICODE_NAME = (PSTR)(void*)20;
	public const PSTR X509_KEYGEN_REQUEST_TO_BE_SIGNED = (PSTR)(void*)21;
	public const PSTR PKCS_ATTRIBUTE = (PSTR)(void*)22;
	public const PSTR PKCS_CONTENT_INFO_SEQUENCE_OF_ANY = (PSTR)(void*)23;
	public const PSTR X509_UNICODE_NAME_VALUE = (PSTR)(void*)24;
	public const int32 X509_ANY_STRING = 6;
	public const int32 X509_UNICODE_ANY_STRING = 24;
	public const PSTR X509_OCTET_STRING = (PSTR)(void*)25;
	public const PSTR X509_BITS = (PSTR)(void*)26;
	public const PSTR X509_INTEGER = (PSTR)(void*)27;
	public const PSTR X509_MULTI_BYTE_INTEGER = (PSTR)(void*)28;
	public const PSTR X509_ENUMERATED = (PSTR)(void*)29;
	public const PSTR X509_CHOICE_OF_TIME = (PSTR)(void*)30;
	public const PSTR X509_AUTHORITY_KEY_ID2 = (PSTR)(void*)31;
	public const PSTR X509_AUTHORITY_INFO_ACCESS = (PSTR)(void*)32;
	public const int32 X509_SUBJECT_INFO_ACCESS = 32;
	public const int32 X509_CRL_REASON_CODE = 29;
	public const PSTR PKCS_CONTENT_INFO = (PSTR)(void*)33;
	public const PSTR X509_SEQUENCE_OF_ANY = (PSTR)(void*)34;
	public const PSTR X509_CRL_DIST_POINTS = (PSTR)(void*)35;
	public const PSTR X509_ENHANCED_KEY_USAGE = (PSTR)(void*)36;
	public const PSTR PKCS_CTL = (PSTR)(void*)37;
	public const PSTR X509_MULTI_BYTE_UINT = (PSTR)(void*)38;
	public const int32 X509_DSS_PUBLICKEY = 38;
	public const PSTR X509_DSS_PARAMETERS = (PSTR)(void*)39;
	public const PSTR X509_DSS_SIGNATURE = (PSTR)(void*)40;
	public const PSTR PKCS_RC2_CBC_PARAMETERS = (PSTR)(void*)41;
	public const PSTR PKCS_SMIME_CAPABILITIES = (PSTR)(void*)42;
	public const PSTR X509_QC_STATEMENTS_EXT = (PSTR)(void*)42;
	public const PSTR PKCS_RSA_PRIVATE_KEY = (PSTR)(void*)43;
	public const PSTR PKCS_PRIVATE_KEY_INFO = (PSTR)(void*)44;
	public const PSTR PKCS_ENCRYPTED_PRIVATE_KEY_INFO = (PSTR)(void*)45;
	public const PSTR X509_PKIX_POLICY_QUALIFIER_USERNOTICE = (PSTR)(void*)46;
	public const int32 X509_DH_PUBLICKEY = 38;
	public const PSTR X509_DH_PARAMETERS = (PSTR)(void*)47;
	public const PSTR PKCS_ATTRIBUTES = (PSTR)(void*)48;
	public const PSTR PKCS_SORTED_CTL = (PSTR)(void*)49;
	public const PSTR X509_ECC_SIGNATURE = (PSTR)(void*)47;
	public const PSTR X942_DH_PARAMETERS = (PSTR)(void*)50;
	public const PSTR X509_BITS_WITHOUT_TRAILING_ZEROES = (PSTR)(void*)51;
	public const PSTR X942_OTHER_INFO = (PSTR)(void*)52;
	public const PSTR X509_CERT_PAIR = (PSTR)(void*)53;
	public const PSTR X509_ISSUING_DIST_POINT = (PSTR)(void*)54;
	public const PSTR X509_NAME_CONSTRAINTS = (PSTR)(void*)55;
	public const PSTR X509_POLICY_MAPPINGS = (PSTR)(void*)56;
	public const PSTR X509_POLICY_CONSTRAINTS = (PSTR)(void*)57;
	public const PSTR X509_CROSS_CERT_DIST_POINTS = (PSTR)(void*)58;
	public const PSTR CMC_DATA = (PSTR)(void*)59;
	public const PSTR CMC_RESPONSE = (PSTR)(void*)60;
	public const PSTR CMC_STATUS = (PSTR)(void*)61;
	public const PSTR CMC_ADD_EXTENSIONS = (PSTR)(void*)62;
	public const PSTR CMC_ADD_ATTRIBUTES = (PSTR)(void*)63;
	public const PSTR X509_CERTIFICATE_TEMPLATE = (PSTR)(void*)64;
	public const PSTR OCSP_SIGNED_REQUEST = (PSTR)(void*)65;
	public const PSTR OCSP_REQUEST = (PSTR)(void*)66;
	public const PSTR OCSP_RESPONSE = (PSTR)(void*)67;
	public const PSTR OCSP_BASIC_SIGNED_RESPONSE = (PSTR)(void*)68;
	public const PSTR OCSP_BASIC_RESPONSE = (PSTR)(void*)69;
	public const PSTR X509_LOGOTYPE_EXT = (PSTR)(void*)70;
	public const PSTR X509_BIOMETRIC_EXT = (PSTR)(void*)71;
	public const PSTR CNG_RSA_PUBLIC_KEY_BLOB = (PSTR)(void*)72;
	public const PSTR X509_OBJECT_IDENTIFIER = (PSTR)(void*)73;
	public const PSTR X509_ALGORITHM_IDENTIFIER = (PSTR)(void*)74;
	public const PSTR PKCS_RSA_SSA_PSS_PARAMETERS = (PSTR)(void*)75;
	public const PSTR PKCS_RSAES_OAEP_PARAMETERS = (PSTR)(void*)76;
	public const PSTR ECC_CMS_SHARED_INFO = (PSTR)(void*)77;
	public const PSTR TIMESTAMP_REQUEST = (PSTR)(void*)78;
	public const PSTR TIMESTAMP_RESPONSE = (PSTR)(void*)79;
	public const PSTR TIMESTAMP_INFO = (PSTR)(void*)80;
	public const PSTR X509_CERT_BUNDLE = (PSTR)(void*)81;
	public const PSTR X509_ECC_PRIVATE_KEY = (PSTR)(void*)82;
	public const PSTR CNG_RSA_PRIVATE_KEY_BLOB = (PSTR)(void*)83;
	public const PSTR X509_SUBJECT_DIR_ATTRS = (PSTR)(void*)84;
	public const PSTR X509_ECC_PARAMETERS = (PSTR)(void*)85;
	public const PSTR PKCS7_SIGNER_INFO = (PSTR)(void*)500;
	public const PSTR CMS_SIGNER_INFO = (PSTR)(void*)501;
	public const String szOID_AUTHORITY_KEY_IDENTIFIER = "2.5.29.1";
	public const String szOID_KEY_ATTRIBUTES = "2.5.29.2";
	public const String szOID_CERT_POLICIES_95 = "2.5.29.3";
	public const String szOID_KEY_USAGE_RESTRICTION = "2.5.29.4";
	public const String szOID_SUBJECT_ALT_NAME = "2.5.29.7";
	public const String szOID_ISSUER_ALT_NAME = "2.5.29.8";
	public const String szOID_BASIC_CONSTRAINTS = "2.5.29.10";
	public const String szOID_KEY_USAGE = "2.5.29.15";
	public const String szOID_PRIVATEKEY_USAGE_PERIOD = "2.5.29.16";
	public const String szOID_BASIC_CONSTRAINTS2 = "2.5.29.19";
	public const String szOID_CERT_POLICIES = "2.5.29.32";
	public const String szOID_ANY_CERT_POLICY = "2.5.29.32.0";
	public const String szOID_INHIBIT_ANY_POLICY = "2.5.29.54";
	public const String szOID_AUTHORITY_KEY_IDENTIFIER2 = "2.5.29.35";
	public const String szOID_SUBJECT_KEY_IDENTIFIER = "2.5.29.14";
	public const String szOID_SUBJECT_ALT_NAME2 = "2.5.29.17";
	public const String szOID_ISSUER_ALT_NAME2 = "2.5.29.18";
	public const String szOID_CRL_REASON_CODE = "2.5.29.21";
	public const String szOID_REASON_CODE_HOLD = "2.5.29.23";
	public const String szOID_CRL_DIST_POINTS = "2.5.29.31";
	public const String szOID_ENHANCED_KEY_USAGE = "2.5.29.37";
	public const String szOID_ANY_ENHANCED_KEY_USAGE = "2.5.29.37.0";
	public const String szOID_CRL_NUMBER = "2.5.29.20";
	public const String szOID_DELTA_CRL_INDICATOR = "2.5.29.27";
	public const String szOID_ISSUING_DIST_POINT = "2.5.29.28";
	public const String szOID_FRESHEST_CRL = "2.5.29.46";
	public const String szOID_NAME_CONSTRAINTS = "2.5.29.30";
	public const String szOID_POLICY_MAPPINGS = "2.5.29.33";
	public const String szOID_LEGACY_POLICY_MAPPINGS = "2.5.29.5";
	public const String szOID_POLICY_CONSTRAINTS = "2.5.29.36";
	public const String szOID_RENEWAL_CERTIFICATE = "1.3.6.1.4.1.311.13.1";
	public const String szOID_ENROLLMENT_NAME_VALUE_PAIR = "1.3.6.1.4.1.311.13.2.1";
	public const String szOID_ENROLLMENT_CSP_PROVIDER = "1.3.6.1.4.1.311.13.2.2";
	public const String szOID_OS_VERSION = "1.3.6.1.4.1.311.13.2.3";
	public const String szOID_ENROLLMENT_AGENT = "1.3.6.1.4.1.311.20.2.1";
	public const String szOID_PKIX = "1.3.6.1.5.5.7";
	public const String szOID_PKIX_PE = "1.3.6.1.5.5.7.1";
	public const String szOID_AUTHORITY_INFO_ACCESS = "1.3.6.1.5.5.7.1.1";
	public const String szOID_SUBJECT_INFO_ACCESS = "1.3.6.1.5.5.7.1.11";
	public const String szOID_BIOMETRIC_EXT = "1.3.6.1.5.5.7.1.2";
	public const String szOID_QC_STATEMENTS_EXT = "1.3.6.1.5.5.7.1.3";
	public const String szOID_LOGOTYPE_EXT = "1.3.6.1.5.5.7.1.12";
	public const String szOID_TLS_FEATURES_EXT = "1.3.6.1.5.5.7.1.24";
	public const String szOID_CERT_EXTENSIONS = "1.3.6.1.4.1.311.2.1.14";
	public const String szOID_NEXT_UPDATE_LOCATION = "1.3.6.1.4.1.311.10.2";
	public const String szOID_REMOVE_CERTIFICATE = "1.3.6.1.4.1.311.10.8.1";
	public const String szOID_CROSS_CERT_DIST_POINTS = "1.3.6.1.4.1.311.10.9.1";
	public const String szOID_CTL = "1.3.6.1.4.1.311.10.1";
	public const String szOID_SORTED_CTL = "1.3.6.1.4.1.311.10.1.1";
	public const String szOID_SERIALIZED = "1.3.6.1.4.1.311.10.3.3.1";
	public const String szOID_NT_PRINCIPAL_NAME = "1.3.6.1.4.1.311.20.2.3";
	public const String szOID_INTERNATIONALIZED_EMAIL_ADDRESS = "1.3.6.1.4.1.311.20.2.4";
	public const String szOID_PRODUCT_UPDATE = "1.3.6.1.4.1.311.31.1";
	public const String szOID_ANY_APPLICATION_POLICY = "1.3.6.1.4.1.311.10.12.1";
	public const String szOID_AUTO_ENROLL_CTL_USAGE = "1.3.6.1.4.1.311.20.1";
	public const String szOID_ENROLL_CERTTYPE_EXTENSION = "1.3.6.1.4.1.311.20.2";
	public const String szOID_CERT_MANIFOLD = "1.3.6.1.4.1.311.20.3";
	public const String szOID_CERTSRV_CA_VERSION = "1.3.6.1.4.1.311.21.1";
	public const String szOID_CERTSRV_PREVIOUS_CERT_HASH = "1.3.6.1.4.1.311.21.2";
	public const String szOID_CRL_VIRTUAL_BASE = "1.3.6.1.4.1.311.21.3";
	public const String szOID_CRL_NEXT_PUBLISH = "1.3.6.1.4.1.311.21.4";
	public const String szOID_KP_CA_EXCHANGE = "1.3.6.1.4.1.311.21.5";
	public const String szOID_KP_PRIVACY_CA = "1.3.6.1.4.1.311.21.36";
	public const String szOID_KP_KEY_RECOVERY_AGENT = "1.3.6.1.4.1.311.21.6";
	public const String szOID_CERTIFICATE_TEMPLATE = "1.3.6.1.4.1.311.21.7";
	public const String szOID_ENTERPRISE_OID_ROOT = "1.3.6.1.4.1.311.21.8";
	public const String szOID_RDN_DUMMY_SIGNER = "1.3.6.1.4.1.311.21.9";
	public const String szOID_APPLICATION_CERT_POLICIES = "1.3.6.1.4.1.311.21.10";
	public const String szOID_APPLICATION_POLICY_MAPPINGS = "1.3.6.1.4.1.311.21.11";
	public const String szOID_APPLICATION_POLICY_CONSTRAINTS = "1.3.6.1.4.1.311.21.12";
	public const String szOID_ARCHIVED_KEY_ATTR = "1.3.6.1.4.1.311.21.13";
	public const String szOID_CRL_SELF_CDP = "1.3.6.1.4.1.311.21.14";
	public const String szOID_REQUIRE_CERT_CHAIN_POLICY = "1.3.6.1.4.1.311.21.15";
	public const String szOID_ARCHIVED_KEY_CERT_HASH = "1.3.6.1.4.1.311.21.16";
	public const String szOID_ISSUED_CERT_HASH = "1.3.6.1.4.1.311.21.17";
	public const String szOID_DS_EMAIL_REPLICATION = "1.3.6.1.4.1.311.21.19";
	public const String szOID_REQUEST_CLIENT_INFO = "1.3.6.1.4.1.311.21.20";
	public const String szOID_ENCRYPTED_KEY_HASH = "1.3.6.1.4.1.311.21.21";
	public const String szOID_CERTSRV_CROSSCA_VERSION = "1.3.6.1.4.1.311.21.22";
	public const String szOID_NTDS_REPLICATION = "1.3.6.1.4.1.311.25.1";
	public const String szOID_SUBJECT_DIR_ATTRS = "2.5.29.9";
	public const String szOID_PKIX_KP = "1.3.6.1.5.5.7.3";
	public const String szOID_PKIX_KP_SERVER_AUTH = "1.3.6.1.5.5.7.3.1";
	public const String szOID_PKIX_KP_CLIENT_AUTH = "1.3.6.1.5.5.7.3.2";
	public const String szOID_PKIX_KP_CODE_SIGNING = "1.3.6.1.5.5.7.3.3";
	public const String szOID_PKIX_KP_EMAIL_PROTECTION = "1.3.6.1.5.5.7.3.4";
	public const String szOID_PKIX_KP_IPSEC_END_SYSTEM = "1.3.6.1.5.5.7.3.5";
	public const String szOID_PKIX_KP_IPSEC_TUNNEL = "1.3.6.1.5.5.7.3.6";
	public const String szOID_PKIX_KP_IPSEC_USER = "1.3.6.1.5.5.7.3.7";
	public const String szOID_PKIX_KP_TIMESTAMP_SIGNING = "1.3.6.1.5.5.7.3.8";
	public const String szOID_PKIX_KP_OCSP_SIGNING = "1.3.6.1.5.5.7.3.9";
	public const String szOID_PKIX_OCSP_NOCHECK = "1.3.6.1.5.5.7.48.1.5";
	public const String szOID_PKIX_OCSP_NONCE = "1.3.6.1.5.5.7.48.1.2";
	public const String szOID_IPSEC_KP_IKE_INTERMEDIATE = "1.3.6.1.5.5.8.2.2";
	public const String szOID_PKINIT_KP_KDC = "1.3.6.1.5.2.3.5";
	public const String szOID_KP_CTL_USAGE_SIGNING = "1.3.6.1.4.1.311.10.3.1";
	public const String szOID_KP_TIME_STAMP_SIGNING = "1.3.6.1.4.1.311.10.3.2";
	public const String szOID_SERVER_GATED_CRYPTO = "1.3.6.1.4.1.311.10.3.3";
	public const String szOID_SGC_NETSCAPE = "2.16.840.1.113730.4.1";
	public const String szOID_KP_EFS = "1.3.6.1.4.1.311.10.3.4";
	public const String szOID_EFS_RECOVERY = "1.3.6.1.4.1.311.10.3.4.1";
	public const String szOID_WHQL_CRYPTO = "1.3.6.1.4.1.311.10.3.5";
	public const String szOID_ATTEST_WHQL_CRYPTO = "1.3.6.1.4.1.311.10.3.5.1";
	public const String szOID_NT5_CRYPTO = "1.3.6.1.4.1.311.10.3.6";
	public const String szOID_OEM_WHQL_CRYPTO = "1.3.6.1.4.1.311.10.3.7";
	public const String szOID_EMBEDDED_NT_CRYPTO = "1.3.6.1.4.1.311.10.3.8";
	public const String szOID_ROOT_LIST_SIGNER = "1.3.6.1.4.1.311.10.3.9";
	public const String szOID_KP_QUALIFIED_SUBORDINATION = "1.3.6.1.4.1.311.10.3.10";
	public const String szOID_KP_KEY_RECOVERY = "1.3.6.1.4.1.311.10.3.11";
	public const String szOID_KP_DOCUMENT_SIGNING = "1.3.6.1.4.1.311.10.3.12";
	public const String szOID_KP_LIFETIME_SIGNING = "1.3.6.1.4.1.311.10.3.13";
	public const String szOID_KP_MOBILE_DEVICE_SOFTWARE = "1.3.6.1.4.1.311.10.3.14";
	public const String szOID_KP_SMART_DISPLAY = "1.3.6.1.4.1.311.10.3.15";
	public const String szOID_KP_CSP_SIGNATURE = "1.3.6.1.4.1.311.10.3.16";
	public const String szOID_KP_FLIGHT_SIGNING = "1.3.6.1.4.1.311.10.3.27";
	public const String szOID_PLATFORM_MANIFEST_BINARY_ID = "1.3.6.1.4.1.311.10.3.28";
	public const String szOID_DRM = "1.3.6.1.4.1.311.10.5.1";
	public const String szOID_DRM_INDIVIDUALIZATION = "1.3.6.1.4.1.311.10.5.2";
	public const String szOID_LICENSES = "1.3.6.1.4.1.311.10.6.1";
	public const String szOID_LICENSE_SERVER = "1.3.6.1.4.1.311.10.6.2";
	public const String szOID_KP_SMARTCARD_LOGON = "1.3.6.1.4.1.311.20.2.2";
	public const String szOID_KP_KERNEL_MODE_CODE_SIGNING = "1.3.6.1.4.1.311.61.1.1";
	public const String szOID_KP_KERNEL_MODE_TRUSTED_BOOT_SIGNING = "1.3.6.1.4.1.311.61.4.1";
	public const String szOID_REVOKED_LIST_SIGNER = "1.3.6.1.4.1.311.10.3.19";
	public const String szOID_WINDOWS_KITS_SIGNER = "1.3.6.1.4.1.311.10.3.20";
	public const String szOID_WINDOWS_RT_SIGNER = "1.3.6.1.4.1.311.10.3.21";
	public const String szOID_PROTECTED_PROCESS_LIGHT_SIGNER = "1.3.6.1.4.1.311.10.3.22";
	public const String szOID_WINDOWS_TCB_SIGNER = "1.3.6.1.4.1.311.10.3.23";
	public const String szOID_PROTECTED_PROCESS_SIGNER = "1.3.6.1.4.1.311.10.3.24";
	public const String szOID_WINDOWS_THIRD_PARTY_COMPONENT_SIGNER = "1.3.6.1.4.1.311.10.3.25";
	public const String szOID_WINDOWS_SOFTWARE_EXTENSION_SIGNER = "1.3.6.1.4.1.311.10.3.26";
	public const String szOID_DISALLOWED_LIST = "1.3.6.1.4.1.311.10.3.30";
	public const String szOID_PIN_RULES_SIGNER = "1.3.6.1.4.1.311.10.3.31";
	public const String szOID_PIN_RULES_CTL = "1.3.6.1.4.1.311.10.3.32";
	public const String szOID_PIN_RULES_EXT = "1.3.6.1.4.1.311.10.3.33";
	public const String szOID_PIN_RULES_DOMAIN_NAME = "1.3.6.1.4.1.311.10.3.34";
	public const String szOID_PIN_RULES_LOG_END_DATE_EXT = "1.3.6.1.4.1.311.10.3.35";
	public const String szOID_IUM_SIGNING = "1.3.6.1.4.1.311.10.3.37";
	public const String szOID_EV_WHQL_CRYPTO = "1.3.6.1.4.1.311.10.3.39";
	public const String szOID_BIOMETRIC_SIGNING = "1.3.6.1.4.1.311.10.3.41";
	public const String szOID_ENCLAVE_SIGNING = "1.3.6.1.4.1.311.10.3.42";
	public const String szOID_SYNC_ROOT_CTL_EXT = "1.3.6.1.4.1.311.10.3.50";
	public const String szOID_HPKP_DOMAIN_NAME_CTL = "1.3.6.1.4.1.311.10.3.60";
	public const String szOID_HPKP_HEADER_VALUE_CTL = "1.3.6.1.4.1.311.10.3.61";
	public const String szOID_KP_KERNEL_MODE_HAL_EXTENSION_SIGNING = "1.3.6.1.4.1.311.61.5.1";
	public const String szOID_WINDOWS_STORE_SIGNER = "1.3.6.1.4.1.311.76.3.1";
	public const String szOID_DYNAMIC_CODE_GEN_SIGNER = "1.3.6.1.4.1.311.76.5.1";
	public const String szOID_MICROSOFT_PUBLISHER_SIGNER = "1.3.6.1.4.1.311.76.8.1";
	public const String szOID_YESNO_TRUST_ATTR = "1.3.6.1.4.1.311.10.4.1";
	public const String szOID_SITE_PIN_RULES_INDEX_ATTR = "1.3.6.1.4.1.311.10.4.2";
	public const String szOID_SITE_PIN_RULES_FLAGS_ATTR = "1.3.6.1.4.1.311.10.4.3";
	public const uint32 SITE_PIN_RULES_ALL_SUBDOMAINS_FLAG = 1;
	public const String szOID_PKIX_POLICY_QUALIFIER_CPS = "1.3.6.1.5.5.7.2.1";
	public const String szOID_PKIX_POLICY_QUALIFIER_USERNOTICE = "1.3.6.1.5.5.7.2.2";
	public const String szOID_ROOT_PROGRAM_FLAGS = "1.3.6.1.4.1.311.60.1.1";
	public const uint32 CERT_ROOT_PROGRAM_FLAG_OU = 16;
	public const uint32 CERT_ROOT_PROGRAM_FLAG_ADDRESS = 8;
	public const String szOID_CERT_POLICIES_95_QUALIFIER1 = "2.16.840.1.113733.1.7.1.1";
	public const String szOID_RDN_TPM_MANUFACTURER = "2.23.133.2.1";
	public const String szOID_RDN_TPM_MODEL = "2.23.133.2.2";
	public const String szOID_RDN_TPM_VERSION = "2.23.133.2.3";
	public const String szOID_RDN_TCG_PLATFORM_MANUFACTURER = "2.23.133.2.4";
	public const String szOID_RDN_TCG_PLATFORM_MODEL = "2.23.133.2.5";
	public const String szOID_RDN_TCG_PLATFORM_VERSION = "2.23.133.2.6";
	public const String szOID_CT_CERT_SCTLIST = "1.3.6.1.4.1.11129.2.4.2";
	public const String szOID_ENROLL_EK_INFO = "1.3.6.1.4.1.311.21.23";
	public const String szOID_ENROLL_AIK_INFO = "1.3.6.1.4.1.311.21.39";
	public const String szOID_ENROLL_ATTESTATION_STATEMENT = "1.3.6.1.4.1.311.21.24";
	public const String szOID_ENROLL_KSP_NAME = "1.3.6.1.4.1.311.21.25";
	public const String szOID_ENROLL_EKPUB_CHALLENGE = "1.3.6.1.4.1.311.21.26";
	public const String szOID_ENROLL_CAXCHGCERT_HASH = "1.3.6.1.4.1.311.21.27";
	public const String szOID_ENROLL_ATTESTATION_CHALLENGE = "1.3.6.1.4.1.311.21.28";
	public const String szOID_ENROLL_ENCRYPTION_ALGORITHM = "1.3.6.1.4.1.311.21.29";
	public const String szOID_KP_TPM_EK_CERTIFICATE = "2.23.133.8.1";
	public const String szOID_KP_TPM_PLATFORM_CERTIFICATE = "2.23.133.8.2";
	public const String szOID_KP_TPM_AIK_CERTIFICATE = "2.23.133.8.3";
	public const String szOID_ENROLL_EKVERIFYKEY = "1.3.6.1.4.1.311.21.30";
	public const String szOID_ENROLL_EKVERIFYCERT = "1.3.6.1.4.1.311.21.31";
	public const String szOID_ENROLL_EKVERIFYCREDS = "1.3.6.1.4.1.311.21.32";
	public const String szOID_ENROLL_SCEP_ERROR = "1.3.6.1.4.1.311.21.33";
	public const String szOID_ENROLL_SCEP_SERVER_STATE = "1.3.6.1.4.1.311.21.34";
	public const String szOID_ENROLL_SCEP_CHALLENGE_ANSWER = "1.3.6.1.4.1.311.21.35";
	public const String szOID_ENROLL_SCEP_CLIENT_REQUEST = "1.3.6.1.4.1.311.21.37";
	public const String szOID_ENROLL_SCEP_SERVER_MESSAGE = "1.3.6.1.4.1.311.21.38";
	public const String szOID_ENROLL_SCEP_SERVER_SECRET = "1.3.6.1.4.1.311.21.40";
	public const String szOID_ENROLL_KEY_AFFINITY = "1.3.6.1.4.1.311.21.41";
	public const String szOID_ENROLL_SCEP_SIGNER_HASH = "1.3.6.1.4.1.311.21.42";
	public const String szOID_ENROLL_EK_CA_KEYID = "1.3.6.1.4.1.311.21.43";
	public const String szOID_ATTR_SUPPORTED_ALGORITHMS = "2.5.4.52";
	public const String szOID_ATTR_TPM_SPECIFICATION = "2.23.133.2.16";
	public const String szOID_ATTR_PLATFORM_SPECIFICATION = "2.23.133.2.17";
	public const String szOID_ATTR_TPM_SECURITY_ASSERTIONS = "2.23.133.2.18";
	public const uint32 CERT_UNICODE_RDN_ERR_INDEX_MASK = 1023;
	public const uint32 CERT_UNICODE_RDN_ERR_INDEX_SHIFT = 22;
	public const uint32 CERT_UNICODE_ATTR_ERR_INDEX_MASK = 63;
	public const uint32 CERT_UNICODE_ATTR_ERR_INDEX_SHIFT = 16;
	public const uint32 CERT_UNICODE_VALUE_ERR_INDEX_MASK = 65535;
	public const uint32 CERT_UNICODE_VALUE_ERR_INDEX_SHIFT = 0;
	public const uint32 CERT_DIGITAL_SIGNATURE_KEY_USAGE = 128;
	public const uint32 CERT_NON_REPUDIATION_KEY_USAGE = 64;
	public const uint32 CERT_KEY_ENCIPHERMENT_KEY_USAGE = 32;
	public const uint32 CERT_DATA_ENCIPHERMENT_KEY_USAGE = 16;
	public const uint32 CERT_KEY_AGREEMENT_KEY_USAGE = 8;
	public const uint32 CERT_KEY_CERT_SIGN_KEY_USAGE = 4;
	public const uint32 CERT_OFFLINE_CRL_SIGN_KEY_USAGE = 2;
	public const uint32 CERT_CRL_SIGN_KEY_USAGE = 2;
	public const uint32 CERT_ENCIPHER_ONLY_KEY_USAGE = 1;
	public const uint32 CERT_DECIPHER_ONLY_KEY_USAGE = 128;
	public const uint32 CERT_ALT_NAME_X400_ADDRESS = 4;
	public const uint32 CERT_ALT_NAME_EDI_PARTY_NAME = 6;
	public const uint32 CERT_ALT_NAME_ENTRY_ERR_INDEX_MASK = 255;
	public const uint32 CERT_ALT_NAME_ENTRY_ERR_INDEX_SHIFT = 16;
	public const uint32 CERT_ALT_NAME_VALUE_ERR_INDEX_MASK = 65535;
	public const uint32 CERT_ALT_NAME_VALUE_ERR_INDEX_SHIFT = 0;
	public const uint32 CERT_CA_SUBJECT_FLAG = 128;
	public const uint32 CERT_END_ENTITY_SUBJECT_FLAG = 64;
	public const String szOID_PKIX_ACC_DESCR = "1.3.6.1.5.5.7.48";
	public const String szOID_PKIX_OCSP = "1.3.6.1.5.5.7.48.1";
	public const String szOID_PKIX_CA_ISSUERS = "1.3.6.1.5.5.7.48.2";
	public const String szOID_PKIX_TIME_STAMPING = "1.3.6.1.5.5.7.48.3";
	public const String szOID_PKIX_CA_REPOSITORY = "1.3.6.1.5.5.7.48.5";
	public const uint32 CRL_REASON_PRIVILEGE_WITHDRAWN = 9;
	public const uint32 CRL_REASON_AA_COMPROMISE = 10;
	public const uint32 CRL_DIST_POINT_NO_NAME = 0;
	public const uint32 CRL_DIST_POINT_FULL_NAME = 1;
	public const uint32 CRL_DIST_POINT_ISSUER_RDN_NAME = 2;
	public const uint32 CRL_REASON_UNUSED_FLAG = 128;
	public const uint32 CRL_REASON_KEY_COMPROMISE_FLAG = 64;
	public const uint32 CRL_REASON_CA_COMPROMISE_FLAG = 32;
	public const uint32 CRL_REASON_AFFILIATION_CHANGED_FLAG = 16;
	public const uint32 CRL_REASON_SUPERSEDED_FLAG = 8;
	public const uint32 CRL_REASON_CESSATION_OF_OPERATION_FLAG = 4;
	public const uint32 CRL_REASON_CERTIFICATE_HOLD_FLAG = 2;
	public const uint32 CRL_REASON_PRIVILEGE_WITHDRAWN_FLAG = 1;
	public const uint32 CRL_REASON_AA_COMPROMISE_FLAG = 128;
	public const uint32 CRL_DIST_POINT_ERR_INDEX_MASK = 127;
	public const uint32 CRL_DIST_POINT_ERR_INDEX_SHIFT = 24;
	public const int32 CRL_DIST_POINT_ERR_CRL_ISSUER_BIT = -2147483648;
	public const uint32 CROSS_CERT_DIST_POINT_ERR_INDEX_MASK = 255;
	public const uint32 CROSS_CERT_DIST_POINT_ERR_INDEX_SHIFT = 24;
	public const int32 CERT_EXCLUDED_SUBTREE_BIT = -2147483648;
	public const uint32 SORTED_CTL_EXT_HASHED_SUBJECT_IDENTIFIER_FLAG = 1;
	public const uint32 CERT_DSS_R_LEN = 20;
	public const uint32 CERT_DSS_S_LEN = 20;
	public const uint32 CRYPT_X942_COUNTER_BYTE_LENGTH = 4;
	public const uint32 CRYPT_X942_KEY_LENGTH_BYTE_LENGTH = 4;
	public const uint32 CRYPT_ECC_CMS_SHARED_INFO_SUPPPUBINFO_BYTE_LENGTH = 4;
	public const uint32 CRYPT_RC2_40BIT_VERSION = 160;
	public const uint32 CRYPT_RC2_56BIT_VERSION = 52;
	public const uint32 CRYPT_RC2_64BIT_VERSION = 120;
	public const uint32 CRYPT_RC2_128BIT_VERSION = 58;
	public const String szOID_QC_EU_COMPLIANCE = "0.4.0.1862.1.1";
	public const String szOID_QC_SSCD = "0.4.0.1862.1.4";
	public const uint32 PKCS_RSA_SSA_PSS_TRAILER_FIELD_BC = 1;
	public const String szOID_VERISIGN_PRIVATE_6_9 = "2.16.840.1.113733.1.6.9";
	public const String szOID_VERISIGN_ONSITE_JURISDICTION_HASH = "2.16.840.1.113733.1.6.11";
	public const String szOID_VERISIGN_BITSTRING_6_13 = "2.16.840.1.113733.1.6.13";
	public const String szOID_VERISIGN_ISS_STRONG_CRYPTO = "2.16.840.1.113733.1.8.1";
	public const String szOIDVerisign_MessageType = "2.16.840.1.113733.1.9.2";
	public const String szOIDVerisign_PkiStatus = "2.16.840.1.113733.1.9.3";
	public const String szOIDVerisign_FailInfo = "2.16.840.1.113733.1.9.4";
	public const String szOIDVerisign_SenderNonce = "2.16.840.1.113733.1.9.5";
	public const String szOIDVerisign_RecipientNonce = "2.16.840.1.113733.1.9.6";
	public const String szOIDVerisign_TransactionID = "2.16.840.1.113733.1.9.7";
	public const String szOID_NETSCAPE = "2.16.840.1.113730";
	public const String szOID_NETSCAPE_CERT_EXTENSION = "2.16.840.1.113730.1";
	public const String szOID_NETSCAPE_CERT_TYPE = "2.16.840.1.113730.1.1";
	public const String szOID_NETSCAPE_BASE_URL = "2.16.840.1.113730.1.2";
	public const String szOID_NETSCAPE_REVOCATION_URL = "2.16.840.1.113730.1.3";
	public const String szOID_NETSCAPE_CA_REVOCATION_URL = "2.16.840.1.113730.1.4";
	public const String szOID_NETSCAPE_CERT_RENEWAL_URL = "2.16.840.1.113730.1.7";
	public const String szOID_NETSCAPE_CA_POLICY_URL = "2.16.840.1.113730.1.8";
	public const String szOID_NETSCAPE_SSL_SERVER_NAME = "2.16.840.1.113730.1.12";
	public const String szOID_NETSCAPE_COMMENT = "2.16.840.1.113730.1.13";
	public const String szOID_NETSCAPE_DATA_TYPE = "2.16.840.1.113730.2";
	public const String szOID_NETSCAPE_CERT_SEQUENCE = "2.16.840.1.113730.2.5";
	public const uint32 NETSCAPE_SSL_CLIENT_AUTH_CERT_TYPE = 128;
	public const uint32 NETSCAPE_SSL_SERVER_AUTH_CERT_TYPE = 64;
	public const uint32 NETSCAPE_SMIME_CERT_TYPE = 32;
	public const uint32 NETSCAPE_SIGN_CERT_TYPE = 16;
	public const uint32 NETSCAPE_SSL_CA_CERT_TYPE = 4;
	public const uint32 NETSCAPE_SMIME_CA_CERT_TYPE = 2;
	public const uint32 NETSCAPE_SIGN_CA_CERT_TYPE = 1;
	public const String szOID_CT_PKI_DATA = "1.3.6.1.5.5.7.12.2";
	public const String szOID_CT_PKI_RESPONSE = "1.3.6.1.5.5.7.12.3";
	public const String szOID_PKIX_NO_SIGNATURE = "1.3.6.1.5.5.7.6.2";
	public const String szOID_CMC = "1.3.6.1.5.5.7.7";
	public const String szOID_CMC_STATUS_INFO = "1.3.6.1.5.5.7.7.1";
	public const String szOID_CMC_IDENTIFICATION = "1.3.6.1.5.5.7.7.2";
	public const String szOID_CMC_IDENTITY_PROOF = "1.3.6.1.5.5.7.7.3";
	public const String szOID_CMC_DATA_RETURN = "1.3.6.1.5.5.7.7.4";
	public const String szOID_CMC_TRANSACTION_ID = "1.3.6.1.5.5.7.7.5";
	public const String szOID_CMC_SENDER_NONCE = "1.3.6.1.5.5.7.7.6";
	public const String szOID_CMC_RECIPIENT_NONCE = "1.3.6.1.5.5.7.7.7";
	public const String szOID_CMC_ADD_EXTENSIONS = "1.3.6.1.5.5.7.7.8";
	public const String szOID_CMC_ENCRYPTED_POP = "1.3.6.1.5.5.7.7.9";
	public const String szOID_CMC_DECRYPTED_POP = "1.3.6.1.5.5.7.7.10";
	public const String szOID_CMC_LRA_POP_WITNESS = "1.3.6.1.5.5.7.7.11";
	public const String szOID_CMC_GET_CERT = "1.3.6.1.5.5.7.7.15";
	public const String szOID_CMC_GET_CRL = "1.3.6.1.5.5.7.7.16";
	public const String szOID_CMC_REVOKE_REQUEST = "1.3.6.1.5.5.7.7.17";
	public const String szOID_CMC_REG_INFO = "1.3.6.1.5.5.7.7.18";
	public const String szOID_CMC_RESPONSE_INFO = "1.3.6.1.5.5.7.7.19";
	public const String szOID_CMC_QUERY_PENDING = "1.3.6.1.5.5.7.7.21";
	public const String szOID_CMC_ID_POP_LINK_RANDOM = "1.3.6.1.5.5.7.7.22";
	public const String szOID_CMC_ID_POP_LINK_WITNESS = "1.3.6.1.5.5.7.7.23";
	public const String szOID_CMC_ID_CONFIRM_CERT_ACCEPTANCE = "1.3.6.1.5.5.7.7.24";
	public const String szOID_CMC_ADD_ATTRIBUTES = "1.3.6.1.4.1.311.10.10.1";
	public const uint32 CMC_TAGGED_CERT_REQUEST_CHOICE = 1;
	public const uint32 CMC_OTHER_INFO_NO_CHOICE = 0;
	public const uint32 CMC_OTHER_INFO_FAIL_CHOICE = 1;
	public const uint32 CMC_OTHER_INFO_PEND_CHOICE = 2;
	public const uint32 CMC_STATUS_SUCCESS = 0;
	public const uint32 CMC_STATUS_FAILED = 2;
	public const uint32 CMC_STATUS_PENDING = 3;
	public const uint32 CMC_STATUS_NO_SUPPORT = 4;
	public const uint32 CMC_STATUS_CONFIRM_REQUIRED = 5;
	public const uint32 CMC_FAIL_BAD_ALG = 0;
	public const uint32 CMC_FAIL_BAD_MESSAGE_CHECK = 1;
	public const uint32 CMC_FAIL_BAD_REQUEST = 2;
	public const uint32 CMC_FAIL_BAD_TIME = 3;
	public const uint32 CMC_FAIL_BAD_CERT_ID = 4;
	public const uint32 CMC_FAIL_UNSUPORTED_EXT = 5;
	public const uint32 CMC_FAIL_MUST_ARCHIVE_KEYS = 6;
	public const uint32 CMC_FAIL_BAD_IDENTITY = 7;
	public const uint32 CMC_FAIL_POP_REQUIRED = 8;
	public const uint32 CMC_FAIL_POP_FAILED = 9;
	public const uint32 CMC_FAIL_NO_KEY_REUSE = 10;
	public const uint32 CMC_FAIL_INTERNAL_CA_ERROR = 11;
	public const uint32 CMC_FAIL_TRY_LATER = 12;
	public const String szOID_LOYALTY_OTHER_LOGOTYPE = "1.3.6.1.5.5.7.20.1";
	public const String szOID_BACKGROUND_OTHER_LOGOTYPE = "1.3.6.1.5.5.7.20.2";
	public const uint32 CERT_BIOMETRIC_PICTURE_TYPE = 0;
	public const uint32 CERT_BIOMETRIC_SIGNATURE_TYPE = 1;
	public const uint32 OCSP_REQUEST_V1 = 0;
	public const uint32 OCSP_SUCCESSFUL_RESPONSE = 0;
	public const uint32 OCSP_MALFORMED_REQUEST_RESPONSE = 1;
	public const uint32 OCSP_INTERNAL_ERROR_RESPONSE = 2;
	public const uint32 OCSP_TRY_LATER_RESPONSE = 3;
	public const uint32 OCSP_SIG_REQUIRED_RESPONSE = 5;
	public const uint32 OCSP_UNAUTHORIZED_RESPONSE = 6;
	public const String szOID_PKIX_OCSP_BASIC_SIGNED_RESPONSE = "1.3.6.1.5.5.7.48.1.1";
	public const uint32 OCSP_BASIC_GOOD_CERT_STATUS = 0;
	public const uint32 OCSP_BASIC_REVOKED_CERT_STATUS = 1;
	public const uint32 OCSP_BASIC_UNKNOWN_CERT_STATUS = 2;
	public const uint32 OCSP_BASIC_RESPONSE_V1 = 0;
	public const uint32 OCSP_BASIC_BY_NAME_RESPONDER_ID = 1;
	public const uint32 OCSP_BASIC_BY_KEY_RESPONDER_ID = 2;
	public const String CRYPT_OID_ENCODE_OBJECT_FUNC = "CryptDllEncodeObject";
	public const String CRYPT_OID_DECODE_OBJECT_FUNC = "CryptDllDecodeObject";
	public const String CRYPT_OID_ENCODE_OBJECT_EX_FUNC = "CryptDllEncodeObjectEx";
	public const String CRYPT_OID_DECODE_OBJECT_EX_FUNC = "CryptDllDecodeObjectEx";
	public const String CRYPT_OID_CREATE_COM_OBJECT_FUNC = "CryptDllCreateCOMObject";
	public const String CRYPT_OID_VERIFY_REVOCATION_FUNC = "CertDllVerifyRevocation";
	public const String CRYPT_OID_VERIFY_CTL_USAGE_FUNC = "CertDllVerifyCTLUsage";
	public const String CRYPT_OID_FORMAT_OBJECT_FUNC = "CryptDllFormatObject";
	public const String CRYPT_OID_FIND_OID_INFO_FUNC = "CryptDllFindOIDInfo";
	public const String CRYPT_OID_FIND_LOCALIZED_NAME_FUNC = "CryptDllFindLocalizedName";
	public const String CRYPT_OID_REGPATH = "Software\\Microsoft\\Cryptography\\OID";
	public const String CRYPT_OID_REG_ENCODING_TYPE_PREFIX = "EncodingType ";
	public const String CRYPT_OID_REG_DLL_VALUE_NAME = "Dll";
	public const String CRYPT_OID_REG_FUNC_NAME_VALUE_NAME = "FuncName";
	public const String CRYPT_OID_REG_FUNC_NAME_VALUE_NAME_A = "FuncName";
	public const String CRYPT_OID_REG_FLAGS_VALUE_NAME = "CryptFlags";
	public const String CRYPT_DEFAULT_OID = "DEFAULT";
	public const uint32 CRYPT_INSTALL_OID_FUNC_BEFORE_FLAG = 1;
	public const uint32 CRYPT_GET_INSTALLED_OID_FUNC_FLAG = 1;
	public const uint32 CRYPT_REGISTER_FIRST_INDEX = 0;
	public const uint32 CRYPT_REGISTER_LAST_INDEX = 4294967295;
	public const uint32 CRYPT_MATCH_ANY_ENCODING_TYPE = 4294967295;
	public const uint32 CALG_OID_INFO_CNG_ONLY = 4294967295;
	public const uint32 CALG_OID_INFO_PARAMETERS = 4294967294;
	public const String CRYPT_OID_INFO_HASH_PARAMETERS_ALGORITHM = "CryptOIDInfoHashParameters";
	public const String CRYPT_OID_INFO_ECC_PARAMETERS_ALGORITHM = "CryptOIDInfoECCParameters";
	public const String CRYPT_OID_INFO_MGF1_PARAMETERS_ALGORITHM = "CryptOIDInfoMgf1Parameters";
	public const String CRYPT_OID_INFO_NO_SIGN_ALGORITHM = "CryptOIDInfoNoSign";
	public const String CRYPT_OID_INFO_OAEP_PARAMETERS_ALGORITHM = "CryptOIDInfoOAEPParameters";
	public const String CRYPT_OID_INFO_ECC_WRAP_PARAMETERS_ALGORITHM = "CryptOIDInfoECCWrapParameters";
	public const String CRYPT_OID_INFO_NO_PARAMETERS_ALGORITHM = "CryptOIDInfoNoParameters";
	public const uint32 CRYPT_HASH_ALG_OID_GROUP_ID = 1;
	public const uint32 CRYPT_ENCRYPT_ALG_OID_GROUP_ID = 2;
	public const uint32 CRYPT_PUBKEY_ALG_OID_GROUP_ID = 3;
	public const uint32 CRYPT_SIGN_ALG_OID_GROUP_ID = 4;
	public const uint32 CRYPT_RDN_ATTR_OID_GROUP_ID = 5;
	public const uint32 CRYPT_EXT_OR_ATTR_OID_GROUP_ID = 6;
	public const uint32 CRYPT_ENHKEY_USAGE_OID_GROUP_ID = 7;
	public const uint32 CRYPT_POLICY_OID_GROUP_ID = 8;
	public const uint32 CRYPT_TEMPLATE_OID_GROUP_ID = 9;
	public const uint32 CRYPT_KDF_OID_GROUP_ID = 10;
	public const uint32 CRYPT_LAST_OID_GROUP_ID = 10;
	public const uint32 CRYPT_FIRST_ALG_OID_GROUP_ID = 1;
	public const uint32 CRYPT_LAST_ALG_OID_GROUP_ID = 4;
	public const uint32 CRYPT_OID_INHIBIT_SIGNATURE_FORMAT_FLAG = 1;
	public const uint32 CRYPT_OID_USE_PUBKEY_PARA_FOR_PKCS7_FLAG = 2;
	public const uint32 CRYPT_OID_NO_NULL_ALGORITHM_PARA_FLAG = 4;
	public const uint32 CRYPT_OID_PUBKEY_SIGN_ONLY_FLAG = 2147483648;
	public const uint32 CRYPT_OID_PUBKEY_ENCRYPT_ONLY_FLAG = 1073741824;
	public const uint32 CRYPT_OID_USE_CURVE_NAME_FOR_ENCODE_FLAG = 536870912;
	public const uint32 CRYPT_OID_USE_CURVE_PARAMETERS_FOR_ENCODE_FLAG = 268435456;
	public const uint32 CRYPT_OID_INFO_OID_KEY = 1;
	public const uint32 CRYPT_OID_INFO_NAME_KEY = 2;
	public const uint32 CRYPT_OID_INFO_ALGID_KEY = 3;
	public const uint32 CRYPT_OID_INFO_SIGN_KEY = 4;
	public const uint32 CRYPT_OID_INFO_CNG_ALGID_KEY = 5;
	public const uint32 CRYPT_OID_INFO_CNG_SIGN_KEY = 6;
	public const uint32 CRYPT_OID_INFO_OID_KEY_FLAGS_MASK = 4294901760;
	public const uint32 CRYPT_OID_DISABLE_SEARCH_DS_FLAG = 2147483648;
	public const uint32 CRYPT_OID_PREFER_CNG_ALGID_FLAG = 1073741824;
	public const uint32 CRYPT_OID_INFO_OID_GROUP_BIT_LEN_MASK = 268369920;
	public const uint32 CRYPT_OID_INFO_OID_GROUP_BIT_LEN_SHIFT = 16;
	public const uint32 CRYPT_INSTALL_OID_INFO_BEFORE_FLAG = 1;
	public const uint32 CRYPT_LOCALIZED_NAME_ENCODING_TYPE = 0;
	public const String CRYPT_LOCALIZED_NAME_OID = "LocalizedNames";
	public const String CERT_STRONG_SIGN_ECDSA_ALGORITHM = "ECDSA";
	public const uint32 CERT_STRONG_SIGN_SERIALIZED_INFO_CHOICE = 1;
	public const uint32 CERT_STRONG_SIGN_OID_INFO_CHOICE = 2;
	public const String szOID_CERT_STRONG_SIGN_OS_PREFIX = "1.3.6.1.4.1.311.72.1.";
	public const String szOID_CERT_STRONG_SIGN_OS_1 = "1.3.6.1.4.1.311.72.1.1";
	public const String szOID_CERT_STRONG_SIGN_OS_CURRENT = "1.3.6.1.4.1.311.72.1.1";
	public const String szOID_CERT_STRONG_KEY_OS_PREFIX = "1.3.6.1.4.1.311.72.2.";
	public const String szOID_CERT_STRONG_KEY_OS_1 = "1.3.6.1.4.1.311.72.2.1";
	public const String szOID_CERT_STRONG_KEY_OS_CURRENT = "1.3.6.1.4.1.311.72.2.1";
	public const String szOID_PKCS_7_DATA = "1.2.840.113549.1.7.1";
	public const String szOID_PKCS_7_SIGNED = "1.2.840.113549.1.7.2";
	public const String szOID_PKCS_7_ENVELOPED = "1.2.840.113549.1.7.3";
	public const String szOID_PKCS_7_SIGNEDANDENVELOPED = "1.2.840.113549.1.7.4";
	public const String szOID_PKCS_7_DIGESTED = "1.2.840.113549.1.7.5";
	public const String szOID_PKCS_7_ENCRYPTED = "1.2.840.113549.1.7.6";
	public const String szOID_PKCS_9_CONTENT_TYPE = "1.2.840.113549.1.9.3";
	public const String szOID_PKCS_9_MESSAGE_DIGEST = "1.2.840.113549.1.9.4";
	public const uint32 CMSG_ENCRYPTED = 6;
	public const uint32 CMSG_MAIL_LIST_HANDLE_KEY_CHOICE = 1;
	public const uint32 CMSG_KEY_TRANS_RECIPIENT = 1;
	public const uint32 CMSG_KEY_AGREE_RECIPIENT = 2;
	public const uint32 CMSG_MAIL_LIST_RECIPIENT = 3;
	public const uint32 CMSG_SP3_COMPATIBLE_ENCRYPT_FLAG = 2147483648;
	public const uint32 CMSG_RC4_NO_SALT_FLAG = 1073741824;
	public const uint32 CMSG_INDEFINITE_LENGTH = 4294967295;
	public const uint32 CMSG_BARE_CONTENT_FLAG = 1;
	public const uint32 CMSG_LENGTH_ONLY_FLAG = 2;
	public const uint32 CMSG_DETACHED_FLAG = 4;
	public const uint32 CMSG_AUTHENTICATED_ATTRIBUTES_FLAG = 8;
	public const uint32 CMSG_CONTENTS_OCTETS_FLAG = 16;
	public const uint32 CMSG_MAX_LENGTH_FLAG = 32;
	public const uint32 CMSG_CMS_ENCAPSULATED_CONTENT_FLAG = 64;
	public const uint32 CMSG_SIGNED_DATA_NO_SIGN_FLAG = 128;
	public const uint32 CMSG_CRYPT_RELEASE_CONTEXT_FLAG = 32768;
	public const uint32 CMSG_TYPE_PARAM = 1;
	public const uint32 CMSG_CONTENT_PARAM = 2;
	public const uint32 CMSG_BARE_CONTENT_PARAM = 3;
	public const uint32 CMSG_INNER_CONTENT_TYPE_PARAM = 4;
	public const uint32 CMSG_SIGNER_COUNT_PARAM = 5;
	public const uint32 CMSG_SIGNER_INFO_PARAM = 6;
	public const uint32 CMSG_SIGNER_CERT_INFO_PARAM = 7;
	public const uint32 CMSG_SIGNER_HASH_ALGORITHM_PARAM = 8;
	public const uint32 CMSG_SIGNER_AUTH_ATTR_PARAM = 9;
	public const uint32 CMSG_SIGNER_UNAUTH_ATTR_PARAM = 10;
	public const uint32 CMSG_CERT_COUNT_PARAM = 11;
	public const uint32 CMSG_CERT_PARAM = 12;
	public const uint32 CMSG_CRL_COUNT_PARAM = 13;
	public const uint32 CMSG_CRL_PARAM = 14;
	public const uint32 CMSG_ENVELOPE_ALGORITHM_PARAM = 15;
	public const uint32 CMSG_RECIPIENT_COUNT_PARAM = 17;
	public const uint32 CMSG_RECIPIENT_INDEX_PARAM = 18;
	public const uint32 CMSG_RECIPIENT_INFO_PARAM = 19;
	public const uint32 CMSG_HASH_ALGORITHM_PARAM = 20;
	public const uint32 CMSG_HASH_DATA_PARAM = 21;
	public const uint32 CMSG_COMPUTED_HASH_PARAM = 22;
	public const uint32 CMSG_ENCRYPT_PARAM = 26;
	public const uint32 CMSG_ENCRYPTED_DIGEST = 27;
	public const uint32 CMSG_ENCODED_SIGNER = 28;
	public const uint32 CMSG_ENCODED_MESSAGE = 29;
	public const uint32 CMSG_VERSION_PARAM = 30;
	public const uint32 CMSG_ATTR_CERT_COUNT_PARAM = 31;
	public const uint32 CMSG_ATTR_CERT_PARAM = 32;
	public const uint32 CMSG_CMS_RECIPIENT_COUNT_PARAM = 33;
	public const uint32 CMSG_CMS_RECIPIENT_INDEX_PARAM = 34;
	public const uint32 CMSG_CMS_RECIPIENT_ENCRYPTED_KEY_INDEX_PARAM = 35;
	public const uint32 CMSG_CMS_RECIPIENT_INFO_PARAM = 36;
	public const uint32 CMSG_UNPROTECTED_ATTR_PARAM = 37;
	public const uint32 CMSG_SIGNER_CERT_ID_PARAM = 38;
	public const uint32 CMSG_CMS_SIGNER_INFO_PARAM = 39;
	public const uint32 CMSG_SIGNED_DATA_V1 = 1;
	public const uint32 CMSG_SIGNED_DATA_V3 = 3;
	public const uint32 CMSG_SIGNED_DATA_PKCS_1_5_VERSION = 1;
	public const uint32 CMSG_SIGNED_DATA_CMS_VERSION = 3;
	public const uint32 CMSG_SIGNER_INFO_V1 = 1;
	public const uint32 CMSG_SIGNER_INFO_V3 = 3;
	public const uint32 CMSG_SIGNER_INFO_PKCS_1_5_VERSION = 1;
	public const uint32 CMSG_SIGNER_INFO_CMS_VERSION = 3;
	public const uint32 CMSG_HASHED_DATA_V0 = 0;
	public const uint32 CMSG_HASHED_DATA_V2 = 2;
	public const uint32 CMSG_HASHED_DATA_PKCS_1_5_VERSION = 0;
	public const uint32 CMSG_HASHED_DATA_CMS_VERSION = 2;
	public const uint32 CMSG_ENVELOPED_DATA_V0 = 0;
	public const uint32 CMSG_ENVELOPED_DATA_V2 = 2;
	public const uint32 CMSG_ENVELOPED_DATA_PKCS_1_5_VERSION = 0;
	public const uint32 CMSG_ENVELOPED_DATA_CMS_VERSION = 2;
	public const uint32 CMSG_ENVELOPED_RECIPIENT_V0 = 0;
	public const uint32 CMSG_ENVELOPED_RECIPIENT_V2 = 2;
	public const uint32 CMSG_ENVELOPED_RECIPIENT_V3 = 3;
	public const uint32 CMSG_ENVELOPED_RECIPIENT_V4 = 4;
	public const uint32 CMSG_KEY_TRANS_PKCS_1_5_VERSION = 0;
	public const uint32 CMSG_KEY_TRANS_CMS_VERSION = 2;
	public const uint32 CMSG_KEY_AGREE_VERSION = 3;
	public const uint32 CMSG_MAIL_LIST_VERSION = 4;
	public const uint32 CMSG_CTRL_VERIFY_SIGNATURE = 1;
	public const uint32 CMSG_CTRL_DECRYPT = 2;
	public const uint32 CMSG_CTRL_VERIFY_HASH = 5;
	public const uint32 CMSG_CTRL_ADD_SIGNER = 6;
	public const uint32 CMSG_CTRL_DEL_SIGNER = 7;
	public const uint32 CMSG_CTRL_ADD_SIGNER_UNAUTH_ATTR = 8;
	public const uint32 CMSG_CTRL_DEL_SIGNER_UNAUTH_ATTR = 9;
	public const uint32 CMSG_CTRL_ADD_CERT = 10;
	public const uint32 CMSG_CTRL_DEL_CERT = 11;
	public const uint32 CMSG_CTRL_ADD_CRL = 12;
	public const uint32 CMSG_CTRL_DEL_CRL = 13;
	public const uint32 CMSG_CTRL_ADD_ATTR_CERT = 14;
	public const uint32 CMSG_CTRL_DEL_ATTR_CERT = 15;
	public const uint32 CMSG_CTRL_KEY_TRANS_DECRYPT = 16;
	public const uint32 CMSG_CTRL_KEY_AGREE_DECRYPT = 17;
	public const uint32 CMSG_CTRL_MAIL_LIST_DECRYPT = 18;
	public const uint32 CMSG_CTRL_VERIFY_SIGNATURE_EX = 19;
	public const uint32 CMSG_CTRL_ADD_CMS_SIGNER_INFO = 20;
	public const uint32 CMSG_CTRL_ENABLE_STRONG_SIGNATURE = 21;
	public const uint32 CMSG_VERIFY_SIGNER_PUBKEY = 1;
	public const uint32 CMSG_VERIFY_SIGNER_CERT = 2;
	public const uint32 CMSG_VERIFY_SIGNER_CHAIN = 3;
	public const uint32 CMSG_VERIFY_SIGNER_NULL = 4;
	public const uint32 CMSG_VERIFY_COUNTER_SIGN_ENABLE_STRONG_FLAG = 1;
	public const String CMSG_OID_GEN_ENCRYPT_KEY_FUNC = "CryptMsgDllGenEncryptKey";
	public const String CMSG_OID_EXPORT_ENCRYPT_KEY_FUNC = "CryptMsgDllExportEncryptKey";
	public const String CMSG_OID_IMPORT_ENCRYPT_KEY_FUNC = "CryptMsgDllImportEncryptKey";
	public const PSTR CMSG_DEFAULT_INSTALLABLE_FUNC_OID = (PSTR)(void*)1;
	public const uint32 CMSG_CONTENT_ENCRYPT_PAD_ENCODED_LEN_FLAG = 1;
	public const uint32 CMSG_CONTENT_ENCRYPT_FREE_PARA_FLAG = 1;
	public const uint32 CMSG_CONTENT_ENCRYPT_FREE_OBJID_FLAG = 2;
	public const uint32 CMSG_CONTENT_ENCRYPT_RELEASE_CONTEXT_FLAG = 32768;
	public const String CMSG_OID_GEN_CONTENT_ENCRYPT_KEY_FUNC = "CryptMsgDllGenContentEncryptKey";
	public const String CMSG_OID_CAPI1_GEN_CONTENT_ENCRYPT_KEY_FUNC = "CryptMsgDllGenContentEncryptKey";
	public const String CMSG_OID_CNG_GEN_CONTENT_ENCRYPT_KEY_FUNC = "CryptMsgDllCNGGenContentEncryptKey";
	public const uint32 CMSG_KEY_TRANS_ENCRYPT_FREE_PARA_FLAG = 1;
	public const uint32 CMSG_KEY_TRANS_ENCRYPT_FREE_OBJID_FLAG = 2;
	public const String CMSG_OID_EXPORT_KEY_TRANS_FUNC = "CryptMsgDllExportKeyTrans";
	public const String CMSG_OID_CAPI1_EXPORT_KEY_TRANS_FUNC = "CryptMsgDllExportKeyTrans";
	public const String CMSG_OID_CNG_EXPORT_KEY_TRANS_FUNC = "CryptMsgDllCNGExportKeyTrans";
	public const uint32 CMSG_KEY_AGREE_ENCRYPT_FREE_PARA_FLAG = 1;
	public const uint32 CMSG_KEY_AGREE_ENCRYPT_FREE_MATERIAL_FLAG = 2;
	public const uint32 CMSG_KEY_AGREE_ENCRYPT_FREE_PUBKEY_ALG_FLAG = 4;
	public const uint32 CMSG_KEY_AGREE_ENCRYPT_FREE_PUBKEY_PARA_FLAG = 8;
	public const uint32 CMSG_KEY_AGREE_ENCRYPT_FREE_PUBKEY_BITS_FLAG = 16;
	public const uint32 CMSG_KEY_AGREE_ENCRYPT_FREE_OBJID_FLAG = 32;
	public const String CMSG_OID_EXPORT_KEY_AGREE_FUNC = "CryptMsgDllExportKeyAgree";
	public const String CMSG_OID_CAPI1_EXPORT_KEY_AGREE_FUNC = "CryptMsgDllExportKeyAgree";
	public const String CMSG_OID_CNG_EXPORT_KEY_AGREE_FUNC = "CryptMsgDllCNGExportKeyAgree";
	public const uint32 CMSG_MAIL_LIST_ENCRYPT_FREE_PARA_FLAG = 1;
	public const uint32 CMSG_MAIL_LIST_ENCRYPT_FREE_OBJID_FLAG = 2;
	public const String CMSG_OID_EXPORT_MAIL_LIST_FUNC = "CryptMsgDllExportMailList";
	public const String CMSG_OID_CAPI1_EXPORT_MAIL_LIST_FUNC = "CryptMsgDllExportMailList";
	public const String CMSG_OID_IMPORT_KEY_TRANS_FUNC = "CryptMsgDllImportKeyTrans";
	public const String CMSG_OID_CAPI1_IMPORT_KEY_TRANS_FUNC = "CryptMsgDllImportKeyTrans";
	public const String CMSG_OID_IMPORT_KEY_AGREE_FUNC = "CryptMsgDllImportKeyAgree";
	public const String CMSG_OID_CAPI1_IMPORT_KEY_AGREE_FUNC = "CryptMsgDllImportKeyAgree";
	public const String CMSG_OID_IMPORT_MAIL_LIST_FUNC = "CryptMsgDllImportMailList";
	public const String CMSG_OID_CAPI1_IMPORT_MAIL_LIST_FUNC = "CryptMsgDllImportMailList";
	public const String CMSG_OID_CNG_IMPORT_KEY_TRANS_FUNC = "CryptMsgDllCNGImportKeyTrans";
	public const String CMSG_OID_CNG_IMPORT_KEY_AGREE_FUNC = "CryptMsgDllCNGImportKeyAgree";
	public const String CMSG_OID_CNG_IMPORT_CONTENT_ENCRYPT_KEY_FUNC = "CryptMsgDllCNGImportContentEncryptKey";
	public const uint32 CERT_KEY_PROV_HANDLE_PROP_ID = 1;
	public const uint32 CERT_KEY_PROV_INFO_PROP_ID = 2;
	public const uint32 CERT_SHA1_HASH_PROP_ID = 3;
	public const uint32 CERT_MD5_HASH_PROP_ID = 4;
	public const uint32 CERT_HASH_PROP_ID = 3;
	public const uint32 CERT_KEY_CONTEXT_PROP_ID = 5;
	public const uint32 CERT_KEY_SPEC_PROP_ID = 6;
	public const uint32 CERT_IE30_RESERVED_PROP_ID = 7;
	public const uint32 CERT_PUBKEY_HASH_RESERVED_PROP_ID = 8;
	public const uint32 CERT_ENHKEY_USAGE_PROP_ID = 9;
	public const uint32 CERT_CTL_USAGE_PROP_ID = 9;
	public const uint32 CERT_NEXT_UPDATE_LOCATION_PROP_ID = 10;
	public const uint32 CERT_FRIENDLY_NAME_PROP_ID = 11;
	public const uint32 CERT_PVK_FILE_PROP_ID = 12;
	public const uint32 CERT_DESCRIPTION_PROP_ID = 13;
	public const uint32 CERT_ACCESS_STATE_PROP_ID = 14;
	public const uint32 CERT_SIGNATURE_HASH_PROP_ID = 15;
	public const uint32 CERT_SMART_CARD_DATA_PROP_ID = 16;
	public const uint32 CERT_EFS_PROP_ID = 17;
	public const uint32 CERT_FORTEZZA_DATA_PROP_ID = 18;
	public const uint32 CERT_ARCHIVED_PROP_ID = 19;
	public const uint32 CERT_KEY_IDENTIFIER_PROP_ID = 20;
	public const uint32 CERT_AUTO_ENROLL_PROP_ID = 21;
	public const uint32 CERT_PUBKEY_ALG_PARA_PROP_ID = 22;
	public const uint32 CERT_CROSS_CERT_DIST_POINTS_PROP_ID = 23;
	public const uint32 CERT_ISSUER_PUBLIC_KEY_MD5_HASH_PROP_ID = 24;
	public const uint32 CERT_SUBJECT_PUBLIC_KEY_MD5_HASH_PROP_ID = 25;
	public const uint32 CERT_ENROLLMENT_PROP_ID = 26;
	public const uint32 CERT_DATE_STAMP_PROP_ID = 27;
	public const uint32 CERT_ISSUER_SERIAL_NUMBER_MD5_HASH_PROP_ID = 28;
	public const uint32 CERT_SUBJECT_NAME_MD5_HASH_PROP_ID = 29;
	public const uint32 CERT_EXTENDED_ERROR_INFO_PROP_ID = 30;
	public const uint32 CERT_RENEWAL_PROP_ID = 64;
	public const uint32 CERT_ARCHIVED_KEY_HASH_PROP_ID = 65;
	public const uint32 CERT_AUTO_ENROLL_RETRY_PROP_ID = 66;
	public const uint32 CERT_AIA_URL_RETRIEVED_PROP_ID = 67;
	public const uint32 CERT_AUTHORITY_INFO_ACCESS_PROP_ID = 68;
	public const uint32 CERT_BACKED_UP_PROP_ID = 69;
	public const uint32 CERT_OCSP_RESPONSE_PROP_ID = 70;
	public const uint32 CERT_REQUEST_ORIGINATOR_PROP_ID = 71;
	public const uint32 CERT_SOURCE_LOCATION_PROP_ID = 72;
	public const uint32 CERT_SOURCE_URL_PROP_ID = 73;
	public const uint32 CERT_NEW_KEY_PROP_ID = 74;
	public const uint32 CERT_OCSP_CACHE_PREFIX_PROP_ID = 75;
	public const uint32 CERT_SMART_CARD_ROOT_INFO_PROP_ID = 76;
	public const uint32 CERT_NO_AUTO_EXPIRE_CHECK_PROP_ID = 77;
	public const uint32 CERT_NCRYPT_KEY_HANDLE_PROP_ID = 78;
	public const uint32 CERT_HCRYPTPROV_OR_NCRYPT_KEY_HANDLE_PROP_ID = 79;
	public const uint32 CERT_SUBJECT_INFO_ACCESS_PROP_ID = 80;
	public const uint32 CERT_CA_OCSP_AUTHORITY_INFO_ACCESS_PROP_ID = 81;
	public const uint32 CERT_CA_DISABLE_CRL_PROP_ID = 82;
	public const uint32 CERT_ROOT_PROGRAM_CERT_POLICIES_PROP_ID = 83;
	public const uint32 CERT_ROOT_PROGRAM_NAME_CONSTRAINTS_PROP_ID = 84;
	public const uint32 CERT_SUBJECT_OCSP_AUTHORITY_INFO_ACCESS_PROP_ID = 85;
	public const uint32 CERT_SUBJECT_DISABLE_CRL_PROP_ID = 86;
	public const uint32 CERT_CEP_PROP_ID = 87;
	public const uint32 CERT_SIGN_HASH_CNG_ALG_PROP_ID = 89;
	public const uint32 CERT_SCARD_PIN_ID_PROP_ID = 90;
	public const uint32 CERT_SCARD_PIN_INFO_PROP_ID = 91;
	public const uint32 CERT_SUBJECT_PUB_KEY_BIT_LENGTH_PROP_ID = 92;
	public const uint32 CERT_PUB_KEY_CNG_ALG_BIT_LENGTH_PROP_ID = 93;
	public const uint32 CERT_ISSUER_PUB_KEY_BIT_LENGTH_PROP_ID = 94;
	public const uint32 CERT_ISSUER_CHAIN_SIGN_HASH_CNG_ALG_PROP_ID = 95;
	public const uint32 CERT_ISSUER_CHAIN_PUB_KEY_CNG_ALG_BIT_LENGTH_PROP_ID = 96;
	public const uint32 CERT_NO_EXPIRE_NOTIFICATION_PROP_ID = 97;
	public const uint32 CERT_AUTH_ROOT_SHA256_HASH_PROP_ID = 98;
	public const uint32 CERT_NCRYPT_KEY_HANDLE_TRANSFER_PROP_ID = 99;
	public const uint32 CERT_HCRYPTPROV_TRANSFER_PROP_ID = 100;
	public const uint32 CERT_SMART_CARD_READER_PROP_ID = 101;
	public const uint32 CERT_SEND_AS_TRUSTED_ISSUER_PROP_ID = 102;
	public const uint32 CERT_KEY_REPAIR_ATTEMPTED_PROP_ID = 103;
	public const uint32 CERT_DISALLOWED_FILETIME_PROP_ID = 104;
	public const uint32 CERT_ROOT_PROGRAM_CHAIN_POLICIES_PROP_ID = 105;
	public const uint32 CERT_SMART_CARD_READER_NON_REMOVABLE_PROP_ID = 106;
	public const uint32 CERT_SHA256_HASH_PROP_ID = 107;
	public const uint32 CERT_SCEP_SERVER_CERTS_PROP_ID = 108;
	public const uint32 CERT_SCEP_RA_SIGNATURE_CERT_PROP_ID = 109;
	public const uint32 CERT_SCEP_RA_ENCRYPTION_CERT_PROP_ID = 110;
	public const uint32 CERT_SCEP_CA_CERT_PROP_ID = 111;
	public const uint32 CERT_SCEP_SIGNER_CERT_PROP_ID = 112;
	public const uint32 CERT_SCEP_NONCE_PROP_ID = 113;
	public const uint32 CERT_SCEP_ENCRYPT_HASH_CNG_ALG_PROP_ID = 114;
	public const uint32 CERT_SCEP_FLAGS_PROP_ID = 115;
	public const uint32 CERT_SCEP_GUID_PROP_ID = 116;
	public const uint32 CERT_SERIALIZABLE_KEY_CONTEXT_PROP_ID = 117;
	public const uint32 CERT_ISOLATED_KEY_PROP_ID = 118;
	public const uint32 CERT_SERIAL_CHAIN_PROP_ID = 119;
	public const uint32 CERT_KEY_CLASSIFICATION_PROP_ID = 120;
	public const uint32 CERT_OCSP_MUST_STAPLE_PROP_ID = 121;
	public const uint32 CERT_DISALLOWED_ENHKEY_USAGE_PROP_ID = 122;
	public const uint32 CERT_NONCOMPLIANT_ROOT_URL_PROP_ID = 123;
	public const uint32 CERT_PIN_SHA256_HASH_PROP_ID = 124;
	public const uint32 CERT_CLR_DELETE_KEY_PROP_ID = 125;
	public const uint32 CERT_NOT_BEFORE_FILETIME_PROP_ID = 126;
	public const uint32 CERT_NOT_BEFORE_ENHKEY_USAGE_PROP_ID = 127;
	public const uint32 CERT_FIRST_RESERVED_PROP_ID = 128;
	public const uint32 CERT_LAST_RESERVED_PROP_ID = 32767;
	public const uint32 CERT_FIRST_USER_PROP_ID = 32768;
	public const uint32 CERT_LAST_USER_PROP_ID = 65535;
	public const String szOID_CERT_PROP_ID_PREFIX = "1.3.6.1.4.1.311.10.11.";
	public const String szOID_CERT_KEY_IDENTIFIER_PROP_ID = "1.3.6.1.4.1.311.10.11.20";
	public const String szOID_CERT_ISSUER_SERIAL_NUMBER_MD5_HASH_PROP_ID = "1.3.6.1.4.1.311.10.11.28";
	public const String szOID_CERT_SUBJECT_NAME_MD5_HASH_PROP_ID = "1.3.6.1.4.1.311.10.11.29";
	public const String szOID_CERT_MD5_HASH_PROP_ID = "1.3.6.1.4.1.311.10.11.4";
	public const String szOID_CERT_SIGNATURE_HASH_PROP_ID = "1.3.6.1.4.1.311.10.11.15";
	public const String szOID_DISALLOWED_HASH = "1.3.6.1.4.1.311.10.11.15";
	public const String szOID_CERT_DISALLOWED_FILETIME_PROP_ID = "1.3.6.1.4.1.311.10.11.104";
	public const uint32 CERT_ACCESS_STATE_WRITE_PERSIST_FLAG = 1;
	public const uint32 CERT_ACCESS_STATE_SYSTEM_STORE_FLAG = 2;
	public const uint32 CERT_ACCESS_STATE_LM_SYSTEM_STORE_FLAG = 4;
	public const uint32 CERT_ACCESS_STATE_GP_SYSTEM_STORE_FLAG = 8;
	public const uint32 CERT_ACCESS_STATE_SHARED_USER_FLAG = 16;
	public const String szOID_ROOT_PROGRAM_AUTO_UPDATE_CA_REVOCATION = "1.3.6.1.4.1.311.60.3.1";
	public const String szOID_ROOT_PROGRAM_AUTO_UPDATE_END_REVOCATION = "1.3.6.1.4.1.311.60.3.2";
	public const String szOID_ROOT_PROGRAM_NO_OCSP_FAILOVER_TO_CRL = "1.3.6.1.4.1.311.60.3.3";
	public const PSTR CERT_STORE_PROV_MSG = (PSTR)(void*)1;
	public const PSTR CERT_STORE_PROV_MEMORY = (PSTR)(void*)2;
	public const PSTR CERT_STORE_PROV_FILE = (PSTR)(void*)3;
	public const PSTR CERT_STORE_PROV_REG = (PSTR)(void*)4;
	public const PSTR CERT_STORE_PROV_PKCS7 = (PSTR)(void*)5;
	public const PSTR CERT_STORE_PROV_SERIALIZED = (PSTR)(void*)6;
	public const PSTR CERT_STORE_PROV_FILENAME_A = (PSTR)(void*)7;
	public const PSTR CERT_STORE_PROV_FILENAME_W = (PSTR)(void*)8;
	public const int32 CERT_STORE_PROV_FILENAME = 8;
	public const PSTR CERT_STORE_PROV_SYSTEM_A = (PSTR)(void*)9;
	public const PSTR CERT_STORE_PROV_SYSTEM_W = (PSTR)(void*)10;
	public const int32 CERT_STORE_PROV_SYSTEM = 10;
	public const PSTR CERT_STORE_PROV_COLLECTION = (PSTR)(void*)11;
	public const PSTR CERT_STORE_PROV_SYSTEM_REGISTRY_A = (PSTR)(void*)12;
	public const PSTR CERT_STORE_PROV_SYSTEM_REGISTRY_W = (PSTR)(void*)13;
	public const int32 CERT_STORE_PROV_SYSTEM_REGISTRY = 13;
	public const PSTR CERT_STORE_PROV_PHYSICAL_W = (PSTR)(void*)14;
	public const int32 CERT_STORE_PROV_PHYSICAL = 14;
	public const PSTR CERT_STORE_PROV_SMART_CARD_W = (PSTR)(void*)15;
	public const int32 CERT_STORE_PROV_SMART_CARD = 15;
	public const PSTR CERT_STORE_PROV_LDAP_W = (PSTR)(void*)16;
	public const int32 CERT_STORE_PROV_LDAP = 16;
	public const PSTR CERT_STORE_PROV_PKCS12 = (PSTR)(void*)17;
	public const String sz_CERT_STORE_PROV_MEMORY = "Memory";
	public const String sz_CERT_STORE_PROV_FILENAME_W = "File";
	public const String sz_CERT_STORE_PROV_FILENAME = "File";
	public const String sz_CERT_STORE_PROV_SYSTEM_W = "System";
	public const String sz_CERT_STORE_PROV_SYSTEM = "System";
	public const String sz_CERT_STORE_PROV_PKCS7 = "PKCS7";
	public const String sz_CERT_STORE_PROV_PKCS12 = "PKCS12";
	public const String sz_CERT_STORE_PROV_SERIALIZED = "Serialized";
	public const String sz_CERT_STORE_PROV_COLLECTION = "Collection";
	public const String sz_CERT_STORE_PROV_SYSTEM_REGISTRY_W = "SystemRegistry";
	public const String sz_CERT_STORE_PROV_SYSTEM_REGISTRY = "SystemRegistry";
	public const String sz_CERT_STORE_PROV_PHYSICAL_W = "Physical";
	public const String sz_CERT_STORE_PROV_PHYSICAL = "Physical";
	public const String sz_CERT_STORE_PROV_SMART_CARD_W = "SmartCard";
	public const String sz_CERT_STORE_PROV_SMART_CARD = "SmartCard";
	public const String sz_CERT_STORE_PROV_LDAP_W = "Ldap";
	public const String sz_CERT_STORE_PROV_LDAP = "Ldap";
	public const uint32 CERT_STORE_SIGNATURE_FLAG = 1;
	public const uint32 CERT_STORE_TIME_VALIDITY_FLAG = 2;
	public const uint32 CERT_STORE_REVOCATION_FLAG = 4;
	public const uint32 CERT_STORE_NO_CRL_FLAG = 65536;
	public const uint32 CERT_STORE_NO_ISSUER_FLAG = 131072;
	public const uint32 CERT_STORE_BASE_CRL_FLAG = 256;
	public const uint32 CERT_STORE_DELTA_CRL_FLAG = 512;
	public const uint32 CERT_STORE_UNSAFE_PHYSICAL_FLAG = 32;
	public const uint32 CERT_STORE_SHARE_STORE_FLAG = 64;
	public const uint32 CERT_STORE_MANIFOLD_FLAG = 256;
	public const uint32 CERT_SYSTEM_STORE_MASK = 4294901760;
	public const uint32 CERT_SYSTEM_STORE_UNPROTECTED_FLAG = 1073741824;
	public const uint32 CERT_SYSTEM_STORE_DEFER_READ_FLAG = 536870912;
	public const uint32 CERT_SYSTEM_STORE_LOCATION_SHIFT = 16;
	public const uint32 CERT_SYSTEM_STORE_CURRENT_USER_ID = 1;
	public const uint32 CERT_SYSTEM_STORE_LOCAL_MACHINE_ID = 2;
	public const uint32 CERT_SYSTEM_STORE_CURRENT_SERVICE_ID = 4;
	public const uint32 CERT_SYSTEM_STORE_SERVICES_ID = 5;
	public const uint32 CERT_SYSTEM_STORE_USERS_ID = 6;
	public const uint32 CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY_ID = 7;
	public const uint32 CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY_ID = 8;
	public const uint32 CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE_ID = 9;
	public const uint32 CERT_SYSTEM_STORE_LOCAL_MACHINE_WCOS_ID = 10;
	public const String CERT_GROUP_POLICY_SYSTEM_STORE_REGPATH = "Software\\Policies\\Microsoft\\SystemCertificates";
	public const String CERT_EFSBLOB_VALUE_NAME = "EFSBlob";
	public const String CERT_PROT_ROOT_FLAGS_VALUE_NAME = "Flags";
	public const uint32 CERT_PROT_ROOT_DISABLE_CURRENT_USER_FLAG = 1;
	public const uint32 CERT_PROT_ROOT_INHIBIT_ADD_AT_INIT_FLAG = 2;
	public const uint32 CERT_PROT_ROOT_INHIBIT_PURGE_LM_FLAG = 4;
	public const uint32 CERT_PROT_ROOT_DISABLE_LM_AUTH_FLAG = 8;
	public const uint32 CERT_PROT_ROOT_ONLY_LM_GPT_FLAG = 8;
	public const uint32 CERT_PROT_ROOT_DISABLE_NT_AUTH_REQUIRED_FLAG = 16;
	public const uint32 CERT_PROT_ROOT_DISABLE_NOT_DEFINED_NAME_CONSTRAINT_FLAG = 32;
	public const uint32 CERT_PROT_ROOT_DISABLE_PEER_TRUST = 65536;
	public const String CERT_PROT_ROOT_PEER_USAGES_VALUE_NAME = "PeerUsages";
	public const String CERT_PROT_ROOT_PEER_USAGES_VALUE_NAME_A = "PeerUsages";
	public const String CERT_LOCAL_MACHINE_SYSTEM_STORE_REGPATH = "Software\\Microsoft\\SystemCertificates";
	public const String CERT_TRUST_PUB_AUTHENTICODE_FLAGS_VALUE_NAME = "AuthenticodeFlags";
	public const uint32 CERT_TRUST_PUB_ALLOW_TRUST_MASK = 3;
	public const uint32 CERT_TRUST_PUB_ALLOW_END_USER_TRUST = 0;
	public const uint32 CERT_TRUST_PUB_ALLOW_MACHINE_ADMIN_TRUST = 1;
	public const uint32 CERT_TRUST_PUB_ALLOW_ENTERPRISE_ADMIN_TRUST = 2;
	public const uint32 CERT_TRUST_PUB_CHECK_PUBLISHER_REV_FLAG = 256;
	public const uint32 CERT_TRUST_PUB_CHECK_TIMESTAMP_REV_FLAG = 512;
	public const String CERT_OCM_SUBCOMPONENTS_LOCAL_MACHINE_REGPATH = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\OC Manager\\Subcomponents";
	public const String CERT_OCM_SUBCOMPONENTS_ROOT_AUTO_UPDATE_VALUE_NAME = "RootAutoUpdate";
	public const String CERT_DISABLE_ROOT_AUTO_UPDATE_VALUE_NAME = "DisableRootAutoUpdate";
	public const String CERT_ENABLE_DISALLOWED_CERT_AUTO_UPDATE_VALUE_NAME = "EnableDisallowedCertAutoUpdate";
	public const String CERT_DISABLE_PIN_RULES_AUTO_UPDATE_VALUE_NAME = "DisablePinRulesAutoUpdate";
	public const String CERT_AUTO_UPDATE_ROOT_DIR_URL_VALUE_NAME = "RootDirUrl";
	public const String CERT_AUTO_UPDATE_SYNC_FROM_DIR_URL_VALUE_NAME = "SyncFromDirUrl";
	public const String CERT_AUTH_ROOT_AUTO_UPDATE_ROOT_DIR_URL_VALUE_NAME = "RootDirUrl";
	public const String CERT_AUTH_ROOT_AUTO_UPDATE_SYNC_DELTA_TIME_VALUE_NAME = "SyncDeltaTime";
	public const String CERT_AUTH_ROOT_AUTO_UPDATE_FLAGS_VALUE_NAME = "Flags";
	public const uint32 CERT_AUTH_ROOT_AUTO_UPDATE_DISABLE_UNTRUSTED_ROOT_LOGGING_FLAG = 1;
	public const uint32 CERT_AUTH_ROOT_AUTO_UPDATE_DISABLE_PARTIAL_CHAIN_LOGGING_FLAG = 2;
	public const uint32 CERT_AUTO_UPDATE_DISABLE_RANDOM_QUERY_STRING_FLAG = 4;
	public const String CERT_AUTH_ROOT_AUTO_UPDATE_LAST_SYNC_TIME_VALUE_NAME = "LastSyncTime";
	public const String CERT_AUTH_ROOT_AUTO_UPDATE_ENCODED_CTL_VALUE_NAME = "EncodedCtl";
	public const String CERT_AUTH_ROOT_CTL_FILENAME = "authroot.stl";
	public const String CERT_AUTH_ROOT_CTL_FILENAME_A = "authroot.stl";
	public const String CERT_AUTH_ROOT_CAB_FILENAME = "authrootstl.cab";
	public const String CERT_AUTH_ROOT_SEQ_FILENAME = "authrootseq.txt";
	public const String CERT_AUTH_ROOT_CERT_EXT = ".crt";
	public const String CERT_DISALLOWED_CERT_AUTO_UPDATE_SYNC_DELTA_TIME_VALUE_NAME = "DisallowedCertSyncDeltaTime";
	public const String CERT_DISALLOWED_CERT_AUTO_UPDATE_LAST_SYNC_TIME_VALUE_NAME = "DisallowedCertLastSyncTime";
	public const String CERT_DISALLOWED_CERT_AUTO_UPDATE_ENCODED_CTL_VALUE_NAME = "DisallowedCertEncodedCtl";
	public const String CERT_DISALLOWED_CERT_CTL_FILENAME = "disallowedcert.stl";
	public const String CERT_DISALLOWED_CERT_CTL_FILENAME_A = "disallowedcert.stl";
	public const String CERT_DISALLOWED_CERT_CAB_FILENAME = "disallowedcertstl.cab";
	public const String CERT_DISALLOWED_CERT_AUTO_UPDATE_LIST_IDENTIFIER = "DisallowedCert_AutoUpdate_1";
	public const String CERT_PIN_RULES_AUTO_UPDATE_SYNC_DELTA_TIME_VALUE_NAME = "PinRulesSyncDeltaTime";
	public const String CERT_PIN_RULES_AUTO_UPDATE_LAST_SYNC_TIME_VALUE_NAME = "PinRulesLastSyncTime";
	public const String CERT_PIN_RULES_AUTO_UPDATE_ENCODED_CTL_VALUE_NAME = "PinRulesEncodedCtl";
	public const String CERT_PIN_RULES_CTL_FILENAME = "pinrules.stl";
	public const String CERT_PIN_RULES_CTL_FILENAME_A = "pinrules.stl";
	public const String CERT_PIN_RULES_CAB_FILENAME = "pinrulesstl.cab";
	public const String CERT_PIN_RULES_AUTO_UPDATE_LIST_IDENTIFIER = "PinRules_AutoUpdate_1";
	public const uint32 CERT_REGISTRY_STORE_REMOTE_FLAG = 65536;
	public const uint32 CERT_REGISTRY_STORE_SERIALIZED_FLAG = 131072;
	public const uint32 CERT_REGISTRY_STORE_CLIENT_GPT_FLAG = 2147483648;
	public const uint32 CERT_REGISTRY_STORE_LM_GPT_FLAG = 16777216;
	public const uint32 CERT_REGISTRY_STORE_ROAMING_FLAG = 262144;
	public const uint32 CERT_REGISTRY_STORE_MY_IE_DIRTY_FLAG = 524288;
	public const uint32 CERT_REGISTRY_STORE_EXTERNAL_FLAG = 1048576;
	public const String CERT_IE_DIRTY_FLAGS_REGPATH = "Software\\Microsoft\\Cryptography\\IEDirtyFlags";
	public const uint32 CERT_FILE_STORE_COMMIT_ENABLE_FLAG = 65536;
	public const uint32 CERT_LDAP_STORE_SIGN_FLAG = 65536;
	public const uint32 CERT_LDAP_STORE_AREC_EXCLUSIVE_FLAG = 131072;
	public const uint32 CERT_LDAP_STORE_OPENED_FLAG = 262144;
	public const uint32 CERT_LDAP_STORE_UNBIND_FLAG = 524288;
	public const String CRYPT_OID_OPEN_STORE_PROV_FUNC = "CertDllOpenStoreProv";
	public const uint32 CERT_STORE_PROV_GP_SYSTEM_STORE_FLAG = 32;
	public const uint32 CERT_STORE_PROV_SHARED_USER_FLAG = 64;
	public const uint32 CERT_STORE_PROV_CLOSE_FUNC = 0;
	public const uint32 CERT_STORE_PROV_READ_CERT_FUNC = 1;
	public const uint32 CERT_STORE_PROV_WRITE_CERT_FUNC = 2;
	public const uint32 CERT_STORE_PROV_DELETE_CERT_FUNC = 3;
	public const uint32 CERT_STORE_PROV_SET_CERT_PROPERTY_FUNC = 4;
	public const uint32 CERT_STORE_PROV_READ_CRL_FUNC = 5;
	public const uint32 CERT_STORE_PROV_WRITE_CRL_FUNC = 6;
	public const uint32 CERT_STORE_PROV_DELETE_CRL_FUNC = 7;
	public const uint32 CERT_STORE_PROV_SET_CRL_PROPERTY_FUNC = 8;
	public const uint32 CERT_STORE_PROV_READ_CTL_FUNC = 9;
	public const uint32 CERT_STORE_PROV_WRITE_CTL_FUNC = 10;
	public const uint32 CERT_STORE_PROV_DELETE_CTL_FUNC = 11;
	public const uint32 CERT_STORE_PROV_SET_CTL_PROPERTY_FUNC = 12;
	public const uint32 CERT_STORE_PROV_CONTROL_FUNC = 13;
	public const uint32 CERT_STORE_PROV_FIND_CERT_FUNC = 14;
	public const uint32 CERT_STORE_PROV_FREE_FIND_CERT_FUNC = 15;
	public const uint32 CERT_STORE_PROV_GET_CERT_PROPERTY_FUNC = 16;
	public const uint32 CERT_STORE_PROV_FIND_CRL_FUNC = 17;
	public const uint32 CERT_STORE_PROV_FREE_FIND_CRL_FUNC = 18;
	public const uint32 CERT_STORE_PROV_GET_CRL_PROPERTY_FUNC = 19;
	public const uint32 CERT_STORE_PROV_FIND_CTL_FUNC = 20;
	public const uint32 CERT_STORE_PROV_FREE_FIND_CTL_FUNC = 21;
	public const uint32 CERT_STORE_PROV_GET_CTL_PROPERTY_FUNC = 22;
	public const uint32 CERT_STORE_PROV_WRITE_ADD_FLAG = 1;
	public const uint32 CERT_STORE_SAVE_AS_PKCS12 = 3;
	public const uint32 CERT_CLOSE_STORE_FORCE_FLAG = 1;
	public const uint32 CERT_CLOSE_STORE_CHECK_FLAG = 2;
	public const uint32 CERT_COMPARE_MASK = 65535;
	public const uint32 CERT_COMPARE_ANY = 0;
	public const uint32 CERT_COMPARE_SHA1_HASH = 1;
	public const uint32 CERT_COMPARE_NAME = 2;
	public const uint32 CERT_COMPARE_ATTR = 3;
	public const uint32 CERT_COMPARE_MD5_HASH = 4;
	public const uint32 CERT_COMPARE_PROPERTY = 5;
	public const uint32 CERT_COMPARE_PUBLIC_KEY = 6;
	public const uint32 CERT_COMPARE_HASH = 1;
	public const uint32 CERT_COMPARE_NAME_STR_A = 7;
	public const uint32 CERT_COMPARE_NAME_STR_W = 8;
	public const uint32 CERT_COMPARE_KEY_SPEC = 9;
	public const uint32 CERT_COMPARE_ENHKEY_USAGE = 10;
	public const uint32 CERT_COMPARE_CTL_USAGE = 10;
	public const uint32 CERT_COMPARE_SUBJECT_CERT = 11;
	public const uint32 CERT_COMPARE_ISSUER_OF = 12;
	public const uint32 CERT_COMPARE_EXISTING = 13;
	public const uint32 CERT_COMPARE_SIGNATURE_HASH = 14;
	public const uint32 CERT_COMPARE_KEY_IDENTIFIER = 15;
	public const uint32 CERT_COMPARE_CERT_ID = 16;
	public const uint32 CERT_COMPARE_CROSS_CERT_DIST_POINTS = 17;
	public const uint32 CERT_COMPARE_PUBKEY_MD5_HASH = 18;
	public const uint32 CERT_COMPARE_SUBJECT_INFO_ACCESS = 19;
	public const uint32 CERT_COMPARE_HASH_STR = 20;
	public const uint32 CERT_COMPARE_HAS_PRIVATE_KEY = 21;
	public const uint32 CERT_SET_PROPERTY_IGNORE_PERSIST_ERROR_FLAG = 2147483648;
	public const uint32 CERT_SET_PROPERTY_INHIBIT_PERSIST_FLAG = 1073741824;
	public const uint32 CTL_ENTRY_FROM_PROP_CHAIN_FLAG = 1;
	public const uint32 CRL_FIND_ANY = 0;
	public const uint32 CRL_FIND_ISSUED_BY = 1;
	public const uint32 CRL_FIND_EXISTING = 2;
	public const uint32 CRL_FIND_ISSUED_FOR = 3;
	public const uint32 CRL_FIND_ISSUED_BY_AKI_FLAG = 1;
	public const uint32 CRL_FIND_ISSUED_BY_SIGNATURE_FLAG = 2;
	public const uint32 CRL_FIND_ISSUED_BY_DELTA_FLAG = 4;
	public const uint32 CRL_FIND_ISSUED_BY_BASE_FLAG = 8;
	public const uint32 CRL_FIND_ISSUED_FOR_SET_STRONG_PROPERTIES_FLAG = 16;
	public const uint32 CERT_STORE_ADD_NEW = 1;
	public const uint32 CERT_STORE_ADD_USE_EXISTING = 2;
	public const uint32 CERT_STORE_ADD_REPLACE_EXISTING = 3;
	public const uint32 CERT_STORE_ADD_ALWAYS = 4;
	public const uint32 CERT_STORE_ADD_REPLACE_EXISTING_INHERIT_PROPERTIES = 5;
	public const uint32 CERT_STORE_ADD_NEWER = 6;
	public const uint32 CERT_STORE_ADD_NEWER_INHERIT_PROPERTIES = 7;
	public const uint32 CERT_STORE_CERTIFICATE_CONTEXT = 1;
	public const uint32 CERT_STORE_CRL_CONTEXT = 2;
	public const uint32 CERT_STORE_CTL_CONTEXT = 3;
	public const uint32 CTL_ANY_SUBJECT_TYPE = 1;
	public const uint32 CTL_CERT_SUBJECT_TYPE = 2;
	public const uint32 CTL_FIND_NO_LIST_ID_CBDATA = 4294967295;
	public const uint32 CERT_STORE_CTRL_RESYNC = 1;
	public const uint32 CERT_STORE_CTRL_NOTIFY_CHANGE = 2;
	public const uint32 CERT_STORE_CTRL_COMMIT = 3;
	public const uint32 CERT_STORE_CTRL_AUTO_RESYNC = 4;
	public const uint32 CERT_STORE_CTRL_CANCEL_NOTIFY = 5;
	public const uint32 CERT_STORE_LOCALIZED_NAME_PROP_ID = 4096;
	public const uint32 CERT_CREATE_CONTEXT_NOCOPY_FLAG = 1;
	public const uint32 CERT_CREATE_CONTEXT_SORTED_FLAG = 2;
	public const uint32 CERT_CREATE_CONTEXT_NO_HCRYPTMSG_FLAG = 4;
	public const uint32 CERT_CREATE_CONTEXT_NO_ENTRY_FLAG = 8;
	public const uint32 CERT_PHYSICAL_STORE_ADD_ENABLE_FLAG = 1;
	public const uint32 CERT_PHYSICAL_STORE_OPEN_DISABLE_FLAG = 2;
	public const uint32 CERT_PHYSICAL_STORE_REMOTE_OPEN_DISABLE_FLAG = 4;
	public const uint32 CERT_PHYSICAL_STORE_INSERT_COMPUTER_NAME_ENABLE_FLAG = 8;
	public const uint32 CERT_PHYSICAL_STORE_PREDEFINED_ENUM_FLAG = 1;
	public const String CERT_PHYSICAL_STORE_DEFAULT_NAME = ".Default";
	public const String CERT_PHYSICAL_STORE_GROUP_POLICY_NAME = ".GroupPolicy";
	public const String CERT_PHYSICAL_STORE_LOCAL_MACHINE_NAME = ".LocalMachine";
	public const String CERT_PHYSICAL_STORE_DS_USER_CERTIFICATE_NAME = ".UserCertificate";
	public const String CERT_PHYSICAL_STORE_LOCAL_MACHINE_GROUP_POLICY_NAME = ".LocalMachineGroupPolicy";
	public const String CERT_PHYSICAL_STORE_ENTERPRISE_NAME = ".Enterprise";
	public const String CERT_PHYSICAL_STORE_AUTH_ROOT_NAME = ".AuthRoot";
	public const String CERT_PHYSICAL_STORE_SMART_CARD_NAME = ".SmartCard";
	public const String CRYPT_OID_OPEN_SYSTEM_STORE_PROV_FUNC = "CertDllOpenSystemStoreProv";
	public const String CRYPT_OID_REGISTER_SYSTEM_STORE_FUNC = "CertDllRegisterSystemStore";
	public const String CRYPT_OID_UNREGISTER_SYSTEM_STORE_FUNC = "CertDllUnregisterSystemStore";
	public const String CRYPT_OID_ENUM_SYSTEM_STORE_FUNC = "CertDllEnumSystemStore";
	public const String CRYPT_OID_REGISTER_PHYSICAL_STORE_FUNC = "CertDllRegisterPhysicalStore";
	public const String CRYPT_OID_UNREGISTER_PHYSICAL_STORE_FUNC = "CertDllUnregisterPhysicalStore";
	public const String CRYPT_OID_ENUM_PHYSICAL_STORE_FUNC = "CertDllEnumPhysicalStore";
	public const String CRYPT_OID_SYSTEM_STORE_LOCATION_VALUE_NAME = "SystemStoreLocation";
	public const uint32 CMSG_TRUSTED_SIGNER_FLAG = 1;
	public const uint32 CMSG_SIGNER_ONLY_FLAG = 2;
	public const uint32 CMSG_USE_SIGNER_INDEX_FLAG = 4;
	public const uint32 CMSG_CMS_ENCAPSULATED_CTL_FLAG = 32768;
	public const uint32 CMSG_ENCODE_SORTED_CTL_FLAG = 1;
	public const uint32 CMSG_ENCODE_HASHED_SUBJECT_IDENTIFIER_FLAG = 2;
	public const uint32 CERT_VERIFY_INHIBIT_CTL_UPDATE_FLAG = 1;
	public const uint32 CERT_VERIFY_TRUSTED_SIGNERS_FLAG = 2;
	public const uint32 CERT_VERIFY_NO_TIME_CHECK_FLAG = 4;
	public const uint32 CERT_VERIFY_ALLOW_MORE_USAGE_FLAG = 8;
	public const uint32 CERT_VERIFY_UPDATED_CTL_FLAG = 1;
	public const uint32 CERT_CONTEXT_REVOCATION_TYPE = 1;
	public const uint32 CERT_VERIFY_REV_CHAIN_FLAG = 1;
	public const uint32 CERT_VERIFY_CACHE_ONLY_BASED_REVOCATION = 2;
	public const uint32 CERT_VERIFY_REV_ACCUMULATIVE_TIMEOUT_FLAG = 4;
	public const uint32 CERT_VERIFY_REV_SERVER_OCSP_FLAG = 8;
	public const uint32 CERT_VERIFY_REV_NO_OCSP_FAILOVER_TO_CRL_FLAG = 16;
	public const uint32 CERT_VERIFY_REV_SERVER_OCSP_WIRE_ONLY_FLAG = 32;
	public const uint32 CERT_UNICODE_IS_RDN_ATTRS_FLAG = 1;
	public const uint32 CERT_CASE_INSENSITIVE_IS_RDN_ATTRS_FLAG = 2;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_SUBJECT_BLOB = 1;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_SUBJECT_CERT = 2;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_SUBJECT_CRL = 3;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_SUBJECT_OCSP_BASIC_SIGNED_RESPONSE = 4;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_ISSUER_PUBKEY = 1;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_ISSUER_CERT = 2;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_ISSUER_CHAIN = 3;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_ISSUER_NULL = 4;
	public const uint32 CRYPT_VERIFY_CERT_SIGN_CHECK_WEAK_HASH_FLAG = 8;
	public const String CRYPT_OID_EXTRACT_ENCODED_SIGNATURE_PARAMETERS_FUNC = "CryptDllExtractEncodedSignatureParameters";
	public const String CRYPT_OID_SIGN_AND_ENCODE_HASH_FUNC = "CryptDllSignAndEncodeHash";
	public const String CRYPT_OID_VERIFY_ENCODED_SIGNATURE_FUNC = "CryptDllVerifyEncodedSignature";
	public const String CRYPT_OID_EXPORT_PUBLIC_KEY_INFO_FUNC = "CryptDllExportPublicKeyInfoEx";
	public const String CRYPT_OID_EXPORT_PUBLIC_KEY_INFO_EX2_FUNC = "CryptDllExportPublicKeyInfoEx2";
	public const String CRYPT_OID_EXPORT_PUBLIC_KEY_INFO_FROM_BCRYPT_HANDLE_FUNC = "CryptDllExportPublicKeyInfoFromBCryptKeyHandle";
	public const String CRYPT_OID_IMPORT_PUBLIC_KEY_INFO_FUNC = "CryptDllImportPublicKeyInfoEx";
	public const String CRYPT_OID_IMPORT_PUBLIC_KEY_INFO_EX2_FUNC = "CryptDllImportPublicKeyInfoEx2";
	public const uint32 CRYPT_ACQUIRE_WINDOW_HANDLE_FLAG = 128;
	public const uint32 CRYPT_ACQUIRE_NCRYPT_KEY_FLAGS_MASK = 458752;
	public const uint32 CRYPT_ACQUIRE_ALLOW_NCRYPT_KEY_FLAG = 65536;
	public const uint32 CRYPT_ACQUIRE_PREFER_NCRYPT_KEY_FLAG = 131072;
	public const uint32 CRYPT_ACQUIRE_ONLY_NCRYPT_KEY_FLAG = 262144;
	public const String CRYPT_OID_IMPORT_PRIVATE_KEY_INFO_FUNC = "CryptDllImportPrivateKeyInfoEx";
	public const String CRYPT_OID_EXPORT_PRIVATE_KEY_INFO_FUNC = "CryptDllExportPrivateKeyInfoEx";
	public const uint32 CRYPT_DELETE_KEYSET = 16;
	public const uint32 CERT_XML_NAME_STR = 4;
	public const uint32 CERT_NAME_STR_SEMICOLON_FLAG = 1073741824;
	public const uint32 CERT_NAME_STR_NO_PLUS_FLAG = 536870912;
	public const uint32 CERT_NAME_STR_NO_QUOTING_FLAG = 268435456;
	public const uint32 CERT_NAME_STR_CRLF_FLAG = 134217728;
	public const uint32 CERT_NAME_STR_COMMA_FLAG = 67108864;
	public const uint32 CERT_NAME_STR_REVERSE_FLAG = 33554432;
	public const uint32 CERT_NAME_STR_FORWARD_FLAG = 16777216;
	public const uint32 CERT_NAME_STR_DISABLE_IE4_UTF8_FLAG = 65536;
	public const uint32 CERT_NAME_STR_ENABLE_T61_UNICODE_FLAG = 131072;
	public const uint32 CERT_NAME_STR_ENABLE_UTF8_UNICODE_FLAG = 262144;
	public const uint32 CERT_NAME_STR_FORCE_UTF8_DIR_STR_FLAG = 524288;
	public const uint32 CERT_NAME_STR_DISABLE_UTF8_DIR_STR_FLAG = 1048576;
	public const uint32 CERT_NAME_STR_ENABLE_PUNYCODE_FLAG = 2097152;
	public const uint32 CERT_NAME_EMAIL_TYPE = 1;
	public const uint32 CERT_NAME_RDN_TYPE = 2;
	public const uint32 CERT_NAME_ATTR_TYPE = 3;
	public const uint32 CERT_NAME_SIMPLE_DISPLAY_TYPE = 4;
	public const uint32 CERT_NAME_FRIENDLY_DISPLAY_TYPE = 5;
	public const uint32 CERT_NAME_DNS_TYPE = 6;
	public const uint32 CERT_NAME_URL_TYPE = 7;
	public const uint32 CERT_NAME_UPN_TYPE = 8;
	public const uint32 CERT_NAME_ISSUER_FLAG = 1;
	public const uint32 CERT_NAME_DISABLE_IE4_UTF8_FLAG = 65536;
	public const uint32 CERT_NAME_SEARCH_ALL_NAMES_FLAG = 2;
	public const uint32 CRYPT_MESSAGE_BARE_CONTENT_OUT_FLAG = 1;
	public const uint32 CRYPT_MESSAGE_ENCAPSULATED_CONTENT_OUT_FLAG = 2;
	public const uint32 CRYPT_MESSAGE_KEYID_SIGNER_FLAG = 4;
	public const uint32 CRYPT_MESSAGE_SILENT_KEYSET_FLAG = 64;
	public const uint32 CRYPT_MESSAGE_KEYID_RECIPIENT_FLAG = 4;
	public const PSTR CREDENTIAL_OID_PASSWORD_CREDENTIALS_A = (PSTR)(void*)1;
	public const PSTR CREDENTIAL_OID_PASSWORD_CREDENTIALS_W = (PSTR)(void*)2;
	public const int32 CREDENTIAL_OID_PASSWORD_CREDENTIALS = 2;
	public const String SCHEME_OID_RETRIEVE_ENCODED_OBJECT_FUNC = "SchemeDllRetrieveEncodedObject";
	public const String SCHEME_OID_RETRIEVE_ENCODED_OBJECTW_FUNC = "SchemeDllRetrieveEncodedObjectW";
	public const String CONTEXT_OID_CREATE_OBJECT_CONTEXT_FUNC = "ContextDllCreateObjectContext";
	public const PSTR CONTEXT_OID_CERTIFICATE = (PSTR)(void*)1;
	public const PSTR CONTEXT_OID_CRL = (PSTR)(void*)2;
	public const PSTR CONTEXT_OID_CTL = (PSTR)(void*)3;
	public const PSTR CONTEXT_OID_PKCS7 = (PSTR)(void*)4;
	public const PSTR CONTEXT_OID_CAPI2_ANY = (PSTR)(void*)5;
	public const PSTR CONTEXT_OID_OCSP_RESP = (PSTR)(void*)6;
	public const uint32 CRYPT_RETRIEVE_MULTIPLE_OBJECTS = 1;
	public const uint32 CRYPT_CACHE_ONLY_RETRIEVAL = 2;
	public const uint32 CRYPT_WIRE_ONLY_RETRIEVAL = 4;
	public const uint32 CRYPT_DONT_CACHE_RESULT = 8;
	public const uint32 CRYPT_ASYNC_RETRIEVAL = 16;
	public const uint32 CRYPT_STICKY_CACHE_RETRIEVAL = 4096;
	public const uint32 CRYPT_LDAP_SCOPE_BASE_ONLY_RETRIEVAL = 8192;
	public const uint32 CRYPT_OFFLINE_CHECK_RETRIEVAL = 16384;
	public const uint32 CRYPT_LDAP_INSERT_ENTRY_ATTRIBUTE = 32768;
	public const uint32 CRYPT_LDAP_SIGN_RETRIEVAL = 65536;
	public const uint32 CRYPT_NO_AUTH_RETRIEVAL = 131072;
	public const uint32 CRYPT_LDAP_AREC_EXCLUSIVE_RETRIEVAL = 262144;
	public const uint32 CRYPT_AIA_RETRIEVAL = 524288;
	public const uint32 CRYPT_HTTP_POST_RETRIEVAL = 1048576;
	public const uint32 CRYPT_PROXY_CACHE_RETRIEVAL = 2097152;
	public const uint32 CRYPT_NOT_MODIFIED_RETRIEVAL = 4194304;
	public const uint32 CRYPT_ENABLE_SSL_REVOCATION_RETRIEVAL = 8388608;
	public const uint32 CRYPT_RANDOM_QUERY_STRING_RETRIEVAL = 67108864;
	public const uint32 CRYPT_ENABLE_FILE_RETRIEVAL = 134217728;
	public const uint32 CRYPT_CREATE_NEW_FLUSH_ENTRY = 268435456;
	public const uint32 CRYPT_VERIFY_CONTEXT_SIGNATURE = 32;
	public const uint32 CRYPT_VERIFY_DATA_HASH = 64;
	public const uint32 CRYPT_KEEP_TIME_VALID = 128;
	public const uint32 CRYPT_DONT_VERIFY_SIGNATURE = 256;
	public const uint32 CRYPT_DONT_CHECK_TIME_VALIDITY = 512;
	public const uint32 CRYPT_CHECK_FRESHNESS_TIME_VALIDITY = 1024;
	public const uint32 CRYPT_ACCUMULATIVE_TIMEOUT = 2048;
	public const uint32 CRYPT_OCSP_ONLY_RETRIEVAL = 16777216;
	public const uint32 CRYPT_NO_OCSP_FAILOVER_TO_CRL_RETRIEVAL = 33554432;
	public const uint32 CRYPTNET_URL_CACHE_PRE_FETCH_NONE = 0;
	public const uint32 CRYPTNET_URL_CACHE_PRE_FETCH_BLOB = 1;
	public const uint32 CRYPTNET_URL_CACHE_PRE_FETCH_CRL = 2;
	public const uint32 CRYPTNET_URL_CACHE_PRE_FETCH_OCSP = 3;
	public const uint32 CRYPTNET_URL_CACHE_PRE_FETCH_AUTOROOT_CAB = 5;
	public const uint32 CRYPTNET_URL_CACHE_PRE_FETCH_DISALLOWED_CERT_CAB = 6;
	public const uint32 CRYPTNET_URL_CACHE_PRE_FETCH_PIN_RULES_CAB = 7;
	public const uint32 CRYPTNET_URL_CACHE_DEFAULT_FLUSH = 0;
	public const uint32 CRYPTNET_URL_CACHE_DISABLE_FLUSH = 4294967295;
	public const uint32 CRYPTNET_URL_CACHE_RESPONSE_NONE = 0;
	public const uint32 CRYPTNET_URL_CACHE_RESPONSE_HTTP = 1;
	public const uint32 CRYPTNET_URL_CACHE_RESPONSE_VALIDATED = 32768;
	public const uint32 CRYPT_RETRIEVE_MAX_ERROR_CONTENT_LENGTH = 4096;
	public const PSTR CRYPT_PARAM_ASYNC_RETRIEVAL_COMPLETION = (PSTR)(void*)1;
	public const PSTR CRYPT_PARAM_CANCEL_ASYNC_RETRIEVAL = (PSTR)(void*)2;
	public const String URL_OID_GET_OBJECT_URL_FUNC = "UrlDllGetObjectUrl";
	public const PSTR URL_OID_CERTIFICATE_ISSUER = (PSTR)(void*)1;
	public const PSTR URL_OID_CERTIFICATE_CRL_DIST_POINT = (PSTR)(void*)2;
	public const PSTR URL_OID_CTL_ISSUER = (PSTR)(void*)3;
	public const PSTR URL_OID_CTL_NEXT_UPDATE = (PSTR)(void*)4;
	public const PSTR URL_OID_CRL_ISSUER = (PSTR)(void*)5;
	public const PSTR URL_OID_CERTIFICATE_FRESHEST_CRL = (PSTR)(void*)6;
	public const PSTR URL_OID_CRL_FRESHEST_CRL = (PSTR)(void*)7;
	public const PSTR URL_OID_CROSS_CERT_DIST_POINT = (PSTR)(void*)8;
	public const PSTR URL_OID_CERTIFICATE_OCSP = (PSTR)(void*)9;
	public const PSTR URL_OID_CERTIFICATE_OCSP_AND_CRL_DIST_POINT = (PSTR)(void*)10;
	public const PSTR URL_OID_CERTIFICATE_CRL_DIST_POINT_AND_OCSP = (PSTR)(void*)11;
	public const PSTR URL_OID_CROSS_CERT_SUBJECT_INFO_ACCESS = (PSTR)(void*)12;
	public const PSTR URL_OID_CERTIFICATE_ONLY_OCSP = (PSTR)(void*)13;
	public const String TIME_VALID_OID_GET_OBJECT_FUNC = "TimeValidDllGetObject";
	public const PSTR TIME_VALID_OID_GET_CTL = (PSTR)(void*)1;
	public const PSTR TIME_VALID_OID_GET_CRL = (PSTR)(void*)2;
	public const PSTR TIME_VALID_OID_GET_CRL_FROM_CERT = (PSTR)(void*)3;
	public const PSTR TIME_VALID_OID_GET_FRESHEST_CRL_FROM_CERT = (PSTR)(void*)4;
	public const PSTR TIME_VALID_OID_GET_FRESHEST_CRL_FROM_CRL = (PSTR)(void*)5;
	public const String TIME_VALID_OID_FLUSH_OBJECT_FUNC = "TimeValidDllFlushObject";
	public const PSTR TIME_VALID_OID_FLUSH_CTL = (PSTR)(void*)1;
	public const PSTR TIME_VALID_OID_FLUSH_CRL = (PSTR)(void*)2;
	public const PSTR TIME_VALID_OID_FLUSH_CRL_FROM_CERT = (PSTR)(void*)3;
	public const PSTR TIME_VALID_OID_FLUSH_FRESHEST_CRL_FROM_CERT = (PSTR)(void*)4;
	public const PSTR TIME_VALID_OID_FLUSH_FRESHEST_CRL_FROM_CRL = (PSTR)(void*)5;
	public const uint32 CRYPT_KEYID_MACHINE_FLAG = 32;
	public const uint32 CRYPT_KEYID_ALLOC_FLAG = 32768;
	public const uint32 CRYPT_KEYID_DELETE_FLAG = 16;
	public const uint32 CRYPT_KEYID_SET_NEW_FLAG = 8192;
	public const String CERT_CHAIN_CONFIG_REGPATH = "Software\\Microsoft\\Cryptography\\OID\\EncodingType 0\\CertDllCreateCertificateChainEngine\\Config";
	public const String CERT_CHAIN_MAX_URL_RETRIEVAL_BYTE_COUNT_VALUE_NAME = "MaxUrlRetrievalByteCount";
	public const String CERT_CHAIN_CACHE_RESYNC_FILETIME_VALUE_NAME = "ChainCacheResyncFiletime";
	public const String CERT_CHAIN_DISABLE_MANDATORY_BASIC_CONSTRAINTS_VALUE_NAME = "DisableMandatoryBasicConstraints";
	public const String CERT_CHAIN_DISABLE_CA_NAME_CONSTRAINTS_VALUE_NAME = "DisableCANameConstraints";
	public const String CERT_CHAIN_DISABLE_UNSUPPORTED_CRITICAL_EXTENSIONS_VALUE_NAME = "DisableUnsupportedCriticalExtensions";
	public const String CERT_CHAIN_MAX_AIA_URL_COUNT_IN_CERT_VALUE_NAME = "MaxAIAUrlCountInCert";
	public const uint32 CERT_CHAIN_MAX_AIA_URL_COUNT_IN_CERT_DEFAULT = 5;
	public const String CERT_CHAIN_MAX_AIA_URL_RETRIEVAL_COUNT_PER_CHAIN_VALUE_NAME = "MaxAIAUrlRetrievalCountPerChain";
	public const uint32 CERT_CHAIN_MAX_AIA_URL_RETRIEVAL_COUNT_PER_CHAIN_DEFAULT = 3;
	public const String CERT_CHAIN_MAX_AIA_URL_RETRIEVAL_BYTE_COUNT_VALUE_NAME = "MaxAIAUrlRetrievalByteCount";
	public const uint32 CERT_CHAIN_MAX_AIA_URL_RETRIEVAL_BYTE_COUNT_DEFAULT = 100000;
	public const String CERT_CHAIN_MAX_AIA_URL_RETRIEVAL_CERT_COUNT_VALUE_NAME = "MaxAIAUrlRetrievalCertCount";
	public const uint32 CERT_CHAIN_MAX_AIA_URL_RETRIEVAL_CERT_COUNT_DEFAULT = 10;
	public const String CERT_CHAIN_OCSP_VALIDITY_SECONDS_VALUE_NAME = "OcspValiditySeconds";
	public const String CERT_CHAIN_DISABLE_SERIAL_CHAIN_VALUE_NAME = "DisableSerialChain";
	public const String CERT_CHAIN_SERIAL_CHAIN_LOG_FILE_NAME_VALUE_NAME = "SerialChainLogFileName";
	public const String CERT_CHAIN_DISABLE_SYNC_WITH_SSL_TIME_VALUE_NAME = "DisableSyncWithSslTime";
	public const String CERT_CHAIN_MAX_SSL_TIME_UPDATED_EVENT_COUNT_VALUE_NAME = "MaxSslTimeUpdatedEventCount";
	public const uint32 CERT_CHAIN_MAX_SSL_TIME_UPDATED_EVENT_COUNT_DEFAULT = 5;
	public const uint32 CERT_CHAIN_MAX_SSL_TIME_UPDATED_EVENT_COUNT_DISABLE = 4294967295;
	public const String CERT_CHAIN_SSL_HANDSHAKE_LOG_FILE_NAME_VALUE_NAME = "SslHandshakeLogFileName";
	public const String CERT_CHAIN_ENABLE_WEAK_SIGNATURE_FLAGS_VALUE_NAME = "EnableWeakSignatureFlags";
	public const uint32 CERT_CHAIN_ENABLE_MD2_MD4_FLAG = 1;
	public const uint32 CERT_CHAIN_ENABLE_WEAK_RSA_ROOT_FLAG = 2;
	public const uint32 CERT_CHAIN_ENABLE_WEAK_LOGGING_FLAG = 4;
	public const uint32 CERT_CHAIN_ENABLE_ONLY_WEAK_LOGGING_FLAG = 8;
	public const String CERT_CHAIN_MIN_RSA_PUB_KEY_BIT_LENGTH_VALUE_NAME = "MinRsaPubKeyBitLength";
	public const uint32 CERT_CHAIN_MIN_RSA_PUB_KEY_BIT_LENGTH_DEFAULT = 1023;
	public const uint32 CERT_CHAIN_MIN_RSA_PUB_KEY_BIT_LENGTH_DISABLE = 4294967295;
	public const String CERT_CHAIN_WEAK_RSA_PUB_KEY_TIME_VALUE_NAME = "WeakRsaPubKeyTime";
	public const String CERT_CHAIN_WEAK_SIGNATURE_LOG_DIR_VALUE_NAME = "WeakSignatureLogDir";
	public const String CERT_CHAIN_DEFAULT_CONFIG_SUBDIR = "Default";
	public const String CERT_CHAIN_WEAK_PREFIX_NAME = "Weak";
	public const String CERT_CHAIN_WEAK_THIRD_PARTY_CONFIG_NAME = "ThirdParty";
	public const String CERT_CHAIN_WEAK_ALL_CONFIG_NAME = "All";
	public const String CERT_CHAIN_WEAK_FLAGS_NAME = "Flags";
	public const String CERT_CHAIN_WEAK_HYGIENE_NAME = "Hygiene";
	public const String CERT_CHAIN_WEAK_AFTER_TIME_NAME = "AfterTime";
	public const String CERT_CHAIN_WEAK_FILE_HASH_AFTER_TIME_NAME = "FileHashAfterTime";
	public const String CERT_CHAIN_WEAK_TIMESTAMP_HASH_AFTER_TIME_NAME = "TimestampHashAfterTime";
	public const String CERT_CHAIN_WEAK_MIN_BIT_LENGTH_NAME = "MinBitLength";
	public const String CERT_CHAIN_WEAK_SHA256_ALLOW_NAME = "Sha256Allow";
	public const uint32 CERT_CHAIN_MIN_PUB_KEY_BIT_LENGTH_DISABLE = 4294967295;
	public const uint32 CERT_CHAIN_ENABLE_WEAK_SETTINGS_FLAG = 2147483648;
	public const uint32 CERT_CHAIN_DISABLE_ECC_PARA_FLAG = 16;
	public const uint32 CERT_CHAIN_DISABLE_ALL_EKU_WEAK_FLAG = 65536;
	public const uint32 CERT_CHAIN_ENABLE_ALL_EKU_HYGIENE_FLAG = 131072;
	public const uint32 CERT_CHAIN_DISABLE_OPT_IN_SERVER_AUTH_WEAK_FLAG = 262144;
	public const uint32 CERT_CHAIN_DISABLE_SERVER_AUTH_WEAK_FLAG = 1048576;
	public const uint32 CERT_CHAIN_ENABLE_SERVER_AUTH_HYGIENE_FLAG = 2097152;
	public const uint32 CERT_CHAIN_DISABLE_CODE_SIGNING_WEAK_FLAG = 4194304;
	public const uint32 CERT_CHAIN_DISABLE_MOTW_CODE_SIGNING_WEAK_FLAG = 8388608;
	public const uint32 CERT_CHAIN_ENABLE_CODE_SIGNING_HYGIENE_FLAG = 16777216;
	public const uint32 CERT_CHAIN_ENABLE_MOTW_CODE_SIGNING_HYGIENE_FLAG = 33554432;
	public const uint32 CERT_CHAIN_DISABLE_TIMESTAMP_WEAK_FLAG = 67108864;
	public const uint32 CERT_CHAIN_DISABLE_MOTW_TIMESTAMP_WEAK_FLAG = 134217728;
	public const uint32 CERT_CHAIN_ENABLE_TIMESTAMP_HYGIENE_FLAG = 268435456;
	public const uint32 CERT_CHAIN_ENABLE_MOTW_TIMESTAMP_HYGIENE_FLAG = 536870912;
	public const uint32 CERT_CHAIN_MOTW_IGNORE_AFTER_TIME_WEAK_FLAG = 1073741824;
	public const uint32 CERT_CHAIN_DISABLE_FILE_HASH_WEAK_FLAG = 4096;
	public const uint32 CERT_CHAIN_DISABLE_MOTW_FILE_HASH_WEAK_FLAG = 8192;
	public const uint32 CERT_CHAIN_DISABLE_TIMESTAMP_HASH_WEAK_FLAG = 16384;
	public const uint32 CERT_CHAIN_DISABLE_MOTW_TIMESTAMP_HASH_WEAK_FLAG = 32768;
	public const uint32 CERT_CHAIN_OPT_IN_WEAK_FLAGS = 262144;
	public const uint32 CERT_CHAIN_AUTO_CURRENT_USER = 1;
	public const uint32 CERT_CHAIN_AUTO_LOCAL_MACHINE = 2;
	public const uint32 CERT_CHAIN_AUTO_IMPERSONATED = 3;
	public const uint32 CERT_CHAIN_AUTO_PROCESS_INFO = 4;
	public const uint32 CERT_CHAIN_AUTO_PINRULE_INFO = 5;
	public const uint32 CERT_CHAIN_AUTO_NETWORK_INFO = 6;
	public const uint32 CERT_CHAIN_AUTO_SERIAL_LOCAL_MACHINE = 7;
	public const uint32 CERT_CHAIN_AUTO_HPKP_RULE_INFO = 8;
	public const String CERT_CHAIN_AUTO_FLAGS_VALUE_NAME = "AutoFlags";
	public const uint32 CERT_CHAIN_AUTO_FLUSH_DISABLE_FLAG = 1;
	public const uint32 CERT_CHAIN_AUTO_LOG_CREATE_FLAG = 2;
	public const uint32 CERT_CHAIN_AUTO_LOG_FREE_FLAG = 4;
	public const uint32 CERT_CHAIN_AUTO_LOG_FLUSH_FLAG = 8;
	public const String CERT_CHAIN_AUTO_FLUSH_FIRST_DELTA_SECONDS_VALUE_NAME = "AutoFlushFirstDeltaSeconds";
	public const String CERT_CHAIN_AUTO_FLUSH_NEXT_DELTA_SECONDS_VALUE_NAME = "AutoFlushNextDeltaSeconds";
	public const String CERT_CHAIN_AUTO_LOG_FILE_NAME_VALUE_NAME = "AutoLogFileName";
	public const String CERT_CHAIN_DISABLE_AUTO_FLUSH_PROCESS_NAME_LIST_VALUE_NAME = "DisableAutoFlushProcessNameList";
	public const String CERT_SRV_OCSP_RESP_MIN_VALIDITY_SECONDS_VALUE_NAME = "SrvOcspRespMinValiditySeconds";
	public const String CERT_SRV_OCSP_RESP_URL_RETRIEVAL_TIMEOUT_MILLISECONDS_VALUE_NAME = "SrvOcspRespUrlRetrievalTimeoutMilliseconds";
	public const String CERT_SRV_OCSP_RESP_MAX_BEFORE_NEXT_UPDATE_SECONDS_VALUE_NAME = "SrvOcspRespMaxBeforeNextUpdateSeconds";
	public const String CERT_SRV_OCSP_RESP_MIN_BEFORE_NEXT_UPDATE_SECONDS_VALUE_NAME = "SrvOcspRespMinBeforeNextUpdateSeconds";
	public const String CERT_SRV_OCSP_RESP_MIN_AFTER_NEXT_UPDATE_SECONDS_VALUE_NAME = "SrvOcspRespMinAfterNextUpdateSeconds";
	public const String CERT_SRV_OCSP_RESP_MIN_SYNC_CERT_FILE_SECONDS_VALUE_NAME = "SrvOcspRespMinSyncCertFileSeconds";
	public const uint32 CERT_SRV_OCSP_RESP_MIN_SYNC_CERT_FILE_SECONDS_DEFAULT = 5;
	public const String CERT_SRV_OCSP_RESP_MAX_SYNC_CERT_FILE_SECONDS_VALUE_NAME = "SrvOcspRespMaxSyncCertFileSeconds";
	public const String CRYPTNET_MAX_CACHED_OCSP_PER_CRL_COUNT_VALUE_NAME = "CryptnetMaxCachedOcspPerCrlCount";
	public const uint32 CRYPTNET_MAX_CACHED_OCSP_PER_CRL_COUNT_DEFAULT = 500;
	public const uint32 CRYPTNET_OCSP_AFTER_CRL_DISABLE = 4294967295;
	public const String CRYPTNET_URL_CACHE_DEFAULT_FLUSH_EXEMPT_SECONDS_VALUE_NAME = "CryptnetDefaultFlushExemptSeconds";
	public const String CRYPTNET_PRE_FETCH_MIN_MAX_AGE_SECONDS_VALUE_NAME = "CryptnetPreFetchMinMaxAgeSeconds";
	public const String CRYPTNET_PRE_FETCH_MAX_MAX_AGE_SECONDS_VALUE_NAME = "CryptnetPreFetchMaxMaxAgeSeconds";
	public const String CRYPTNET_PRE_FETCH_MIN_OCSP_VALIDITY_PERIOD_SECONDS_VALUE_NAME = "CryptnetPreFetchMinOcspValidityPeriodSeconds";
	public const String CRYPTNET_PRE_FETCH_AFTER_PUBLISH_PRE_FETCH_DIVISOR_VALUE_NAME = "CryptnetPreFetchAfterPublishPreFetchDivisor";
	public const uint32 CRYPTNET_PRE_FETCH_AFTER_PUBLISH_PRE_FETCH_DIVISOR_DEFAULT = 10;
	public const String CRYPTNET_PRE_FETCH_BEFORE_NEXT_UPDATE_PRE_FETCH_DIVISOR_VALUE_NAME = "CryptnetPreFetchBeforeNextUpdatePreFetchDivisor";
	public const uint32 CRYPTNET_PRE_FETCH_BEFORE_NEXT_UPDATE_PRE_FETCH_DIVISOR_DEFAULT = 20;
	public const String CRYPTNET_PRE_FETCH_MIN_BEFORE_NEXT_UPDATE_PRE_FETCH_PERIOD_SECONDS_VALUE_NAME = "CryptnetPreFetchMinBeforeNextUpdatePreFetchSeconds";
	public const String CRYPTNET_PRE_FETCH_VALIDITY_PERIOD_AFTER_NEXT_UPDATE_PRE_FETCH_DIVISOR_VALUE_NAME = "CryptnetPreFetchValidityPeriodAfterNextUpdatePreFetchDivisor";
	public const uint32 CRYPTNET_PRE_FETCH_VALIDITY_PERIOD_AFTER_NEXT_UPDATE_PRE_FETCH_DIVISOR_DEFAULT = 10;
	public const String CRYPTNET_PRE_FETCH_MAX_AFTER_NEXT_UPDATE_PRE_FETCH_PERIOD_SECONDS_VALUE_NAME = "CryptnetPreFetchMaxAfterNextUpdatePreFetchPeriodSeconds";
	public const String CRYPTNET_PRE_FETCH_MIN_AFTER_NEXT_UPDATE_PRE_FETCH_PERIOD_SECONDS_VALUE_NAME = "CryptnetPreFetchMinAfterNextUpdatePreFetchPeriodSeconds";
	public const String CRYPTNET_PRE_FETCH_AFTER_CURRENT_TIME_PRE_FETCH_PERIOD_SECONDS_VALUE_NAME = "CryptnetPreFetchAfterCurrentTimePreFetchPeriodSeconds";
	public const String CRYPTNET_PRE_FETCH_TRIGGER_PERIOD_SECONDS_VALUE_NAME = "CryptnetPreFetchTriggerPeriodSeconds";
	public const uint32 CRYPTNET_PRE_FETCH_TRIGGER_DISABLE = 4294967295;
	public const String CRYPTNET_PRE_FETCH_SCAN_AFTER_TRIGGER_DELAY_SECONDS_VALUE_NAME = "CryptnetPreFetchScanAfterTriggerDelaySeconds";
	public const uint32 CRYPTNET_PRE_FETCH_SCAN_AFTER_TRIGGER_DELAY_SECONDS_DEFAULT = 60;
	public const String CRYPTNET_PRE_FETCH_RETRIEVAL_TIMEOUT_SECONDS_VALUE_NAME = "CryptnetPreFetchRetrievalTimeoutSeconds";
	public const String CRYPTNET_CRL_PRE_FETCH_PROCESS_NAME_LIST_VALUE_NAME = "ProcessNameList";
	public const String CRYPTNET_CRL_PRE_FETCH_URL_LIST_VALUE_NAME = "PreFetchUrlList";
	public const String CRYPTNET_CRL_PRE_FETCH_DISABLE_INFORMATION_EVENTS_VALUE_NAME = "DisableInformationEvents";
	public const String CRYPTNET_CRL_PRE_FETCH_LOG_FILE_NAME_VALUE_NAME = "LogFileName";
	public const String CRYPTNET_CRL_PRE_FETCH_TIMEOUT_SECONDS_VALUE_NAME = "TimeoutSeconds";
	public const String CRYPTNET_CRL_PRE_FETCH_MAX_AGE_SECONDS_VALUE_NAME = "MaxAgeSeconds";
	public const String CRYPTNET_CRL_PRE_FETCH_PUBLISH_BEFORE_NEXT_UPDATE_SECONDS_VALUE_NAME = "PublishBeforeNextUpdateSeconds";
	public const String CRYPTNET_CRL_PRE_FETCH_PUBLISH_RANDOM_INTERVAL_SECONDS_VALUE_NAME = "PublishRandomIntervalSeconds";
	public const String CRYPTNET_CRL_PRE_FETCH_MIN_BEFORE_NEXT_UPDATE_SECONDS_VALUE_NAME = "MinBeforeNextUpdateSeconds";
	public const String CRYPTNET_CRL_PRE_FETCH_MIN_AFTER_NEXT_UPDATE_SECONDS_VALUE_NAME = "MinAfterNextUpdateSeconds";
	public const String CERT_CHAIN_URL_RETRIEVAL_TIMEOUT_MILLISECONDS_VALUE_NAME = "ChainUrlRetrievalTimeoutMilliseconds";
	public const String CERT_CHAIN_REV_ACCUMULATIVE_URL_RETRIEVAL_TIMEOUT_MILLISECONDS_VALUE_NAME = "ChainRevAccumulativeUrlRetrievalTimeoutMilliseconds";
	public const String CERT_RETR_BEHAVIOR_INET_AUTH_VALUE_NAME = "EnableInetUnknownAuth";
	public const String CERT_RETR_BEHAVIOR_INET_STATUS_VALUE_NAME = "EnableInetLocal";
	public const String CERT_RETR_BEHAVIOR_FILE_VALUE_NAME = "AllowFileUrlScheme";
	public const String CERT_RETR_BEHAVIOR_LDAP_VALUE_NAME = "DisableLDAPSignAndEncrypt";
	public const String CRYPTNET_CACHED_OCSP_SWITCH_TO_CRL_COUNT_VALUE_NAME = "CryptnetCachedOcspSwitchToCrlCount";
	public const uint32 CRYPTNET_CACHED_OCSP_SWITCH_TO_CRL_COUNT_DEFAULT = 50;
	public const uint32 CRYPTNET_CRL_BEFORE_OCSP_ENABLE = 4294967295;
	public const String CERT_CHAIN_DISABLE_AIA_URL_RETRIEVAL_VALUE_NAME = "DisableAIAUrlRetrieval";
	public const String CERT_CHAIN_OPTIONS_VALUE_NAME = "Options";
	public const uint32 CERT_CHAIN_OPTION_DISABLE_AIA_URL_RETRIEVAL = 2;
	public const uint32 CERT_CHAIN_OPTION_ENABLE_SIA_URL_RETRIEVAL = 4;
	public const String CERT_CHAIN_CROSS_CERT_DOWNLOAD_INTERVAL_HOURS_VALUE_NAME = "CrossCertDownloadIntervalHours";
	public const String CERT_CHAIN_CRL_VALIDITY_EXT_PERIOD_HOURS_VALUE_NAME = "CRLValidityExtensionPeriod";
	public const uint32 CERT_CHAIN_CRL_VALIDITY_EXT_PERIOD_HOURS_DEFAULT = 12;
	public const uint32 CERT_CHAIN_CACHE_END_CERT = 1;
	public const uint32 CERT_CHAIN_THREAD_STORE_SYNC = 2;
	public const uint32 CERT_CHAIN_CACHE_ONLY_URL_RETRIEVAL = 4;
	public const uint32 CERT_CHAIN_USE_LOCAL_MACHINE_STORE = 8;
	public const uint32 CERT_CHAIN_ENABLE_CACHE_AUTO_UPDATE = 16;
	public const uint32 CERT_CHAIN_ENABLE_SHARE_STORE = 32;
	public const uint32 CERT_CHAIN_EXCLUSIVE_ENABLE_CA_FLAG = 1;
	public const uint32 CERT_TRUST_NO_ERROR = 0;
	public const uint32 CERT_TRUST_IS_NOT_TIME_VALID = 1;
	public const uint32 CERT_TRUST_IS_NOT_TIME_NESTED = 2;
	public const uint32 CERT_TRUST_IS_REVOKED = 4;
	public const uint32 CERT_TRUST_IS_NOT_SIGNATURE_VALID = 8;
	public const uint32 CERT_TRUST_IS_NOT_VALID_FOR_USAGE = 16;
	public const uint32 CERT_TRUST_IS_UNTRUSTED_ROOT = 32;
	public const uint32 CERT_TRUST_REVOCATION_STATUS_UNKNOWN = 64;
	public const uint32 CERT_TRUST_IS_CYCLIC = 128;
	public const uint32 CERT_TRUST_INVALID_EXTENSION = 256;
	public const uint32 CERT_TRUST_INVALID_POLICY_CONSTRAINTS = 512;
	public const uint32 CERT_TRUST_INVALID_BASIC_CONSTRAINTS = 1024;
	public const uint32 CERT_TRUST_INVALID_NAME_CONSTRAINTS = 2048;
	public const uint32 CERT_TRUST_HAS_NOT_SUPPORTED_NAME_CONSTRAINT = 4096;
	public const uint32 CERT_TRUST_HAS_NOT_DEFINED_NAME_CONSTRAINT = 8192;
	public const uint32 CERT_TRUST_HAS_NOT_PERMITTED_NAME_CONSTRAINT = 16384;
	public const uint32 CERT_TRUST_HAS_EXCLUDED_NAME_CONSTRAINT = 32768;
	public const uint32 CERT_TRUST_IS_OFFLINE_REVOCATION = 16777216;
	public const uint32 CERT_TRUST_NO_ISSUANCE_CHAIN_POLICY = 33554432;
	public const uint32 CERT_TRUST_IS_EXPLICIT_DISTRUST = 67108864;
	public const uint32 CERT_TRUST_HAS_NOT_SUPPORTED_CRITICAL_EXT = 134217728;
	public const uint32 CERT_TRUST_HAS_WEAK_SIGNATURE = 1048576;
	public const uint32 CERT_TRUST_HAS_WEAK_HYGIENE = 2097152;
	public const uint32 CERT_TRUST_IS_PARTIAL_CHAIN = 65536;
	public const uint32 CERT_TRUST_CTL_IS_NOT_TIME_VALID = 131072;
	public const uint32 CERT_TRUST_CTL_IS_NOT_SIGNATURE_VALID = 262144;
	public const uint32 CERT_TRUST_CTL_IS_NOT_VALID_FOR_USAGE = 524288;
	public const uint32 CERT_TRUST_HAS_EXACT_MATCH_ISSUER = 1;
	public const uint32 CERT_TRUST_HAS_KEY_MATCH_ISSUER = 2;
	public const uint32 CERT_TRUST_HAS_NAME_MATCH_ISSUER = 4;
	public const uint32 CERT_TRUST_IS_SELF_SIGNED = 8;
	public const uint32 CERT_TRUST_AUTO_UPDATE_CA_REVOCATION = 16;
	public const uint32 CERT_TRUST_AUTO_UPDATE_END_REVOCATION = 32;
	public const uint32 CERT_TRUST_NO_OCSP_FAILOVER_TO_CRL = 64;
	public const uint32 CERT_TRUST_IS_KEY_ROLLOVER = 128;
	public const uint32 CERT_TRUST_SSL_HANDSHAKE_OCSP = 262144;
	public const uint32 CERT_TRUST_SSL_TIME_VALID_OCSP = 524288;
	public const uint32 CERT_TRUST_SSL_RECONNECT_OCSP = 1048576;
	public const uint32 CERT_TRUST_HAS_PREFERRED_ISSUER = 256;
	public const uint32 CERT_TRUST_HAS_ISSUANCE_CHAIN_POLICY = 512;
	public const uint32 CERT_TRUST_HAS_VALID_NAME_CONSTRAINTS = 1024;
	public const uint32 CERT_TRUST_IS_PEER_TRUSTED = 2048;
	public const uint32 CERT_TRUST_HAS_CRL_VALIDITY_EXTENDED = 4096;
	public const uint32 CERT_TRUST_IS_FROM_EXCLUSIVE_TRUST_STORE = 8192;
	public const uint32 CERT_TRUST_IS_CA_TRUSTED = 16384;
	public const uint32 CERT_TRUST_HAS_AUTO_UPDATE_WEAK_SIGNATURE = 32768;
	public const uint32 CERT_TRUST_HAS_ALLOW_WEAK_SIGNATURE = 131072;
	public const uint32 CERT_TRUST_IS_COMPLEX_CHAIN = 65536;
	public const uint32 CERT_TRUST_SSL_TIME_VALID = 16777216;
	public const uint32 CERT_TRUST_NO_TIME_CHECK = 33554432;
	public const uint32 USAGE_MATCH_TYPE_AND = 0;
	public const uint32 USAGE_MATCH_TYPE_OR = 1;
	public const uint32 CERT_CHAIN_STRONG_SIGN_DISABLE_END_CHECK_FLAG = 1;
	public const uint32 CERT_CHAIN_REVOCATION_CHECK_END_CERT = 268435456;
	public const uint32 CERT_CHAIN_REVOCATION_CHECK_CHAIN = 536870912;
	public const uint32 CERT_CHAIN_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT = 1073741824;
	public const uint32 CERT_CHAIN_REVOCATION_CHECK_CACHE_ONLY = 2147483648;
	public const uint32 CERT_CHAIN_REVOCATION_ACCUMULATIVE_TIMEOUT = 134217728;
	public const uint32 CERT_CHAIN_REVOCATION_CHECK_OCSP_CERT = 67108864;
	public const uint32 CERT_CHAIN_DISABLE_PASS1_QUALITY_FILTERING = 64;
	public const uint32 CERT_CHAIN_RETURN_LOWER_QUALITY_CONTEXTS = 128;
	public const uint32 CERT_CHAIN_DISABLE_AUTH_ROOT_AUTO_UPDATE = 256;
	public const uint32 CERT_CHAIN_TIMESTAMP_TIME = 512;
	public const uint32 CERT_CHAIN_ENABLE_PEER_TRUST = 1024;
	public const uint32 CERT_CHAIN_DISABLE_MY_PEER_TRUST = 2048;
	public const uint32 CERT_CHAIN_DISABLE_MD2_MD4 = 4096;
	public const uint32 CERT_CHAIN_DISABLE_AIA = 8192;
	public const uint32 CERT_CHAIN_HAS_MOTW = 16384;
	public const uint32 CERT_CHAIN_ONLY_ADDITIONAL_AND_AUTH_ROOT = 32768;
	public const uint32 CERT_CHAIN_OPT_IN_WEAK_SIGNATURE = 65536;
	public const PSTR REVOCATION_OID_CRL_REVOCATION = (PSTR)(void*)1;
	public const uint32 CERT_CHAIN_FIND_BY_ISSUER = 1;
	public const uint32 CERT_CHAIN_POLICY_IGNORE_WEAK_SIGNATURE_FLAG = 134217728;
	public const String CRYPT_OID_VERIFY_CERTIFICATE_CHAIN_POLICY_FUNC = "CertDllVerifyCertificateChainPolicy";
	public const PSTR CERT_CHAIN_POLICY_BASE = (PSTR)(void*)1;
	public const PSTR CERT_CHAIN_POLICY_AUTHENTICODE = (PSTR)(void*)2;
	public const PSTR CERT_CHAIN_POLICY_AUTHENTICODE_TS = (PSTR)(void*)3;
	public const PSTR CERT_CHAIN_POLICY_SSL = (PSTR)(void*)4;
	public const PSTR CERT_CHAIN_POLICY_BASIC_CONSTRAINTS = (PSTR)(void*)5;
	public const PSTR CERT_CHAIN_POLICY_NT_AUTH = (PSTR)(void*)6;
	public const PSTR CERT_CHAIN_POLICY_MICROSOFT_ROOT = (PSTR)(void*)7;
	public const PSTR CERT_CHAIN_POLICY_EV = (PSTR)(void*)8;
	public const PSTR CERT_CHAIN_POLICY_SSL_F12 = (PSTR)(void*)9;
	public const PSTR CERT_CHAIN_POLICY_SSL_HPKP_HEADER = (PSTR)(void*)10;
	public const PSTR CERT_CHAIN_POLICY_THIRD_PARTY_ROOT = (PSTR)(void*)11;
	public const PSTR CERT_CHAIN_POLICY_SSL_KEY_PIN = (PSTR)(void*)12;
	public const uint32 BASIC_CONSTRAINTS_CERT_CHAIN_POLICY_CA_FLAG = 2147483648;
	public const uint32 BASIC_CONSTRAINTS_CERT_CHAIN_POLICY_END_ENTITY_FLAG = 1073741824;
	public const uint32 MICROSOFT_ROOT_CERT_CHAIN_POLICY_ENABLE_TEST_ROOT_FLAG = 65536;
	public const uint32 MICROSOFT_ROOT_CERT_CHAIN_POLICY_CHECK_APPLICATION_ROOT_FLAG = 131072;
	public const uint32 MICROSOFT_ROOT_CERT_CHAIN_POLICY_DISABLE_FLIGHT_ROOT_FLAG = 262144;
	public const uint32 SSL_F12_ERROR_TEXT_LENGTH = 256;
	public const uint32 CERT_CHAIN_POLICY_SSL_F12_SUCCESS_LEVEL = 0;
	public const uint32 CERT_CHAIN_POLICY_SSL_F12_WARNING_LEVEL = 1;
	public const uint32 CERT_CHAIN_POLICY_SSL_F12_ERROR_LEVEL = 2;
	public const uint32 CERT_CHAIN_POLICY_SSL_F12_NONE_CATEGORY = 0;
	public const uint32 CERT_CHAIN_POLICY_SSL_F12_WEAK_CRYPTO_CATEGORY = 1;
	public const uint32 CERT_CHAIN_POLICY_SSL_F12_ROOT_PROGRAM_CATEGORY = 2;
	public const uint32 SSL_HPKP_PKP_HEADER_INDEX = 0;
	public const uint32 SSL_HPKP_PKP_RO_HEADER_INDEX = 1;
	public const uint32 SSL_HPKP_HEADER_COUNT = 2;
	public const uint32 SSL_KEY_PIN_ERROR_TEXT_LENGTH = 512;
	public const int32 CERT_CHAIN_POLICY_SSL_KEY_PIN_MISMATCH_ERROR = -2;
	public const int32 CERT_CHAIN_POLICY_SSL_KEY_PIN_MITM_ERROR = -1;
	public const uint32 CERT_CHAIN_POLICY_SSL_KEY_PIN_SUCCESS = 0;
	public const uint32 CERT_CHAIN_POLICY_SSL_KEY_PIN_MITM_WARNING = 1;
	public const uint32 CERT_CHAIN_POLICY_SSL_KEY_PIN_MISMATCH_WARNING = 2;
	public const uint32 CRYPT_STRING_BASE64URI = 13;
	public const uint32 CRYPT_STRING_ENCODEMASK = 255;
	public const uint32 CRYPT_STRING_RESERVED100 = 256;
	public const uint32 CRYPT_STRING_RESERVED200 = 512;
	public const uint32 CRYPT_STRING_PERCENTESCAPE = 134217728;
	public const uint32 CRYPT_STRING_HASHDATA = 268435456;
	public const uint32 CRYPT_STRING_NOCRLF = 1073741824;
	public const uint32 CRYPT_STRING_NOCR = 2147483648;
	public const String szOID_PKCS_12_PbeIds = "1.2.840.113549.1.12.1";
	public const String szOID_PKCS_12_pbeWithSHA1And128BitRC4 = "1.2.840.113549.1.12.1.1";
	public const String szOID_PKCS_12_pbeWithSHA1And40BitRC4 = "1.2.840.113549.1.12.1.2";
	public const String szOID_PKCS_12_pbeWithSHA1And3KeyTripleDES = "1.2.840.113549.1.12.1.3";
	public const String szOID_PKCS_12_pbeWithSHA1And2KeyTripleDES = "1.2.840.113549.1.12.1.4";
	public const String szOID_PKCS_12_pbeWithSHA1And128BitRC2 = "1.2.840.113549.1.12.1.5";
	public const String szOID_PKCS_12_pbeWithSHA1And40BitRC2 = "1.2.840.113549.1.12.1.6";
	public const String szOID_PKCS_5_PBKDF2 = "1.2.840.113549.1.5.12";
	public const String szOID_PKCS_5_PBES2 = "1.2.840.113549.1.5.13";
	public const uint32 PKCS12_IMPORT_SILENT = 64;
	public const uint32 PKCS12_ONLY_CERTIFICATES = 1024;
	public const uint32 PKCS12_ONLY_NOT_ENCRYPTED_CERTIFICATES = 2048;
	public const uint32 PKCS12_VIRTUAL_ISOLATION_KEY = 65536;
	public const uint32 PKCS12_IMPORT_RESERVED_MASK = 4294901760;
	public const uint32 PKCS12_ONLY_CERTIFICATES_PROVIDER_TYPE = 0;
	public const String PKCS12_ONLY_CERTIFICATES_PROVIDER_NAME = "PfxProvider";
	public const String PKCS12_ONLY_CERTIFICATES_CONTAINER_NAME = "PfxContainer";
	public const uint32 REPORT_NO_PRIVATE_KEY = 1;
	public const uint32 REPORT_NOT_ABLE_TO_EXPORT_PRIVATE_KEY = 2;
	public const uint32 EXPORT_PRIVATE_KEYS = 4;
	public const uint32 PKCS12_PROTECT_TO_DOMAIN_SIDS = 32;
	public const uint32 PKCS12_EXPORT_SILENT = 64;
	public const uint32 PKCS12_EXPORT_PBES2_PARAMS = 128;
	public const uint32 PKCS12_DISABLE_ENCRYPT_CERTIFICATES = 256;
	public const uint32 PKCS12_ENCRYPT_CERTIFICATES = 512;
	public const uint32 PKCS12_EXPORT_ECC_CURVE_PARAMETERS = 4096;
	public const uint32 PKCS12_EXPORT_ECC_CURVE_OID = 8192;
	public const uint32 PKCS12_EXPORT_RESERVED_MASK = 4294901760;
	public const String PKCS12_PBKDF2_ID_HMAC_SHA1 = "1.2.840.113549.2.7";
	public const String PKCS12_PBKDF2_ID_HMAC_SHA256 = "1.2.840.113549.2.9";
	public const String PKCS12_PBKDF2_ID_HMAC_SHA384 = "1.2.840.113549.2.10";
	public const String PKCS12_PBKDF2_ID_HMAC_SHA512 = "1.2.840.113549.2.11";
	public const String PKCS12_PBES2_ALG_AES256_SHA256 = "AES256-SHA256";
	public const String PKCS12_CONFIG_REGPATH = "Software\\Microsoft\\Windows\\CurrentVersion\\PFX";
	public const String PKCS12_ENCRYPT_CERTIFICATES_VALUE_NAME = "EncryptCertificates";
	public const uint32 CERT_SERVER_OCSP_RESPONSE_OPEN_PARA_READ_FLAG = 1;
	public const uint32 CERT_SERVER_OCSP_RESPONSE_OPEN_PARA_WRITE_FLAG = 2;
	public const uint32 CERT_SERVER_OCSP_RESPONSE_ASYNC_FLAG = 1;
	public const PSTR CERT_RETRIEVE_ISSUER_LOGO = (PSTR)(void*)1;
	public const PSTR CERT_RETRIEVE_SUBJECT_LOGO = (PSTR)(void*)2;
	public const PSTR CERT_RETRIEVE_COMMUNITY_LOGO = (PSTR)(void*)3;
	public const PSTR CERT_RETRIEVE_BIOMETRIC_PREDEFINED_BASE_TYPE = (PSTR)(void*)1000;
	public const uint32 CERT_SELECT_MAX_PARA = 500;
	public const uint32 CERT_SELECT_BY_ISSUER_DISPLAYNAME = 12;
	public const uint32 CERT_SELECT_BY_FRIENDLYNAME = 13;
	public const uint32 CERT_SELECT_BY_THUMBPRINT = 14;
	public const uint32 CERT_SELECT_ALLOW_EXPIRED = 1;
	public const uint32 CERT_SELECT_TRUSTED_ROOT = 2;
	public const uint32 CERT_SELECT_DISALLOW_SELFSIGNED = 4;
	public const uint32 CERT_SELECT_HAS_PRIVATE_KEY = 8;
	public const uint32 CERT_SELECT_HAS_KEY_FOR_SIGNATURE = 16;
	public const uint32 CERT_SELECT_HAS_KEY_FOR_KEY_EXCHANGE = 32;
	public const uint32 CERT_SELECT_HARDWARE_ONLY = 64;
	public const uint32 CERT_SELECT_ALLOW_DUPLICATES = 128;
	public const uint32 CERT_SELECT_IGNORE_AUTOSELECT = 256;
	public const uint32 TIMESTAMP_FAILURE_BAD_ALG = 0;
	public const uint32 TIMESTAMP_FAILURE_BAD_REQUEST = 2;
	public const uint32 TIMESTAMP_FAILURE_BAD_FORMAT = 5;
	public const uint32 TIMESTAMP_FAILURE_TIME_NOT_AVAILABLE = 14;
	public const uint32 TIMESTAMP_FAILURE_POLICY_NOT_SUPPORTED = 15;
	public const uint32 TIMESTAMP_FAILURE_EXTENSION_NOT_SUPPORTED = 16;
	public const uint32 TIMESTAMP_FAILURE_INFO_NOT_AVAILABLE = 17;
	public const uint32 TIMESTAMP_FAILURE_SYSTEM_FAILURE = 25;
	public const uint32 TIMESTAMP_DONT_HASH_DATA = 1;
	public const uint32 TIMESTAMP_VERIFY_CONTEXT_SIGNATURE = 32;
	public const uint32 TIMESTAMP_NO_AUTH_RETRIEVAL = 131072;
	public const uint32 CRYPT_OBJECT_LOCATOR_SPN_NAME_TYPE = 1;
	public const uint32 CRYPT_OBJECT_LOCATOR_LAST_RESERVED_NAME_TYPE = 32;
	public const uint32 CRYPT_OBJECT_LOCATOR_FIRST_RESERVED_USER_NAME_TYPE = 33;
	public const uint32 CRYPT_OBJECT_LOCATOR_LAST_RESERVED_USER_NAME_TYPE = 65535;
	public const String SSL_OBJECT_LOCATOR_PFX_FUNC = "SslObjectLocatorInitializePfx";
	public const String SSL_OBJECT_LOCATOR_ISSUER_LIST_FUNC = "SslObjectLocatorInitializeIssuerList";
	public const String SSL_OBJECT_LOCATOR_CERT_VALIDATION_CONFIG_FUNC = "SslObjectLocatorInitializeCertValidationConfig";
	public const uint32 CERT_FILE_HASH_USE_TYPE = 1;
	public const uint32 CERT_TIMESTAMP_HASH_USE_TYPE = 2;
	public const uint32 RECIPIENTPOLICYV1 = 1;
	public const uint32 RECIPIENTPOLICYV2 = 2;
	public const HRESULT E_ICARD_COMMUNICATION = -1073413888;
	public const HRESULT E_ICARD_DATA_ACCESS = -1073413887;
	public const HRESULT E_ICARD_EXPORT = -1073413886;
	public const HRESULT E_ICARD_IDENTITY = -1073413885;
	public const HRESULT E_ICARD_IMPORT = -1073413884;
	public const HRESULT E_ICARD_ARGUMENT = -1073413883;
	public const HRESULT E_ICARD_REQUEST = -1073413882;
	public const HRESULT E_ICARD_INFORMATIONCARD = -1073413881;
	public const HRESULT E_ICARD_STOREKEY = -1073413880;
	public const HRESULT E_ICARD_LOGOVALIDATION = -1073413879;
	public const HRESULT E_ICARD_PASSWORDVALIDATION = -1073413878;
	public const HRESULT E_ICARD_POLICY = -1073413877;
	public const HRESULT E_ICARD_PROCESSDIED = -1073413876;
	public const HRESULT E_ICARD_SERVICEBUSY = -1073413875;
	public const HRESULT E_ICARD_SERVICE = -1073413874;
	public const HRESULT E_ICARD_SHUTTINGDOWN = -1073413873;
	public const HRESULT E_ICARD_TOKENCREATION = -1073413872;
	public const HRESULT E_ICARD_TRUSTEXCHANGE = -1073413871;
	public const HRESULT E_ICARD_UNTRUSTED = -1073413870;
	public const HRESULT E_ICARD_USERCANCELLED = -1073413869;
	public const HRESULT E_ICARD_STORE_IMPORT = -1073413868;
	public const HRESULT E_ICARD_FAIL = -1073413867;
	public const HRESULT E_ICARD_UI_INITIALIZATION = -1073413862;
	public const HRESULT E_ICARD_REFRESH_REQUIRED = -1073413760;
	public const HRESULT E_ICARD_MISSING_APPLIESTO = -1073413759;
	public const HRESULT E_ICARD_INVALID_PROOF_KEY = -1073413758;
	public const HRESULT E_ICARD_UNKNOWN_REFERENCE = -1073413757;
	public const HRESULT E_ICARD_FAILED_REQUIRED_CLAIMS = -1073413756;
	public const HRESULT AUDIT_CARD_WRITTEN = 1074070016;
	public const HRESULT AUDIT_CARD_DELETE = 1074070017;
	public const HRESULT AUDIT_CARD_IMPORT = 1074070018;
	public const HRESULT AUDIT_STORE_IMPORT = 1074070019;
	public const HRESULT AUDIT_STORE_EXPORT = 1074070020;
	public const HRESULT AUDIT_STORE_DELETE = 1074070021;
	public const HRESULT AUDIT_SERVICE_IDLE_STOP = 1074070022;
}
#endregion

#region TypeDefs
typealias HCRYPTASYNC = int;

typealias HCERTCHAINENGINE = int;

typealias BCRYPT_ALG_HANDLE = int;

typealias BCRYPT_KEY_HANDLE = int;

typealias BCRYPT_HASH_HANDLE = int;

typealias BCRYPT_SECRET_HANDLE = int;

typealias BCRYPT_HANDLE = int;

typealias NCRYPT_HANDLE = uint;

typealias NCRYPT_PROV_HANDLE = uint;

typealias NCRYPT_KEY_HANDLE = uint;

typealias NCRYPT_HASH_HANDLE = uint;

typealias NCRYPT_SECRET_HANDLE = uint;

typealias HCRYPTPROV_LEGACY = uint;

typealias HCRYPTPROV_OR_NCRYPT_KEY_HANDLE = uint;

typealias HCERTSTORE = void*;

typealias HCERTSTOREPROV = void*;

#endregion


#region Enums

[AllowDuplicates]
public enum BCRYPT_OPERATION : uint32
{
	BCRYPT_CIPHER_OPERATION = 1,
	BCRYPT_HASH_OPERATION = 2,
	BCRYPT_ASYMMETRIC_ENCRYPTION_OPERATION = 4,
	BCRYPT_SECRET_AGREEMENT_OPERATION = 8,
	BCRYPT_SIGNATURE_OPERATION = 16,
	BCRYPT_RNG_OPERATION = 32,
}


[AllowDuplicates]
public enum NCRYPT_OPERATION : uint32
{
	NCRYPT_CIPHER_OPERATION = 1,
	NCRYPT_HASH_OPERATION = 2,
	NCRYPT_ASYMMETRIC_ENCRYPTION_OPERATION = 4,
	NCRYPT_SECRET_AGREEMENT_OPERATION = 8,
	NCRYPT_SIGNATURE_OPERATION = 16,
}


[AllowDuplicates]
public enum CERT_FIND_FLAGS : uint32
{
	CERT_FIND_ANY = 0,
	CERT_FIND_CERT_ID = 1048576,
	CERT_FIND_CTL_USAGE = 655360,
	CERT_FIND_ENHKEY_USAGE = 655360,
	CERT_FIND_EXISTING = 851968,
	CERT_FIND_HASH = 65536,
	CERT_FIND_HAS_PRIVATE_KEY = 1376256,
	CERT_FIND_ISSUER_ATTR = 196612,
	CERT_FIND_ISSUER_NAME = 131076,
	CERT_FIND_ISSUER_OF = 786432,
	CERT_FIND_ISSUER_STR = 524292,
	CERT_FIND_KEY_IDENTIFIER = 983040,
	CERT_FIND_KEY_SPEC = 589824,
	CERT_FIND_MD5_HASH = 262144,
	CERT_FIND_PROPERTY = 327680,
	CERT_FIND_PUBLIC_KEY = 393216,
	CERT_FIND_SHA1_HASH = 65536,
	CERT_FIND_SIGNATURE_HASH = 917504,
	CERT_FIND_SUBJECT_ATTR = 196615,
	CERT_FIND_SUBJECT_CERT = 720896,
	CERT_FIND_SUBJECT_NAME = 131079,
	CERT_FIND_SUBJECT_STR = 524295,
	CERT_FIND_CROSS_CERT_DIST_POINTS = 1114112,
	CERT_FIND_PUBKEY_MD5_HASH = 1179648,
	CERT_FIND_SUBJECT_STR_A = 458759,
	CERT_FIND_SUBJECT_STR_W = 524295,
	CERT_FIND_ISSUER_STR_A = 458756,
	CERT_FIND_ISSUER_STR_W = 524292,
	CERT_FIND_SUBJECT_INFO_ACCESS = 1245184,
	CERT_FIND_HASH_STR = 1310720,
	CERT_FIND_OPTIONAL_ENHKEY_USAGE_FLAG = 1,
	CERT_FIND_EXT_ONLY_ENHKEY_USAGE_FLAG = 2,
	CERT_FIND_PROP_ONLY_ENHKEY_USAGE_FLAG = 4,
	CERT_FIND_NO_ENHKEY_USAGE_FLAG = 8,
	CERT_FIND_OR_ENHKEY_USAGE_FLAG = 16,
	CERT_FIND_VALID_ENHKEY_USAGE_FLAG = 32,
	CERT_FIND_OPTIONAL_CTL_USAGE_FLAG = 1,
	CERT_FIND_EXT_ONLY_CTL_USAGE_FLAG = 2,
	CERT_FIND_PROP_ONLY_CTL_USAGE_FLAG = 4,
	CERT_FIND_NO_CTL_USAGE_FLAG = 8,
	CERT_FIND_OR_CTL_USAGE_FLAG = 16,
	CERT_FIND_VALID_CTL_USAGE_FLAG = 32,
}


[AllowDuplicates]
public enum CERT_QUERY_OBJECT_TYPE : uint32
{
	CERT_QUERY_OBJECT_FILE = 1,
	CERT_QUERY_OBJECT_BLOB = 2,
}


[AllowDuplicates]
public enum CERT_QUERY_CONTENT_TYPE : uint32
{
	CERT_QUERY_CONTENT_CERT = 1,
	CERT_QUERY_CONTENT_CTL = 2,
	CERT_QUERY_CONTENT_CRL = 3,
	CERT_QUERY_CONTENT_SERIALIZED_STORE = 4,
	CERT_QUERY_CONTENT_SERIALIZED_CERT = 5,
	CERT_QUERY_CONTENT_SERIALIZED_CTL = 6,
	CERT_QUERY_CONTENT_SERIALIZED_CRL = 7,
	CERT_QUERY_CONTENT_PKCS7_SIGNED = 8,
	CERT_QUERY_CONTENT_PKCS7_UNSIGNED = 9,
	CERT_QUERY_CONTENT_PKCS7_SIGNED_EMBED = 10,
	CERT_QUERY_CONTENT_PKCS10 = 11,
	CERT_QUERY_CONTENT_PFX = 12,
	CERT_QUERY_CONTENT_CERT_PAIR = 13,
	CERT_QUERY_CONTENT_PFX_AND_LOAD = 14,
}


[AllowDuplicates]
public enum CERT_QUERY_CONTENT_TYPE_FLAGS : uint32
{
	CERT_QUERY_CONTENT_FLAG_CERT = 2,
	CERT_QUERY_CONTENT_FLAG_CTL = 4,
	CERT_QUERY_CONTENT_FLAG_CRL = 8,
	CERT_QUERY_CONTENT_FLAG_SERIALIZED_STORE = 16,
	CERT_QUERY_CONTENT_FLAG_SERIALIZED_CERT = 32,
	CERT_QUERY_CONTENT_FLAG_SERIALIZED_CTL = 64,
	CERT_QUERY_CONTENT_FLAG_SERIALIZED_CRL = 128,
	CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED = 256,
	CERT_QUERY_CONTENT_FLAG_PKCS7_UNSIGNED = 512,
	CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED_EMBED = 1024,
	CERT_QUERY_CONTENT_FLAG_PKCS10 = 2048,
	CERT_QUERY_CONTENT_FLAG_PFX = 4096,
	CERT_QUERY_CONTENT_FLAG_CERT_PAIR = 8192,
	CERT_QUERY_CONTENT_FLAG_PFX_AND_LOAD = 16384,
	CERT_QUERY_CONTENT_FLAG_ALL = 16382,
	CERT_QUERY_CONTENT_FLAG_ALL_ISSUER_CERT = 818,
}


[AllowDuplicates]
public enum CERT_QUERY_FORMAT_TYPE : uint32
{
	CERT_QUERY_FORMAT_BINARY = 1,
	CERT_QUERY_FORMAT_BASE64_ENCODED = 2,
	CERT_QUERY_FORMAT_ASN_ASCII_HEX_ENCODED = 3,
}


[AllowDuplicates]
public enum CERT_QUERY_FORMAT_TYPE_FLAGS : uint32
{
	CERT_QUERY_FORMAT_FLAG_BINARY = 2,
	CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED = 4,
	CERT_QUERY_FORMAT_FLAG_ASN_ASCII_HEX_ENCODED = 8,
	CERT_QUERY_FORMAT_FLAG_ALL = 14,
}


[AllowDuplicates]
public enum CERT_QUERY_ENCODING_TYPE : uint32
{
	X509_ASN_ENCODING = 1,
	PKCS_7_ASN_ENCODING = 65536,
}


[AllowDuplicates]
public enum CERT_RDN_ATTR_VALUE_TYPE : uint32
{
	CERT_RDN_ANY_TYPE = 0,
	CERT_RDN_NUMERIC_STRING = 3,
	CERT_RDN_PRINTABLE_STRING = 4,
	CERT_RDN_T61_STRING = 5,
	CERT_RDN_VIDEOTEX_STRING = 6,
	CERT_RDN_IA5_STRING = 7,
	CERT_RDN_GRAPHIC_STRING = 8,
	CERT_RDN_ISO646_STRING = 9,
	CERT_RDN_GENERAL_STRING = 10,
	CERT_RDN_INT4_STRING = 11,
	CERT_RDN_UNICODE_STRING = 12,
	CERT_RDN_BMP_STRING = 12,
	CERT_RDN_ENCODED_BLOB = 1,
	CERT_RDN_OCTET_STRING = 2,
	CERT_RDN_TELETEX_STRING = 5,
	CERT_RDN_UNIVERSAL_STRING = 11,
	CERT_RDN_UTF8_STRING = 13,
	CERT_RDN_VISIBLE_STRING = 9,
}


[AllowDuplicates]
public enum CERT_STRING_TYPE : uint32
{
	CERT_SIMPLE_NAME_STR = 1,
	CERT_OID_NAME_STR = 2,
	CERT_X500_NAME_STR = 3,
}


[AllowDuplicates]
public enum BCRYPT_TABLE : uint32
{
	CRYPT_LOCAL = 1,
	CRYPT_DOMAIN = 2,
}


[AllowDuplicates]
public enum CERT_KEY_SPEC : uint32
{
	AT_KEYEXCHANGE = 1,
	AT_SIGNATURE = 2,
	CERT_NCRYPT_KEY_SPEC = 4294967295,
}


[AllowDuplicates]
public enum BCRYPT_INTERFACE : uint32
{
	BCRYPT_ASYMMETRIC_ENCRYPTION_INTERFACE = 3,
	BCRYPT_CIPHER_INTERFACE = 1,
	BCRYPT_HASH_INTERFACE = 2,
	BCRYPT_RNG_INTERFACE = 6,
	BCRYPT_SECRET_AGREEMENT_INTERFACE = 4,
	BCRYPT_SIGNATURE_INTERFACE = 5,
	NCRYPT_KEY_STORAGE_INTERFACE = 65537,
	NCRYPT_SCHANNEL_INTERFACE = 65538,
	NCRYPT_SCHANNEL_SIGNATURE_INTERFACE = 65539,
}


[AllowDuplicates]
public enum NCRYPT_FLAGS : uint32
{
	BCRYPT_PAD_NONE = 1,
	BCRYPT_PAD_OAEP = 4,
	BCRYPT_PAD_PKCS1 = 2,
	BCRYPT_PAD_PSS = 8,
	NCRYPT_SILENT_FLAG = 64,
	NCRYPT_NO_PADDING_FLAG = 1,
	NCRYPT_PAD_OAEP_FLAG = 4,
	NCRYPT_PAD_PKCS1_FLAG = 2,
	NCRYPT_REGISTER_NOTIFY_FLAG = 1,
	NCRYPT_UNREGISTER_NOTIFY_FLAG = 2,
	NCRYPT_MACHINE_KEY_FLAG = 32,
	NCRYPT_UNPROTECT_NO_DECRYPT = 1,
	NCRYPT_OVERWRITE_KEY_FLAG = 128,
	NCRYPT_NO_KEY_VALIDATION = 8,
	NCRYPT_WRITE_KEY_TO_LEGACY_STORE_FLAG = 512,
	NCRYPT_PAD_PSS_FLAG = 8,
	NCRYPT_PERSIST_FLAG = 2147483648,
	NCRYPT_PERSIST_ONLY_FLAG = 1073741824,
}


[AllowDuplicates]
public enum CRYPT_STRING : uint32
{
	CRYPT_STRING_BASE64HEADER = 0,
	CRYPT_STRING_BASE64 = 1,
	CRYPT_STRING_BINARY = 2,
	CRYPT_STRING_BASE64REQUESTHEADER = 3,
	CRYPT_STRING_HEX = 4,
	CRYPT_STRING_HEXASCII = 5,
	CRYPT_STRING_BASE64X509CRLHEADER = 9,
	CRYPT_STRING_HEXADDR = 10,
	CRYPT_STRING_HEXASCIIADDR = 11,
	CRYPT_STRING_HEXRAW = 12,
	CRYPT_STRING_STRICT = 536870912,
	CRYPT_STRING_BASE64_ANY = 6,
	CRYPT_STRING_ANY = 7,
	CRYPT_STRING_HEX_ANY = 8,
}


[AllowDuplicates]
public enum CRYPT_IMPORT_PUBLIC_KEY_FLAGS : uint32
{
	CRYPT_OID_INFO_PUBKEY_SIGN_KEY_FLAG = 2147483648,
	CRYPT_OID_INFO_PUBKEY_ENCRYPT_KEY_FLAG = 1073741824,
}


[AllowDuplicates]
public enum CRYPT_XML_FLAGS : uint32
{
	CRYPT_XML_FLAG_DISABLE_EXTENSIONS = 268435456,
	CRYPT_XML_FLAG_NO_SERIALIZE = 2147483648,
	CRYPT_XML_SIGN_ADD_KEYVALUE = 1,
}


[AllowDuplicates]
public enum CRYPT_ENCODE_OBJECT_FLAGS : uint32
{
	CRYPT_ENCODE_ALLOC_FLAG = 32768,
	CRYPT_ENCODE_ENABLE_PUNYCODE_FLAG = 131072,
	CRYPT_UNICODE_NAME_ENCODE_DISABLE_CHECK_TYPE_FLAG = 1073741824,
	CRYPT_UNICODE_NAME_ENCODE_ENABLE_T61_UNICODE_FLAG = 2147483648,
	CRYPT_UNICODE_NAME_ENCODE_ENABLE_UTF8_UNICODE_FLAG = 536870912,
}


[AllowDuplicates]
public enum CRYPT_OBJECT_LOCATOR_RELEASE_REASON : uint32
{
	CRYPT_OBJECT_LOCATOR_RELEASE_SYSTEM_SHUTDOWN = 1,
	CRYPT_OBJECT_LOCATOR_RELEASE_SERVICE_STOP = 2,
	CRYPT_OBJECT_LOCATOR_RELEASE_PROCESS_EXIT = 3,
	CRYPT_OBJECT_LOCATOR_RELEASE_DLL_UNLOAD = 4,
}


[AllowDuplicates]
public enum CRYPT_ACQUIRE_FLAGS : uint32
{
	CRYPT_ACQUIRE_CACHE_FLAG = 1,
	CRYPT_ACQUIRE_COMPARE_KEY_FLAG = 4,
	CRYPT_ACQUIRE_NO_HEALING = 8,
	CRYPT_ACQUIRE_SILENT_FLAG = 64,
	CRYPT_ACQUIRE_USE_PROV_INFO_FLAG = 2,
}


[AllowDuplicates]
public enum CRYPT_GET_URL_FLAGS : uint32
{
	CRYPT_GET_URL_FROM_PROPERTY = 1,
	CRYPT_GET_URL_FROM_EXTENSION = 2,
	CRYPT_GET_URL_FROM_UNAUTH_ATTRIBUTE = 4,
	CRYPT_GET_URL_FROM_AUTH_ATTRIBUTE = 8,
}


[AllowDuplicates]
public enum CERT_STORE_SAVE_AS : uint32
{
	CERT_STORE_SAVE_AS_PKCS7 = 2,
	CERT_STORE_SAVE_AS_STORE = 1,
}


[AllowDuplicates]
public enum BCRYPT_QUERY_PROVIDER_MODE : uint32
{
	CRYPT_ANY = 4,
	CRYPT_UM = 1,
	CRYPT_KM = 2,
	CRYPT_MM = 3,
}


[AllowDuplicates]
public enum CERT_FIND_CHAIN_IN_STORE_FLAGS : uint32
{
	CERT_CHAIN_FIND_BY_ISSUER_COMPARE_KEY_FLAG = 1,
	CERT_CHAIN_FIND_BY_ISSUER_COMPLEX_CHAIN_FLAG = 2,
	CERT_CHAIN_FIND_BY_ISSUER_CACHE_ONLY_FLAG = 32768,
	CERT_CHAIN_FIND_BY_ISSUER_CACHE_ONLY_URL_FLAG = 4,
	CERT_CHAIN_FIND_BY_ISSUER_LOCAL_MACHINE_FLAG = 8,
	CERT_CHAIN_FIND_BY_ISSUER_NO_KEY_FLAG = 16384,
}


[AllowDuplicates]
public enum CERT_CONTROL_STORE_FLAGS : uint32
{
	CERT_STORE_CTRL_COMMIT_FORCE_FLAG = 1,
	CERT_STORE_CTRL_COMMIT_CLEAR_FLAG = 2,
	CERT_STORE_CTRL_INHIBIT_DUPLICATE_HANDLE_FLAG = 1,
}


[AllowDuplicates]
public enum BCRYPT_OPEN_ALGORITHM_PROVIDER_FLAGS : uint32
{
	BCRYPT_ALG_HANDLE_HMAC_FLAG = 8,
	BCRYPT_PROV_DISPATCH = 1,
	BCRYPT_HASH_REUSABLE_FLAG = 32,
}


[AllowDuplicates]
public enum CERT_STORE_SAVE_TO : uint32
{
	CERT_STORE_SAVE_TO_FILE = 1,
	CERT_STORE_SAVE_TO_FILENAME = 4,
	CERT_STORE_SAVE_TO_FILENAME_A = 3,
	CERT_STORE_SAVE_TO_FILENAME_W = 4,
	CERT_STORE_SAVE_TO_MEMORY = 2,
}


[AllowDuplicates]
public enum CRYPT_SET_PROV_PARAM_ID : uint32
{
	PP_CLIENT_HWND = 1,
	PP_DELETEKEY = 24,
	PP_KEYEXCHANGE_ALG = 14,
	PP_KEYEXCHANGE_PIN = 32,
	PP_KEYEXCHANGE_KEYSIZE = 12,
	PP_KEYSET_SEC_DESCR = 8,
	PP_PIN_PROMPT_STRING = 44,
	PP_ROOT_CERTSTORE = 46,
	PP_SIGNATURE_ALG = 15,
	PP_SIGNATURE_PIN = 33,
	PP_SIGNATURE_KEYSIZE = 13,
	PP_UI_PROMPT = 21,
	PP_USE_HARDWARE_RNG = 38,
	PP_USER_CERTSTORE = 42,
	PP_SECURE_KEYEXCHANGE_PIN = 47,
	PP_SECURE_SIGNATURE_PIN = 48,
	PP_SMARTCARD_READER = 43,
}


[AllowDuplicates]
public enum CRYPT_KEY_PARAM_ID : uint32
{
	KP_ALGID = 7,
	KP_CERTIFICATE = 26,
	KP_PERMISSIONS = 6,
	KP_SALT = 2,
	KP_SALT_EX = 10,
	KP_BLOCKLEN = 8,
	KP_GET_USE_COUNT = 42,
	KP_KEYLEN = 9,
}


[AllowDuplicates]
public enum CRYPT_KEY_FLAGS : uint32
{
	CRYPT_EXPORTABLE = 1,
	CRYPT_USER_PROTECTED = 2,
	CRYPT_ARCHIVABLE = 16384,
	CRYPT_CREATE_IV = 512,
	CRYPT_CREATE_SALT = 4,
	CRYPT_DATA_KEY = 2048,
	CRYPT_FORCE_KEY_PROTECTION_HIGH = 32768,
	CRYPT_KEK = 1024,
	CRYPT_INITIATOR = 64,
	CRYPT_NO_SALT = 16,
	CRYPT_ONLINE = 128,
	CRYPT_PREGEN = 64,
	CRYPT_RECIPIENT = 16,
	CRYPT_SF = 256,
	CRYPT_SGCKEY = 8192,
	CRYPT_VOLATILE = 4096,
	CRYPT_MACHINE_KEYSET = 32,
	CRYPT_USER_KEYSET = 4096,
	PKCS12_PREFER_CNG_KSP = 256,
	PKCS12_ALWAYS_CNG_KSP = 512,
	PKCS12_ALLOW_OVERWRITE_KEY = 16384,
	PKCS12_NO_PERSIST_KEY = 32768,
	PKCS12_INCLUDE_EXTENDED_PROPERTIES = 16,
	CRYPT_OAEP = 64,
	CRYPT_BLOB_VER3 = 128,
	CRYPT_DESTROYKEY = 4,
	CRYPT_SSL2_FALLBACK = 2,
	CRYPT_Y_ONLY = 1,
	CRYPT_IPSEC_HMAC_KEY = 256,
	CERT_SET_KEY_PROV_HANDLE_PROP_ID = 1,
	CERT_SET_KEY_CONTEXT_PROP_ID = 1,
}


[AllowDuplicates]
public enum CRYPT_MSG_TYPE : uint32
{
	CMSG_DATA = 1,
	CMSG_SIGNED = 2,
	CMSG_ENVELOPED = 3,
	CMSG_SIGNED_AND_ENVELOPED = 4,
	CMSG_HASHED = 5,
}


[AllowDuplicates]
public enum CERT_OPEN_STORE_FLAGS : uint32
{
	CERT_STORE_BACKUP_RESTORE_FLAG = 2048,
	CERT_STORE_CREATE_NEW_FLAG = 8192,
	CERT_STORE_DEFER_CLOSE_UNTIL_LAST_FREE_FLAG = 4,
	CERT_STORE_DELETE_FLAG = 16,
	CERT_STORE_ENUM_ARCHIVED_FLAG = 512,
	CERT_STORE_MAXIMUM_ALLOWED_FLAG = 4096,
	CERT_STORE_NO_CRYPT_RELEASE_FLAG = 1,
	CERT_STORE_OPEN_EXISTING_FLAG = 16384,
	CERT_STORE_READONLY_FLAG = 32768,
	CERT_STORE_SET_LOCALIZED_NAME_FLAG = 2,
	CERT_STORE_SHARE_CONTEXT_FLAG = 128,
	CERT_STORE_UPDATE_KEYID_FLAG = 1024,
}


[AllowDuplicates]
public enum CRYPT_DEFAULT_CONTEXT_FLAGS : uint32
{
	CRYPT_DEFAULT_CONTEXT_AUTO_RELEASE_FLAG = 1,
	CRYPT_DEFAULT_CONTEXT_PROCESS_FLAG = 2,
}


[AllowDuplicates]
public enum CRYPT_VERIFY_CERT_FLAGS : uint32
{
	CRYPT_VERIFY_CERT_SIGN_DISABLE_MD2_MD4_FLAG = 1,
	CRYPT_VERIFY_CERT_SIGN_SET_STRONG_PROPERTIES_FLAG = 2,
	CRYPT_VERIFY_CERT_SIGN_RETURN_STRONG_PROPERTIES_FLAG = 4,
}


[AllowDuplicates]
public enum CRYPT_SET_HASH_PARAM : uint32
{
	HP_HMAC_INFO = 5,
	HP_HASHVAL = 2,
}


[AllowDuplicates]
public enum CERT_SYSTEM_STORE_FLAGS : uint32
{
	CERT_SYSTEM_STORE_LOCATION_MASK = 16711680,
	CERT_SYSTEM_STORE_RELOCATE_FLAG = 2147483648,
}


[AllowDuplicates]
public enum CERT_CREATE_SELFSIGN_FLAGS : uint32
{
	CERT_CREATE_SELFSIGN_NO_KEY_INFO = 2,
	CERT_CREATE_SELFSIGN_NO_SIGN = 1,
}


[AllowDuplicates]
public enum CRYPT_DEFAULT_CONTEXT_TYPE : uint32
{
	CRYPT_DEFAULT_CONTEXT_CERT_SIGN_OID = 1,
	CRYPT_DEFAULT_CONTEXT_MULTI_CERT_SIGN_OID = 2,
}


[AllowDuplicates]
public enum BCRYPT_RESOLVE_PROVIDERS_FLAGS : uint32
{
	CRYPT_ALL_FUNCTIONS = 1,
	CRYPT_ALL_PROVIDERS = 2,
}


[AllowDuplicates]
public enum CERT_FIND_TYPE : uint32
{
	CTL_FIND_ANY = 0,
	CTL_FIND_SHA1_HASH = 1,
	CTL_FIND_MD5_HASH = 2,
	CTL_FIND_USAGE = 3,
	CTL_FIND_SAME_USAGE_FLAG = 1,
	CTL_FIND_EXISTING = 5,
	CTL_FIND_SUBJECT = 4,
}


[AllowDuplicates]
public enum CRYPT_FIND_FLAGS : uint32
{
	CRYPT_FIND_USER_KEYSET_FLAG = 1,
	CRYPT_FIND_MACHINE_KEYSET_FLAG = 2,
	CRYPT_FIND_SILENT_KEYSET_FLAG = 64,
}


[AllowDuplicates]
public enum CRYPT_IMAGE_REF_FLAGS : uint32
{
	CRYPT_MIN_DEPENDENCIES = 1,
	CRYPT_PROCESS_ISOLATE = 65536,
}


[AllowDuplicates]
public enum CERT_REVOCATION_STATUS_REASON : uint32
{
	CRL_REASON_UNSPECIFIED = 0,
	CRL_REASON_KEY_COMPROMISE = 1,
	CRL_REASON_CA_COMPROMISE = 2,
	CRL_REASON_AFFILIATION_CHANGED = 3,
	CRL_REASON_SUPERSEDED = 4,
	CRL_REASON_CESSATION_OF_OPERATION = 5,
	CRL_REASON_CERTIFICATE_HOLD = 6,
	CRL_REASON_REMOVE_FROM_CRL = 8,
}


[AllowDuplicates]
public enum CERT_ROOT_PROGRAM_FLAGS : uint32
{
	CERT_ROOT_PROGRAM_FLAG_LSC = 64,
	CERT_ROOT_PROGRAM_FLAG_ORG = 128,
	CERT_ROOT_PROGRAM_FLAG_SUBJECT_LOGO = 32,
}


[AllowDuplicates]
public enum CRYPT_XML_KEY_VALUE_TYPE : uint32
{
	CRYPT_XML_KEY_VALUE_TYPE_DSA = 1,
	CRYPT_XML_KEY_VALUE_TYPE_RSA = 2,
	CRYPT_XML_KEY_VALUE_TYPE_ECDSA = 3,
	CRYPT_XML_KEY_VALUE_TYPE_CUSTOM = 4,
}


[AllowDuplicates]
public enum CERT_LOGOTYPE_CHOICE : uint32
{
	CERT_LOGOTYPE_NO_IMAGE_RESOLUTION_CHOICE = 0,
	CERT_LOGOTYPE_BITS_IMAGE_RESOLUTION_CHOICE = 1,
	CERT_LOGOTYPE_TABLE_SIZE_IMAGE_RESOLUTION_CHOICE = 2,
}


[AllowDuplicates]
public enum CMSG_KEY_AGREE_OPTION : uint32
{
	CMSG_KEY_AGREE_EPHEMERAL_KEY_CHOICE = 1,
	CMSG_KEY_AGREE_STATIC_KEY_CHOICE = 2,
}


[AllowDuplicates]
public enum CERT_LOGOTYPE_OPTION : uint32
{
	CERT_LOGOTYPE_DIRECT_INFO_CHOICE = 1,
	CERT_LOGOTYPE_INDIRECT_INFO_CHOICE = 2,
}


[AllowDuplicates]
public enum CERT_STORE_PROV_FLAGS : uint32
{
	CERT_STORE_PROV_EXTERNAL_FLAG = 1,
	CERT_STORE_PROV_DELETED_FLAG = 2,
	CERT_STORE_PROV_NO_PERSIST_FLAG = 4,
	CERT_STORE_PROV_SYSTEM_STORE_FLAG = 8,
	CERT_STORE_PROV_LM_SYSTEM_STORE_FLAG = 16,
}


[AllowDuplicates]
public enum CMSG_KEY_AGREE_ORIGINATOR : uint32
{
	CMSG_KEY_AGREE_ORIGINATOR_CERT = 1,
	CMSG_KEY_AGREE_ORIGINATOR_PUBLIC_KEY = 2,
}


[AllowDuplicates]
public enum CRYPT_CONTEXT_CONFIG_FLAGS : uint32
{
	CRYPT_EXCLUSIVE = 1,
	CRYPT_OVERRIDE = 65536,
}


[AllowDuplicates]
public enum BCRYPT_DSA_MAGIC : uint32
{
	BCRYPT_DSA_PUBLIC_MAGIC = 1112560452,
	BCRYPT_DSA_PRIVATE_MAGIC = 1448104772,
}


[AllowDuplicates]
public enum CRYPT_XML_X509DATA_TYPE : uint32
{
	CRYPT_XML_X509DATA_TYPE_ISSUER_SERIAL = 1,
	CRYPT_XML_X509DATA_TYPE_SKI = 2,
	CRYPT_XML_X509DATA_TYPE_SUBJECT_NAME = 3,
	CRYPT_XML_X509DATA_TYPE_CERTIFICATE = 4,
	CRYPT_XML_X509DATA_TYPE_CRL = 5,
	CRYPT_XML_X509DATA_TYPE_CUSTOM = 6,
}


[AllowDuplicates]
public enum CERT_BIOMETRIC_DATA_TYPE : uint32
{
	CERT_BIOMETRIC_PREDEFINED_DATA_CHOICE = 1,
	CERT_BIOMETRIC_OID_DATA_CHOICE = 2,
}


[AllowDuplicates]
public enum CERT_CHAIN_POLICY_FLAGS : uint32
{
	CERT_CHAIN_POLICY_IGNORE_NOT_TIME_VALID_FLAG = 1,
	CERT_CHAIN_POLICY_IGNORE_CTL_NOT_TIME_VALID_FLAG = 2,
	CERT_CHAIN_POLICY_IGNORE_NOT_TIME_NESTED_FLAG = 4,
	CERT_CHAIN_POLICY_IGNORE_ALL_NOT_TIME_VALID_FLAGS = 7,
	CERT_CHAIN_POLICY_IGNORE_INVALID_BASIC_CONSTRAINTS_FLAG = 8,
	CERT_CHAIN_POLICY_ALLOW_UNKNOWN_CA_FLAG = 16,
	CERT_CHAIN_POLICY_IGNORE_WRONG_USAGE_FLAG = 32,
	CERT_CHAIN_POLICY_IGNORE_INVALID_NAME_FLAG = 64,
	CERT_CHAIN_POLICY_IGNORE_INVALID_POLICY_FLAG = 128,
	CERT_CHAIN_POLICY_IGNORE_END_REV_UNKNOWN_FLAG = 256,
	CERT_CHAIN_POLICY_IGNORE_CTL_SIGNER_REV_UNKNOWN_FLAG = 512,
	CERT_CHAIN_POLICY_IGNORE_CA_REV_UNKNOWN_FLAG = 1024,
	CERT_CHAIN_POLICY_IGNORE_ROOT_REV_UNKNOWN_FLAG = 2048,
	CERT_CHAIN_POLICY_IGNORE_ALL_REV_UNKNOWN_FLAGS = 3840,
	CERT_CHAIN_POLICY_ALLOW_TESTROOT_FLAG = 32768,
	CERT_CHAIN_POLICY_TRUST_TESTROOT_FLAG = 16384,
	CERT_CHAIN_POLICY_IGNORE_NOT_SUPPORTED_CRITICAL_EXT_FLAG = 8192,
	CERT_CHAIN_POLICY_IGNORE_PEER_TRUST_FLAG = 4096,
}


[AllowDuplicates]
public enum CERT_STRONG_SIGN_FLAGS : uint32
{
	CERT_STRONG_SIGN_ENABLE_CRL_CHECK = 1,
	CERT_STRONG_SIGN_ENABLE_OCSP_CHECK = 2,
}


[AllowDuplicates]
public enum CERT_LOGOTYPE_IMAGE_INFO_TYPE : uint32
{
	CERT_LOGOTYPE_GRAY_SCALE_IMAGE_INFO_CHOICE = 1,
	CERT_LOGOTYPE_COLOR_IMAGE_INFO_CHOICE = 2,
}


[AllowDuplicates]
public enum CRYPT_XML_STATUS_INFO_STATUS : uint32
{
	CRYPT_XML_STATUS_INTERNAL_REFERENCE = 1,
	CRYPT_XML_STATUS_KEY_AVAILABLE = 2,
	CRYPT_XML_STATUS_DIGESTING = 4,
	CRYPT_XML_STATUS_DIGEST_VALID = 8,
	CRYPT_XML_STATUS_SIGNATURE_VALID = 65536,
	CRYPT_XML_STATUS_OPENED_TO_ENCODE = 2147483648,
}


[AllowDuplicates]
public enum CRYPT_XML_TRANSFORM_FLAGS : uint32
{
	CRYPT_XML_TRANSFORM_ON_STREAM = 1,
	CRYPT_XML_TRANSFORM_ON_NODESET = 2,
	CRYPT_XML_TRANSFORM_URI_QUERY_STRING = 3,
}


[AllowDuplicates]
public enum CRYPT_XML_GROUP_ID : uint32
{
	CRYPT_XML_GROUP_ID_HASH = 1,
	CRYPT_XML_GROUP_ID_SIGN = 2,
}


[AllowDuplicates]
public enum CERT_SELECT_CRITERIA_TYPE : uint32
{
	CERT_SELECT_BY_ENHKEY_USAGE = 1,
	CERT_SELECT_BY_KEY_USAGE = 2,
	CERT_SELECT_BY_POLICY_OID = 3,
	CERT_SELECT_BY_PROV_NAME = 4,
	CERT_SELECT_BY_EXTENSION = 5,
	CERT_SELECT_BY_SUBJECT_HOST_NAME = 6,
	CERT_SELECT_BY_ISSUER_ATTR = 7,
	CERT_SELECT_BY_SUBJECT_ATTR = 8,
	CERT_SELECT_BY_ISSUER_NAME = 9,
	CERT_SELECT_BY_PUBLIC_KEY = 10,
	CERT_SELECT_BY_TLS_SIGNATURES = 11,
}


[AllowDuplicates]
public enum BCRYPT_RSAKEY_BLOB_MAGIC : uint32
{
	BCRYPT_RSAPUBLIC_MAGIC = 826364754,
	BCRYPT_RSAPRIVATE_MAGIC = 843141970,
	BCRYPT_RSAFULLPRIVATE_MAGIC = 859919186,
}


[AllowDuplicates]
public enum CRYPT_XML_KEYINFO_TYPE : uint32
{
	CRYPT_XML_KEYINFO_TYPE_KEYNAME = 1,
	CRYPT_XML_KEYINFO_TYPE_KEYVALUE = 2,
	CRYPT_XML_KEYINFO_TYPE_RETRIEVAL = 3,
	CRYPT_XML_KEYINFO_TYPE_X509DATA = 4,
	CRYPT_XML_KEYINFO_TYPE_CUSTOM = 5,
}


[AllowDuplicates]
public enum CRYPT_TIMESTAMP_VERSION : uint32
{
	TIMESTAMP_VERSION = 1,
}


[AllowDuplicates]
public enum CERT_ID_OPTION : uint32
{
	CERT_ID_ISSUER_SERIAL_NUMBER = 1,
	CERT_ID_KEY_IDENTIFIER = 2,
	CERT_ID_SHA1_HASH = 3,
}


[AllowDuplicates]
public enum HTTPSPOLICY_CALLBACK_DATA_AUTH_TYPE : uint32
{
	AUTHTYPE_CLIENT = 1,
	AUTHTYPE_SERVER = 2,
}


[AllowDuplicates]
public enum BCRYPT_DH_KEY_BLOB_MAGIC : uint32
{
	BCRYPT_DH_PUBLIC_MAGIC = 1112557636,
	BCRYPT_DH_PRIVATE_MAGIC = 1448101956,
}


[AllowDuplicates]
public enum CRYPT_XML_STATUS_ERROR_STATUS : uint32
{
	CRYPT_XML_STATUS_ERROR_NOT_RESOLVED = 1,
	CRYPT_XML_STATUS_ERROR_DIGEST_INVALID = 2,
	CRYPT_XML_STATUS_ERROR_NOT_SUPPORTED_ALGORITHM = 5,
	CRYPT_XML_STATUS_ERROR_NOT_SUPPORTED_TRANSFORM = 8,
	CRYPT_XML_STATUS_ERROR_SIGNATURE_INVALID = 65536,
	CRYPT_XML_STATUS_ERROR_KEYINFO_NOT_PARSED = 131072,
}


[AllowDuplicates]
public enum CRYPT_TIMESTAMP_RESPONSE_STATUS : uint32
{
	TIMESTAMP_STATUS_GRANTED = 0,
	TIMESTAMP_STATUS_GRANTED_WITH_MODS = 1,
	TIMESTAMP_STATUS_REJECTED = 2,
	TIMESTAMP_STATUS_WAITING = 3,
	TIMESTAMP_STATUS_REVOCATION_WARNING = 4,
	TIMESTAMP_STATUS_REVOKED = 5,
}


[AllowDuplicates]
public enum NCRYPT_ALGORITHM_NAME_CLASS : uint32
{
	NCRYPT_ASYMMETRIC_ENCRYPTION_INTERFACE = 3,
	NCRYPT_SECRET_AGREEMENT_INTERFACE = 4,
	NCRYPT_SIGNATURE_INTERFACE = 5,
}


[AllowDuplicates]
public enum ECC_CURVE_TYPE_ENUM : int32
{
	BCRYPT_ECC_PRIME_SHORT_WEIERSTRASS_CURVE = 1,
	BCRYPT_ECC_PRIME_TWISTED_EDWARDS_CURVE = 2,
	BCRYPT_ECC_PRIME_MONTGOMERY_CURVE = 3,
}


[AllowDuplicates]
public enum ECC_CURVE_ALG_ID_ENUM : int32
{
	BCRYPT_NO_CURVE_GENERATION_ALG_ID = 0,
}


[AllowDuplicates]
public enum HASHALGORITHM_ENUM : int32
{
	DSA_HASH_ALGORITHM_SHA1 = 0,
	DSA_HASH_ALGORITHM_SHA256 = 1,
	DSA_HASH_ALGORITHM_SHA512 = 2,
}


[AllowDuplicates]
public enum DSAFIPSVERSION_ENUM : int32
{
	DSA_FIPS186_2 = 0,
	DSA_FIPS186_3 = 1,
}


[AllowDuplicates]
public enum BCRYPT_HASH_OPERATION_TYPE : int32
{
	BCRYPT_HASH_OPERATION_HASH_DATA = 1,
	BCRYPT_HASH_OPERATION_FINISH_HASH = 2,
}


[AllowDuplicates]
public enum BCRYPT_MULTI_OPERATION_TYPE : int32
{
	BCRYPT_OPERATION_TYPE_HASH = 1,
}


[AllowDuplicates]
public enum CertKeyType : uint32
{
	KeyTypeOther = 0,
	KeyTypeVirtualSmartCard = 1,
	KeyTypePhysicalSmartCard = 2,
	KeyTypePassport = 3,
	KeyTypePassportRemote = 4,
	KeyTypePassportSmartCard = 5,
	KeyTypeHardware = 6,
	KeyTypeSoftware = 7,
	KeyTypeSelfSigned = 8,
}


[AllowDuplicates]
public enum CRYPT_XML_CHARSET : int32
{
	CRYPT_XML_CHARSET_AUTO = 0,
	CRYPT_XML_CHARSET_UTF8 = 1,
	CRYPT_XML_CHARSET_UTF16LE = 2,
	CRYPT_XML_CHARSET_UTF16BE = 3,
}


[AllowDuplicates]
public enum CRYPT_XML_PROPERTY_ID : int32
{
	CRYPT_XML_PROPERTY_MAX_HEAP_SIZE = 1,
	CRYPT_XML_PROPERTY_SIGNATURE_LOCATION = 2,
	CRYPT_XML_PROPERTY_MAX_SIGNATURES = 3,
	CRYPT_XML_PROPERTY_DOC_DECLARATION = 4,
	CRYPT_XML_PROPERTY_XML_OUTPUT_CHARSET = 5,
}


[AllowDuplicates]
public enum CRYPT_XML_KEYINFO_SPEC : int32
{
	CRYPT_XML_KEYINFO_SPEC_NONE = 0,
	CRYPT_XML_KEYINFO_SPEC_ENCODED = 1,
	CRYPT_XML_KEYINFO_SPEC_PARAM = 2,
}


[AllowDuplicates]
public enum HandleType : int32
{
	Asymmetric = 1,
	Symmetric = 2,
	Transform = 3,
	Hash = 4,
}


[AllowDuplicates]
public enum PaddingMode : int32
{
	None = 1,
	PKCS7 = 2,
	Zeros = 3,
	ANSIX923 = 4,
	ISO10126 = 5,
}


[AllowDuplicates]
public enum Direction : int32
{
	DirectionEncrypt = 1,
	DirectionDecrypt = 2,
}


[AllowDuplicates]
public enum CASetupProperty : int32
{
	ENUM_SETUPPROP_INVALID = -1,
	ENUM_SETUPPROP_CATYPE = 0,
	ENUM_SETUPPROP_CAKEYINFORMATION = 1,
	ENUM_SETUPPROP_INTERACTIVE = 2,
	ENUM_SETUPPROP_CANAME = 3,
	ENUM_SETUPPROP_CADSSUFFIX = 4,
	ENUM_SETUPPROP_VALIDITYPERIOD = 5,
	ENUM_SETUPPROP_VALIDITYPERIODUNIT = 6,
	ENUM_SETUPPROP_EXPIRATIONDATE = 7,
	ENUM_SETUPPROP_PRESERVEDATABASE = 8,
	ENUM_SETUPPROP_DATABASEDIRECTORY = 9,
	ENUM_SETUPPROP_LOGDIRECTORY = 10,
	ENUM_SETUPPROP_SHAREDFOLDER = 11,
	ENUM_SETUPPROP_PARENTCAMACHINE = 12,
	ENUM_SETUPPROP_PARENTCANAME = 13,
	ENUM_SETUPPROP_REQUESTFILE = 14,
	ENUM_SETUPPROP_WEBCAMACHINE = 15,
	ENUM_SETUPPROP_WEBCANAME = 16,
}


[AllowDuplicates]
public enum MSCEPSetupProperty : int32
{
	ENUM_CEPSETUPPROP_USELOCALSYSTEM = 0,
	ENUM_CEPSETUPPROP_USECHALLENGE = 1,
	ENUM_CEPSETUPPROP_RANAME_CN = 2,
	ENUM_CEPSETUPPROP_RANAME_EMAIL = 3,
	ENUM_CEPSETUPPROP_RANAME_COMPANY = 4,
	ENUM_CEPSETUPPROP_RANAME_DEPT = 5,
	ENUM_CEPSETUPPROP_RANAME_CITY = 6,
	ENUM_CEPSETUPPROP_RANAME_STATE = 7,
	ENUM_CEPSETUPPROP_RANAME_COUNTRY = 8,
	ENUM_CEPSETUPPROP_SIGNINGKEYINFORMATION = 9,
	ENUM_CEPSETUPPROP_EXCHANGEKEYINFORMATION = 10,
	ENUM_CEPSETUPPROP_CAINFORMATION = 11,
	ENUM_CEPSETUPPROP_MSCEPURL = 12,
	ENUM_CEPSETUPPROP_CHALLENGEURL = 13,
}


[AllowDuplicates]
public enum CESSetupProperty : int32
{
	ENUM_CESSETUPPROP_USE_IISAPPPOOLIDENTITY = 0,
	ENUM_CESSETUPPROP_CACONFIG = 1,
	ENUM_CESSETUPPROP_AUTHENTICATION = 2,
	ENUM_CESSETUPPROP_SSLCERTHASH = 3,
	ENUM_CESSETUPPROP_URL = 4,
	ENUM_CESSETUPPROP_RENEWALONLY = 5,
	ENUM_CESSETUPPROP_ALLOW_KEYBASED_RENEWAL = 6,
}


[AllowDuplicates]
public enum CEPSetupProperty : int32
{
	ENUM_CEPSETUPPROP_AUTHENTICATION = 0,
	ENUM_CEPSETUPPROP_SSLCERTHASH = 1,
	ENUM_CEPSETUPPROP_URL = 2,
	ENUM_CEPSETUPPROP_KEYBASED_RENEWAL = 3,
}

#endregion

#region Function Pointers
public function void* PFN_NCRYPT_ALLOC(uint cbSize);

public function void PFN_NCRYPT_FREE(void* pv);

public function BOOL PCRYPT_DECRYPT_PRIVATE_KEY_FUNC(CRYPT_ALGORITHM_IDENTIFIER Algorithm, CRYPTOAPI_BLOB EncryptedPrivateKey, uint8* pbClearTextKey, uint32* pcbClearTextKey, void* pVoidDecryptFunc);

public function BOOL PCRYPT_ENCRYPT_PRIVATE_KEY_FUNC(CRYPT_ALGORITHM_IDENTIFIER* pAlgorithm, CRYPTOAPI_BLOB* pClearTextPrivateKey, uint8* pbEncryptedKey, uint32* pcbEncryptedKey, void* pVoidEncryptFunc);

public function BOOL PCRYPT_RESOLVE_HCRYPTPROV_FUNC(CRYPT_PRIVATE_KEY_INFO* pPrivateKeyInfo, uint* phCryptProv, void* pVoidResolveFunc);

public function void* PFN_CRYPT_ALLOC(uint cbSize);

public function void PFN_CRYPT_FREE(void* pv);

public function BOOL PFN_CRYPT_ENUM_OID_FUNC(uint32 dwEncodingType, PSTR pszFuncName, PSTR pszOID, uint32 cValue, uint32* rgdwValueType, PWSTR* rgpwszValueName, uint8** rgpbValueData, uint32* rgcbValueData, void* pvArg);

public function BOOL PFN_CRYPT_ENUM_OID_INFO(CRYPT_OID_INFO* pInfo, void* pvArg);

public function BOOL PFN_CMSG_STREAM_OUTPUT(void* pvArg, uint8* pbData, uint32 cbData, BOOL fFinal);

public function void* PFN_CMSG_ALLOC(uint cb);

public function void PFN_CMSG_FREE(void* pv);

public function BOOL PFN_CMSG_GEN_ENCRYPT_KEY(uint* phCryptProv, CRYPT_ALGORITHM_IDENTIFIER* paiEncrypt, void* pvEncryptAuxInfo, CERT_PUBLIC_KEY_INFO* pPublicKeyInfo, PFN_CMSG_ALLOC pfnAlloc, uint* phEncryptKey, uint8** ppbEncryptParameters, uint32* pcbEncryptParameters);

public function BOOL PFN_CMSG_EXPORT_ENCRYPT_KEY(uint hCryptProv, uint hEncryptKey, CERT_PUBLIC_KEY_INFO* pPublicKeyInfo, uint8* pbData, uint32* pcbData);

public function BOOL PFN_CMSG_IMPORT_ENCRYPT_KEY(uint hCryptProv, uint32 dwKeySpec, CRYPT_ALGORITHM_IDENTIFIER* paiEncrypt, CRYPT_ALGORITHM_IDENTIFIER* paiPubKey, uint8* pbEncodedKey, uint32 cbEncodedKey, uint* phEncryptKey);

public function BOOL PFN_CMSG_GEN_CONTENT_ENCRYPT_KEY(CMSG_CONTENT_ENCRYPT_INFO* pContentEncryptInfo, uint32 dwFlags, void* pvReserved);

public function BOOL PFN_CMSG_EXPORT_KEY_TRANS(CMSG_CONTENT_ENCRYPT_INFO* pContentEncryptInfo, CMSG_KEY_TRANS_RECIPIENT_ENCODE_INFO* pKeyTransEncodeInfo, CMSG_KEY_TRANS_ENCRYPT_INFO* pKeyTransEncryptInfo, uint32 dwFlags, void* pvReserved);

public function BOOL PFN_CMSG_EXPORT_KEY_AGREE(CMSG_CONTENT_ENCRYPT_INFO* pContentEncryptInfo, CMSG_KEY_AGREE_RECIPIENT_ENCODE_INFO* pKeyAgreeEncodeInfo, CMSG_KEY_AGREE_ENCRYPT_INFO* pKeyAgreeEncryptInfo, uint32 dwFlags, void* pvReserved);

public function BOOL PFN_CMSG_EXPORT_MAIL_LIST(CMSG_CONTENT_ENCRYPT_INFO* pContentEncryptInfo, CMSG_MAIL_LIST_RECIPIENT_ENCODE_INFO* pMailListEncodeInfo, CMSG_MAIL_LIST_ENCRYPT_INFO* pMailListEncryptInfo, uint32 dwFlags, void* pvReserved);

public function BOOL PFN_CMSG_IMPORT_KEY_TRANS(CRYPT_ALGORITHM_IDENTIFIER* pContentEncryptionAlgorithm, CMSG_CTRL_KEY_TRANS_DECRYPT_PARA* pKeyTransDecryptPara, uint32 dwFlags, void* pvReserved, uint* phContentEncryptKey);

public function BOOL PFN_CMSG_IMPORT_KEY_AGREE(CRYPT_ALGORITHM_IDENTIFIER* pContentEncryptionAlgorithm, CMSG_CTRL_KEY_AGREE_DECRYPT_PARA* pKeyAgreeDecryptPara, uint32 dwFlags, void* pvReserved, uint* phContentEncryptKey);

public function BOOL PFN_CMSG_IMPORT_MAIL_LIST(CRYPT_ALGORITHM_IDENTIFIER* pContentEncryptionAlgorithm, CMSG_CTRL_MAIL_LIST_DECRYPT_PARA* pMailListDecryptPara, uint32 dwFlags, void* pvReserved, uint* phContentEncryptKey);

public function BOOL PFN_CMSG_CNG_IMPORT_KEY_TRANS(CMSG_CNG_CONTENT_DECRYPT_INFO* pCNGContentDecryptInfo, CMSG_CTRL_KEY_TRANS_DECRYPT_PARA* pKeyTransDecryptPara, uint32 dwFlags, void* pvReserved);

public function BOOL PFN_CMSG_CNG_IMPORT_KEY_AGREE(CMSG_CNG_CONTENT_DECRYPT_INFO* pCNGContentDecryptInfo, CMSG_CTRL_KEY_AGREE_DECRYPT_PARA* pKeyAgreeDecryptPara, uint32 dwFlags, void* pvReserved);

public function BOOL PFN_CMSG_CNG_IMPORT_CONTENT_ENCRYPT_KEY(CMSG_CNG_CONTENT_DECRYPT_INFO* pCNGContentDecryptInfo, uint32 dwFlags, void* pvReserved);

public function BOOL PFN_CERT_DLL_OPEN_STORE_PROV_FUNC(PSTR lpszStoreProvider, CERT_QUERY_ENCODING_TYPE dwEncodingType, HCRYPTPROV_LEGACY hCryptProv, CERT_OPEN_STORE_FLAGS dwFlags, void* pvPara, HCERTSTORE hCertStore, CERT_STORE_PROV_INFO* pStoreProvInfo);

public function void PFN_CERT_STORE_PROV_CLOSE(HCERTSTOREPROV hStoreProv, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_READ_CERT(HCERTSTOREPROV hStoreProv, CERT_CONTEXT* pStoreCertContext, uint32 dwFlags, CERT_CONTEXT** ppProvCertContext);

public function BOOL PFN_CERT_STORE_PROV_WRITE_CERT(HCERTSTOREPROV hStoreProv, CERT_CONTEXT* pCertContext, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_DELETE_CERT(HCERTSTOREPROV hStoreProv, CERT_CONTEXT* pCertContext, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_SET_CERT_PROPERTY(HCERTSTOREPROV hStoreProv, CERT_CONTEXT* pCertContext, uint32 dwPropId, uint32 dwFlags, void* pvData);

public function BOOL PFN_CERT_STORE_PROV_READ_CRL(HCERTSTOREPROV hStoreProv, CRL_CONTEXT* pStoreCrlContext, uint32 dwFlags, CRL_CONTEXT** ppProvCrlContext);

public function BOOL PFN_CERT_STORE_PROV_WRITE_CRL(HCERTSTOREPROV hStoreProv, CRL_CONTEXT* pCrlContext, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_DELETE_CRL(HCERTSTOREPROV hStoreProv, CRL_CONTEXT* pCrlContext, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_SET_CRL_PROPERTY(HCERTSTOREPROV hStoreProv, CRL_CONTEXT* pCrlContext, uint32 dwPropId, uint32 dwFlags, void* pvData);

public function BOOL PFN_CERT_STORE_PROV_READ_CTL(HCERTSTOREPROV hStoreProv, CTL_CONTEXT* pStoreCtlContext, uint32 dwFlags, CTL_CONTEXT** ppProvCtlContext);

public function BOOL PFN_CERT_STORE_PROV_WRITE_CTL(HCERTSTOREPROV hStoreProv, CTL_CONTEXT* pCtlContext, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_DELETE_CTL(HCERTSTOREPROV hStoreProv, CTL_CONTEXT* pCtlContext, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_SET_CTL_PROPERTY(HCERTSTOREPROV hStoreProv, CTL_CONTEXT* pCtlContext, uint32 dwPropId, uint32 dwFlags, void* pvData);

public function BOOL PFN_CERT_STORE_PROV_CONTROL(HCERTSTOREPROV hStoreProv, uint32 dwFlags, uint32 dwCtrlType, void* pvCtrlPara);

public function BOOL PFN_CERT_STORE_PROV_FIND_CERT(HCERTSTOREPROV hStoreProv, CERT_STORE_PROV_FIND_INFO* pFindInfo, CERT_CONTEXT* pPrevCertContext, uint32 dwFlags, void** ppvStoreProvFindInfo, CERT_CONTEXT** ppProvCertContext);

public function BOOL PFN_CERT_STORE_PROV_FREE_FIND_CERT(HCERTSTOREPROV hStoreProv, CERT_CONTEXT* pCertContext, void* pvStoreProvFindInfo, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_GET_CERT_PROPERTY(HCERTSTOREPROV hStoreProv, CERT_CONTEXT* pCertContext, uint32 dwPropId, uint32 dwFlags, void* pvData, uint32* pcbData);

public function BOOL PFN_CERT_STORE_PROV_FIND_CRL(HCERTSTOREPROV hStoreProv, CERT_STORE_PROV_FIND_INFO* pFindInfo, CRL_CONTEXT* pPrevCrlContext, uint32 dwFlags, void** ppvStoreProvFindInfo, CRL_CONTEXT** ppProvCrlContext);

public function BOOL PFN_CERT_STORE_PROV_FREE_FIND_CRL(HCERTSTOREPROV hStoreProv, CRL_CONTEXT* pCrlContext, void* pvStoreProvFindInfo, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_GET_CRL_PROPERTY(HCERTSTOREPROV hStoreProv, CRL_CONTEXT* pCrlContext, uint32 dwPropId, uint32 dwFlags, void* pvData, uint32* pcbData);

public function BOOL PFN_CERT_STORE_PROV_FIND_CTL(HCERTSTOREPROV hStoreProv, CERT_STORE_PROV_FIND_INFO* pFindInfo, CTL_CONTEXT* pPrevCtlContext, uint32 dwFlags, void** ppvStoreProvFindInfo, CTL_CONTEXT** ppProvCtlContext);

public function BOOL PFN_CERT_STORE_PROV_FREE_FIND_CTL(HCERTSTOREPROV hStoreProv, CTL_CONTEXT* pCtlContext, void* pvStoreProvFindInfo, uint32 dwFlags);

public function BOOL PFN_CERT_STORE_PROV_GET_CTL_PROPERTY(HCERTSTOREPROV hStoreProv, CTL_CONTEXT* pCtlContext, uint32 dwPropId, uint32 dwFlags, void* pvData, uint32* pcbData);

public function BOOL PFN_CERT_CREATE_CONTEXT_SORT_FUNC(uint32 cbTotalEncoded, uint32 cbRemainEncoded, uint32 cEntry, void* pvSort);

public function BOOL PFN_CERT_ENUM_SYSTEM_STORE_LOCATION(PWSTR pwszStoreLocation, uint32 dwFlags, void* pvReserved, void* pvArg);

public function BOOL PFN_CERT_ENUM_SYSTEM_STORE(void* pvSystemStore, CERT_SYSTEM_STORE_FLAGS dwFlags, CERT_SYSTEM_STORE_INFO* pStoreInfo, void* pvReserved, void* pvArg);

public function BOOL PFN_CERT_ENUM_PHYSICAL_STORE(void* pvSystemStore, uint32 dwFlags, PWSTR pwszStoreName, CERT_PHYSICAL_STORE_INFO* pStoreInfo, void* pvReserved, void* pvArg);

public function BOOL PFN_CRYPT_EXTRACT_ENCODED_SIGNATURE_PARAMETERS_FUNC(uint32 dwCertEncodingType, CRYPT_ALGORITHM_IDENTIFIER* pSignatureAlgorithm, void** ppvDecodedSignPara, PWSTR* ppwszCNGHashAlgid);

public function BOOL PFN_CRYPT_SIGN_AND_ENCODE_HASH_FUNC(NCRYPT_KEY_HANDLE hKey, uint32 dwCertEncodingType, CRYPT_ALGORITHM_IDENTIFIER* pSignatureAlgorithm, void* pvDecodedSignPara, PWSTR pwszCNGPubKeyAlgid, PWSTR pwszCNGHashAlgid, uint8* pbComputedHash, uint32 cbComputedHash, uint8* pbSignature, uint32* pcbSignature);

public function BOOL PFN_CRYPT_VERIFY_ENCODED_SIGNATURE_FUNC(uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pPubKeyInfo, CRYPT_ALGORITHM_IDENTIFIER* pSignatureAlgorithm, void* pvDecodedSignPara, PWSTR pwszCNGPubKeyAlgid, PWSTR pwszCNGHashAlgid, uint8* pbComputedHash, uint32 cbComputedHash, uint8* pbSignature, uint32 cbSignature);

public function BOOL PFN_CRYPT_EXPORT_PUBLIC_KEY_INFO_EX2_FUNC(NCRYPT_KEY_HANDLE hNCryptKey, uint32 dwCertEncodingType, PSTR pszPublicKeyObjId, uint32 dwFlags, void* pvAuxInfo, CERT_PUBLIC_KEY_INFO* pInfo, uint32* pcbInfo);

public function BOOL PFN_CRYPT_EXPORT_PUBLIC_KEY_INFO_FROM_BCRYPT_HANDLE_FUNC(BCRYPT_KEY_HANDLE hBCryptKey, uint32 dwCertEncodingType, PSTR pszPublicKeyObjId, uint32 dwFlags, void* pvAuxInfo, CERT_PUBLIC_KEY_INFO* pInfo, uint32* pcbInfo);

public function BOOL PFN_IMPORT_PUBLIC_KEY_INFO_EX2_FUNC(uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pInfo, uint32 dwFlags, void* pvAuxInfo, BCRYPT_KEY_HANDLE* phKey);

public function BOOL PFN_IMPORT_PRIV_KEY_FUNC(uint hCryptProv, CRYPT_PRIVATE_KEY_INFO* pPrivateKeyInfo, uint32 dwFlags, void* pvAuxInfo);

public function BOOL PFN_EXPORT_PRIV_KEY_FUNC(uint hCryptProv, uint32 dwKeySpec, PSTR pszPrivateKeyObjId, uint32 dwFlags, void* pvAuxInfo, CRYPT_PRIVATE_KEY_INFO* pPrivateKeyInfo, uint32* pcbPrivateKeyInfo);

public function CERT_CONTEXT* PFN_CRYPT_GET_SIGNER_CERTIFICATE(void* pvGetArg, uint32 dwCertEncodingType, CERT_INFO* pSignerId, HCERTSTORE hMsgCertStore);

public function void PFN_CRYPT_ASYNC_PARAM_FREE_FUNC(PSTR pszParamOid, void* pvParam);

public function void PFN_FREE_ENCODED_OBJECT_FUNC(PSTR pszObjectOid, CRYPT_BLOB_ARRAY* pObject, void* pvFreeContext);

public function BOOL PFN_CRYPT_CANCEL_RETRIEVAL(uint32 dwFlags, void* pvArg);

public function void PFN_CRYPT_ASYNC_RETRIEVAL_COMPLETION_FUNC(void* pvCompletion, uint32 dwCompletionCode, PSTR pszUrl, PSTR pszObjectOid, void* pvObject);

public function BOOL PFN_CANCEL_ASYNC_RETRIEVAL_FUNC(HCRYPTASYNC hAsyncRetrieve);

public function BOOL PFN_CRYPT_ENUM_KEYID_PROP(CRYPTOAPI_BLOB* pKeyIdentifier, uint32 dwFlags, void* pvReserved, void* pvArg, uint32 cProp, uint32* rgdwPropId, void** rgpvData, uint32* rgcbData);

public function BOOL PFN_CERT_CHAIN_FIND_BY_ISSUER_CALLBACK(CERT_CONTEXT* pCert, void* pvFindArg);

public function void PFN_CERT_SERVER_OCSP_RESPONSE_UPDATE_CALLBACK(CERT_CHAIN_CONTEXT* pChainContext, CERT_SERVER_OCSP_RESPONSE_CONTEXT* pServerOcspResponseContext, CRL_CONTEXT* pNewCrlContext, CRL_CONTEXT* pPrevCrlContext, void* pvArg, uint32 dwWriteOcspFileError);

public function BOOL PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FLUSH(void* pContext, CRYPTOAPI_BLOB** rgIdentifierOrNameList, uint32 dwIdentifierOrNameListCount);

public function BOOL PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_GET(void* pPluginContext, CRYPTOAPI_BLOB* pIdentifier, uint32 dwNameType, CRYPTOAPI_BLOB* pNameBlob, uint8** ppbContent, uint32* pcbContent, PWSTR* ppwszPassword, CRYPTOAPI_BLOB** ppIdentifier);

public function void PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_RELEASE(CRYPT_OBJECT_LOCATOR_RELEASE_REASON dwReason, void* pPluginContext);

public function void PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FREE_PASSWORD(void* pPluginContext, PWSTR pwszPassword);

public function void PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FREE(void* pPluginContext, uint8* pbData);

public function void PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FREE_IDENTIFIER(void* pPluginContext, CRYPTOAPI_BLOB* pIdentifier);

public function BOOL PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_INITIALIZE(PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FLUSH pfnFlush, void* pContext, uint32* pdwExpectedObjectCount, CRYPT_OBJECT_LOCATOR_PROVIDER_TABLE** ppFuncTable, void** ppPluginContext);

public function BOOL PFN_CERT_IS_WEAK_HASH(uint32 dwHashUseType, PWSTR pwszCNGHashAlgid, uint32 dwChainFlags, CERT_CHAIN_CONTEXT* pSignerChainContext, FILETIME* pTimeStamp, PWSTR pwszFileName);

public function HRESULT PFNCryptStreamOutputCallback(void* pvCallbackCtxt, uint8* pbData, uint cbData, BOOL fFinal);

public function HRESULT PFNCryptStreamOutputCallbackEx(void* pvCallbackCtxt, uint8* pbData, uint cbData, NCRYPT_DESCRIPTOR_HANDLE hDescriptor, BOOL fFinal);

public function HRESULT PFN_CRYPT_XML_WRITE_CALLBACK(void* pvCallbackState, uint8* pbData, uint32 cbData);

public function HRESULT PFN_CRYPT_XML_DATA_PROVIDER_READ(void* pvCallbackState, uint8* pbData, uint32 cbData, uint32* pcbRead);

public function HRESULT PFN_CRYPT_XML_DATA_PROVIDER_CLOSE(void* pvCallbackState);

public function HRESULT PFN_CRYPT_XML_CREATE_TRANSFORM(CRYPT_XML_ALGORITHM* pTransform, CRYPT_XML_DATA_PROVIDER* pProviderIn, CRYPT_XML_DATA_PROVIDER* pProviderOut);

public function BOOL PFN_CRYPT_XML_ENUM_ALG_INFO(CRYPT_XML_ALGORITHM_INFO* pInfo, void* pvArg);

public function HRESULT CryptXmlDllGetInterface(uint32 dwFlags, CRYPT_XML_ALGORITHM_INFO* pMethod, CRYPT_XML_CRYPTOGRAPHIC_INTERFACE* pInterface);

public function HRESULT CryptXmlDllEncodeAlgorithm(CRYPT_XML_ALGORITHM_INFO* pAlgInfo, CRYPT_XML_CHARSET dwCharset, void* pvCallbackState, PFN_CRYPT_XML_WRITE_CALLBACK pfnWrite);

public function HRESULT CryptXmlDllCreateDigest(CRYPT_XML_ALGORITHM* pDigestMethod, uint32* pcbSize, void** phDigest);

public function HRESULT CryptXmlDllDigestData(void* hDigest, uint8* pbData, uint32 cbData);

public function HRESULT CryptXmlDllFinalizeDigest(void* hDigest, uint8* pbDigest, uint32 cbDigest);

public function HRESULT CryptXmlDllCloseDigest(void* hDigest);

public function HRESULT CryptXmlDllSignData(CRYPT_XML_ALGORITHM* pSignatureMethod, HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hCryptProvOrNCryptKey, uint32 dwKeySpec, uint8* pbInput, uint32 cbInput, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult);

public function HRESULT CryptXmlDllVerifySignature(CRYPT_XML_ALGORITHM* pSignatureMethod, BCRYPT_KEY_HANDLE hKey, uint8* pbInput, uint32 cbInput, uint8* pbSignature, uint32 cbSignature);

public function HRESULT CryptXmlDllGetAlgorithmInfo(CRYPT_XML_ALGORITHM* pXmlAlgorithm, CRYPT_XML_ALGORITHM_INFO** ppAlgInfo);

public function HRESULT CryptXmlDllEncodeKeyValue(NCRYPT_KEY_HANDLE hKey, CRYPT_XML_CHARSET dwCharset, void* pvCallbackState, PFN_CRYPT_XML_WRITE_CALLBACK pfnWrite);

public function HRESULT CryptXmlDllCreateKey(CRYPT_XML_BLOB* pEncoded, BCRYPT_KEY_HANDLE* phKey);

#endregion

#region Structs
[CRepr]
public struct CMS_KEY_INFO
{
	public uint32 dwVersion;
	public uint32 Algid;
	public uint8* pbOID;
	public uint32 cbOID;
}

[CRepr]
public struct HMAC_INFO
{
	public uint32 HashAlgid;
	public uint8* pbInnerString;
	public uint32 cbInnerString;
	public uint8* pbOuterString;
	public uint32 cbOuterString;
}

[CRepr]
public struct SCHANNEL_ALG
{
	public uint32 dwUse;
	public uint32 Algid;
	public uint32 cBits;
	public uint32 dwFlags;
	public uint32 dwReserved;
}

[CRepr]
public struct PROV_ENUMALGS
{
	public uint32 aiAlgid;
	public uint32 dwBitLen;
	public uint32 dwNameLen;
	public CHAR[20] szName;
}

[CRepr]
public struct PROV_ENUMALGS_EX
{
	public uint32 aiAlgid;
	public uint32 dwDefaultLen;
	public uint32 dwMinLen;
	public uint32 dwMaxLen;
	public uint32 dwProtocols;
	public uint32 dwNameLen;
	public CHAR[20] szName;
	public uint32 dwLongNameLen;
	public CHAR[40] szLongName;
}

[CRepr]
public struct PUBLICKEYSTRUC
{
	public uint8 bType;
	public uint8 bVersion;
	public uint16 reserved;
	public uint32 aiKeyAlg;
}

[CRepr]
public struct RSAPUBKEY
{
	public uint32 magic;
	public uint32 bitlen;
	public uint32 pubexp;
}

[CRepr]
public struct PUBKEY
{
	public uint32 magic;
	public uint32 bitlen;
}

[CRepr]
public struct DSSSEED
{
	public uint32 counter;
	public uint8[20] seed;
}

[CRepr]
public struct PUBKEYVER3
{
	public uint32 magic;
	public uint32 bitlenP;
	public uint32 bitlenQ;
	public uint32 bitlenJ;
	public DSSSEED DSSSeed;
}

[CRepr]
public struct PRIVKEYVER3
{
	public uint32 magic;
	public uint32 bitlenP;
	public uint32 bitlenQ;
	public uint32 bitlenJ;
	public uint32 bitlenX;
	public DSSSEED DSSSeed;
}

[CRepr]
public struct KEY_TYPE_SUBTYPE
{
	public uint32 dwKeySpec;
	public Guid Type;
	public Guid Subtype;
}

[CRepr]
public struct CERT_FORTEZZA_DATA_PROP
{
	public uint8[8] SerialNumber;
	public int32 CertIndex;
	public uint8[36] CertLabel;
}

[CRepr]
public struct CRYPT_RC4_KEY_STATE
{
	public uint8[16] Key;
	public uint8[256] SBox;
	public uint8 i;
	public uint8 j;
}

[CRepr]
public struct CRYPT_DES_KEY_STATE
{
	public uint8[8] Key;
	public uint8[8] IV;
	public uint8[8] Feedback;
}

[CRepr]
public struct CRYPT_3DES_KEY_STATE
{
	public uint8[24] Key;
	public uint8[8] IV;
	public uint8[8] Feedback;
}

[CRepr]
public struct CRYPT_AES_128_KEY_STATE
{
	public uint8[16] Key;
	public uint8[16] IV;
	public uint8[176] EncryptionState;
	public uint8[176] DecryptionState;
	public uint8[16] Feedback;
}

[CRepr]
public struct CRYPT_AES_256_KEY_STATE
{
	public uint8[32] Key;
	public uint8[16] IV;
	public uint8[240] EncryptionState;
	public uint8[240] DecryptionState;
	public uint8[16] Feedback;
}

[CRepr]
public struct CRYPTOAPI_BLOB
{
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct CMS_DH_KEY_INFO
{
	public uint32 dwVersion;
	public uint32 Algid;
	public PSTR pszContentEncObjId;
	public CRYPTOAPI_BLOB PubInfo;
	public void* pReserved;
}

[CRepr]
public struct BCRYPT_KEY_LENGTHS_STRUCT
{
	public uint32 dwMinLength;
	public uint32 dwMaxLength;
	public uint32 dwIncrement;
}

[CRepr]
public struct BCRYPT_OID
{
	public uint32 cbOID;
	public uint8* pbOID;
}

[CRepr]
public struct BCRYPT_OID_LIST
{
	public uint32 dwOIDCount;
	public BCRYPT_OID* pOIDs;
}

[CRepr]
public struct BCRYPT_PKCS1_PADDING_INFO
{
	public PWSTR pszAlgId;
}

[CRepr]
public struct BCRYPT_PSS_PADDING_INFO
{
	public PWSTR pszAlgId;
	public uint32 cbSalt;
}

[CRepr]
public struct BCRYPT_OAEP_PADDING_INFO
{
	public PWSTR pszAlgId;
	public uint8* pbLabel;
	public uint32 cbLabel;
}

[CRepr]
public struct BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO
{
	public uint32 cbSize;
	public uint32 dwInfoVersion;
	public uint8* pbNonce;
	public uint32 cbNonce;
	public uint8* pbAuthData;
	public uint32 cbAuthData;
	public uint8* pbTag;
	public uint32 cbTag;
	public uint8* pbMacContext;
	public uint32 cbMacContext;
	public uint32 cbAAD;
	public uint64 cbData;
	public uint32 dwFlags;
}

[CRepr]
public struct BCryptBuffer
{
	public uint32 cbBuffer;
	public uint32 BufferType;
	public void* pvBuffer;
}

[CRepr]
public struct BCryptBufferDesc
{
	public uint32 ulVersion;
	public uint32 cBuffers;
	public BCryptBuffer* pBuffers;
}

[CRepr]
public struct BCRYPT_KEY_BLOB
{
	public uint32 Magic;
}

[CRepr]
public struct BCRYPT_RSAKEY_BLOB
{
	public BCRYPT_RSAKEY_BLOB_MAGIC Magic;
	public uint32 BitLength;
	public uint32 cbPublicExp;
	public uint32 cbModulus;
	public uint32 cbPrime1;
	public uint32 cbPrime2;
}

[CRepr]
public struct BCRYPT_ECCKEY_BLOB
{
	public uint32 dwMagic;
	public uint32 cbKey;
}

[CRepr]
public struct SSL_ECCKEY_BLOB
{
	public uint32 dwCurveType;
	public uint32 cbKey;
}

[CRepr]
public struct BCRYPT_ECCFULLKEY_BLOB
{
	public uint32 dwMagic;
	public uint32 dwVersion;
	public ECC_CURVE_TYPE_ENUM dwCurveType;
	public ECC_CURVE_ALG_ID_ENUM dwCurveGenerationAlgId;
	public uint32 cbFieldLength;
	public uint32 cbSubgroupOrder;
	public uint32 cbCofactor;
	public uint32 cbSeed;
}

[CRepr]
public struct BCRYPT_DH_KEY_BLOB
{
	public BCRYPT_DH_KEY_BLOB_MAGIC dwMagic;
	public uint32 cbKey;
}

[CRepr]
public struct BCRYPT_DH_PARAMETER_HEADER
{
	public uint32 cbLength;
	public uint32 dwMagic;
	public uint32 cbKeyLength;
}

[CRepr]
public struct BCRYPT_DSA_KEY_BLOB
{
	public BCRYPT_DSA_MAGIC dwMagic;
	public uint32 cbKey;
	public uint8[4] Count;
	public uint8[20] Seed;
	public uint8[20] q;
}

[CRepr]
public struct BCRYPT_DSA_KEY_BLOB_V2
{
	public BCRYPT_DSA_MAGIC dwMagic;
	public uint32 cbKey;
	public HASHALGORITHM_ENUM hashAlgorithm;
	public DSAFIPSVERSION_ENUM standardVersion;
	public uint32 cbSeedLength;
	public uint32 cbGroupSize;
	public uint8[4] Count;
}

[CRepr]
public struct BCRYPT_KEY_DATA_BLOB_HEADER
{
	public uint32 dwMagic;
	public uint32 dwVersion;
	public uint32 cbKeyData;
}

[CRepr]
public struct BCRYPT_DSA_PARAMETER_HEADER
{
	public uint32 cbLength;
	public uint32 dwMagic;
	public uint32 cbKeyLength;
	public uint8[4] Count;
	public uint8[20] Seed;
	public uint8[20] q;
}

[CRepr]
public struct BCRYPT_DSA_PARAMETER_HEADER_V2
{
	public uint32 cbLength;
	public uint32 dwMagic;
	public uint32 cbKeyLength;
	public HASHALGORITHM_ENUM hashAlgorithm;
	public DSAFIPSVERSION_ENUM standardVersion;
	public uint32 cbSeedLength;
	public uint32 cbGroupSize;
	public uint8[4] Count;
}

[CRepr]
public struct BCRYPT_ECC_CURVE_NAMES
{
	public uint32 dwEccCurveNames;
	public PWSTR* pEccCurveNames;
}

[CRepr]
public struct BCRYPT_MULTI_HASH_OPERATION
{
	public uint32 iHash;
	public BCRYPT_HASH_OPERATION_TYPE hashOperation;
	public uint8* pbBuffer;
	public uint32 cbBuffer;
}

[CRepr]
public struct BCRYPT_MULTI_OBJECT_LENGTH_STRUCT
{
	public uint32 cbPerObject;
	public uint32 cbPerElement;
}

[CRepr]
public struct BCRYPT_ALGORITHM_IDENTIFIER
{
	public PWSTR pszName;
	public uint32 dwClass;
	public uint32 dwFlags;
}

[CRepr]
public struct BCRYPT_PROVIDER_NAME
{
	public PWSTR pszProviderName;
}

[CRepr]
public struct BCRYPT_INTERFACE_VERSION
{
	public uint16 MajorVersion;
	public uint16 MinorVersion;
}

[CRepr]
public struct CRYPT_INTERFACE_REG
{
	public BCRYPT_INTERFACE dwInterface;
	public BCRYPT_TABLE dwFlags;
	public uint32 cFunctions;
	public PWSTR* rgpszFunctions;
}

[CRepr]
public struct CRYPT_IMAGE_REG
{
	public PWSTR pszImage;
	public uint32 cInterfaces;
	public CRYPT_INTERFACE_REG** rgpInterfaces;
}

[CRepr]
public struct CRYPT_PROVIDER_REG
{
	public uint32 cAliases;
	public PWSTR* rgpszAliases;
	public CRYPT_IMAGE_REG* pUM;
	public CRYPT_IMAGE_REG* pKM;
}

[CRepr]
public struct CRYPT_PROVIDERS
{
	public uint32 cProviders;
	public PWSTR* rgpszProviders;
}

[CRepr]
public struct CRYPT_CONTEXT_CONFIG
{
	public CRYPT_CONTEXT_CONFIG_FLAGS dwFlags;
	public uint32 dwReserved;
}

[CRepr]
public struct CRYPT_CONTEXT_FUNCTION_CONFIG
{
	public uint32 dwFlags;
	public uint32 dwReserved;
}

[CRepr]
public struct CRYPT_CONTEXTS
{
	public uint32 cContexts;
	public PWSTR* rgpszContexts;
}

[CRepr]
public struct CRYPT_CONTEXT_FUNCTIONS
{
	public uint32 cFunctions;
	public PWSTR* rgpszFunctions;
}

[CRepr]
public struct CRYPT_CONTEXT_FUNCTION_PROVIDERS
{
	public uint32 cProviders;
	public PWSTR* rgpszProviders;
}

[CRepr]
public struct CRYPT_PROPERTY_REF
{
	public PWSTR pszProperty;
	public uint32 cbValue;
	public uint8* pbValue;
}

[CRepr]
public struct CRYPT_IMAGE_REF
{
	public PWSTR pszImage;
	public CRYPT_IMAGE_REF_FLAGS dwFlags;
}

[CRepr]
public struct CRYPT_PROVIDER_REF
{
	public uint32 dwInterface;
	public PWSTR pszFunction;
	public PWSTR pszProvider;
	public uint32 cProperties;
	public CRYPT_PROPERTY_REF** rgpProperties;
	public CRYPT_IMAGE_REF* pUM;
	public CRYPT_IMAGE_REF* pKM;
}

[CRepr]
public struct CRYPT_PROVIDER_REFS
{
	public uint32 cProviders;
	public CRYPT_PROVIDER_REF** rgpProviders;
}

[CRepr]
public struct NCRYPT_ALLOC_PARA
{
	public uint32 cbSize;
	public PFN_NCRYPT_ALLOC pfnAlloc;
	public PFN_NCRYPT_FREE pfnFree;
}

[CRepr]
public struct NCRYPT_CIPHER_PADDING_INFO
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint8* pbIV;
	public uint32 cbIV;
	public uint8* pbOtherInfo;
	public uint32 cbOtherInfo;
}

[CRepr]
public struct NCRYPT_PLATFORM_ATTEST_PADDING_INFO
{
	public uint32 magic;
	public uint32 pcrMask;
}

[CRepr]
public struct NCRYPT_KEY_ATTEST_PADDING_INFO
{
	public uint32 magic;
	public uint8* pbKeyBlob;
	public uint32 cbKeyBlob;
	public uint8* pbKeyAuth;
	public uint32 cbKeyAuth;
}

[CRepr]
public struct NCRYPT_ISOLATED_KEY_ATTESTED_ATTRIBUTES
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 cbPublicKeyBlob;
}

[CRepr]
public struct NCRYPT_VSM_KEY_ATTESTATION_STATEMENT
{
	public uint32 Magic;
	public uint32 Version;
	public uint32 cbSignature;
	public uint32 cbReport;
	public uint32 cbAttributes;
}

[CRepr]
public struct NCRYPT_VSM_KEY_ATTESTATION_CLAIM_RESTRICTIONS
{
	public uint32 Version;
	public uint64 TrustletId;
	public uint32 MinSvn;
	public uint32 FlagsMask;
	public uint32 FlagsExpected;
	public uint32 _bitfield;
}

[CRepr]
public struct NCRYPT_EXPORTED_ISOLATED_KEY_HEADER
{
	public uint32 Version;
	public uint32 KeyUsage;
	public uint32 _bitfield;
	public uint32 cbAlgName;
	public uint32 cbNonce;
	public uint32 cbAuthTag;
	public uint32 cbWrappingKey;
	public uint32 cbIsolatedKey;
}

[CRepr]
public struct NCRYPT_EXPORTED_ISOLATED_KEY_ENVELOPE
{
	public NCRYPT_EXPORTED_ISOLATED_KEY_HEADER Header;
}

[CRepr]
public struct NCRYPT_PCP_TPM_WEB_AUTHN_ATTESTATION_STATEMENT
{
	public uint32 Magic;
	public uint32 Version;
	public uint32 HeaderSize;
	public uint32 cbCertifyInfo;
	public uint32 cbSignature;
	public uint32 cbTpmPublic;
}

[CRepr]
public struct NCRYPT_TPM_PLATFORM_ATTESTATION_STATEMENT
{
	public uint32 Magic;
	public uint32 Version;
	public uint32 pcrAlg;
	public uint32 cbSignature;
	public uint32 cbQuote;
	public uint32 cbPcrs;
}

[CRepr]
public struct NCryptAlgorithmName
{
	public PWSTR pszName;
	public NCRYPT_ALGORITHM_NAME_CLASS dwClass;
	public NCRYPT_OPERATION dwAlgOperations;
	public uint32 dwFlags;
}

[CRepr]
public struct NCryptKeyName
{
	public PWSTR pszName;
	public PWSTR pszAlgid;
	public CERT_KEY_SPEC dwLegacyKeySpec;
	public uint32 dwFlags;
}

[CRepr]
public struct NCryptProviderName
{
	public PWSTR pszName;
	public PWSTR pszComment;
}

[CRepr]
public struct NCRYPT_UI_POLICY
{
	public uint32 dwVersion;
	public uint32 dwFlags;
	public PWSTR pszCreationTitle;
	public PWSTR pszFriendlyName;
	public PWSTR pszDescription;
}

[CRepr]
public struct NCRYPT_KEY_ACCESS_POLICY_BLOB
{
	public uint32 dwVersion;
	public uint32 dwPolicyFlags;
	public uint32 cbUserSid;
	public uint32 cbApplicationSid;
}

[CRepr]
public struct NCRYPT_SUPPORTED_LENGTHS
{
	public uint32 dwMinLength;
	public uint32 dwMaxLength;
	public uint32 dwIncrement;
	public uint32 dwDefaultLength;
}

[CRepr]
public struct NCRYPT_PCP_HMAC_AUTH_SIGNATURE_INFO
{
	public uint32 dwVersion;
	public int32 iExpiration;
	public uint8[32] pabNonce;
	public uint8[32] pabPolicyRef;
	public uint8[32] pabHMAC;
}

[CRepr]
public struct NCRYPT_PCP_TPM_FW_VERSION_INFO
{
	public uint16 major1;
	public uint16 major2;
	public uint16 minor1;
	public uint16 minor2;
}

[CRepr]
public struct NCRYPT_PCP_RAW_POLICYDIGEST_INFO
{
	public uint32 dwVersion;
	public uint32 cbDigest;
}

[CRepr]
public struct NCRYPT_KEY_BLOB_HEADER
{
	public uint32 cbSize;
	public uint32 dwMagic;
	public uint32 cbAlgName;
	public uint32 cbKeyData;
}

[CRepr]
public struct NCRYPT_TPM_LOADABLE_KEY_BLOB_HEADER
{
	public uint32 magic;
	public uint32 cbHeader;
	public uint32 cbPublic;
	public uint32 cbPrivate;
	public uint32 cbName;
}

[CRepr]
public struct CRYPT_BIT_BLOB
{
	public uint32 cbData;
	public uint8* pbData;
	public uint32 cUnusedBits;
}

[CRepr]
public struct CRYPT_ALGORITHM_IDENTIFIER
{
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB Parameters;
}

[CRepr]
public struct CRYPT_OBJID_TABLE
{
	public uint32 dwAlgId;
	public PSTR pszObjId;
}

[CRepr]
public struct CRYPT_HASH_INFO
{
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPTOAPI_BLOB Hash;
}

[CRepr]
public struct CERT_EXTENSION
{
	public PSTR pszObjId;
	public BOOL fCritical;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct CRYPT_ATTRIBUTE_TYPE_VALUE
{
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct CRYPT_ATTRIBUTE
{
	public PSTR pszObjId;
	public uint32 cValue;
	public CRYPTOAPI_BLOB* rgValue;
}

[CRepr]
public struct CRYPT_ATTRIBUTES
{
	public uint32 cAttr;
	public CRYPT_ATTRIBUTE* rgAttr;
}

[CRepr]
public struct CERT_RDN_ATTR
{
	public PSTR pszObjId;
	public CERT_RDN_ATTR_VALUE_TYPE dwValueType;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct CERT_RDN
{
	public uint32 cRDNAttr;
	public CERT_RDN_ATTR* rgRDNAttr;
}

[CRepr]
public struct CERT_NAME_INFO
{
	public uint32 cRDN;
	public CERT_RDN* rgRDN;
}

[CRepr]
public struct CERT_NAME_VALUE
{
	public uint32 dwValueType;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct CERT_PUBLIC_KEY_INFO
{
	public CRYPT_ALGORITHM_IDENTIFIER Algorithm;
	public CRYPT_BIT_BLOB PublicKey;
}

[CRepr]
public struct CRYPT_ECC_PRIVATE_KEY_INFO
{
	public uint32 dwVersion;
	public CRYPTOAPI_BLOB PrivateKey;
	public PSTR szCurveOid;
	public CRYPT_BIT_BLOB PublicKey;
}

[CRepr]
public struct CRYPT_PRIVATE_KEY_INFO
{
	public uint32 Version;
	public CRYPT_ALGORITHM_IDENTIFIER Algorithm;
	public CRYPTOAPI_BLOB PrivateKey;
	public CRYPT_ATTRIBUTES* pAttributes;
}

[CRepr]
public struct CRYPT_ENCRYPTED_PRIVATE_KEY_INFO
{
	public CRYPT_ALGORITHM_IDENTIFIER EncryptionAlgorithm;
	public CRYPTOAPI_BLOB EncryptedPrivateKey;
}

[CRepr]
public struct CRYPT_PKCS8_IMPORT_PARAMS
{
	public CRYPTOAPI_BLOB PrivateKey;
	public PCRYPT_RESOLVE_HCRYPTPROV_FUNC pResolvehCryptProvFunc;
	public void* pVoidResolveFunc;
	public PCRYPT_DECRYPT_PRIVATE_KEY_FUNC pDecryptPrivateKeyFunc;
	public void* pVoidDecryptFunc;
}

[CRepr]
public struct CRYPT_PKCS8_EXPORT_PARAMS
{
	public uint hCryptProv;
	public uint32 dwKeySpec;
	public PSTR pszPrivateKeyObjId;
	public PCRYPT_ENCRYPT_PRIVATE_KEY_FUNC pEncryptPrivateKeyFunc;
	public void* pVoidEncryptFunc;
}

[CRepr]
public struct CERT_INFO
{
	public uint32 dwVersion;
	public CRYPTOAPI_BLOB SerialNumber;
	public CRYPT_ALGORITHM_IDENTIFIER SignatureAlgorithm;
	public CRYPTOAPI_BLOB Issuer;
	public FILETIME NotBefore;
	public FILETIME NotAfter;
	public CRYPTOAPI_BLOB Subject;
	public CERT_PUBLIC_KEY_INFO SubjectPublicKeyInfo;
	public CRYPT_BIT_BLOB IssuerUniqueId;
	public CRYPT_BIT_BLOB SubjectUniqueId;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CRL_ENTRY
{
	public CRYPTOAPI_BLOB SerialNumber;
	public FILETIME RevocationDate;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CRL_INFO
{
	public uint32 dwVersion;
	public CRYPT_ALGORITHM_IDENTIFIER SignatureAlgorithm;
	public CRYPTOAPI_BLOB Issuer;
	public FILETIME ThisUpdate;
	public FILETIME NextUpdate;
	public uint32 cCRLEntry;
	public CRL_ENTRY* rgCRLEntry;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CERT_OR_CRL_BLOB
{
	public uint32 dwChoice;
	public uint32 cbEncoded;
	public uint8* pbEncoded;
}

[CRepr]
public struct CERT_OR_CRL_BUNDLE
{
	public uint32 cItem;
	public CERT_OR_CRL_BLOB* rgItem;
}

[CRepr]
public struct CERT_REQUEST_INFO
{
	public uint32 dwVersion;
	public CRYPTOAPI_BLOB Subject;
	public CERT_PUBLIC_KEY_INFO SubjectPublicKeyInfo;
	public uint32 cAttribute;
	public CRYPT_ATTRIBUTE* rgAttribute;
}

[CRepr]
public struct CERT_KEYGEN_REQUEST_INFO
{
	public uint32 dwVersion;
	public CERT_PUBLIC_KEY_INFO SubjectPublicKeyInfo;
	public PWSTR pwszChallengeString;
}

[CRepr]
public struct CERT_SIGNED_CONTENT_INFO
{
	public CRYPTOAPI_BLOB ToBeSigned;
	public CRYPT_ALGORITHM_IDENTIFIER SignatureAlgorithm;
	public CRYPT_BIT_BLOB Signature;
}

[CRepr]
public struct CTL_USAGE
{
	public uint32 cUsageIdentifier;
	public PSTR* rgpszUsageIdentifier;
}

[CRepr]
public struct CTL_ENTRY
{
	public CRYPTOAPI_BLOB SubjectIdentifier;
	public uint32 cAttribute;
	public CRYPT_ATTRIBUTE* rgAttribute;
}

[CRepr]
public struct CTL_INFO
{
	public uint32 dwVersion;
	public CTL_USAGE SubjectUsage;
	public CRYPTOAPI_BLOB ListIdentifier;
	public CRYPTOAPI_BLOB SequenceNumber;
	public FILETIME ThisUpdate;
	public FILETIME NextUpdate;
	public CRYPT_ALGORITHM_IDENTIFIER SubjectAlgorithm;
	public uint32 cCTLEntry;
	public CTL_ENTRY* rgCTLEntry;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CRYPT_TIME_STAMP_REQUEST_INFO
{
	public PSTR pszTimeStampAlgorithm;
	public PSTR pszContentType;
	public CRYPTOAPI_BLOB Content;
	public uint32 cAttribute;
	public CRYPT_ATTRIBUTE* rgAttribute;
}

[CRepr]
public struct CRYPT_ENROLLMENT_NAME_VALUE_PAIR
{
	public PWSTR pwszName;
	public PWSTR pwszValue;
}

[CRepr]
public struct CRYPT_CSP_PROVIDER
{
	public uint32 dwKeySpec;
	public PWSTR pwszProviderName;
	public CRYPT_BIT_BLOB Signature;
}

[CRepr]
public struct CRYPT_ENCODE_PARA
{
	public uint32 cbSize;
	public PFN_CRYPT_ALLOC pfnAlloc;
	public PFN_CRYPT_FREE pfnFree;
}

[CRepr]
public struct CRYPT_DECODE_PARA
{
	public uint32 cbSize;
	public PFN_CRYPT_ALLOC pfnAlloc;
	public PFN_CRYPT_FREE pfnFree;
}

[CRepr]
public struct CERT_EXTENSIONS
{
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CERT_AUTHORITY_KEY_ID_INFO
{
	public CRYPTOAPI_BLOB KeyId;
	public CRYPTOAPI_BLOB CertIssuer;
	public CRYPTOAPI_BLOB CertSerialNumber;
}

[CRepr]
public struct CERT_PRIVATE_KEY_VALIDITY
{
	public FILETIME NotBefore;
	public FILETIME NotAfter;
}

[CRepr]
public struct CERT_KEY_ATTRIBUTES_INFO
{
	public CRYPTOAPI_BLOB KeyId;
	public CRYPT_BIT_BLOB IntendedKeyUsage;
	public CERT_PRIVATE_KEY_VALIDITY* pPrivateKeyUsagePeriod;
}

[CRepr]
public struct CERT_POLICY_ID
{
	public uint32 cCertPolicyElementId;
	public PSTR* rgpszCertPolicyElementId;
}

[CRepr]
public struct CERT_KEY_USAGE_RESTRICTION_INFO
{
	public uint32 cCertPolicyId;
	public CERT_POLICY_ID* rgCertPolicyId;
	public CRYPT_BIT_BLOB RestrictedKeyUsage;
}

[CRepr]
public struct CERT_OTHER_NAME
{
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct CERT_ALT_NAME_ENTRY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CERT_OTHER_NAME* pOtherName;
		public PWSTR pwszRfc822Name;
		public PWSTR pwszDNSName;
		public CRYPTOAPI_BLOB DirectoryName;
		public PWSTR pwszURL;
		public CRYPTOAPI_BLOB IPAddress;
		public PSTR pszRegisteredID;
	}
	public uint32 dwAltNameChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CERT_ALT_NAME_INFO
{
	public uint32 cAltEntry;
	public CERT_ALT_NAME_ENTRY* rgAltEntry;
}

[CRepr]
public struct CERT_BASIC_CONSTRAINTS_INFO
{
	public CRYPT_BIT_BLOB SubjectType;
	public BOOL fPathLenConstraint;
	public uint32 dwPathLenConstraint;
	public uint32 cSubtreesConstraint;
	public CRYPTOAPI_BLOB* rgSubtreesConstraint;
}

[CRepr]
public struct CERT_BASIC_CONSTRAINTS2_INFO
{
	public BOOL fCA;
	public BOOL fPathLenConstraint;
	public uint32 dwPathLenConstraint;
}

[CRepr]
public struct CERT_POLICY_QUALIFIER_INFO
{
	public PSTR pszPolicyQualifierId;
	public CRYPTOAPI_BLOB Qualifier;
}

[CRepr]
public struct CERT_POLICY_INFO
{
	public PSTR pszPolicyIdentifier;
	public uint32 cPolicyQualifier;
	public CERT_POLICY_QUALIFIER_INFO* rgPolicyQualifier;
}

[CRepr]
public struct CERT_POLICIES_INFO
{
	public uint32 cPolicyInfo;
	public CERT_POLICY_INFO* rgPolicyInfo;
}

[CRepr]
public struct CERT_POLICY_QUALIFIER_NOTICE_REFERENCE
{
	public PSTR pszOrganization;
	public uint32 cNoticeNumbers;
	public int32* rgNoticeNumbers;
}

[CRepr]
public struct CERT_POLICY_QUALIFIER_USER_NOTICE
{
	public CERT_POLICY_QUALIFIER_NOTICE_REFERENCE* pNoticeReference;
	public PWSTR pszDisplayText;
}

[CRepr]
public struct CPS_URLS
{
	public PWSTR pszURL;
	public CRYPT_ALGORITHM_IDENTIFIER* pAlgorithm;
	public CRYPTOAPI_BLOB* pDigest;
}

[CRepr]
public struct CERT_POLICY95_QUALIFIER1
{
	public PWSTR pszPracticesReference;
	public PSTR pszNoticeIdentifier;
	public PSTR pszNSINoticeIdentifier;
	public uint32 cCPSURLs;
	public CPS_URLS* rgCPSURLs;
}

[CRepr]
public struct CERT_POLICY_MAPPING
{
	public PSTR pszIssuerDomainPolicy;
	public PSTR pszSubjectDomainPolicy;
}

[CRepr]
public struct CERT_POLICY_MAPPINGS_INFO
{
	public uint32 cPolicyMapping;
	public CERT_POLICY_MAPPING* rgPolicyMapping;
}

[CRepr]
public struct CERT_POLICY_CONSTRAINTS_INFO
{
	public BOOL fRequireExplicitPolicy;
	public uint32 dwRequireExplicitPolicySkipCerts;
	public BOOL fInhibitPolicyMapping;
	public uint32 dwInhibitPolicyMappingSkipCerts;
}

[CRepr]
public struct CRYPT_CONTENT_INFO_SEQUENCE_OF_ANY
{
	public PSTR pszObjId;
	public uint32 cValue;
	public CRYPTOAPI_BLOB* rgValue;
}

[CRepr]
public struct CRYPT_CONTENT_INFO
{
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB Content;
}

[CRepr]
public struct CRYPT_SEQUENCE_OF_ANY
{
	public uint32 cValue;
	public CRYPTOAPI_BLOB* rgValue;
}

[CRepr]
public struct CERT_AUTHORITY_KEY_ID2_INFO
{
	public CRYPTOAPI_BLOB KeyId;
	public CERT_ALT_NAME_INFO AuthorityCertIssuer;
	public CRYPTOAPI_BLOB AuthorityCertSerialNumber;
}

[CRepr]
public struct CERT_ACCESS_DESCRIPTION
{
	public PSTR pszAccessMethod;
	public CERT_ALT_NAME_ENTRY AccessLocation;
}

[CRepr]
public struct CERT_AUTHORITY_INFO_ACCESS
{
	public uint32 cAccDescr;
	public CERT_ACCESS_DESCRIPTION* rgAccDescr;
}

[CRepr]
public struct CRL_DIST_POINT_NAME
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CERT_ALT_NAME_INFO FullName;
	}
	public uint32 dwDistPointNameChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CRL_DIST_POINT
{
	public CRL_DIST_POINT_NAME DistPointName;
	public CRYPT_BIT_BLOB ReasonFlags;
	public CERT_ALT_NAME_INFO CRLIssuer;
}

[CRepr]
public struct CRL_DIST_POINTS_INFO
{
	public uint32 cDistPoint;
	public CRL_DIST_POINT* rgDistPoint;
}

[CRepr]
public struct CROSS_CERT_DIST_POINTS_INFO
{
	public uint32 dwSyncDeltaTime;
	public uint32 cDistPoint;
	public CERT_ALT_NAME_INFO* rgDistPoint;
}

[CRepr]
public struct CERT_PAIR
{
	public CRYPTOAPI_BLOB Forward;
	public CRYPTOAPI_BLOB Reverse;
}

[CRepr]
public struct CRL_ISSUING_DIST_POINT
{
	public CRL_DIST_POINT_NAME DistPointName;
	public BOOL fOnlyContainsUserCerts;
	public BOOL fOnlyContainsCACerts;
	public CRYPT_BIT_BLOB OnlySomeReasonFlags;
	public BOOL fIndirectCRL;
}

[CRepr]
public struct CERT_GENERAL_SUBTREE
{
	public CERT_ALT_NAME_ENTRY Base;
	public uint32 dwMinimum;
	public BOOL fMaximum;
	public uint32 dwMaximum;
}

[CRepr]
public struct CERT_NAME_CONSTRAINTS_INFO
{
	public uint32 cPermittedSubtree;
	public CERT_GENERAL_SUBTREE* rgPermittedSubtree;
	public uint32 cExcludedSubtree;
	public CERT_GENERAL_SUBTREE* rgExcludedSubtree;
}

[CRepr]
public struct CERT_DSS_PARAMETERS
{
	public CRYPTOAPI_BLOB p;
	public CRYPTOAPI_BLOB q;
	public CRYPTOAPI_BLOB g;
}

[CRepr]
public struct CERT_DH_PARAMETERS
{
	public CRYPTOAPI_BLOB p;
	public CRYPTOAPI_BLOB g;
}

[CRepr]
public struct CERT_ECC_SIGNATURE
{
	public CRYPTOAPI_BLOB r;
	public CRYPTOAPI_BLOB s;
}

[CRepr]
public struct CERT_X942_DH_VALIDATION_PARAMS
{
	public CRYPT_BIT_BLOB seed;
	public uint32 pgenCounter;
}

[CRepr]
public struct CERT_X942_DH_PARAMETERS
{
	public CRYPTOAPI_BLOB p;
	public CRYPTOAPI_BLOB g;
	public CRYPTOAPI_BLOB q;
	public CRYPTOAPI_BLOB j;
	public CERT_X942_DH_VALIDATION_PARAMS* pValidationParams;
}

[CRepr]
public struct CRYPT_X942_OTHER_INFO
{
	public PSTR pszContentEncryptionObjId;
	public uint8[4] rgbCounter;
	public uint8[4] rgbKeyLength;
	public CRYPTOAPI_BLOB PubInfo;
}

[CRepr]
public struct CRYPT_ECC_CMS_SHARED_INFO
{
	public CRYPT_ALGORITHM_IDENTIFIER Algorithm;
	public CRYPTOAPI_BLOB EntityUInfo;
	public uint8[4] rgbSuppPubInfo;
}

[CRepr]
public struct CRYPT_RC2_CBC_PARAMETERS
{
	public uint32 dwVersion;
	public BOOL fIV;
	public uint8[8] rgbIV;
}

[CRepr]
public struct CRYPT_SMIME_CAPABILITY
{
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB Parameters;
}

[CRepr]
public struct CRYPT_SMIME_CAPABILITIES
{
	public uint32 cCapability;
	public CRYPT_SMIME_CAPABILITY* rgCapability;
}

[CRepr]
public struct CERT_QC_STATEMENT
{
	public PSTR pszStatementId;
	public CRYPTOAPI_BLOB StatementInfo;
}

[CRepr]
public struct CERT_QC_STATEMENTS_EXT_INFO
{
	public uint32 cStatement;
	public CERT_QC_STATEMENT* rgStatement;
}

[CRepr]
public struct CRYPT_MASK_GEN_ALGORITHM
{
	public PSTR pszObjId;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
}

[CRepr]
public struct CRYPT_RSA_SSA_PSS_PARAMETERS
{
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPT_MASK_GEN_ALGORITHM MaskGenAlgorithm;
	public uint32 dwSaltLength;
	public uint32 dwTrailerField;
}

[CRepr]
public struct CRYPT_PSOURCE_ALGORITHM
{
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB EncodingParameters;
}

[CRepr]
public struct CRYPT_RSAES_OAEP_PARAMETERS
{
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPT_MASK_GEN_ALGORITHM MaskGenAlgorithm;
	public CRYPT_PSOURCE_ALGORITHM PSourceAlgorithm;
}

[CRepr]
public struct CMC_TAGGED_ATTRIBUTE
{
	public uint32 dwBodyPartID;
	public CRYPT_ATTRIBUTE Attribute;
}

[CRepr]
public struct CMC_TAGGED_CERT_REQUEST
{
	public uint32 dwBodyPartID;
	public CRYPTOAPI_BLOB SignedCertRequest;
}

[CRepr]
public struct CMC_TAGGED_REQUEST
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CMC_TAGGED_CERT_REQUEST* pTaggedCertRequest;
	}
	public uint32 dwTaggedRequestChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CMC_TAGGED_CONTENT_INFO
{
	public uint32 dwBodyPartID;
	public CRYPTOAPI_BLOB EncodedContentInfo;
}

[CRepr]
public struct CMC_TAGGED_OTHER_MSG
{
	public uint32 dwBodyPartID;
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct CMC_DATA_INFO
{
	public uint32 cTaggedAttribute;
	public CMC_TAGGED_ATTRIBUTE* rgTaggedAttribute;
	public uint32 cTaggedRequest;
	public CMC_TAGGED_REQUEST* rgTaggedRequest;
	public uint32 cTaggedContentInfo;
	public CMC_TAGGED_CONTENT_INFO* rgTaggedContentInfo;
	public uint32 cTaggedOtherMsg;
	public CMC_TAGGED_OTHER_MSG* rgTaggedOtherMsg;
}

[CRepr]
public struct CMC_RESPONSE_INFO
{
	public uint32 cTaggedAttribute;
	public CMC_TAGGED_ATTRIBUTE* rgTaggedAttribute;
	public uint32 cTaggedContentInfo;
	public CMC_TAGGED_CONTENT_INFO* rgTaggedContentInfo;
	public uint32 cTaggedOtherMsg;
	public CMC_TAGGED_OTHER_MSG* rgTaggedOtherMsg;
}

[CRepr]
public struct CMC_PEND_INFO
{
	public CRYPTOAPI_BLOB PendToken;
	public FILETIME PendTime;
}

[CRepr]
public struct CMC_STATUS_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwFailInfo;
		public CMC_PEND_INFO* pPendInfo;
	}
	public uint32 dwStatus;
	public uint32 cBodyList;
	public uint32* rgdwBodyList;
	public PWSTR pwszStatusString;
	public uint32 dwOtherInfoChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CMC_ADD_EXTENSIONS_INFO
{
	public uint32 dwCmcDataReference;
	public uint32 cCertReference;
	public uint32* rgdwCertReference;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CMC_ADD_ATTRIBUTES_INFO
{
	public uint32 dwCmcDataReference;
	public uint32 cCertReference;
	public uint32* rgdwCertReference;
	public uint32 cAttribute;
	public CRYPT_ATTRIBUTE* rgAttribute;
}

[CRepr]
public struct CERT_TEMPLATE_EXT
{
	public PSTR pszObjId;
	public uint32 dwMajorVersion;
	public BOOL fMinorVersion;
	public uint32 dwMinorVersion;
}

[CRepr]
public struct CERT_HASHED_URL
{
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPTOAPI_BLOB Hash;
	public PWSTR pwszUrl;
}

[CRepr]
public struct CERT_LOGOTYPE_DETAILS
{
	public PWSTR pwszMimeType;
	public uint32 cHashedUrl;
	public CERT_HASHED_URL* rgHashedUrl;
}

[CRepr]
public struct CERT_LOGOTYPE_REFERENCE
{
	public uint32 cHashedUrl;
	public CERT_HASHED_URL* rgHashedUrl;
}

[CRepr]
public struct CERT_LOGOTYPE_IMAGE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwNumBits;
		public uint32 dwTableSize;
	}
	public CERT_LOGOTYPE_IMAGE_INFO_TYPE dwLogotypeImageInfoChoice;
	public uint32 dwFileSize;
	public uint32 dwXSize;
	public uint32 dwYSize;
	public CERT_LOGOTYPE_CHOICE dwLogotypeImageResolutionChoice;
	public using _Anonymous_e__Union Anonymous;
	public PWSTR pwszLanguage;
}

[CRepr]
public struct CERT_LOGOTYPE_IMAGE
{
	public CERT_LOGOTYPE_DETAILS LogotypeDetails;
	public CERT_LOGOTYPE_IMAGE_INFO* pLogotypeImageInfo;
}

[CRepr]
public struct CERT_LOGOTYPE_AUDIO_INFO
{
	public uint32 dwFileSize;
	public uint32 dwPlayTime;
	public uint32 dwChannels;
	public uint32 dwSampleRate;
	public PWSTR pwszLanguage;
}

[CRepr]
public struct CERT_LOGOTYPE_AUDIO
{
	public CERT_LOGOTYPE_DETAILS LogotypeDetails;
	public CERT_LOGOTYPE_AUDIO_INFO* pLogotypeAudioInfo;
}

[CRepr]
public struct CERT_LOGOTYPE_DATA
{
	public uint32 cLogotypeImage;
	public CERT_LOGOTYPE_IMAGE* rgLogotypeImage;
	public uint32 cLogotypeAudio;
	public CERT_LOGOTYPE_AUDIO* rgLogotypeAudio;
}

[CRepr]
public struct CERT_LOGOTYPE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CERT_LOGOTYPE_DATA* pLogotypeDirectInfo;
		public CERT_LOGOTYPE_REFERENCE* pLogotypeIndirectInfo;
	}
	public CERT_LOGOTYPE_OPTION dwLogotypeInfoChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CERT_OTHER_LOGOTYPE_INFO
{
	public PSTR pszObjId;
	public CERT_LOGOTYPE_INFO LogotypeInfo;
}

[CRepr]
public struct CERT_LOGOTYPE_EXT_INFO
{
	public uint32 cCommunityLogo;
	public CERT_LOGOTYPE_INFO* rgCommunityLogo;
	public CERT_LOGOTYPE_INFO* pIssuerLogo;
	public CERT_LOGOTYPE_INFO* pSubjectLogo;
	public uint32 cOtherLogo;
	public CERT_OTHER_LOGOTYPE_INFO* rgOtherLogo;
}

[CRepr]
public struct CERT_BIOMETRIC_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwPredefined;
		public PSTR pszObjId;
	}
	public CERT_BIOMETRIC_DATA_TYPE dwTypeOfBiometricDataChoice;
	public using _Anonymous_e__Union Anonymous;
	public CERT_HASHED_URL HashedUrl;
}

[CRepr]
public struct CERT_BIOMETRIC_EXT_INFO
{
	public uint32 cBiometricData;
	public CERT_BIOMETRIC_DATA* rgBiometricData;
}

[CRepr]
public struct OCSP_SIGNATURE_INFO
{
	public CRYPT_ALGORITHM_IDENTIFIER SignatureAlgorithm;
	public CRYPT_BIT_BLOB Signature;
	public uint32 cCertEncoded;
	public CRYPTOAPI_BLOB* rgCertEncoded;
}

[CRepr]
public struct OCSP_SIGNED_REQUEST_INFO
{
	public CRYPTOAPI_BLOB ToBeSigned;
	public OCSP_SIGNATURE_INFO* pOptionalSignatureInfo;
}

[CRepr]
public struct OCSP_CERT_ID
{
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPTOAPI_BLOB IssuerNameHash;
	public CRYPTOAPI_BLOB IssuerKeyHash;
	public CRYPTOAPI_BLOB SerialNumber;
}

[CRepr]
public struct OCSP_REQUEST_ENTRY
{
	public OCSP_CERT_ID CertId;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct OCSP_REQUEST_INFO
{
	public uint32 dwVersion;
	public CERT_ALT_NAME_ENTRY* pRequestorName;
	public uint32 cRequestEntry;
	public OCSP_REQUEST_ENTRY* rgRequestEntry;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct OCSP_RESPONSE_INFO
{
	public uint32 dwStatus;
	public PSTR pszObjId;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct OCSP_BASIC_SIGNED_RESPONSE_INFO
{
	public CRYPTOAPI_BLOB ToBeSigned;
	public OCSP_SIGNATURE_INFO SignatureInfo;
}

[CRepr]
public struct OCSP_BASIC_REVOKED_INFO
{
	public FILETIME RevocationDate;
	public CERT_REVOCATION_STATUS_REASON dwCrlReasonCode;
}

[CRepr]
public struct OCSP_BASIC_RESPONSE_ENTRY
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public OCSP_BASIC_REVOKED_INFO* pRevokedInfo;
	}
	public OCSP_CERT_ID CertId;
	public uint32 dwCertStatus;
	public using _Anonymous_e__Union Anonymous;
	public FILETIME ThisUpdate;
	public FILETIME NextUpdate;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct OCSP_BASIC_RESPONSE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CRYPTOAPI_BLOB ByNameResponderId;
		public CRYPTOAPI_BLOB ByKeyResponderId;
	}
	public uint32 dwVersion;
	public uint32 dwResponderIdChoice;
	public using _Anonymous_e__Union Anonymous;
	public FILETIME ProducedAt;
	public uint32 cResponseEntry;
	public OCSP_BASIC_RESPONSE_ENTRY* rgResponseEntry;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CERT_SUPPORTED_ALGORITHM_INFO
{
	public CRYPT_ALGORITHM_IDENTIFIER Algorithm;
	public CRYPT_BIT_BLOB IntendedKeyUsage;
	public CERT_POLICIES_INFO IntendedCertPolicies;
}

[CRepr]
public struct CERT_TPM_SPECIFICATION_INFO
{
	public PWSTR pwszFamily;
	public uint32 dwLevel;
	public uint32 dwRevision;
}

[CRepr]
public struct CRYPT_OID_FUNC_ENTRY
{
	public PSTR pszOID;
	public void* pvFuncAddr;
}

[CRepr]
public struct CRYPT_OID_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwValue;
		public uint32 Algid;
		public uint32 dwLength;
	}
	public uint32 cbSize;
	public PSTR pszOID;
	public PWSTR pwszName;
	public uint32 dwGroupId;
	public using _Anonymous_e__Union Anonymous;
	public CRYPTOAPI_BLOB ExtraInfo;
}

[CRepr]
public struct CERT_STRONG_SIGN_SERIALIZED_INFO
{
	public CERT_STRONG_SIGN_FLAGS dwFlags;
	public PWSTR pwszCNGSignHashAlgids;
	public PWSTR pwszCNGPubKeyMinBitLengths;
}

[CRepr]
public struct CERT_STRONG_SIGN_PARA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public void* pvInfo;
		public CERT_STRONG_SIGN_SERIALIZED_INFO* pSerializedInfo;
		public PSTR pszOID;
	}
	public uint32 cbSize;
	public uint32 dwInfoChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CERT_ISSUER_SERIAL_NUMBER
{
	public CRYPTOAPI_BLOB Issuer;
	public CRYPTOAPI_BLOB SerialNumber;
}

[CRepr]
public struct CERT_ID
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CERT_ISSUER_SERIAL_NUMBER IssuerSerialNumber;
		public CRYPTOAPI_BLOB KeyId;
		public CRYPTOAPI_BLOB HashId;
	}
	public CERT_ID_OPTION dwIdChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CMSG_SIGNER_ENCODE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hCryptProv;
		public NCRYPT_KEY_HANDLE hNCryptKey;
	}
	public uint32 cbSize;
	public CERT_INFO* pCertInfo;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwKeySpec;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public void* pvHashAuxInfo;
	public uint32 cAuthAttr;
	public CRYPT_ATTRIBUTE* rgAuthAttr;
	public uint32 cUnauthAttr;
	public CRYPT_ATTRIBUTE* rgUnauthAttr;
}

[CRepr]
public struct CMSG_SIGNED_ENCODE_INFO
{
	public uint32 cbSize;
	public uint32 cSigners;
	public CMSG_SIGNER_ENCODE_INFO* rgSigners;
	public uint32 cCertEncoded;
	public CRYPTOAPI_BLOB* rgCertEncoded;
	public uint32 cCrlEncoded;
	public CRYPTOAPI_BLOB* rgCrlEncoded;
}

[CRepr]
public struct CMSG_ENVELOPED_ENCODE_INFO
{
	public uint32 cbSize;
	public HCRYPTPROV_LEGACY hCryptProv;
	public CRYPT_ALGORITHM_IDENTIFIER ContentEncryptionAlgorithm;
	public void* pvEncryptionAuxInfo;
	public uint32 cRecipients;
	public CERT_INFO** rgpRecipients;
}

[CRepr]
public struct CMSG_KEY_TRANS_RECIPIENT_ENCODE_INFO
{
	public uint32 cbSize;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public void* pvKeyEncryptionAuxInfo;
	public HCRYPTPROV_LEGACY hCryptProv;
	public CRYPT_BIT_BLOB RecipientPublicKey;
	public CERT_ID RecipientId;
}

[CRepr]
public struct CMSG_RECIPIENT_ENCRYPTED_KEY_ENCODE_INFO
{
	public uint32 cbSize;
	public CRYPT_BIT_BLOB RecipientPublicKey;
	public CERT_ID RecipientId;
	public FILETIME Date;
	public CRYPT_ATTRIBUTE_TYPE_VALUE* pOtherAttr;
}

[CRepr]
public struct CMSG_KEY_AGREE_RECIPIENT_ENCODE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CRYPT_ALGORITHM_IDENTIFIER* pEphemeralAlgorithm;
		public CERT_ID* pSenderId;
	}
	public uint32 cbSize;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public void* pvKeyEncryptionAuxInfo;
	public CRYPT_ALGORITHM_IDENTIFIER KeyWrapAlgorithm;
	public void* pvKeyWrapAuxInfo;
	public HCRYPTPROV_LEGACY hCryptProv;
	public uint32 dwKeySpec;
	public CMSG_KEY_AGREE_OPTION dwKeyChoice;
	public using _Anonymous_e__Union Anonymous;
	public CRYPTOAPI_BLOB UserKeyingMaterial;
	public uint32 cRecipientEncryptedKeys;
	public CMSG_RECIPIENT_ENCRYPTED_KEY_ENCODE_INFO** rgpRecipientEncryptedKeys;
}

[CRepr]
public struct CMSG_MAIL_LIST_RECIPIENT_ENCODE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hKeyEncryptionKey;
		public void* pvKeyEncryptionKey;
	}
	public uint32 cbSize;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public void* pvKeyEncryptionAuxInfo;
	public uint hCryptProv;
	public uint32 dwKeyChoice;
	public using _Anonymous_e__Union Anonymous;
	public CRYPTOAPI_BLOB KeyId;
	public FILETIME Date;
	public CRYPT_ATTRIBUTE_TYPE_VALUE* pOtherAttr;
}

[CRepr]
public struct CMSG_RECIPIENT_ENCODE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CMSG_KEY_TRANS_RECIPIENT_ENCODE_INFO* pKeyTrans;
		public CMSG_KEY_AGREE_RECIPIENT_ENCODE_INFO* pKeyAgree;
		public CMSG_MAIL_LIST_RECIPIENT_ENCODE_INFO* pMailList;
	}
	public uint32 dwRecipientChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CMSG_RC2_AUX_INFO
{
	public uint32 cbSize;
	public uint32 dwBitLen;
}

[CRepr]
public struct CMSG_SP3_COMPATIBLE_AUX_INFO
{
	public uint32 cbSize;
	public uint32 dwFlags;
}

[CRepr]
public struct CMSG_RC4_AUX_INFO
{
	public uint32 cbSize;
	public uint32 dwBitLen;
}

[CRepr]
public struct CMSG_SIGNED_AND_ENVELOPED_ENCODE_INFO
{
	public uint32 cbSize;
	public CMSG_SIGNED_ENCODE_INFO SignedInfo;
	public CMSG_ENVELOPED_ENCODE_INFO EnvelopedInfo;
}

[CRepr]
public struct CMSG_HASHED_ENCODE_INFO
{
	public uint32 cbSize;
	public HCRYPTPROV_LEGACY hCryptProv;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public void* pvHashAuxInfo;
}

[CRepr]
public struct CMSG_ENCRYPTED_ENCODE_INFO
{
	public uint32 cbSize;
	public CRYPT_ALGORITHM_IDENTIFIER ContentEncryptionAlgorithm;
	public void* pvEncryptionAuxInfo;
}

[CRepr]
public struct CMSG_STREAM_INFO
{
	public uint32 cbContent;
	public PFN_CMSG_STREAM_OUTPUT pfnStreamOutput;
	public void* pvArg;
}

[CRepr]
public struct CMSG_SIGNER_INFO
{
	public uint32 dwVersion;
	public CRYPTOAPI_BLOB Issuer;
	public CRYPTOAPI_BLOB SerialNumber;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPT_ALGORITHM_IDENTIFIER HashEncryptionAlgorithm;
	public CRYPTOAPI_BLOB EncryptedHash;
	public CRYPT_ATTRIBUTES AuthAttrs;
	public CRYPT_ATTRIBUTES UnauthAttrs;
}

[CRepr]
public struct CMSG_CMS_SIGNER_INFO
{
	public uint32 dwVersion;
	public CERT_ID SignerId;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPT_ALGORITHM_IDENTIFIER HashEncryptionAlgorithm;
	public CRYPTOAPI_BLOB EncryptedHash;
	public CRYPT_ATTRIBUTES AuthAttrs;
	public CRYPT_ATTRIBUTES UnauthAttrs;
}

[CRepr]
public struct CMSG_KEY_TRANS_RECIPIENT_INFO
{
	public uint32 dwVersion;
	public CERT_ID RecipientId;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public CRYPTOAPI_BLOB EncryptedKey;
}

[CRepr]
public struct CMSG_RECIPIENT_ENCRYPTED_KEY_INFO
{
	public CERT_ID RecipientId;
	public CRYPTOAPI_BLOB EncryptedKey;
	public FILETIME Date;
	public CRYPT_ATTRIBUTE_TYPE_VALUE* pOtherAttr;
}

[CRepr]
public struct CMSG_KEY_AGREE_RECIPIENT_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CERT_ID OriginatorCertId;
		public CERT_PUBLIC_KEY_INFO OriginatorPublicKeyInfo;
	}
	public uint32 dwVersion;
	public CMSG_KEY_AGREE_ORIGINATOR dwOriginatorChoice;
	public using _Anonymous_e__Union Anonymous;
	public CRYPTOAPI_BLOB UserKeyingMaterial;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public uint32 cRecipientEncryptedKeys;
	public CMSG_RECIPIENT_ENCRYPTED_KEY_INFO** rgpRecipientEncryptedKeys;
}

[CRepr]
public struct CMSG_MAIL_LIST_RECIPIENT_INFO
{
	public uint32 dwVersion;
	public CRYPTOAPI_BLOB KeyId;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public CRYPTOAPI_BLOB EncryptedKey;
	public FILETIME Date;
	public CRYPT_ATTRIBUTE_TYPE_VALUE* pOtherAttr;
}

[CRepr]
public struct CMSG_CMS_RECIPIENT_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CMSG_KEY_TRANS_RECIPIENT_INFO* pKeyTrans;
		public CMSG_KEY_AGREE_RECIPIENT_INFO* pKeyAgree;
		public CMSG_MAIL_LIST_RECIPIENT_INFO* pMailList;
	}
	public uint32 dwRecipientChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CMSG_CTRL_VERIFY_SIGNATURE_EX_PARA
{
	public uint32 cbSize;
	public HCRYPTPROV_LEGACY hCryptProv;
	public uint32 dwSignerIndex;
	public uint32 dwSignerType;
	public void* pvSigner;
}

[CRepr]
public struct CMSG_CTRL_DECRYPT_PARA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hCryptProv;
		public NCRYPT_KEY_HANDLE hNCryptKey;
	}
	public uint32 cbSize;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwKeySpec;
	public uint32 dwRecipientIndex;
}

[CRepr]
public struct CMSG_CTRL_KEY_TRANS_DECRYPT_PARA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hCryptProv;
		public NCRYPT_KEY_HANDLE hNCryptKey;
	}
	public uint32 cbSize;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwKeySpec;
	public CMSG_KEY_TRANS_RECIPIENT_INFO* pKeyTrans;
	public uint32 dwRecipientIndex;
}

[CRepr]
public struct CMSG_CTRL_KEY_AGREE_DECRYPT_PARA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hCryptProv;
		public NCRYPT_KEY_HANDLE hNCryptKey;
	}
	public uint32 cbSize;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwKeySpec;
	public CMSG_KEY_AGREE_RECIPIENT_INFO* pKeyAgree;
	public uint32 dwRecipientIndex;
	public uint32 dwRecipientEncryptedKeyIndex;
	public CRYPT_BIT_BLOB OriginatorPublicKey;
}

[CRepr]
public struct CMSG_CTRL_MAIL_LIST_DECRYPT_PARA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hKeyEncryptionKey;
		public void* pvKeyEncryptionKey;
	}
	public uint32 cbSize;
	public uint hCryptProv;
	public CMSG_MAIL_LIST_RECIPIENT_INFO* pMailList;
	public uint32 dwRecipientIndex;
	public uint32 dwKeyChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CMSG_CTRL_ADD_SIGNER_UNAUTH_ATTR_PARA
{
	public uint32 cbSize;
	public uint32 dwSignerIndex;
	public CRYPTOAPI_BLOB blob;
}

[CRepr]
public struct CMSG_CTRL_DEL_SIGNER_UNAUTH_ATTR_PARA
{
	public uint32 cbSize;
	public uint32 dwSignerIndex;
	public uint32 dwUnauthAttrIndex;
}

[CRepr]
public struct CMSG_CONTENT_ENCRYPT_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hContentEncryptKey;
		public BCRYPT_KEY_HANDLE hCNGContentEncryptKey;
	}
	public uint32 cbSize;
	public HCRYPTPROV_LEGACY hCryptProv;
	public CRYPT_ALGORITHM_IDENTIFIER ContentEncryptionAlgorithm;
	public void* pvEncryptionAuxInfo;
	public uint32 cRecipients;
	public CMSG_RECIPIENT_ENCODE_INFO* rgCmsRecipients;
	public PFN_CMSG_ALLOC pfnAlloc;
	public PFN_CMSG_FREE pfnFree;
	public uint32 dwEncryptFlags;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwFlags;
	public BOOL fCNG;
	public uint8* pbCNGContentEncryptKeyObject;
	public uint8* pbContentEncryptKey;
	public uint32 cbContentEncryptKey;
}

[CRepr]
public struct CMSG_KEY_TRANS_ENCRYPT_INFO
{
	public uint32 cbSize;
	public uint32 dwRecipientIndex;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public CRYPTOAPI_BLOB EncryptedKey;
	public uint32 dwFlags;
}

[CRepr]
public struct CMSG_KEY_AGREE_KEY_ENCRYPT_INFO
{
	public uint32 cbSize;
	public CRYPTOAPI_BLOB EncryptedKey;
}

[CRepr]
public struct CMSG_KEY_AGREE_ENCRYPT_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CERT_ID OriginatorCertId;
		public CERT_PUBLIC_KEY_INFO OriginatorPublicKeyInfo;
	}
	public uint32 cbSize;
	public uint32 dwRecipientIndex;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public CRYPTOAPI_BLOB UserKeyingMaterial;
	public CMSG_KEY_AGREE_ORIGINATOR dwOriginatorChoice;
	public using _Anonymous_e__Union Anonymous;
	public uint32 cKeyAgreeKeyEncryptInfo;
	public CMSG_KEY_AGREE_KEY_ENCRYPT_INFO** rgpKeyAgreeKeyEncryptInfo;
	public uint32 dwFlags;
}

[CRepr]
public struct CMSG_MAIL_LIST_ENCRYPT_INFO
{
	public uint32 cbSize;
	public uint32 dwRecipientIndex;
	public CRYPT_ALGORITHM_IDENTIFIER KeyEncryptionAlgorithm;
	public CRYPTOAPI_BLOB EncryptedKey;
	public uint32 dwFlags;
}

[CRepr]
public struct CMSG_CNG_CONTENT_DECRYPT_INFO
{
	public uint32 cbSize;
	public CRYPT_ALGORITHM_IDENTIFIER ContentEncryptionAlgorithm;
	public PFN_CMSG_ALLOC pfnAlloc;
	public PFN_CMSG_FREE pfnFree;
	public NCRYPT_KEY_HANDLE hNCryptKey;
	public uint8* pbContentEncryptKey;
	public uint32 cbContentEncryptKey;
	public BCRYPT_KEY_HANDLE hCNGContentEncryptKey;
	public uint8* pbCNGContentEncryptKeyObject;
}

[CRepr]
public struct CERT_CONTEXT
{
	public uint32 dwCertEncodingType;
	public uint8* pbCertEncoded;
	public uint32 cbCertEncoded;
	public CERT_INFO* pCertInfo;
	public HCERTSTORE hCertStore;
}

[CRepr]
public struct CRL_CONTEXT
{
	public uint32 dwCertEncodingType;
	public uint8* pbCrlEncoded;
	public uint32 cbCrlEncoded;
	public CRL_INFO* pCrlInfo;
	public HCERTSTORE hCertStore;
}

[CRepr]
public struct CTL_CONTEXT
{
	public uint32 dwMsgAndCertEncodingType;
	public uint8* pbCtlEncoded;
	public uint32 cbCtlEncoded;
	public CTL_INFO* pCtlInfo;
	public HCERTSTORE hCertStore;
	public void* hCryptMsg;
	public uint8* pbCtlContent;
	public uint32 cbCtlContent;
}

[CRepr]
public struct CRYPT_KEY_PROV_PARAM
{
	public uint32 dwParam;
	public uint8* pbData;
	public uint32 cbData;
	public uint32 dwFlags;
}

[CRepr]
public struct CRYPT_KEY_PROV_INFO
{
	public PWSTR pwszContainerName;
	public PWSTR pwszProvName;
	public uint32 dwProvType;
	public CRYPT_KEY_FLAGS dwFlags;
	public uint32 cProvParam;
	public CRYPT_KEY_PROV_PARAM* rgProvParam;
	public uint32 dwKeySpec;
}

[CRepr]
public struct CERT_KEY_CONTEXT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hCryptProv;
		public NCRYPT_KEY_HANDLE hNCryptKey;
	}
	public uint32 cbSize;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwKeySpec;
}

[CRepr]
public struct ROOT_INFO_LUID
{
	public uint32 LowPart;
	public int32 HighPart;
}

[CRepr]
public struct CRYPT_SMART_CARD_ROOT_INFO
{
	public uint8[16] rgbCardID;
	public ROOT_INFO_LUID luid;
}

[CRepr]
public struct CERT_SYSTEM_STORE_RELOCATE_PARA
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public void* pvSystemStore;
		public PSTR pszSystemStore;
		public PWSTR pwszSystemStore;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public HKEY hKeyBase;
		public void* pvBase;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct CERT_REGISTRY_STORE_CLIENT_GPT_PARA
{
	public HKEY hKeyBase;
	public PWSTR pwszRegPath;
}

[CRepr]
public struct CERT_REGISTRY_STORE_ROAMING_PARA
{
	public HKEY hKey;
	public PWSTR pwszStoreDirectory;
}

[CRepr]
public struct CERT_LDAP_STORE_OPENED_PARA
{
	public void* pvLdapSessionHandle;
	public PWSTR pwszLdapUrl;
}

[CRepr]
public struct CERT_STORE_PROV_INFO
{
	public uint32 cbSize;
	public uint32 cStoreProvFunc;
	public void** rgpvStoreProvFunc;
	public HCERTSTOREPROV hStoreProv;
	public CERT_STORE_PROV_FLAGS dwStoreProvFlags;
	public void* hStoreProvFuncAddr2;
}

[CRepr]
public struct CERT_STORE_PROV_FIND_INFO
{
	public uint32 cbSize;
	public uint32 dwMsgAndCertEncodingType;
	public uint32 dwFindFlags;
	public uint32 dwFindType;
	public void* pvFindPara;
}

[CRepr]
public struct CRL_FIND_ISSUED_FOR_PARA
{
	public CERT_CONTEXT* pSubjectCert;
	public CERT_CONTEXT* pIssuerCert;
}

[CRepr]
public struct CTL_ANY_SUBJECT_INFO
{
	public CRYPT_ALGORITHM_IDENTIFIER SubjectAlgorithm;
	public CRYPTOAPI_BLOB SubjectIdentifier;
}

[CRepr]
public struct CTL_FIND_USAGE_PARA
{
	public uint32 cbSize;
	public CTL_USAGE SubjectUsage;
	public CRYPTOAPI_BLOB ListIdentifier;
	public CERT_INFO* pSigner;
}

[CRepr]
public struct CTL_FIND_SUBJECT_PARA
{
	public uint32 cbSize;
	public CTL_FIND_USAGE_PARA* pUsagePara;
	public uint32 dwSubjectType;
	public void* pvSubject;
}

[CRepr]
public struct CERT_CREATE_CONTEXT_PARA
{
	public uint32 cbSize;
	public PFN_CRYPT_FREE pfnFree;
	public void* pvFree;
	public PFN_CERT_CREATE_CONTEXT_SORT_FUNC pfnSort;
	public void* pvSort;
}

[CRepr]
public struct CERT_SYSTEM_STORE_INFO
{
	public uint32 cbSize;
}

[CRepr]
public struct CERT_PHYSICAL_STORE_INFO
{
	public uint32 cbSize;
	public PSTR pszOpenStoreProvider;
	public uint32 dwOpenEncodingType;
	public uint32 dwOpenFlags;
	public CRYPTOAPI_BLOB OpenParameters;
	public uint32 dwFlags;
	public uint32 dwPriority;
}

[CRepr]
public struct CTL_VERIFY_USAGE_PARA
{
	public uint32 cbSize;
	public CRYPTOAPI_BLOB ListIdentifier;
	public uint32 cCtlStore;
	public HCERTSTORE* rghCtlStore;
	public uint32 cSignerStore;
	public HCERTSTORE* rghSignerStore;
}

[CRepr]
public struct CTL_VERIFY_USAGE_STATUS
{
	public uint32 cbSize;
	public uint32 dwError;
	public uint32 dwFlags;
	public CTL_CONTEXT** ppCtl;
	public uint32 dwCtlEntryIndex;
	public CERT_CONTEXT** ppSigner;
	public uint32 dwSignerIndex;
}

[CRepr]
public struct CERT_REVOCATION_CRL_INFO
{
	public uint32 cbSize;
	public CRL_CONTEXT* pBaseCrlContext;
	public CRL_CONTEXT* pDeltaCrlContext;
	public CRL_ENTRY* pCrlEntry;
	public BOOL fDeltaCrlEntry;
}

[CRepr]
public struct CERT_REVOCATION_PARA
{
	public uint32 cbSize;
	public CERT_CONTEXT* pIssuerCert;
	public uint32 cCertStore;
	public HCERTSTORE* rgCertStore;
	public HCERTSTORE hCrlStore;
	public FILETIME* pftTimeToUse;
}

[CRepr]
public struct CERT_REVOCATION_STATUS
{
	public uint32 cbSize;
	public uint32 dwIndex;
	public uint32 dwError;
	public CERT_REVOCATION_STATUS_REASON dwReason;
	public BOOL fHasFreshnessTime;
	public uint32 dwFreshnessTime;
}

[CRepr]
public struct CRYPT_VERIFY_CERT_SIGN_STRONG_PROPERTIES_INFO
{
	public CRYPTOAPI_BLOB CertSignHashCNGAlgPropData;
	public CRYPTOAPI_BLOB CertIssuerPubKeyBitLengthPropData;
}

[CRepr]
public struct CRYPT_VERIFY_CERT_SIGN_WEAK_HASH_INFO
{
	public uint32 cCNGHashAlgid;
	public PWSTR* rgpwszCNGHashAlgid;
	public uint32 dwWeakIndex;
}

[CRepr]
public struct CRYPT_DEFAULT_CONTEXT_MULTI_OID_PARA
{
	public uint32 cOID;
	public PSTR* rgpszOID;
}

[CRepr]
public struct CRYPT_SIGN_MESSAGE_PARA
{
	public uint32 cbSize;
	public uint32 dwMsgEncodingType;
	public CERT_CONTEXT* pSigningCert;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public void* pvHashAuxInfo;
	public uint32 cMsgCert;
	public CERT_CONTEXT** rgpMsgCert;
	public uint32 cMsgCrl;
	public CRL_CONTEXT** rgpMsgCrl;
	public uint32 cAuthAttr;
	public CRYPT_ATTRIBUTE* rgAuthAttr;
	public uint32 cUnauthAttr;
	public CRYPT_ATTRIBUTE* rgUnauthAttr;
	public uint32 dwFlags;
	public uint32 dwInnerContentType;
}

[CRepr]
public struct CRYPT_VERIFY_MESSAGE_PARA
{
	public uint32 cbSize;
	public uint32 dwMsgAndCertEncodingType;
	public HCRYPTPROV_LEGACY hCryptProv;
	public PFN_CRYPT_GET_SIGNER_CERTIFICATE pfnGetSignerCertificate;
	public void* pvGetArg;
}

[CRepr]
public struct CRYPT_ENCRYPT_MESSAGE_PARA
{
	public uint32 cbSize;
	public uint32 dwMsgEncodingType;
	public HCRYPTPROV_LEGACY hCryptProv;
	public CRYPT_ALGORITHM_IDENTIFIER ContentEncryptionAlgorithm;
	public void* pvEncryptionAuxInfo;
	public uint32 dwFlags;
	public uint32 dwInnerContentType;
}

[CRepr]
public struct CRYPT_DECRYPT_MESSAGE_PARA
{
	public uint32 cbSize;
	public uint32 dwMsgAndCertEncodingType;
	public uint32 cCertStore;
	public HCERTSTORE* rghCertStore;
}

[CRepr]
public struct CRYPT_HASH_MESSAGE_PARA
{
	public uint32 cbSize;
	public uint32 dwMsgEncodingType;
	public HCRYPTPROV_LEGACY hCryptProv;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public void* pvHashAuxInfo;
}

[CRepr]
public struct CRYPT_KEY_SIGN_MESSAGE_PARA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint hCryptProv;
		public NCRYPT_KEY_HANDLE hNCryptKey;
	}
	public uint32 cbSize;
	public CERT_QUERY_ENCODING_TYPE dwMsgAndCertEncodingType;
	public using _Anonymous_e__Union Anonymous;
	public CERT_KEY_SPEC dwKeySpec;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public void* pvHashAuxInfo;
	public CRYPT_ALGORITHM_IDENTIFIER PubKeyAlgorithm;
}

[CRepr]
public struct CRYPT_KEY_VERIFY_MESSAGE_PARA
{
	public uint32 cbSize;
	public uint32 dwMsgEncodingType;
	public HCRYPTPROV_LEGACY hCryptProv;
}

[CRepr]
public struct CERT_CHAIN
{
	public uint32 cCerts;
	public CRYPTOAPI_BLOB* certs;
	public CRYPT_KEY_PROV_INFO keyLocatorInfo;
}

[CRepr]
public struct CRYPT_BLOB_ARRAY
{
	public uint32 cBlob;
	public CRYPTOAPI_BLOB* rgBlob;
}

[CRepr]
public struct CRYPT_CREDENTIALS
{
	public uint32 cbSize;
	public PSTR pszCredentialsOid;
	public void* pvCredentials;
}

[CRepr]
public struct CRYPT_PASSWORD_CREDENTIALSA
{
	public uint32 cbSize;
	public PSTR pszUsername;
	public PSTR pszPassword;
}

[CRepr]
public struct CRYPT_PASSWORD_CREDENTIALSW
{
	public uint32 cbSize;
	public PWSTR pszUsername;
	public PWSTR pszPassword;
}

[CRepr]
public struct CRYPTNET_URL_CACHE_PRE_FETCH_INFO
{
	public uint32 cbSize;
	public uint32 dwObjectType;
	public uint32 dwError;
	public uint32 dwReserved;
	public FILETIME ThisUpdateTime;
	public FILETIME NextUpdateTime;
	public FILETIME PublishTime;
}

[CRepr]
public struct CRYPTNET_URL_CACHE_FLUSH_INFO
{
	public uint32 cbSize;
	public uint32 dwExemptSeconds;
	public FILETIME ExpireTime;
}

[CRepr]
public struct CRYPTNET_URL_CACHE_RESPONSE_INFO
{
	public uint32 cbSize;
	public uint16 wResponseType;
	public uint16 wResponseFlags;
	public FILETIME LastModifiedTime;
	public uint32 dwMaxAge;
	public PWSTR pwszETag;
	public uint32 dwProxyId;
}

[CRepr]
public struct CRYPT_RETRIEVE_AUX_INFO
{
	public uint32 cbSize;
	public FILETIME* pLastSyncTime;
	public uint32 dwMaxUrlRetrievalByteCount;
	public CRYPTNET_URL_CACHE_PRE_FETCH_INFO* pPreFetchInfo;
	public CRYPTNET_URL_CACHE_FLUSH_INFO* pFlushInfo;
	public CRYPTNET_URL_CACHE_RESPONSE_INFO** ppResponseInfo;
	public PWSTR pwszCacheFileNamePrefix;
	public FILETIME* pftCacheResync;
	public BOOL fProxyCacheRetrieval;
	public uint32 dwHttpStatusCode;
	public PWSTR* ppwszErrorResponseHeaders;
	public CRYPTOAPI_BLOB** ppErrorContentBlob;
}

[CRepr]
public struct CRYPT_ASYNC_RETRIEVAL_COMPLETION
{
	public PFN_CRYPT_ASYNC_RETRIEVAL_COMPLETION_FUNC pfnCompletion;
	public void* pvCompletion;
}

[CRepr]
public struct CRYPT_URL_ARRAY
{
	public uint32 cUrl;
	public PWSTR* rgwszUrl;
}

[CRepr]
public struct CRYPT_URL_INFO
{
	public uint32 cbSize;
	public uint32 dwSyncDeltaTime;
	public uint32 cGroup;
	public uint32* rgcGroupEntry;
}

[CRepr]
public struct CERT_CRL_CONTEXT_PAIR
{
	public CERT_CONTEXT* pCertContext;
	public CRL_CONTEXT* pCrlContext;
}

[CRepr]
public struct CRYPT_GET_TIME_VALID_OBJECT_EXTRA_INFO
{
	public uint32 cbSize;
	public int32 iDeltaCrlIndicator;
	public FILETIME* pftCacheResync;
	public FILETIME* pLastSyncTime;
	public FILETIME* pMaxAgeTime;
	public CERT_REVOCATION_CHAIN_PARA* pChainPara;
	public CRYPTOAPI_BLOB* pDeltaCrlIndicator;
}

[CRepr]
public struct CERT_CHAIN_ENGINE_CONFIG
{
	public uint32 cbSize;
	public HCERTSTORE hRestrictedRoot;
	public HCERTSTORE hRestrictedTrust;
	public HCERTSTORE hRestrictedOther;
	public uint32 cAdditionalStore;
	public HCERTSTORE* rghAdditionalStore;
	public uint32 dwFlags;
	public uint32 dwUrlRetrievalTimeout;
	public uint32 MaximumCachedCertificates;
	public uint32 CycleDetectionModulus;
	public HCERTSTORE hExclusiveRoot;
	public HCERTSTORE hExclusiveTrustedPeople;
	public uint32 dwExclusiveFlags;
}

[CRepr]
public struct CERT_TRUST_STATUS
{
	public uint32 dwErrorStatus;
	public uint32 dwInfoStatus;
}

[CRepr]
public struct CERT_REVOCATION_INFO
{
	public uint32 cbSize;
	public uint32 dwRevocationResult;
	public PSTR pszRevocationOid;
	public void* pvOidSpecificInfo;
	public BOOL fHasFreshnessTime;
	public uint32 dwFreshnessTime;
	public CERT_REVOCATION_CRL_INFO* pCrlInfo;
}

[CRepr]
public struct CERT_TRUST_LIST_INFO
{
	public uint32 cbSize;
	public CTL_ENTRY* pCtlEntry;
	public CTL_CONTEXT* pCtlContext;
}

[CRepr]
public struct CERT_CHAIN_ELEMENT
{
	public uint32 cbSize;
	public CERT_CONTEXT* pCertContext;
	public CERT_TRUST_STATUS TrustStatus;
	public CERT_REVOCATION_INFO* pRevocationInfo;
	public CTL_USAGE* pIssuanceUsage;
	public CTL_USAGE* pApplicationUsage;
	public PWSTR pwszExtendedErrorInfo;
}

[CRepr]
public struct CERT_SIMPLE_CHAIN
{
	public uint32 cbSize;
	public CERT_TRUST_STATUS TrustStatus;
	public uint32 cElement;
	public CERT_CHAIN_ELEMENT** rgpElement;
	public CERT_TRUST_LIST_INFO* pTrustListInfo;
	public BOOL fHasRevocationFreshnessTime;
	public uint32 dwRevocationFreshnessTime;
}

[CRepr]
public struct CERT_CHAIN_CONTEXT
{
	public uint32 cbSize;
	public CERT_TRUST_STATUS TrustStatus;
	public uint32 cChain;
	public CERT_SIMPLE_CHAIN** rgpChain;
	public uint32 cLowerQualityChainContext;
	public CERT_CHAIN_CONTEXT** rgpLowerQualityChainContext;
	public BOOL fHasRevocationFreshnessTime;
	public uint32 dwRevocationFreshnessTime;
	public uint32 dwCreateFlags;
	public Guid ChainId;
}

[CRepr]
public struct CERT_USAGE_MATCH
{
	public uint32 dwType;
	public CTL_USAGE Usage;
}

[CRepr]
public struct CTL_USAGE_MATCH
{
	public uint32 dwType;
	public CTL_USAGE Usage;
}

[CRepr]
public struct CERT_CHAIN_PARA
{
	public uint32 cbSize;
	public CERT_USAGE_MATCH RequestedUsage;
}

[CRepr]
public struct CERT_REVOCATION_CHAIN_PARA
{
	public uint32 cbSize;
	public HCERTCHAINENGINE hChainEngine;
	public HCERTSTORE hAdditionalStore;
	public uint32 dwChainFlags;
	public uint32 dwUrlRetrievalTimeout;
	public FILETIME* pftCurrentTime;
	public FILETIME* pftCacheResync;
	public uint32 cbMaxUrlRetrievalByteCount;
}

[CRepr]
public struct CRL_REVOCATION_INFO
{
	public CRL_ENTRY* pCrlEntry;
	public CRL_CONTEXT* pCrlContext;
	public CERT_CHAIN_CONTEXT* pCrlIssuerChain;
}

[CRepr]
public struct CERT_CHAIN_FIND_BY_ISSUER_PARA
{
	public uint32 cbSize;
	public PSTR pszUsageIdentifier;
	public uint32 dwKeySpec;
	public uint32 dwAcquirePrivateKeyFlags;
	public uint32 cIssuer;
	public CRYPTOAPI_BLOB* rgIssuer;
	public PFN_CERT_CHAIN_FIND_BY_ISSUER_CALLBACK pfnFindCallback;
	public void* pvFindArg;
}

[CRepr]
public struct CERT_CHAIN_POLICY_PARA
{
	public uint32 cbSize;
	public CERT_CHAIN_POLICY_FLAGS dwFlags;
	public void* pvExtraPolicyPara;
}

[CRepr]
public struct CERT_CHAIN_POLICY_STATUS
{
	public uint32 cbSize;
	public uint32 dwError;
	public int32 lChainIndex;
	public int32 lElementIndex;
	public void* pvExtraPolicyStatus;
}

[CRepr]
public struct AUTHENTICODE_EXTRA_CERT_CHAIN_POLICY_PARA
{
	public uint32 cbSize;
	public uint32 dwRegPolicySettings;
	public CMSG_SIGNER_INFO* pSignerInfo;
}

[CRepr]
public struct AUTHENTICODE_EXTRA_CERT_CHAIN_POLICY_STATUS
{
	public uint32 cbSize;
	public BOOL fCommercial;
}

[CRepr]
public struct AUTHENTICODE_TS_EXTRA_CERT_CHAIN_POLICY_PARA
{
	public uint32 cbSize;
	public uint32 dwRegPolicySettings;
	public BOOL fCommercial;
}

[CRepr]
public struct HTTPSPolicyCallbackData
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 cbStruct;
		public uint32 cbSize;
	}
	public using _Anonymous_e__Union Anonymous;
	public HTTPSPOLICY_CALLBACK_DATA_AUTH_TYPE dwAuthType;
	public uint32 fdwChecks;
	public PWSTR pwszServerName;
}

[CRepr]
public struct EV_EXTRA_CERT_CHAIN_POLICY_PARA
{
	public uint32 cbSize;
	public CERT_ROOT_PROGRAM_FLAGS dwRootProgramQualifierFlags;
}

[CRepr]
public struct EV_EXTRA_CERT_CHAIN_POLICY_STATUS
{
	public uint32 cbSize;
	public uint32 dwQualifiers;
	public uint32 dwIssuanceUsageIndex;
}

[CRepr]
public struct SSL_F12_EXTRA_CERT_CHAIN_POLICY_STATUS
{
	public uint32 cbSize;
	public uint32 dwErrorLevel;
	public uint32 dwErrorCategory;
	public uint32 dwReserved;
	public char16[256] wszErrorText;
}

[CRepr]
public struct SSL_HPKP_HEADER_EXTRA_CERT_CHAIN_POLICY_PARA
{
	public uint32 cbSize;
	public uint32 dwReserved;
	public PWSTR pwszServerName;
	public PSTR[2] rgpszHpkpValue;
}

[CRepr]
public struct SSL_KEY_PIN_EXTRA_CERT_CHAIN_POLICY_PARA
{
	public uint32 cbSize;
	public uint32 dwReserved;
	public PWSTR pwszServerName;
}

[CRepr]
public struct SSL_KEY_PIN_EXTRA_CERT_CHAIN_POLICY_STATUS
{
	public uint32 cbSize;
	public int32 lError;
	public char16[512] wszErrorText;
}

[CRepr]
public struct CRYPT_PKCS12_PBE_PARAMS
{
	public int32 iIterations;
	public uint32 cbSalt;
}

[CRepr]
public struct PKCS12_PBES2_EXPORT_PARAMS
{
	public uint32 dwSize;
	public void* hNcryptDescriptor;
	public PWSTR pwszPbes2Alg;
}

[CRepr]
public struct CERT_SERVER_OCSP_RESPONSE_CONTEXT
{
	public uint32 cbSize;
	public uint8* pbEncodedOcspResponse;
	public uint32 cbEncodedOcspResponse;
}

[CRepr]
public struct CERT_SERVER_OCSP_RESPONSE_OPEN_PARA
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint32* pcbUsedSize;
	public PWSTR pwszOcspDirectory;
	public PFN_CERT_SERVER_OCSP_RESPONSE_UPDATE_CALLBACK pfnUpdateCallback;
	public void* pvUpdateCallbackArg;
}

[CRepr]
public struct CERT_SELECT_CHAIN_PARA
{
	public HCERTCHAINENGINE hChainEngine;
	public FILETIME* pTime;
	public HCERTSTORE hAdditionalStore;
	public CERT_CHAIN_PARA* pChainPara;
	public uint32 dwFlags;
}

[CRepr]
public struct CERT_SELECT_CRITERIA
{
	public CERT_SELECT_CRITERIA_TYPE dwType;
	public uint32 cPara;
	public void** ppPara;
}

[CRepr]
public struct CRYPT_TIMESTAMP_REQUEST
{
	public CRYPT_TIMESTAMP_VERSION dwVersion;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPTOAPI_BLOB HashedMessage;
	public PSTR pszTSAPolicyId;
	public CRYPTOAPI_BLOB Nonce;
	public BOOL fCertReq;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CRYPT_TIMESTAMP_RESPONSE
{
	public CRYPT_TIMESTAMP_RESPONSE_STATUS dwStatus;
	public uint32 cFreeText;
	public PWSTR* rgFreeText;
	public CRYPT_BIT_BLOB FailureInfo;
	public CRYPTOAPI_BLOB ContentInfo;
}

[CRepr]
public struct CRYPT_TIMESTAMP_ACCURACY
{
	public uint32 dwSeconds;
	public uint32 dwMillis;
	public uint32 dwMicros;
}

[CRepr]
public struct CRYPT_TIMESTAMP_INFO
{
	public uint32 dwVersion;
	public PSTR pszTSAPolicyId;
	public CRYPT_ALGORITHM_IDENTIFIER HashAlgorithm;
	public CRYPTOAPI_BLOB HashedMessage;
	public CRYPTOAPI_BLOB SerialNumber;
	public FILETIME ftTime;
	public CRYPT_TIMESTAMP_ACCURACY* pvAccuracy;
	public BOOL fOrdering;
	public CRYPTOAPI_BLOB Nonce;
	public CRYPTOAPI_BLOB Tsa;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CRYPT_TIMESTAMP_CONTEXT
{
	public uint32 cbEncoded;
	public uint8* pbEncoded;
	public CRYPT_TIMESTAMP_INFO* pTimeStamp;
}

[CRepr]
public struct CRYPT_TIMESTAMP_PARA
{
	public PSTR pszTSAPolicyId;
	public BOOL fRequestCerts;
	public CRYPTOAPI_BLOB Nonce;
	public uint32 cExtension;
	public CERT_EXTENSION* rgExtension;
}

[CRepr]
public struct CRYPT_OBJECT_LOCATOR_PROVIDER_TABLE
{
	public uint32 cbSize;
	public PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_GET pfnGet;
	public PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_RELEASE pfnRelease;
	public PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FREE_PASSWORD pfnFreePassword;
	public PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FREE pfnFree;
	public PFN_CRYPT_OBJECT_LOCATOR_PROVIDER_FREE_IDENTIFIER pfnFreeIdentifier;
}

[CRepr]
public struct CRYPTPROTECT_PROMPTSTRUCT
{
	public uint32 cbSize;
	public uint32 dwPromptFlags;
	public HWND hwndApp;
	public PWSTR szPrompt;
}

[CRepr]
public struct NCRYPT_PROTECT_STREAM_INFO
{
	public PFNCryptStreamOutputCallback pfnStreamOutput;
	public void* pvCallbackCtxt;
}

[CRepr]
public struct NCRYPT_PROTECT_STREAM_INFO_EX
{
	public PFNCryptStreamOutputCallbackEx pfnStreamOutput;
	public void* pvCallbackCtxt;
}

[CRepr]
public struct CRYPT_XML_BLOB
{
	public CRYPT_XML_CHARSET dwCharset;
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct CRYPT_XML_DATA_BLOB
{
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct CRYPT_XML_PROPERTY
{
	public CRYPT_XML_PROPERTY_ID dwPropId;
	public void* pvValue;
	public uint32 cbValue;
}

[CRepr]
public struct CRYPT_XML_DATA_PROVIDER
{
	public void* pvCallbackState;
	public uint32 cbBufferSize;
	public PFN_CRYPT_XML_DATA_PROVIDER_READ pfnRead;
	public PFN_CRYPT_XML_DATA_PROVIDER_CLOSE pfnClose;
}

[CRepr]
public struct CRYPT_XML_STATUS
{
	public uint32 cbSize;
	public CRYPT_XML_STATUS_ERROR_STATUS dwErrorStatus;
	public CRYPT_XML_STATUS_INFO_STATUS dwInfoStatus;
}

[CRepr]
public struct CRYPT_XML_ALGORITHM
{
	public uint32 cbSize;
	public PWSTR wszAlgorithm;
	public CRYPT_XML_BLOB Encoded;
}

[CRepr]
public struct CRYPT_XML_TRANSFORM_INFO
{
	public uint32 cbSize;
	public PWSTR wszAlgorithm;
	public uint32 cbBufferSize;
	public CRYPT_XML_TRANSFORM_FLAGS dwFlags;
	public PFN_CRYPT_XML_CREATE_TRANSFORM pfnCreateTransform;
}

[CRepr]
public struct CRYPT_XML_TRANSFORM_CHAIN_CONFIG
{
	public uint32 cbSize;
	public uint32 cTransformInfo;
	public CRYPT_XML_TRANSFORM_INFO** rgpTransformInfo;
}

[CRepr]
public struct CRYPT_XML_KEY_DSA_KEY_VALUE
{
	public CRYPT_XML_DATA_BLOB P;
	public CRYPT_XML_DATA_BLOB Q;
	public CRYPT_XML_DATA_BLOB G;
	public CRYPT_XML_DATA_BLOB Y;
	public CRYPT_XML_DATA_BLOB J;
	public CRYPT_XML_DATA_BLOB Seed;
	public CRYPT_XML_DATA_BLOB Counter;
}

[CRepr]
public struct CRYPT_XML_KEY_ECDSA_KEY_VALUE
{
	public PWSTR wszNamedCurve;
	public CRYPT_XML_DATA_BLOB X;
	public CRYPT_XML_DATA_BLOB Y;
	public CRYPT_XML_BLOB ExplicitPara;
}

[CRepr]
public struct CRYPT_XML_KEY_RSA_KEY_VALUE
{
	public CRYPT_XML_DATA_BLOB Modulus;
	public CRYPT_XML_DATA_BLOB Exponent;
}

[CRepr]
public struct CRYPT_XML_KEY_VALUE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CRYPT_XML_KEY_DSA_KEY_VALUE DSAKeyValue;
		public CRYPT_XML_KEY_RSA_KEY_VALUE RSAKeyValue;
		public CRYPT_XML_KEY_ECDSA_KEY_VALUE ECDSAKeyValue;
		public CRYPT_XML_BLOB Custom;
	}
	public CRYPT_XML_KEY_VALUE_TYPE dwType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CRYPT_XML_ISSUER_SERIAL
{
	public PWSTR wszIssuer;
	public PWSTR wszSerial;
}

[CRepr]
public struct CRYPT_XML_X509DATA_ITEM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CRYPT_XML_ISSUER_SERIAL IssuerSerial;
		public CRYPT_XML_DATA_BLOB SKI;
		public PWSTR wszSubjectName;
		public CRYPT_XML_DATA_BLOB Certificate;
		public CRYPT_XML_DATA_BLOB CRL;
		public CRYPT_XML_BLOB Custom;
	}
	public CRYPT_XML_X509DATA_TYPE dwType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CRYPT_XML_X509DATA
{
	public uint32 cX509Data;
	public CRYPT_XML_X509DATA_ITEM* rgX509Data;
}

[CRepr]
public struct CRYPT_XML_KEY_INFO_ITEM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PWSTR wszKeyName;
		public CRYPT_XML_KEY_VALUE KeyValue;
		public CRYPT_XML_BLOB RetrievalMethod;
		public CRYPT_XML_X509DATA X509Data;
		public CRYPT_XML_BLOB Custom;
	}
	public CRYPT_XML_KEYINFO_TYPE dwType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CRYPT_XML_KEY_INFO
{
	public uint32 cbSize;
	public PWSTR wszId;
	public uint32 cKeyInfo;
	public CRYPT_XML_KEY_INFO_ITEM* rgKeyInfo;
	public BCRYPT_KEY_HANDLE hVerifyKey;
}

[CRepr]
public struct CRYPT_XML_REFERENCE
{
	public uint32 cbSize;
	public void* hReference;
	public PWSTR wszId;
	public PWSTR wszUri;
	public PWSTR wszType;
	public CRYPT_XML_ALGORITHM DigestMethod;
	public CRYPTOAPI_BLOB DigestValue;
	public uint32 cTransform;
	public CRYPT_XML_ALGORITHM* rgTransform;
}

[CRepr]
public struct CRYPT_XML_REFERENCES
{
	public uint32 cReference;
	public CRYPT_XML_REFERENCE** rgpReference;
}

[CRepr]
public struct CRYPT_XML_SIGNED_INFO
{
	public uint32 cbSize;
	public PWSTR wszId;
	public CRYPT_XML_ALGORITHM Canonicalization;
	public CRYPT_XML_ALGORITHM SignatureMethod;
	public uint32 cReference;
	public CRYPT_XML_REFERENCE** rgpReference;
	public CRYPT_XML_BLOB Encoded;
}

[CRepr]
public struct CRYPT_XML_OBJECT
{
	public uint32 cbSize;
	public void* hObject;
	public PWSTR wszId;
	public PWSTR wszMimeType;
	public PWSTR wszEncoding;
	public CRYPT_XML_REFERENCES Manifest;
	public CRYPT_XML_BLOB Encoded;
}

[CRepr]
public struct CRYPT_XML_SIGNATURE
{
	public uint32 cbSize;
	public void* hSignature;
	public PWSTR wszId;
	public CRYPT_XML_SIGNED_INFO SignedInfo;
	public CRYPTOAPI_BLOB SignatureValue;
	public CRYPT_XML_KEY_INFO* pKeyInfo;
	public uint32 cObject;
	public CRYPT_XML_OBJECT** rgpObject;
}

[CRepr]
public struct CRYPT_XML_DOC_CTXT
{
	public uint32 cbSize;
	public void* hDocCtxt;
	public CRYPT_XML_TRANSFORM_CHAIN_CONFIG* pTransformsConfig;
	public uint32 cSignature;
	public CRYPT_XML_SIGNATURE** rgpSignature;
}

[CRepr]
public struct CRYPT_XML_KEYINFO_PARAM
{
	public PWSTR wszId;
	public PWSTR wszKeyName;
	public CRYPTOAPI_BLOB SKI;
	public PWSTR wszSubjectName;
	public uint32 cCertificate;
	public CRYPTOAPI_BLOB* rgCertificate;
	public uint32 cCRL;
	public CRYPTOAPI_BLOB* rgCRL;
}

[CRepr]
public struct CRYPT_XML_ALGORITHM_INFO
{
	public uint32 cbSize;
	public PWSTR wszAlgorithmURI;
	public PWSTR wszName;
	public CRYPT_XML_GROUP_ID dwGroupId;
	public PWSTR wszCNGAlgid;
	public PWSTR wszCNGExtraAlgid;
	public uint32 dwSignFlags;
	public uint32 dwVerifyFlags;
	public void* pvPaddingInfo;
	public void* pvExtraInfo;
}

[CRepr]
public struct CRYPT_XML_CRYPTOGRAPHIC_INTERFACE
{
	public uint32 cbSize;
	public CryptXmlDllEncodeAlgorithm fpCryptXmlEncodeAlgorithm;
	public CryptXmlDllCreateDigest fpCryptXmlCreateDigest;
	public CryptXmlDllDigestData fpCryptXmlDigestData;
	public CryptXmlDllFinalizeDigest fpCryptXmlFinalizeDigest;
	public CryptXmlDllCloseDigest fpCryptXmlCloseDigest;
	public CryptXmlDllSignData fpCryptXmlSignData;
	public CryptXmlDllVerifySignature fpCryptXmlVerifySignature;
	public CryptXmlDllGetAlgorithmInfo fpCryptXmlGetAlgorithmInfo;
}

[CRepr]
public struct INFORMATIONCARD_ASYMMETRIC_CRYPTO_PARAMETERS
{
	public int32 keySize;
	public PWSTR keyExchangeAlgorithm;
	public PWSTR signatureAlgorithm;
}

[CRepr]
public struct INFORMATIONCARD_SYMMETRIC_CRYPTO_PARAMETERS
{
	public int32 keySize;
	public int32 blockSize;
	public int32 feedbackSize;
}

[CRepr]
public struct INFORMATIONCARD_TRANSFORM_CRYPTO_PARAMETERS
{
	public int32 inputBlockSize;
	public int32 outputBlockSize;
	public BOOL canTransformMultipleBlocks;
	public BOOL canReuseTransform;
}

[CRepr]
public struct INFORMATIONCARD_HASH_CRYPTO_PARAMETERS
{
	public int32 hashSize;
	public INFORMATIONCARD_TRANSFORM_CRYPTO_PARAMETERS transform;
}

[CRepr]
public struct INFORMATIONCARD_CRYPTO_HANDLE
{
	public HandleType type;
	public int64 expiration;
	public void* cryptoParameters;
}

[CRepr, Packed(1)]
public struct GENERIC_XML_TOKEN
{
	public FILETIME createDate;
	public FILETIME expiryDate;
	public PWSTR xmlToken;
	public PWSTR internalTokenReference;
	public PWSTR externalTokenReference;
}

[CRepr]
public struct POLICY_ELEMENT
{
	public PWSTR targetEndpointAddress;
	public PWSTR issuerEndpointAddress;
	public PWSTR issuedTokenParameters;
	public PWSTR privacyNoticeLink;
	public uint32 privacyNoticeVersion;
	public BOOL useManagedPresentation;
}

[CRepr]
public struct ENDPOINTADDRESS
{
	public PWSTR serviceUrl;
	public PWSTR policyUrl;
	public CRYPTOAPI_BLOB rawCertificate;
}

[CRepr]
public struct ENDPOINTADDRESS2
{
	public PWSTR serviceUrl;
	public PWSTR policyUrl;
	public uint32 identityType;
	public void* identityBytes;
}

[CRepr]
public struct CERTIFICATE_CHAIN_BLOB
{
	public uint32 certCount;
	public CRYPTOAPI_BLOB* rawCertificates;
}

[CRepr]
public struct CLAIMLIST
{
	public uint32 count;
	public PWSTR* claims;
}

[CRepr]
public struct RECIPIENTPOLICY
{
	public ENDPOINTADDRESS recipient;
	public ENDPOINTADDRESS issuer;
	public PWSTR tokenType;
	public CLAIMLIST requiredClaims;
	public CLAIMLIST optionalClaims;
	public PWSTR privacyUrl;
	public uint32 privacyVersion;
}

[CRepr]
public struct RECIPIENTPOLICY2
{
	public ENDPOINTADDRESS2 recipient;
	public ENDPOINTADDRESS2 issuer;
	public PWSTR tokenType;
	public CLAIMLIST requiredClaims;
	public CLAIMLIST optionalClaims;
	public PWSTR privacyUrl;
	public uint32 privacyVersion;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_CCertSrvSetupKeyInformation = .(0x38373906, 0x5433, 0x4633, 0xb0, 0xfb, 0x29, 0xb7, 0xe7, 0x82, 0x62, 0xe1);


	public const Guid CLSID_CCertSrvSetup = .(0x961f180f, 0xf55c, 0x413d, 0xa9, 0xb3, 0x7d, 0x2a, 0xf4, 0xd8, 0xe4, 0x2f);


	public const Guid CLSID_CMSCEPSetup = .(0xaa4f5c02, 0x8e7c, 0x49c4, 0x94, 0xfa, 0x67, 0xa5, 0xcc, 0x5e, 0xad, 0xb4);


	public const Guid CLSID_CCertificateEnrollmentServerSetup = .(0x9902f3bc, 0x88af, 0x4cf8, 0xae, 0x62, 0x71, 0x40, 0x53, 0x15, 0x52, 0xb6);


	public const Guid CLSID_CCertificateEnrollmentPolicyServerSetup = .(0xafe2fa32, 0x41b1, 0x459d, 0xa5, 0xde, 0x49, 0xad, 0xd8, 0xa7, 0x21, 0x82);


}
#endregion

#region COM Types
[CRepr]struct ICertSrvSetupKeyInformation : IDispatch
{
	public new const Guid IID = .(0x6ba73778, 0x36da, 0x4c39, 0x8a, 0x85, 0xbc, 0xfa, 0x7d, 0x00, 0x07, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lVal) put_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Existing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bVal) put_Existing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_ContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrVal) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_ExistingCACertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varVal) put_ExistingCACertificate;
	}


	public HRESULT get_ProviderName(BSTR* pVal) mut => VT.[Friend]get_ProviderName(&this, pVal);

	public HRESULT put_ProviderName(BSTR bstrVal) mut => VT.[Friend]put_ProviderName(&this, bstrVal);

	public HRESULT get_Length(int32* pVal) mut => VT.[Friend]get_Length(&this, pVal);

	public HRESULT put_Length(int32 lVal) mut => VT.[Friend]put_Length(&this, lVal);

	public HRESULT get_Existing(int16* pVal) mut => VT.[Friend]get_Existing(&this, pVal);

	public HRESULT put_Existing(int16 bVal) mut => VT.[Friend]put_Existing(&this, bVal);

	public HRESULT get_ContainerName(BSTR* pVal) mut => VT.[Friend]get_ContainerName(&this, pVal);

	public HRESULT put_ContainerName(BSTR bstrVal) mut => VT.[Friend]put_ContainerName(&this, bstrVal);

	public HRESULT get_HashAlgorithm(BSTR* pVal) mut => VT.[Friend]get_HashAlgorithm(&this, pVal);

	public HRESULT put_HashAlgorithm(BSTR bstrVal) mut => VT.[Friend]put_HashAlgorithm(&this, bstrVal);

	public HRESULT get_ExistingCACertificate(VARIANT* pVal) mut => VT.[Friend]get_ExistingCACertificate(&this, pVal);

	public HRESULT put_ExistingCACertificate(VARIANT varVal) mut => VT.[Friend]put_ExistingCACertificate(&this, varVal);
}

[CRepr]struct ICertSrvSetupKeyInformationCollection : IDispatch
{
	public new const Guid IID = .(0xe65c8b00, 0xe58f, 0x41f9, 0xa9, 0xec, 0xa2, 0x8d, 0x74, 0x27, 0xc8, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertSrvSetupKeyInformation* pIKeyInformation) Add;
	}


	public HRESULT get__NewEnum(IUnknown** ppVal) mut => VT.[Friend]get__NewEnum(&this, ppVal);

	public HRESULT get_Item(int32 Index, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT Add(ICertSrvSetupKeyInformation* pIKeyInformation) mut => VT.[Friend]Add(&this, pIKeyInformation);
}

[CRepr]struct ICertSrvSetup : IDispatch
{
	public new const Guid IID = .(0xb760a1bb, 0x4784, 0x44c0, 0x8f, 0x12, 0x55, 0x5f, 0x07, 0x80, 0xff, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_CAErrorId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_CAErrorString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bServer, int16 bClient) InitializeDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CASetupProperty propertyId, VARIANT* pPropertyValue) GetCASetupProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CASetupProperty propertyId, VARIANT* pPropertyValue) SetCASetupProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CASetupProperty propertyId, int16* pbEditable) IsPropertyEditable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pCATypes) GetSupportedCATypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) GetProviderNameList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProviderName, VARIANT* pVal) GetKeyLengthList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProviderName, VARIANT* pVal) GetHashAlgorithmList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProviderName, VARIANT* pVal) GetPrivateKeyContainerList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertSrvSetupKeyInformationCollection** ppVal) GetExistingCACertificates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFileName, BSTR bstrPasswd, int16 bOverwriteExistingKey, ICertSrvSetupKeyInformation** ppVal) CAImportPFX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCADN, int16 bIgnoreUnicode, int16 bOverwriteExistingKey, int16 bOverwriteExistingCAInDS) SetCADistinguishedName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDBDirectory, BSTR bstrLogDirectory, BSTR bstrSharedFolder, int16 bForceOverwrite) SetDatabaseInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCAConfiguration) SetParentCAInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCAConfiguration) SetWebCAInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Install;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bClientOnly) PreUnInstall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PostUnInstall;
	}


	public HRESULT get_CAErrorId(int32* pVal) mut => VT.[Friend]get_CAErrorId(&this, pVal);

	public HRESULT get_CAErrorString(BSTR* pVal) mut => VT.[Friend]get_CAErrorString(&this, pVal);

	public HRESULT InitializeDefaults(int16 bServer, int16 bClient) mut => VT.[Friend]InitializeDefaults(&this, bServer, bClient);

	public HRESULT GetCASetupProperty(CASetupProperty propertyId, VARIANT* pPropertyValue) mut => VT.[Friend]GetCASetupProperty(&this, propertyId, pPropertyValue);

	public HRESULT SetCASetupProperty(CASetupProperty propertyId, VARIANT* pPropertyValue) mut => VT.[Friend]SetCASetupProperty(&this, propertyId, pPropertyValue);

	public HRESULT IsPropertyEditable(CASetupProperty propertyId, int16* pbEditable) mut => VT.[Friend]IsPropertyEditable(&this, propertyId, pbEditable);

	public HRESULT GetSupportedCATypes(VARIANT* pCATypes) mut => VT.[Friend]GetSupportedCATypes(&this, pCATypes);

	public HRESULT GetProviderNameList(VARIANT* pVal) mut => VT.[Friend]GetProviderNameList(&this, pVal);

	public HRESULT GetKeyLengthList(BSTR bstrProviderName, VARIANT* pVal) mut => VT.[Friend]GetKeyLengthList(&this, bstrProviderName, pVal);

	public HRESULT GetHashAlgorithmList(BSTR bstrProviderName, VARIANT* pVal) mut => VT.[Friend]GetHashAlgorithmList(&this, bstrProviderName, pVal);

	public HRESULT GetPrivateKeyContainerList(BSTR bstrProviderName, VARIANT* pVal) mut => VT.[Friend]GetPrivateKeyContainerList(&this, bstrProviderName, pVal);

	public HRESULT GetExistingCACertificates(ICertSrvSetupKeyInformationCollection** ppVal) mut => VT.[Friend]GetExistingCACertificates(&this, ppVal);

	public HRESULT CAImportPFX(BSTR bstrFileName, BSTR bstrPasswd, int16 bOverwriteExistingKey, ICertSrvSetupKeyInformation** ppVal) mut => VT.[Friend]CAImportPFX(&this, bstrFileName, bstrPasswd, bOverwriteExistingKey, ppVal);

	public HRESULT SetCADistinguishedName(BSTR bstrCADN, int16 bIgnoreUnicode, int16 bOverwriteExistingKey, int16 bOverwriteExistingCAInDS) mut => VT.[Friend]SetCADistinguishedName(&this, bstrCADN, bIgnoreUnicode, bOverwriteExistingKey, bOverwriteExistingCAInDS);

	public HRESULT SetDatabaseInformation(BSTR bstrDBDirectory, BSTR bstrLogDirectory, BSTR bstrSharedFolder, int16 bForceOverwrite) mut => VT.[Friend]SetDatabaseInformation(&this, bstrDBDirectory, bstrLogDirectory, bstrSharedFolder, bForceOverwrite);

	public HRESULT SetParentCAInformation(BSTR bstrCAConfiguration) mut => VT.[Friend]SetParentCAInformation(&this, bstrCAConfiguration);

	public HRESULT SetWebCAInformation(BSTR bstrCAConfiguration) mut => VT.[Friend]SetWebCAInformation(&this, bstrCAConfiguration);

	public HRESULT Install() mut => VT.[Friend]Install(&this);

	public HRESULT PreUnInstall(int16 bClientOnly) mut => VT.[Friend]PreUnInstall(&this, bClientOnly);

	public HRESULT PostUnInstall() mut => VT.[Friend]PostUnInstall(&this);
}

[CRepr]struct IMSCEPSetup : IDispatch
{
	public new const Guid IID = .(0x4f7761bb, 0x9f3b, 0x4592, 0x9e, 0xe0, 0x9a, 0x73, 0x25, 0x9c, 0x31, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_MSCEPErrorId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_MSCEPErrorString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitializeDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSCEPSetupProperty propertyId, VARIANT* pVal) GetMSCEPSetupProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSCEPSetupProperty propertyId, VARIANT* pPropertyValue) SetMSCEPSetupProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUserName, BSTR bstrPassword) SetAccountInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEmpty) IsMSCEPStoreEmpty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bExchange, VARIANT* pVal) GetProviderNameList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bExchange, BSTR bstrProviderName, VARIANT* pVal) GetKeyLengthList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Install;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PreUnInstall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PostUnInstall;
	}


	public HRESULT get_MSCEPErrorId(int32* pVal) mut => VT.[Friend]get_MSCEPErrorId(&this, pVal);

	public HRESULT get_MSCEPErrorString(BSTR* pVal) mut => VT.[Friend]get_MSCEPErrorString(&this, pVal);

	public HRESULT InitializeDefaults() mut => VT.[Friend]InitializeDefaults(&this);

	public HRESULT GetMSCEPSetupProperty(MSCEPSetupProperty propertyId, VARIANT* pVal) mut => VT.[Friend]GetMSCEPSetupProperty(&this, propertyId, pVal);

	public HRESULT SetMSCEPSetupProperty(MSCEPSetupProperty propertyId, VARIANT* pPropertyValue) mut => VT.[Friend]SetMSCEPSetupProperty(&this, propertyId, pPropertyValue);

	public HRESULT SetAccountInformation(BSTR bstrUserName, BSTR bstrPassword) mut => VT.[Friend]SetAccountInformation(&this, bstrUserName, bstrPassword);

	public HRESULT IsMSCEPStoreEmpty(int16* pbEmpty) mut => VT.[Friend]IsMSCEPStoreEmpty(&this, pbEmpty);

	public HRESULT GetProviderNameList(int16 bExchange, VARIANT* pVal) mut => VT.[Friend]GetProviderNameList(&this, bExchange, pVal);

	public HRESULT GetKeyLengthList(int16 bExchange, BSTR bstrProviderName, VARIANT* pVal) mut => VT.[Friend]GetKeyLengthList(&this, bExchange, bstrProviderName, pVal);

	public HRESULT Install() mut => VT.[Friend]Install(&this);

	public HRESULT PreUnInstall() mut => VT.[Friend]PreUnInstall(&this);

	public HRESULT PostUnInstall() mut => VT.[Friend]PostUnInstall(&this);
}

[CRepr]struct ICertificateEnrollmentServerSetup : IDispatch
{
	public new const Guid IID = .(0x70027fdb, 0x9dd9, 0x4921, 0x89, 0x44, 0xb3, 0x5c, 0xb3, 0x1b, 0xd2, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ErrorString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitializeInstallDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CESSetupProperty propertyId, VARIANT* pPropertyValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CESSetupProperty propertyId, VARIANT* pPropertyValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUsername, BSTR bstrPassword) SetApplicationPoolCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Install;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pCAConfig, VARIANT* pAuthentication) UnInstall;
	}


	public HRESULT get_ErrorString(BSTR* pVal) mut => VT.[Friend]get_ErrorString(&this, pVal);

	public HRESULT InitializeInstallDefaults() mut => VT.[Friend]InitializeInstallDefaults(&this);

	public HRESULT GetProperty(CESSetupProperty propertyId, VARIANT* pPropertyValue) mut => VT.[Friend]GetProperty(&this, propertyId, pPropertyValue);

	public HRESULT SetProperty(CESSetupProperty propertyId, VARIANT* pPropertyValue) mut => VT.[Friend]SetProperty(&this, propertyId, pPropertyValue);

	public HRESULT SetApplicationPoolCredentials(BSTR bstrUsername, BSTR bstrPassword) mut => VT.[Friend]SetApplicationPoolCredentials(&this, bstrUsername, bstrPassword);

	public HRESULT Install() mut => VT.[Friend]Install(&this);

	public HRESULT UnInstall(VARIANT* pCAConfig, VARIANT* pAuthentication) mut => VT.[Friend]UnInstall(&this, pCAConfig, pAuthentication);
}

[CRepr]struct ICertificateEnrollmentPolicyServerSetup : IDispatch
{
	public new const Guid IID = .(0x859252cc, 0x238c, 0x4a88, 0xb8, 0xfd, 0xa3, 0x7e, 0x7d, 0x04, 0xe6, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ErrorString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitializeInstallDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CEPSetupProperty propertyId, VARIANT* pPropertyValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CEPSetupProperty propertyId, VARIANT* pPropertyValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Install;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pAuthKeyBasedRenewal) UnInstall;
	}


	public HRESULT get_ErrorString(BSTR* pVal) mut => VT.[Friend]get_ErrorString(&this, pVal);

	public HRESULT InitializeInstallDefaults() mut => VT.[Friend]InitializeInstallDefaults(&this);

	public HRESULT GetProperty(CEPSetupProperty propertyId, VARIANT* pPropertyValue) mut => VT.[Friend]GetProperty(&this, propertyId, pPropertyValue);

	public HRESULT SetProperty(CEPSetupProperty propertyId, VARIANT* pPropertyValue) mut => VT.[Friend]SetProperty(&this, propertyId, pPropertyValue);

	public HRESULT Install() mut => VT.[Friend]Install(&this);

	public HRESULT UnInstall(VARIANT* pAuthKeyBasedRenewal) mut => VT.[Friend]UnInstall(&this, pAuthKeyBasedRenewal);
}

#endregion

#region Functions
public static
{
	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptAcquireContextA(uint* phProv, PSTR szContainer, PSTR szProvider, uint32 dwProvType, uint32 dwFlags);
	public static BOOL CryptAcquireContext(uint* phProv, PSTR szContainer, PSTR szProvider, uint32 dwProvType, uint32 dwFlags) => CryptAcquireContextA(phProv, szContainer, szProvider, dwProvType, dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptAcquireContextW(uint* phProv, PWSTR szContainer, PWSTR szProvider, uint32 dwProvType, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptReleaseContext(uint hProv, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGenKey(uint hProv, uint32 Algid, CRYPT_KEY_FLAGS dwFlags, uint* phKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDeriveKey(uint hProv, uint32 Algid, uint hBaseData, uint32 dwFlags, uint* phKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDestroyKey(uint hKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetKeyParam(uint hKey, CRYPT_KEY_PARAM_ID dwParam, uint8* pbData, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetKeyParam(uint hKey, CRYPT_KEY_PARAM_ID dwParam, uint8* pbData, uint32* pdwDataLen, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetHashParam(uint hHash, CRYPT_SET_HASH_PARAM dwParam, uint8* pbData, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetHashParam(uint hHash, uint32 dwParam, uint8* pbData, uint32* pdwDataLen, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetProvParam(uint hProv, CRYPT_SET_PROV_PARAM_ID dwParam, uint8* pbData, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetProvParam(uint hProv, uint32 dwParam, uint8* pbData, uint32* pdwDataLen, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGenRandom(uint hProv, uint32 dwLen, uint8* pbBuffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetUserKey(uint hProv, uint32 dwKeySpec, uint* phUserKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptExportKey(uint hKey, uint hExpKey, uint32 dwBlobType, CRYPT_KEY_FLAGS dwFlags, uint8* pbData, uint32* pdwDataLen);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptImportKey(uint hProv, uint8* pbData, uint32 dwDataLen, uint hPubKey, CRYPT_KEY_FLAGS dwFlags, uint* phKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEncrypt(uint hKey, uint hHash, BOOL Final, uint32 dwFlags, uint8* pbData, uint32* pdwDataLen, uint32 dwBufLen);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDecrypt(uint hKey, uint hHash, BOOL Final, uint32 dwFlags, uint8* pbData, uint32* pdwDataLen);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCreateHash(uint hProv, uint32 Algid, uint hKey, uint32 dwFlags, uint* phHash);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptHashData(uint hHash, uint8* pbData, uint32 dwDataLen, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptHashSessionKey(uint hHash, uint hKey, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDestroyHash(uint hHash);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSignHashA(uint hHash, uint32 dwKeySpec, PSTR szDescription, uint32 dwFlags, uint8* pbSignature, uint32* pdwSigLen);
	public static BOOL CryptSignHash(uint hHash, uint32 dwKeySpec, PSTR szDescription, uint32 dwFlags, uint8* pbSignature, uint32* pdwSigLen) => CryptSignHashA(hHash, dwKeySpec, szDescription, dwFlags, pbSignature, pdwSigLen);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSignHashW(uint hHash, uint32 dwKeySpec, PWSTR szDescription, uint32 dwFlags, uint8* pbSignature, uint32* pdwSigLen);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifySignatureA(uint hHash, uint8* pbSignature, uint32 dwSigLen, uint hPubKey, PSTR szDescription, uint32 dwFlags);
	public static BOOL CryptVerifySignature(uint hHash, uint8* pbSignature, uint32 dwSigLen, uint hPubKey, PSTR szDescription, uint32 dwFlags) => CryptVerifySignatureA(hHash, pbSignature, dwSigLen, hPubKey, szDescription, dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifySignatureW(uint hHash, uint8* pbSignature, uint32 dwSigLen, uint hPubKey, PWSTR szDescription, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetProviderA(PSTR pszProvName, uint32 dwProvType);
	public static BOOL CryptSetProvider(PSTR pszProvName, uint32 dwProvType) => CryptSetProviderA(pszProvName, dwProvType);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetProviderW(PWSTR pszProvName, uint32 dwProvType);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetProviderExA(PSTR pszProvName, uint32 dwProvType, uint32* pdwReserved, uint32 dwFlags);
	public static BOOL CryptSetProviderEx(PSTR pszProvName, uint32 dwProvType, uint32* pdwReserved, uint32 dwFlags) => CryptSetProviderExA(pszProvName, dwProvType, pdwReserved, dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetProviderExW(PWSTR pszProvName, uint32 dwProvType, uint32* pdwReserved, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetDefaultProviderA(uint32 dwProvType, uint32* pdwReserved, uint32 dwFlags, PSTR pszProvName, uint32* pcbProvName);
	public static BOOL CryptGetDefaultProvider(uint32 dwProvType, uint32* pdwReserved, uint32 dwFlags, PSTR pszProvName, uint32* pcbProvName) => CryptGetDefaultProviderA(dwProvType, pdwReserved, dwFlags, pszProvName, pcbProvName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetDefaultProviderW(uint32 dwProvType, uint32* pdwReserved, uint32 dwFlags, PWSTR pszProvName, uint32* pcbProvName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEnumProviderTypesA(uint32 dwIndex, uint32* pdwReserved, uint32 dwFlags, uint32* pdwProvType, PSTR szTypeName, uint32* pcbTypeName);
	public static BOOL CryptEnumProviderTypes(uint32 dwIndex, uint32* pdwReserved, uint32 dwFlags, uint32* pdwProvType, PSTR szTypeName, uint32* pcbTypeName) => CryptEnumProviderTypesA(dwIndex, pdwReserved, dwFlags, pdwProvType, szTypeName, pcbTypeName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEnumProviderTypesW(uint32 dwIndex, uint32* pdwReserved, uint32 dwFlags, uint32* pdwProvType, PWSTR szTypeName, uint32* pcbTypeName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEnumProvidersA(uint32 dwIndex, uint32* pdwReserved, uint32 dwFlags, uint32* pdwProvType, PSTR szProvName, uint32* pcbProvName);
	public static BOOL CryptEnumProviders(uint32 dwIndex, uint32* pdwReserved, uint32 dwFlags, uint32* pdwProvType, PSTR szProvName, uint32* pcbProvName) => CryptEnumProvidersA(dwIndex, pdwReserved, dwFlags, pdwProvType, szProvName, pcbProvName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEnumProvidersW(uint32 dwIndex, uint32* pdwReserved, uint32 dwFlags, uint32* pdwProvType, PWSTR szProvName, uint32* pcbProvName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptContextAddRef(uint hProv, uint32* pdwReserved, uint32 dwFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDuplicateKey(uint hKey, uint32* pdwReserved, uint32 dwFlags, uint* phKey);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDuplicateHash(uint hHash, uint32* pdwReserved, uint32 dwFlags, uint* phHash);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptOpenAlgorithmProvider(BCRYPT_ALG_HANDLE* phAlgorithm, PWSTR pszAlgId, PWSTR pszImplementation, BCRYPT_OPEN_ALGORITHM_PROVIDER_FLAGS dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptEnumAlgorithms(BCRYPT_OPERATION dwAlgOperations, uint32* pAlgCount, BCRYPT_ALGORITHM_IDENTIFIER** ppAlgList, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptEnumProviders(PWSTR pszAlgId, uint32* pImplCount, BCRYPT_PROVIDER_NAME** ppImplList, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptGetProperty(BCRYPT_HANDLE hObject, PWSTR pszProperty, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptSetProperty(BCRYPT_HANDLE hObject, PWSTR pszProperty, uint8* pbInput, uint32 cbInput, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptCloseAlgorithmProvider(BCRYPT_ALG_HANDLE hAlgorithm, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BCryptFreeBuffer(void* pvBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptGenerateSymmetricKey(BCRYPT_ALG_HANDLE hAlgorithm, BCRYPT_KEY_HANDLE* phKey, uint8* pbKeyObject, uint32 cbKeyObject, uint8* pbSecret, uint32 cbSecret, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptGenerateKeyPair(BCRYPT_ALG_HANDLE hAlgorithm, BCRYPT_KEY_HANDLE* phKey, uint32 dwLength, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptEncrypt(BCRYPT_KEY_HANDLE hKey, uint8* pbInput, uint32 cbInput, void* pPaddingInfo, uint8* pbIV, uint32 cbIV, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, NCRYPT_FLAGS dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDecrypt(BCRYPT_KEY_HANDLE hKey, uint8* pbInput, uint32 cbInput, void* pPaddingInfo, uint8* pbIV, uint32 cbIV, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, NCRYPT_FLAGS dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptExportKey(BCRYPT_KEY_HANDLE hKey, BCRYPT_KEY_HANDLE hExportKey, PWSTR pszBlobType, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptImportKey(BCRYPT_ALG_HANDLE hAlgorithm, BCRYPT_KEY_HANDLE hImportKey, PWSTR pszBlobType, BCRYPT_KEY_HANDLE* phKey, uint8* pbKeyObject, uint32 cbKeyObject, uint8* pbInput, uint32 cbInput, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptImportKeyPair(BCRYPT_ALG_HANDLE hAlgorithm, BCRYPT_KEY_HANDLE hImportKey, PWSTR pszBlobType, BCRYPT_KEY_HANDLE* phKey, uint8* pbInput, uint32 cbInput, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDuplicateKey(BCRYPT_KEY_HANDLE hKey, BCRYPT_KEY_HANDLE* phNewKey, uint8* pbKeyObject, uint32 cbKeyObject, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptFinalizeKeyPair(BCRYPT_KEY_HANDLE hKey, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDestroyKey(BCRYPT_KEY_HANDLE hKey);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDestroySecret(BCRYPT_SECRET_HANDLE hSecret);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptSignHash(BCRYPT_KEY_HANDLE hKey, void* pPaddingInfo, uint8* pbInput, uint32 cbInput, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, NCRYPT_FLAGS dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptVerifySignature(BCRYPT_KEY_HANDLE hKey, void* pPaddingInfo, uint8* pbHash, uint32 cbHash, uint8* pbSignature, uint32 cbSignature, NCRYPT_FLAGS dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptSecretAgreement(BCRYPT_KEY_HANDLE hPrivKey, BCRYPT_KEY_HANDLE hPubKey, BCRYPT_SECRET_HANDLE* phAgreedSecret, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDeriveKey(BCRYPT_SECRET_HANDLE hSharedSecret, PWSTR pwszKDF, BCryptBufferDesc* pParameterList, uint8* pbDerivedKey, uint32 cbDerivedKey, uint32* pcbResult, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptKeyDerivation(BCRYPT_KEY_HANDLE hKey, BCryptBufferDesc* pParameterList, uint8* pbDerivedKey, uint32 cbDerivedKey, uint32* pcbResult, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptCreateHash(BCRYPT_ALG_HANDLE hAlgorithm, BCRYPT_HASH_HANDLE* phHash, uint8* pbHashObject, uint32 cbHashObject, uint8* pbSecret, uint32 cbSecret, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptHashData(BCRYPT_HASH_HANDLE hHash, uint8* pbInput, uint32 cbInput, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptFinishHash(BCRYPT_HASH_HANDLE hHash, uint8* pbOutput, uint32 cbOutput, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptCreateMultiHash(BCRYPT_ALG_HANDLE hAlgorithm, BCRYPT_HASH_HANDLE* phHash, uint32 nHashes, uint8* pbHashObject, uint32 cbHashObject, uint8* pbSecret, uint32 cbSecret, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptProcessMultiOperations(BCRYPT_HANDLE hObject, BCRYPT_MULTI_OPERATION_TYPE operationType, void* pOperations, uint32 cbOperations, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDuplicateHash(BCRYPT_HASH_HANDLE hHash, BCRYPT_HASH_HANDLE* phNewHash, uint8* pbHashObject, uint32 cbHashObject, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDestroyHash(BCRYPT_HASH_HANDLE hHash);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptHash(BCRYPT_ALG_HANDLE hAlgorithm, uint8* pbSecret, uint32 cbSecret, uint8* pbInput, uint32 cbInput, uint8* pbOutput, uint32 cbOutput);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptGenRandom(BCRYPT_ALG_HANDLE hAlgorithm, uint8* pbBuffer, uint32 cbBuffer, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDeriveKeyCapi(BCRYPT_HASH_HANDLE hHash, BCRYPT_ALG_HANDLE hTargetAlg, uint8* pbDerivedKey, uint32 cbDerivedKey, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDeriveKeyPBKDF2(BCRYPT_ALG_HANDLE hPrf, uint8* pbPassword, uint32 cbPassword, uint8* pbSalt, uint32 cbSalt, uint64 cIterations, uint8* pbDerivedKey, uint32 cbDerivedKey, uint32 dwFlags);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptQueryProviderRegistration(PWSTR pszProvider, BCRYPT_QUERY_PROVIDER_MODE dwMode, BCRYPT_INTERFACE dwInterface, uint32* pcbBuffer, CRYPT_PROVIDER_REG** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptEnumRegisteredProviders(uint32* pcbBuffer, CRYPT_PROVIDERS** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptCreateContext(BCRYPT_TABLE dwTable, PWSTR pszContext, CRYPT_CONTEXT_CONFIG* pConfig);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptDeleteContext(BCRYPT_TABLE dwTable, PWSTR pszContext);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptEnumContexts(BCRYPT_TABLE dwTable, uint32* pcbBuffer, CRYPT_CONTEXTS** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptConfigureContext(BCRYPT_TABLE dwTable, PWSTR pszContext, CRYPT_CONTEXT_CONFIG* pConfig);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptQueryContextConfiguration(BCRYPT_TABLE dwTable, PWSTR pszContext, uint32* pcbBuffer, CRYPT_CONTEXT_CONFIG** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptAddContextFunction(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, PWSTR pszFunction, uint32 dwPosition);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptRemoveContextFunction(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, PWSTR pszFunction);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptEnumContextFunctions(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, uint32* pcbBuffer, CRYPT_CONTEXT_FUNCTIONS** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptConfigureContextFunction(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, PWSTR pszFunction, CRYPT_CONTEXT_FUNCTION_CONFIG* pConfig);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptQueryContextFunctionConfiguration(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, PWSTR pszFunction, uint32* pcbBuffer, CRYPT_CONTEXT_FUNCTION_CONFIG** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptEnumContextFunctionProviders(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, PWSTR pszFunction, uint32* pcbBuffer, CRYPT_CONTEXT_FUNCTION_PROVIDERS** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptSetContextFunctionProperty(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, PWSTR pszFunction, PWSTR pszProperty, uint32 cbValue, uint8* pbValue);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptQueryContextFunctionProperty(BCRYPT_TABLE dwTable, PWSTR pszContext, BCRYPT_INTERFACE dwInterface, PWSTR pszFunction, PWSTR pszProperty, uint32* pcbValue, uint8** ppbValue);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptRegisterConfigChangeNotify(HANDLE* phEvent);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptUnregisterConfigChangeNotify(HANDLE hEvent);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptResolveProviders(PWSTR pszContext, uint32 dwInterface, PWSTR pszFunction, PWSTR pszProvider, BCRYPT_QUERY_PROVIDER_MODE dwMode, BCRYPT_RESOLVE_PROVIDERS_FLAGS dwFlags, uint32* pcbBuffer, CRYPT_PROVIDER_REFS** ppBuffer);

	[Import("bcrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS BCryptGetFipsAlgorithmMode(uint8* pfEnabled);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptOpenStorageProvider(NCRYPT_PROV_HANDLE* phProvider, PWSTR pszProviderName, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptEnumAlgorithms(NCRYPT_PROV_HANDLE hProvider, NCRYPT_OPERATION dwAlgOperations, uint32* pdwAlgCount, NCryptAlgorithmName** ppAlgList, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptIsAlgSupported(NCRYPT_PROV_HANDLE hProvider, PWSTR pszAlgId, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptEnumKeys(NCRYPT_PROV_HANDLE hProvider, PWSTR pszScope, NCryptKeyName** ppKeyName, void** ppEnumState, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptEnumStorageProviders(uint32* pdwProviderCount, NCryptProviderName** ppProviderList, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptFreeBuffer(void* pvInput);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptOpenKey(NCRYPT_PROV_HANDLE hProvider, NCRYPT_KEY_HANDLE* phKey, PWSTR pszKeyName, CERT_KEY_SPEC dwLegacyKeySpec, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptCreatePersistedKey(NCRYPT_PROV_HANDLE hProvider, NCRYPT_KEY_HANDLE* phKey, PWSTR pszAlgId, PWSTR pszKeyName, CERT_KEY_SPEC dwLegacyKeySpec, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptGetProperty(NCRYPT_HANDLE hObject, PWSTR pszProperty, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, OBJECT_SECURITY_INFORMATION dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptSetProperty(NCRYPT_HANDLE hObject, PWSTR pszProperty, uint8* pbInput, uint32 cbInput, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptFinalizeKey(NCRYPT_KEY_HANDLE hKey, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptEncrypt(NCRYPT_KEY_HANDLE hKey, uint8* pbInput, uint32 cbInput, void* pPaddingInfo, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptDecrypt(NCRYPT_KEY_HANDLE hKey, uint8* pbInput, uint32 cbInput, void* pPaddingInfo, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptImportKey(NCRYPT_PROV_HANDLE hProvider, NCRYPT_KEY_HANDLE hImportKey, PWSTR pszBlobType, BCryptBufferDesc* pParameterList, NCRYPT_KEY_HANDLE* phKey, uint8* pbData, uint32 cbData, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptExportKey(NCRYPT_KEY_HANDLE hKey, NCRYPT_KEY_HANDLE hExportKey, PWSTR pszBlobType, BCryptBufferDesc* pParameterList, uint8* pbOutput, uint32 cbOutput, uint32* pcbResult, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptSignHash(NCRYPT_KEY_HANDLE hKey, void* pPaddingInfo, uint8* pbHashValue, uint32 cbHashValue, uint8* pbSignature, uint32 cbSignature, uint32* pcbResult, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptVerifySignature(NCRYPT_KEY_HANDLE hKey, void* pPaddingInfo, uint8* pbHashValue, uint32 cbHashValue, uint8* pbSignature, uint32 cbSignature, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptDeleteKey(NCRYPT_KEY_HANDLE hKey, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptFreeObject(NCRYPT_HANDLE hObject);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL NCryptIsKeyHandle(NCRYPT_KEY_HANDLE hKey);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptTranslateHandle(NCRYPT_PROV_HANDLE* phProvider, NCRYPT_KEY_HANDLE* phKey, uint hLegacyProv, uint hLegacyKey, CERT_KEY_SPEC dwLegacyKeySpec, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptNotifyChangeKey(NCRYPT_PROV_HANDLE hProvider, HANDLE* phEvent, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptSecretAgreement(NCRYPT_KEY_HANDLE hPrivKey, NCRYPT_KEY_HANDLE hPubKey, NCRYPT_SECRET_HANDLE* phAgreedSecret, NCRYPT_FLAGS dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptDeriveKey(NCRYPT_SECRET_HANDLE hSharedSecret, PWSTR pwszKDF, BCryptBufferDesc* pParameterList, uint8* pbDerivedKey, uint32 cbDerivedKey, uint32* pcbResult, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptKeyDerivation(NCRYPT_KEY_HANDLE hKey, BCryptBufferDesc* pParameterList, uint8* pbDerivedKey, uint32 cbDerivedKey, uint32* pcbResult, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptCreateClaim(NCRYPT_KEY_HANDLE hSubjectKey, NCRYPT_KEY_HANDLE hAuthorityKey, uint32 dwClaimType, BCryptBufferDesc* pParameterList, uint8* pbClaimBlob, uint32 cbClaimBlob, uint32* pcbResult, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptVerifyClaim(NCRYPT_KEY_HANDLE hSubjectKey, NCRYPT_KEY_HANDLE hAuthorityKey, uint32 dwClaimType, BCryptBufferDesc* pParameterList, uint8* pbClaimBlob, uint32 cbClaimBlob, BCryptBufferDesc* pOutput, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptFormatObject(uint32 dwCertEncodingType, uint32 dwFormatType, uint32 dwFormatStrType, void* pFormatStruct, PSTR lpszStructType, uint8* pbEncoded, uint32 cbEncoded, void* pbFormat, uint32* pcbFormat);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEncodeObjectEx(CERT_QUERY_ENCODING_TYPE dwCertEncodingType, PSTR lpszStructType, void* pvStructInfo, CRYPT_ENCODE_OBJECT_FLAGS dwFlags, CRYPT_ENCODE_PARA* pEncodePara, void* pvEncoded, uint32* pcbEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEncodeObject(uint32 dwCertEncodingType, PSTR lpszStructType, void* pvStructInfo, uint8* pbEncoded, uint32* pcbEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDecodeObjectEx(uint32 dwCertEncodingType, PSTR lpszStructType, uint8* pbEncoded, uint32 cbEncoded, uint32 dwFlags, CRYPT_DECODE_PARA* pDecodePara, void* pvStructInfo, uint32* pcbStructInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDecodeObject(uint32 dwCertEncodingType, PSTR lpszStructType, uint8* pbEncoded, uint32 cbEncoded, uint32 dwFlags, void* pvStructInfo, uint32* pcbStructInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptInstallOIDFunctionAddress(HINSTANCE hModule, uint32 dwEncodingType, PSTR pszFuncName, uint32 cFuncEntry, CRYPT_OID_FUNC_ENTRY* rgFuncEntry, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CryptInitOIDFunctionSet(PSTR pszFuncName, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetOIDFunctionAddress(void* hFuncSet, uint32 dwEncodingType, PSTR pszOID, uint32 dwFlags, void** ppvFuncAddr, void** phFuncAddr);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetDefaultOIDDllList(void* hFuncSet, uint32 dwEncodingType, char16* pwszDllList, uint32* pcchDllList);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetDefaultOIDFunctionAddress(void* hFuncSet, uint32 dwEncodingType, PWSTR pwszDll, uint32 dwFlags, void** ppvFuncAddr, void** phFuncAddr);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptFreeOIDFunctionAddress(void* hFuncAddr, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptRegisterOIDFunction(uint32 dwEncodingType, PSTR pszFuncName, PSTR pszOID, PWSTR pwszDll, PSTR pszOverrideFuncName);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUnregisterOIDFunction(uint32 dwEncodingType, PSTR pszFuncName, PSTR pszOID);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptRegisterDefaultOIDFunction(uint32 dwEncodingType, PSTR pszFuncName, uint32 dwIndex, PWSTR pwszDll);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUnregisterDefaultOIDFunction(uint32 dwEncodingType, PSTR pszFuncName, PWSTR pwszDll);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetOIDFunctionValue(uint32 dwEncodingType, PSTR pszFuncName, PSTR pszOID, PWSTR pwszValueName, REG_VALUE_TYPE dwValueType, uint8* pbValueData, uint32 cbValueData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetOIDFunctionValue(uint32 dwEncodingType, PSTR pszFuncName, PSTR pszOID, PWSTR pwszValueName, uint32* pdwValueType, uint8* pbValueData, uint32* pcbValueData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEnumOIDFunction(uint32 dwEncodingType, PSTR pszFuncName, PSTR pszOID, uint32 dwFlags, void* pvArg, PFN_CRYPT_ENUM_OID_FUNC pfnEnumOIDFunc);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPT_OID_INFO* CryptFindOIDInfo(uint32 dwKeyType, void* pvKey, uint32 dwGroupId);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptRegisterOIDInfo(CRYPT_OID_INFO* pInfo, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUnregisterOIDInfo(CRYPT_OID_INFO* pInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEnumOIDInfo(uint32 dwGroupId, uint32 dwFlags, void* pvArg, PFN_CRYPT_ENUM_OID_INFO pfnEnumOIDInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR CryptFindLocalizedName(PWSTR pwszCryptName);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CryptMsgOpenToEncode(uint32 dwMsgEncodingType, uint32 dwFlags, CRYPT_MSG_TYPE dwMsgType, void* pvMsgEncodeInfo, PSTR pszInnerContentObjID, CMSG_STREAM_INFO* pStreamInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CryptMsgCalculateEncodedLength(uint32 dwMsgEncodingType, uint32 dwFlags, uint32 dwMsgType, void* pvMsgEncodeInfo, PSTR pszInnerContentObjID, uint32 cbData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CryptMsgOpenToDecode(uint32 dwMsgEncodingType, uint32 dwFlags, uint32 dwMsgType, HCRYPTPROV_LEGACY hCryptProv, CERT_INFO* pRecipientInfo, CMSG_STREAM_INFO* pStreamInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CryptMsgDuplicate(void* hCryptMsg);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgClose(void* hCryptMsg);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgUpdate(void* hCryptMsg, uint8* pbData, uint32 cbData, BOOL fFinal);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgGetParam(void* hCryptMsg, uint32 dwParamType, uint32 dwIndex, void* pvData, uint32* pcbData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgControl(void* hCryptMsg, uint32 dwFlags, uint32 dwCtrlType, void* pvCtrlPara);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgVerifyCountersignatureEncoded(HCRYPTPROV_LEGACY hCryptProv, uint32 dwEncodingType, uint8* pbSignerInfo, uint32 cbSignerInfo, uint8* pbSignerInfoCountersignature, uint32 cbSignerInfoCountersignature, CERT_INFO* pciCountersigner);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgVerifyCountersignatureEncodedEx(HCRYPTPROV_LEGACY hCryptProv, uint32 dwEncodingType, uint8* pbSignerInfo, uint32 cbSignerInfo, uint8* pbSignerInfoCountersignature, uint32 cbSignerInfoCountersignature, uint32 dwSignerType, void* pvSigner, uint32 dwFlags, void* pvExtra);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgCountersign(void* hCryptMsg, uint32 dwIndex, uint32 cCountersigners, CMSG_SIGNER_ENCODE_INFO* rgCountersigners);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgCountersignEncoded(uint32 dwEncodingType, uint8* pbSignerInfo, uint32 cbSignerInfo, uint32 cCountersigners, CMSG_SIGNER_ENCODE_INFO* rgCountersigners, uint8* pbCountersignature, uint32* pcbCountersignature);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCERTSTORE CertOpenStore(PSTR lpszStoreProvider, CERT_QUERY_ENCODING_TYPE dwEncodingType, HCRYPTPROV_LEGACY hCryptProv, CERT_OPEN_STORE_FLAGS dwFlags, void* pvPara);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCERTSTORE CertDuplicateStore(HCERTSTORE hCertStore);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSaveStore(HCERTSTORE hCertStore, CERT_QUERY_ENCODING_TYPE dwEncodingType, CERT_STORE_SAVE_AS dwSaveAs, CERT_STORE_SAVE_TO dwSaveTo, void* pvSaveToPara, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertCloseStore(HCERTSTORE hCertStore, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CertGetSubjectCertificateFromStore(HCERTSTORE hCertStore, uint32 dwCertEncodingType, CERT_INFO* pCertId);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CertEnumCertificatesInStore(HCERTSTORE hCertStore, CERT_CONTEXT* pPrevCertContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CertFindCertificateInStore(HCERTSTORE hCertStore, uint32 dwCertEncodingType, uint32 dwFindFlags, CERT_FIND_FLAGS dwFindType, void* pvFindPara, CERT_CONTEXT* pPrevCertContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CertGetIssuerCertificateFromStore(HCERTSTORE hCertStore, CERT_CONTEXT* pSubjectContext, CERT_CONTEXT* pPrevIssuerContext, uint32* pdwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertVerifySubjectCertificateContext(CERT_CONTEXT* pSubject, CERT_CONTEXT* pIssuer, uint32* pdwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CertDuplicateCertificateContext(CERT_CONTEXT* pCertContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CertCreateCertificateContext(uint32 dwCertEncodingType, uint8* pbCertEncoded, uint32 cbCertEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertFreeCertificateContext(CERT_CONTEXT* pCertContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSetCertificateContextProperty(CERT_CONTEXT* pCertContext, uint32 dwPropId, uint32 dwFlags, void* pvData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetCertificateContextProperty(CERT_CONTEXT* pCertContext, uint32 dwPropId, void* pvData, uint32* pcbData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertEnumCertificateContextProperties(CERT_CONTEXT* pCertContext, uint32 dwPropId);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertCreateCTLEntryFromCertificateContextProperties(CERT_CONTEXT* pCertContext, uint32 cOptAttr, CRYPT_ATTRIBUTE* rgOptAttr, uint32 dwFlags, void* pvReserved, CTL_ENTRY* pCtlEntry, uint32* pcbCtlEntry);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSetCertificateContextPropertiesFromCTLEntry(CERT_CONTEXT* pCertContext, CTL_ENTRY* pCtlEntry, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRL_CONTEXT* CertGetCRLFromStore(HCERTSTORE hCertStore, CERT_CONTEXT* pIssuerContext, CRL_CONTEXT* pPrevCrlContext, uint32* pdwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRL_CONTEXT* CertEnumCRLsInStore(HCERTSTORE hCertStore, CRL_CONTEXT* pPrevCrlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRL_CONTEXT* CertFindCRLInStore(HCERTSTORE hCertStore, uint32 dwCertEncodingType, uint32 dwFindFlags, uint32 dwFindType, void* pvFindPara, CRL_CONTEXT* pPrevCrlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRL_CONTEXT* CertDuplicateCRLContext(CRL_CONTEXT* pCrlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRL_CONTEXT* CertCreateCRLContext(uint32 dwCertEncodingType, uint8* pbCrlEncoded, uint32 cbCrlEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertFreeCRLContext(CRL_CONTEXT* pCrlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSetCRLContextProperty(CRL_CONTEXT* pCrlContext, uint32 dwPropId, uint32 dwFlags, void* pvData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetCRLContextProperty(CRL_CONTEXT* pCrlContext, uint32 dwPropId, void* pvData, uint32* pcbData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertEnumCRLContextProperties(CRL_CONTEXT* pCrlContext, uint32 dwPropId);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertFindCertificateInCRL(CERT_CONTEXT* pCert, CRL_CONTEXT* pCrlContext, uint32 dwFlags, void* pvReserved, CRL_ENTRY** ppCrlEntry);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertIsValidCRLForCertificate(CERT_CONTEXT* pCert, CRL_CONTEXT* pCrl, uint32 dwFlags, void* pvReserved);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddEncodedCertificateToStore(HCERTSTORE hCertStore, uint32 dwCertEncodingType, uint8* pbCertEncoded, uint32 cbCertEncoded, uint32 dwAddDisposition, CERT_CONTEXT** ppCertContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddCertificateContextToStore(HCERTSTORE hCertStore, CERT_CONTEXT* pCertContext, uint32 dwAddDisposition, CERT_CONTEXT** ppStoreContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddSerializedElementToStore(HCERTSTORE hCertStore, uint8* pbElement, uint32 cbElement, uint32 dwAddDisposition, uint32 dwFlags, uint32 dwContextTypeFlags, uint32* pdwContextType, void** ppvContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertDeleteCertificateFromStore(CERT_CONTEXT* pCertContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddEncodedCRLToStore(HCERTSTORE hCertStore, uint32 dwCertEncodingType, uint8* pbCrlEncoded, uint32 cbCrlEncoded, uint32 dwAddDisposition, CRL_CONTEXT** ppCrlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddCRLContextToStore(HCERTSTORE hCertStore, CRL_CONTEXT* pCrlContext, uint32 dwAddDisposition, CRL_CONTEXT** ppStoreContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertDeleteCRLFromStore(CRL_CONTEXT* pCrlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSerializeCertificateStoreElement(CERT_CONTEXT* pCertContext, uint32 dwFlags, uint8* pbElement, uint32* pcbElement);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSerializeCRLStoreElement(CRL_CONTEXT* pCrlContext, uint32 dwFlags, uint8* pbElement, uint32* pcbElement);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CTL_CONTEXT* CertDuplicateCTLContext(CTL_CONTEXT* pCtlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CTL_CONTEXT* CertCreateCTLContext(uint32 dwMsgAndCertEncodingType, uint8* pbCtlEncoded, uint32 cbCtlEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertFreeCTLContext(CTL_CONTEXT* pCtlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSetCTLContextProperty(CTL_CONTEXT* pCtlContext, uint32 dwPropId, uint32 dwFlags, void* pvData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetCTLContextProperty(CTL_CONTEXT* pCtlContext, uint32 dwPropId, void* pvData, uint32* pcbData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertEnumCTLContextProperties(CTL_CONTEXT* pCtlContext, uint32 dwPropId);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CTL_CONTEXT* CertEnumCTLsInStore(HCERTSTORE hCertStore, CTL_CONTEXT* pPrevCtlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CTL_ENTRY* CertFindSubjectInCTL(uint32 dwEncodingType, uint32 dwSubjectType, void* pvSubject, CTL_CONTEXT* pCtlContext, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CTL_CONTEXT* CertFindCTLInStore(HCERTSTORE hCertStore, uint32 dwMsgAndCertEncodingType, uint32 dwFindFlags, CERT_FIND_TYPE dwFindType, void* pvFindPara, CTL_CONTEXT* pPrevCtlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddEncodedCTLToStore(HCERTSTORE hCertStore, uint32 dwMsgAndCertEncodingType, uint8* pbCtlEncoded, uint32 cbCtlEncoded, uint32 dwAddDisposition, CTL_CONTEXT** ppCtlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddCTLContextToStore(HCERTSTORE hCertStore, CTL_CONTEXT* pCtlContext, uint32 dwAddDisposition, CTL_CONTEXT** ppStoreContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSerializeCTLStoreElement(CTL_CONTEXT* pCtlContext, uint32 dwFlags, uint8* pbElement, uint32* pcbElement);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertDeleteCTLFromStore(CTL_CONTEXT* pCtlContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddCertificateLinkToStore(HCERTSTORE hCertStore, CERT_CONTEXT* pCertContext, uint32 dwAddDisposition, CERT_CONTEXT** ppStoreContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddCRLLinkToStore(HCERTSTORE hCertStore, CRL_CONTEXT* pCrlContext, uint32 dwAddDisposition, CRL_CONTEXT** ppStoreContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddCTLLinkToStore(HCERTSTORE hCertStore, CTL_CONTEXT* pCtlContext, uint32 dwAddDisposition, CTL_CONTEXT** ppStoreContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddStoreToCollection(HCERTSTORE hCollectionStore, HCERTSTORE hSiblingStore, uint32 dwUpdateFlags, uint32 dwPriority);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertRemoveStoreFromCollection(HCERTSTORE hCollectionStore, HCERTSTORE hSiblingStore);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertControlStore(HCERTSTORE hCertStore, CERT_CONTROL_STORE_FLAGS dwFlags, uint32 dwCtrlType, void* pvCtrlPara);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSetStoreProperty(HCERTSTORE hCertStore, uint32 dwPropId, uint32 dwFlags, void* pvData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetStoreProperty(HCERTSTORE hCertStore, uint32 dwPropId, void* pvData, uint32* pcbData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CertCreateContext(uint32 dwContextType, uint32 dwEncodingType, uint8* pbEncoded, uint32 cbEncoded, uint32 dwFlags, CERT_CREATE_CONTEXT_PARA* pCreatePara);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertRegisterSystemStore(void* pvSystemStore, uint32 dwFlags, CERT_SYSTEM_STORE_INFO* pStoreInfo, void* pvReserved);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertRegisterPhysicalStore(void* pvSystemStore, uint32 dwFlags, PWSTR pwszStoreName, CERT_PHYSICAL_STORE_INFO* pStoreInfo, void* pvReserved);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertUnregisterSystemStore(void* pvSystemStore, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertUnregisterPhysicalStore(void* pvSystemStore, uint32 dwFlags, PWSTR pwszStoreName);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertEnumSystemStoreLocation(uint32 dwFlags, void* pvArg, PFN_CERT_ENUM_SYSTEM_STORE_LOCATION pfnEnum);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertEnumSystemStore(uint32 dwFlags, void* pvSystemStoreLocationPara, void* pvArg, PFN_CERT_ENUM_SYSTEM_STORE pfnEnum);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertEnumPhysicalStore(void* pvSystemStore, uint32 dwFlags, void* pvArg, PFN_CERT_ENUM_PHYSICAL_STORE pfnEnum);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetEnhancedKeyUsage(CERT_CONTEXT* pCertContext, uint32 dwFlags, CTL_USAGE* pUsage, uint32* pcbUsage);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSetEnhancedKeyUsage(CERT_CONTEXT* pCertContext, CTL_USAGE* pUsage);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddEnhancedKeyUsageIdentifier(CERT_CONTEXT* pCertContext, PSTR pszUsageIdentifier);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertRemoveEnhancedKeyUsageIdentifier(CERT_CONTEXT* pCertContext, PSTR pszUsageIdentifier);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetValidUsages(uint32 cCerts, CERT_CONTEXT** rghCerts, int32* cNumOIDs, PSTR* rghOIDs, uint32* pcbOIDs);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgGetAndVerifySigner(void* hCryptMsg, uint32 cSignerStore, HCERTSTORE* rghSignerStore, uint32 dwFlags, CERT_CONTEXT** ppSigner, uint32* pdwSignerIndex);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgSignCTL(uint32 dwMsgEncodingType, uint8* pbCtlContent, uint32 cbCtlContent, CMSG_SIGNED_ENCODE_INFO* pSignInfo, uint32 dwFlags, uint8* pbEncoded, uint32* pcbEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptMsgEncodeAndSignCTL(uint32 dwMsgEncodingType, CTL_INFO* pCtlInfo, CMSG_SIGNED_ENCODE_INFO* pSignInfo, uint32 dwFlags, uint8* pbEncoded, uint32* pcbEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertFindSubjectInSortedCTL(CRYPTOAPI_BLOB* pSubjectIdentifier, CTL_CONTEXT* pCtlContext, uint32 dwFlags, void* pvReserved, CRYPTOAPI_BLOB* pEncodedAttributes);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertEnumSubjectInSortedCTL(CTL_CONTEXT* pCtlContext, void** ppvNextSubject, CRYPTOAPI_BLOB* pSubjectIdentifier, CRYPTOAPI_BLOB* pEncodedAttributes);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertVerifyCTLUsage(uint32 dwEncodingType, uint32 dwSubjectType, void* pvSubject, CTL_USAGE* pSubjectUsage, uint32 dwFlags, CTL_VERIFY_USAGE_PARA* pVerifyUsagePara, CTL_VERIFY_USAGE_STATUS* pVerifyUsageStatus);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertVerifyRevocation(uint32 dwEncodingType, uint32 dwRevType, uint32 cContext, void** rgpvContext, uint32 dwFlags, CERT_REVOCATION_PARA* pRevPara, CERT_REVOCATION_STATUS* pRevStatus);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertCompareIntegerBlob(CRYPTOAPI_BLOB* pInt1, CRYPTOAPI_BLOB* pInt2);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertCompareCertificate(uint32 dwCertEncodingType, CERT_INFO* pCertId1, CERT_INFO* pCertId2);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertCompareCertificateName(uint32 dwCertEncodingType, CRYPTOAPI_BLOB* pCertName1, CRYPTOAPI_BLOB* pCertName2);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertIsRDNAttrsInCertificateName(uint32 dwCertEncodingType, uint32 dwFlags, CRYPTOAPI_BLOB* pCertName, CERT_RDN* pRDN);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertComparePublicKeyInfo(uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pPublicKey1, CERT_PUBLIC_KEY_INFO* pPublicKey2);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertGetPublicKeyLength(uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pPublicKey);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyCertificateSignature(HCRYPTPROV_LEGACY hCryptProv, uint32 dwCertEncodingType, uint8* pbEncoded, uint32 cbEncoded, CERT_PUBLIC_KEY_INFO* pPublicKey);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyCertificateSignatureEx(HCRYPTPROV_LEGACY hCryptProv, uint32 dwCertEncodingType, uint32 dwSubjectType, void* pvSubject, uint32 dwIssuerType, void* pvIssuer, CRYPT_VERIFY_CERT_FLAGS dwFlags, void* pvExtra);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertIsStrongHashToSign(CERT_STRONG_SIGN_PARA* pStrongSignPara, PWSTR pwszCNGHashAlgid, CERT_CONTEXT* pSigningCert);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptHashToBeSigned(HCRYPTPROV_LEGACY hCryptProv, uint32 dwCertEncodingType, uint8* pbEncoded, uint32 cbEncoded, uint8* pbComputedHash, uint32* pcbComputedHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptHashCertificate(HCRYPTPROV_LEGACY hCryptProv, uint32 Algid, uint32 dwFlags, uint8* pbEncoded, uint32 cbEncoded, uint8* pbComputedHash, uint32* pcbComputedHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptHashCertificate2(PWSTR pwszCNGHashAlgid, uint32 dwFlags, void* pvReserved, uint8* pbEncoded, uint32 cbEncoded, uint8* pbComputedHash, uint32* pcbComputedHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSignCertificate(HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hCryptProvOrNCryptKey, uint32 dwKeySpec, uint32 dwCertEncodingType, uint8* pbEncodedToBeSigned, uint32 cbEncodedToBeSigned, CRYPT_ALGORITHM_IDENTIFIER* pSignatureAlgorithm, void* pvHashAuxInfo, uint8* pbSignature, uint32* pcbSignature);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSignAndEncodeCertificate(HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hCryptProvOrNCryptKey, CERT_KEY_SPEC dwKeySpec, uint32 dwCertEncodingType, PSTR lpszStructType, void* pvStructInfo, CRYPT_ALGORITHM_IDENTIFIER* pSignatureAlgorithm, void* pvHashAuxInfo, uint8* pbEncoded, uint32* pcbEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CertVerifyTimeValidity(FILETIME* pTimeToVerify, CERT_INFO* pCertInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CertVerifyCRLTimeValidity(FILETIME* pTimeToVerify, CRL_INFO* pCrlInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertVerifyValidityNesting(CERT_INFO* pSubjectInfo, CERT_INFO* pIssuerInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertVerifyCRLRevocation(uint32 dwCertEncodingType, CERT_INFO* pCertId, uint32 cCrlInfo, CRL_INFO** rgpCrlInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR CertAlgIdToOID(uint32 dwAlgId);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertOIDToAlgId(PSTR pszObjId);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_EXTENSION* CertFindExtension(PSTR pszObjId, uint32 cExtensions, CERT_EXTENSION* rgExtensions);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPT_ATTRIBUTE* CertFindAttribute(PSTR pszObjId, uint32 cAttr, CRYPT_ATTRIBUTE* rgAttr);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_RDN_ATTR* CertFindRDNAttr(PSTR pszObjId, CERT_NAME_INFO* pName);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetIntendedKeyUsage(uint32 dwCertEncodingType, CERT_INFO* pCertInfo, uint8* pbKeyUsage, uint32 cbKeyUsage);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptInstallDefaultContext(uint hCryptProv, CRYPT_DEFAULT_CONTEXT_TYPE dwDefaultType, void* pvDefaultPara, CRYPT_DEFAULT_CONTEXT_FLAGS dwFlags, void* pvReserved, void** phDefaultContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUninstallDefaultContext(void* hDefaultContext, uint32 dwFlags, void* pvReserved);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptExportPublicKeyInfo(HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hCryptProvOrNCryptKey, uint32 dwKeySpec, uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pInfo, uint32* pcbInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptExportPublicKeyInfoEx(HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hCryptProvOrNCryptKey, uint32 dwKeySpec, uint32 dwCertEncodingType, PSTR pszPublicKeyObjId, uint32 dwFlags, void* pvAuxInfo, CERT_PUBLIC_KEY_INFO* pInfo, uint32* pcbInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptExportPublicKeyInfoFromBCryptKeyHandle(BCRYPT_KEY_HANDLE hBCryptKey, uint32 dwCertEncodingType, PSTR pszPublicKeyObjId, uint32 dwFlags, void* pvAuxInfo, CERT_PUBLIC_KEY_INFO* pInfo, uint32* pcbInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptImportPublicKeyInfo(uint hCryptProv, uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pInfo, uint* phKey);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptImportPublicKeyInfoEx(uint hCryptProv, uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pInfo, uint32 aiKeyAlg, uint32 dwFlags, void* pvAuxInfo, uint* phKey);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptImportPublicKeyInfoEx2(uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pInfo, CRYPT_IMPORT_PUBLIC_KEY_FLAGS dwFlags, void* pvAuxInfo, BCRYPT_KEY_HANDLE* phKey);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptAcquireCertificatePrivateKey(CERT_CONTEXT* pCert, CRYPT_ACQUIRE_FLAGS dwFlags, void* pvParameters, HCRYPTPROV_OR_NCRYPT_KEY_HANDLE* phCryptProvOrNCryptKey, CERT_KEY_SPEC* pdwKeySpec, BOOL* pfCallerFreeProvOrNCryptKey);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptFindCertificateKeyProvInfo(CERT_CONTEXT* pCert, CRYPT_FIND_FLAGS dwFlags, void* pvReserved);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptImportPKCS8(CRYPT_PKCS8_IMPORT_PARAMS sPrivateKeyAndParams, CRYPT_KEY_FLAGS dwFlags, uint* phCryptProv, void* pvAuxInfo);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptExportPKCS8(uint hCryptProv, uint32 dwKeySpec, PSTR pszPrivateKeyObjId, uint32 dwFlags, void* pvAuxInfo, uint8* pbPrivateKeyBlob, uint32* pcbPrivateKeyBlob);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptHashPublicKeyInfo(HCRYPTPROV_LEGACY hCryptProv, uint32 Algid, uint32 dwFlags, uint32 dwCertEncodingType, CERT_PUBLIC_KEY_INFO* pInfo, uint8* pbComputedHash, uint32* pcbComputedHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertRDNValueToStrA(uint32 dwValueType, CRYPTOAPI_BLOB* pValue, uint8* psz, uint32 csz);
	public static uint32 CertRDNValueToStr(uint32 dwValueType, CRYPTOAPI_BLOB* pValue, uint8* psz, uint32 csz) => CertRDNValueToStrA(dwValueType, pValue, psz, csz);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertRDNValueToStrW(uint32 dwValueType, CRYPTOAPI_BLOB* pValue, char16* psz, uint32 csz);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertNameToStrA(uint32 dwCertEncodingType, CRYPTOAPI_BLOB* pName, CERT_STRING_TYPE dwStrType, uint8* psz, uint32 csz);
	public static uint32 CertNameToStr(uint32 dwCertEncodingType, CRYPTOAPI_BLOB* pName, CERT_STRING_TYPE dwStrType, uint8* psz, uint32 csz) => CertNameToStrA(dwCertEncodingType, pName, dwStrType, psz, csz);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertNameToStrW(uint32 dwCertEncodingType, CRYPTOAPI_BLOB* pName, CERT_STRING_TYPE dwStrType, char16* psz, uint32 csz);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertStrToNameA(uint32 dwCertEncodingType, PSTR pszX500, CERT_STRING_TYPE dwStrType, void* pvReserved, uint8* pbEncoded, uint32* pcbEncoded, PSTR* ppszError);
	public static BOOL CertStrToName(uint32 dwCertEncodingType, PSTR pszX500, CERT_STRING_TYPE dwStrType, void* pvReserved, uint8* pbEncoded, uint32* pcbEncoded, PSTR* ppszError) => CertStrToNameA(dwCertEncodingType, pszX500, dwStrType, pvReserved, pbEncoded, pcbEncoded, ppszError);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertStrToNameW(uint32 dwCertEncodingType, PWSTR pszX500, CERT_STRING_TYPE dwStrType, void* pvReserved, uint8* pbEncoded, uint32* pcbEncoded, PWSTR* ppszError);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertGetNameStringA(CERT_CONTEXT* pCertContext, uint32 dwType, uint32 dwFlags, void* pvTypePara, uint8* pszNameString, uint32 cchNameString);
	public static uint32 CertGetNameString(CERT_CONTEXT* pCertContext, uint32 dwType, uint32 dwFlags, void* pvTypePara, uint8* pszNameString, uint32 cchNameString) => CertGetNameStringA(pCertContext, dwType, dwFlags, pvTypePara, pszNameString, cchNameString);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CertGetNameStringW(CERT_CONTEXT* pCertContext, uint32 dwType, uint32 dwFlags, void* pvTypePara, char16* pszNameString, uint32 cchNameString);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSignMessage(CRYPT_SIGN_MESSAGE_PARA* pSignPara, BOOL fDetachedSignature, uint32 cToBeSigned, uint8** rgpbToBeSigned, uint32* rgcbToBeSigned, uint8* pbSignedBlob, uint32* pcbSignedBlob);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyMessageSignature(CRYPT_VERIFY_MESSAGE_PARA* pVerifyPara, uint32 dwSignerIndex, uint8* pbSignedBlob, uint32 cbSignedBlob, uint8* pbDecoded, uint32* pcbDecoded, CERT_CONTEXT** ppSignerCert);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CryptGetMessageSignerCount(uint32 dwMsgEncodingType, uint8* pbSignedBlob, uint32 cbSignedBlob);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCERTSTORE CryptGetMessageCertificates(uint32 dwMsgAndCertEncodingType, HCRYPTPROV_LEGACY hCryptProv, uint32 dwFlags, uint8* pbSignedBlob, uint32 cbSignedBlob);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyDetachedMessageSignature(CRYPT_VERIFY_MESSAGE_PARA* pVerifyPara, uint32 dwSignerIndex, uint8* pbDetachedSignBlob, uint32 cbDetachedSignBlob, uint32 cToBeSigned, uint8** rgpbToBeSigned, uint32* rgcbToBeSigned, CERT_CONTEXT** ppSignerCert);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEncryptMessage(CRYPT_ENCRYPT_MESSAGE_PARA* pEncryptPara, uint32 cRecipientCert, CERT_CONTEXT** rgpRecipientCert, uint8* pbToBeEncrypted, uint32 cbToBeEncrypted, uint8* pbEncryptedBlob, uint32* pcbEncryptedBlob);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDecryptMessage(CRYPT_DECRYPT_MESSAGE_PARA* pDecryptPara, uint8* pbEncryptedBlob, uint32 cbEncryptedBlob, uint8* pbDecrypted, uint32* pcbDecrypted, CERT_CONTEXT** ppXchgCert);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSignAndEncryptMessage(CRYPT_SIGN_MESSAGE_PARA* pSignPara, CRYPT_ENCRYPT_MESSAGE_PARA* pEncryptPara, uint32 cRecipientCert, CERT_CONTEXT** rgpRecipientCert, uint8* pbToBeSignedAndEncrypted, uint32 cbToBeSignedAndEncrypted, uint8* pbSignedAndEncryptedBlob, uint32* pcbSignedAndEncryptedBlob);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDecryptAndVerifyMessageSignature(CRYPT_DECRYPT_MESSAGE_PARA* pDecryptPara, CRYPT_VERIFY_MESSAGE_PARA* pVerifyPara, uint32 dwSignerIndex, uint8* pbEncryptedBlob, uint32 cbEncryptedBlob, uint8* pbDecrypted, uint32* pcbDecrypted, CERT_CONTEXT** ppXchgCert, CERT_CONTEXT** ppSignerCert);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptDecodeMessage(uint32 dwMsgTypeFlags, CRYPT_DECRYPT_MESSAGE_PARA* pDecryptPara, CRYPT_VERIFY_MESSAGE_PARA* pVerifyPara, uint32 dwSignerIndex, uint8* pbEncodedBlob, uint32 cbEncodedBlob, uint32 dwPrevInnerContentType, uint32* pdwMsgType, uint32* pdwInnerContentType, uint8* pbDecoded, uint32* pcbDecoded, CERT_CONTEXT** ppXchgCert, CERT_CONTEXT** ppSignerCert);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptHashMessage(CRYPT_HASH_MESSAGE_PARA* pHashPara, BOOL fDetachedHash, uint32 cToBeHashed, uint8** rgpbToBeHashed, uint32* rgcbToBeHashed, uint8* pbHashedBlob, uint32* pcbHashedBlob, uint8* pbComputedHash, uint32* pcbComputedHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyMessageHash(CRYPT_HASH_MESSAGE_PARA* pHashPara, uint8* pbHashedBlob, uint32 cbHashedBlob, uint8* pbToBeHashed, uint32* pcbToBeHashed, uint8* pbComputedHash, uint32* pcbComputedHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyDetachedMessageHash(CRYPT_HASH_MESSAGE_PARA* pHashPara, uint8* pbDetachedHashBlob, uint32 cbDetachedHashBlob, uint32 cToBeHashed, uint8** rgpbToBeHashed, uint32* rgcbToBeHashed, uint8* pbComputedHash, uint32* pcbComputedHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSignMessageWithKey(CRYPT_KEY_SIGN_MESSAGE_PARA* pSignPara, uint8* pbToBeSigned, uint32 cbToBeSigned, uint8* pbSignedBlob, uint32* pcbSignedBlob);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyMessageSignatureWithKey(CRYPT_KEY_VERIFY_MESSAGE_PARA* pVerifyPara, CERT_PUBLIC_KEY_INFO* pPublicKeyInfo, uint8* pbSignedBlob, uint32 cbSignedBlob, uint8* pbDecoded, uint32* pcbDecoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCERTSTORE CertOpenSystemStoreA(HCRYPTPROV_LEGACY hProv, PSTR szSubsystemProtocol);
	public static HCERTSTORE CertOpenSystemStore(HCRYPTPROV_LEGACY hProv, PSTR szSubsystemProtocol) => CertOpenSystemStoreA(hProv, szSubsystemProtocol);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCERTSTORE CertOpenSystemStoreW(HCRYPTPROV_LEGACY hProv, PWSTR szSubsystemProtocol);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddEncodedCertificateToSystemStoreA(PSTR szCertStoreName, uint8* pbCertEncoded, uint32 cbCertEncoded);
	public static BOOL CertAddEncodedCertificateToSystemStore(PSTR szCertStoreName, uint8* pbCertEncoded, uint32 cbCertEncoded) => CertAddEncodedCertificateToSystemStoreA(szCertStoreName, pbCertEncoded, cbCertEncoded);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertAddEncodedCertificateToSystemStoreW(PWSTR szCertStoreName, uint8* pbCertEncoded, uint32 cbCertEncoded);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FindCertsByIssuer(CERT_CHAIN* pCertChains, uint32* pcbCertChains, uint32* pcCertChains, uint8* pbEncodedIssuerName, uint32 cbEncodedIssuerName, PWSTR pwszPurpose, uint32 dwKeySpec);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptQueryObject(CERT_QUERY_OBJECT_TYPE dwObjectType, void* pvObject, CERT_QUERY_CONTENT_TYPE_FLAGS dwExpectedContentTypeFlags, CERT_QUERY_FORMAT_TYPE_FLAGS dwExpectedFormatTypeFlags, uint32 dwFlags, CERT_QUERY_ENCODING_TYPE* pdwMsgAndCertEncodingType, CERT_QUERY_CONTENT_TYPE* pdwContentType, CERT_QUERY_FORMAT_TYPE* pdwFormatType, HCERTSTORE* phCertStore, void** phMsg, void** ppvContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CryptMemAlloc(uint32 cbSize);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CryptMemRealloc(void* pv, uint32 cbSize);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CryptMemFree(void* pv);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCreateAsyncHandle(uint32 dwFlags, HCRYPTASYNC* phAsync);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetAsyncParam(HCRYPTASYNC hAsync, PSTR pszParamOid, void* pvParam, PFN_CRYPT_ASYNC_PARAM_FREE_FUNC pfnFree);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetAsyncParam(HCRYPTASYNC hAsync, PSTR pszParamOid, void** ppvParam, PFN_CRYPT_ASYNC_PARAM_FREE_FUNC* ppfnFree);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCloseAsyncHandle(HCRYPTASYNC hAsync);

	[Import("CRYPTNET.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptRetrieveObjectByUrlA(PSTR pszUrl, PSTR pszObjectOid, uint32 dwRetrievalFlags, uint32 dwTimeout, void** ppvObject, HCRYPTASYNC hAsyncRetrieve, CRYPT_CREDENTIALS* pCredentials, void* pvVerify, CRYPT_RETRIEVE_AUX_INFO* pAuxInfo);
	public static BOOL CryptRetrieveObjectByUrl(PSTR pszUrl, PSTR pszObjectOid, uint32 dwRetrievalFlags, uint32 dwTimeout, void** ppvObject, HCRYPTASYNC hAsyncRetrieve, CRYPT_CREDENTIALS* pCredentials, void* pvVerify, CRYPT_RETRIEVE_AUX_INFO* pAuxInfo) => CryptRetrieveObjectByUrlA(pszUrl, pszObjectOid, dwRetrievalFlags, dwTimeout, ppvObject, hAsyncRetrieve, pCredentials, pvVerify, pAuxInfo);

	[Import("CRYPTNET.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptRetrieveObjectByUrlW(PWSTR pszUrl, PSTR pszObjectOid, uint32 dwRetrievalFlags, uint32 dwTimeout, void** ppvObject, HCRYPTASYNC hAsyncRetrieve, CRYPT_CREDENTIALS* pCredentials, void* pvVerify, CRYPT_RETRIEVE_AUX_INFO* pAuxInfo);

	[Import("CRYPTNET.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptInstallCancelRetrieval(PFN_CRYPT_CANCEL_RETRIEVAL pfnCancel, void* pvArg, uint32 dwFlags, void* pvReserved);

	[Import("CRYPTNET.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUninstallCancelRetrieval(uint32 dwFlags, void* pvReserved);

	[Import("CRYPTNET.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetObjectUrl(PSTR pszUrlOid, void* pvPara, CRYPT_GET_URL_FLAGS dwFlags, CRYPT_URL_ARRAY* pUrlArray, uint32* pcbUrlArray, CRYPT_URL_INFO* pUrlInfo, uint32* pcbUrlInfo, void* pvReserved);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CertCreateSelfSignCertificate(HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hCryptProvOrNCryptKey, CRYPTOAPI_BLOB* pSubjectIssuerBlob, CERT_CREATE_SELFSIGN_FLAGS dwFlags, CRYPT_KEY_PROV_INFO* pKeyProvInfo, CRYPT_ALGORITHM_IDENTIFIER* pSignatureAlgorithm, SYSTEMTIME* pStartTime, SYSTEMTIME* pEndTime, CERT_EXTENSIONS* pExtensions);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptGetKeyIdentifierProperty(CRYPTOAPI_BLOB* pKeyIdentifier, uint32 dwPropId, uint32 dwFlags, PWSTR pwszComputerName, void* pvReserved, void* pvData, uint32* pcbData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptSetKeyIdentifierProperty(CRYPTOAPI_BLOB* pKeyIdentifier, uint32 dwPropId, uint32 dwFlags, PWSTR pwszComputerName, void* pvReserved, void* pvData);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptEnumKeyIdentifierProperties(CRYPTOAPI_BLOB* pKeyIdentifier, uint32 dwPropId, uint32 dwFlags, PWSTR pwszComputerName, void* pvReserved, void* pvArg, PFN_CRYPT_ENUM_KEYID_PROP pfnEnum);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCreateKeyIdentifierFromCSP(uint32 dwCertEncodingType, PSTR pszPubKeyOID, PUBLICKEYSTRUC* pPubKeyStruc, uint32 cbPubKeyStruc, uint32 dwFlags, void* pvReserved, uint8* pbHash, uint32* pcbHash);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertCreateCertificateChainEngine(CERT_CHAIN_ENGINE_CONFIG* pConfig, HCERTCHAINENGINE* phChainEngine);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertFreeCertificateChainEngine(HCERTCHAINENGINE hChainEngine);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertResyncCertificateChainEngine(HCERTCHAINENGINE hChainEngine);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertGetCertificateChain(HCERTCHAINENGINE hChainEngine, CERT_CONTEXT* pCertContext, FILETIME* pTime, HCERTSTORE hAdditionalStore, CERT_CHAIN_PARA* pChainPara, uint32 dwFlags, void* pvReserved, CERT_CHAIN_CONTEXT** ppChainContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertFreeCertificateChain(CERT_CHAIN_CONTEXT* pChainContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CHAIN_CONTEXT* CertDuplicateCertificateChain(CERT_CHAIN_CONTEXT* pChainContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CHAIN_CONTEXT* CertFindChainInStore(HCERTSTORE hCertStore, uint32 dwCertEncodingType, CERT_FIND_CHAIN_IN_STORE_FLAGS dwFindFlags, uint32 dwFindType, void* pvFindPara, CERT_CHAIN_CONTEXT* pPrevChainContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertVerifyCertificateChainPolicy(PSTR pszPolicyOID, CERT_CHAIN_CONTEXT* pChainContext, CERT_CHAIN_POLICY_PARA* pPolicyPara, CERT_CHAIN_POLICY_STATUS* pPolicyStatus);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptStringToBinaryA(uint8* pszString, uint32 cchString, CRYPT_STRING dwFlags, uint8* pbBinary, uint32* pcbBinary, uint32* pdwSkip, uint32* pdwFlags);
	public static BOOL CryptStringToBinary(uint8* pszString, uint32 cchString, CRYPT_STRING dwFlags, uint8* pbBinary, uint32* pcbBinary, uint32* pdwSkip, uint32* pdwFlags) => CryptStringToBinaryA(pszString, cchString, dwFlags, pbBinary, pcbBinary, pdwSkip, pdwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptStringToBinaryW(char16* pszString, uint32 cchString, CRYPT_STRING dwFlags, uint8* pbBinary, uint32* pcbBinary, uint32* pdwSkip, uint32* pdwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptBinaryToStringA(uint8* pbBinary, uint32 cbBinary, CRYPT_STRING dwFlags, uint8* pszString, uint32* pcchString);
	public static BOOL CryptBinaryToString(uint8* pbBinary, uint32 cbBinary, CRYPT_STRING dwFlags, uint8* pszString, uint32* pcchString) => CryptBinaryToStringA(pbBinary, cbBinary, dwFlags, pszString, pcchString);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptBinaryToStringW(uint8* pbBinary, uint32 cbBinary, CRYPT_STRING dwFlags, char16* pszString, uint32* pcchString);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCERTSTORE PFXImportCertStore(CRYPTOAPI_BLOB* pPFX, PWSTR szPassword, CRYPT_KEY_FLAGS dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PFXIsPFXBlob(CRYPTOAPI_BLOB* pPFX);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PFXVerifyPassword(CRYPTOAPI_BLOB* pPFX, PWSTR szPassword, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PFXExportCertStoreEx(HCERTSTORE hStore, CRYPTOAPI_BLOB* pPFX, PWSTR szPassword, void* pvPara, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PFXExportCertStore(HCERTSTORE hStore, CRYPTOAPI_BLOB* pPFX, PWSTR szPassword, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* CertOpenServerOcspResponse(CERT_CHAIN_CONTEXT* pChainContext, uint32 dwFlags, CERT_SERVER_OCSP_RESPONSE_OPEN_PARA* pOpenPara);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertAddRefServerOcspResponse(void* hServerOcspResponse);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertCloseServerOcspResponse(void* hServerOcspResponse, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_SERVER_OCSP_RESPONSE_CONTEXT* CertGetServerOcspResponseContext(void* hServerOcspResponse, uint32 dwFlags, void* pvReserved);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertAddRefServerOcspResponseContext(CERT_SERVER_OCSP_RESPONSE_CONTEXT* pServerOcspResponseContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertFreeServerOcspResponseContext(CERT_SERVER_OCSP_RESPONSE_CONTEXT* pServerOcspResponseContext);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertRetrieveLogoOrBiometricInfo(CERT_CONTEXT* pCertContext, PSTR lpszLogoOrBiometricType, uint32 dwRetrievalFlags, uint32 dwTimeout, uint32 dwFlags, void* pvReserved, uint8** ppbData, uint32* pcbData, PWSTR* ppwszMimeType);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertSelectCertificateChains(Guid* pSelectionContext, uint32 dwFlags, CERT_SELECT_CHAIN_PARA* pChainParameters, uint32 cCriteria, CERT_SELECT_CRITERIA* rgpCriteria, HCERTSTORE hStore, uint32* pcSelection, CERT_CHAIN_CONTEXT*** pprgpSelection);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertFreeCertificateChainList(CERT_CHAIN_CONTEXT** prgpSelection);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptRetrieveTimeStamp(PWSTR wszUrl, uint32 dwRetrievalFlags, uint32 dwTimeout, PSTR pszHashId, CRYPT_TIMESTAMP_PARA* pPara, uint8* pbData, uint32 cbData, CRYPT_TIMESTAMP_CONTEXT** ppTsContext, CERT_CONTEXT** ppTsSigner, HCERTSTORE* phStore);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptVerifyTimeStampSignature(uint8* pbTSContentInfo, uint32 cbTSContentInfo, uint8* pbData, uint32 cbData, HCERTSTORE hAdditionalStore, CRYPT_TIMESTAMP_CONTEXT** ppTsContext, CERT_CONTEXT** ppTsSigner, HCERTSTORE* phStore);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CertIsWeakHash(uint32 dwHashUseType, PWSTR pwszCNGHashAlgid, uint32 dwChainFlags, CERT_CHAIN_CONTEXT* pSignerChainContext, FILETIME* pTimeStamp, PWSTR pwszFileName);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptProtectData(CRYPTOAPI_BLOB* pDataIn, PWSTR szDataDescr, CRYPTOAPI_BLOB* pOptionalEntropy, void* pvReserved, CRYPTPROTECT_PROMPTSTRUCT* pPromptStruct, uint32 dwFlags, CRYPTOAPI_BLOB* pDataOut);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUnprotectData(CRYPTOAPI_BLOB* pDataIn, PWSTR* ppszDataDescr, CRYPTOAPI_BLOB* pOptionalEntropy, void* pvReserved, CRYPTPROTECT_PROMPTSTRUCT* pPromptStruct, uint32 dwFlags, CRYPTOAPI_BLOB* pDataOut);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUpdateProtectedState(PSID pOldSid, PWSTR pwszOldPassword, uint32 dwFlags, uint32* pdwSuccessCount, uint32* pdwFailureCount);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptProtectMemory(void* pDataIn, uint32 cbDataIn, uint32 dwFlags);

	[Import("CRYPT32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUnprotectMemory(void* pDataIn, uint32 cbDataIn, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptRegisterProtectionDescriptorName(PWSTR pwszName, PWSTR pwszDescriptorString, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptQueryProtectionDescriptorName(PWSTR pwszName, char16* pwszDescriptorString, uint* pcDescriptorString, uint32 dwFlags);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptCreateProtectionDescriptor(PWSTR pwszDescriptorString, uint32 dwFlags, NCRYPT_DESCRIPTOR_HANDLE* phDescriptor);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptCloseProtectionDescriptor(NCRYPT_DESCRIPTOR_HANDLE hDescriptor);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptGetProtectionDescriptorInfo(NCRYPT_DESCRIPTOR_HANDLE hDescriptor, NCRYPT_ALLOC_PARA* pMemPara, uint32 dwInfoType, void** ppvInfo);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptProtectSecret(NCRYPT_DESCRIPTOR_HANDLE hDescriptor, uint32 dwFlags, uint8* pbData, uint32 cbData, NCRYPT_ALLOC_PARA* pMemPara, HWND hWnd, uint8** ppbProtectedBlob, uint32* pcbProtectedBlob);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptUnprotectSecret(NCRYPT_DESCRIPTOR_HANDLE* phDescriptor, NCRYPT_FLAGS dwFlags, uint8* pbProtectedBlob, uint32 cbProtectedBlob, NCRYPT_ALLOC_PARA* pMemPara, HWND hWnd, uint8** ppbData, uint32* pcbData);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptStreamOpenToProtect(NCRYPT_DESCRIPTOR_HANDLE hDescriptor, uint32 dwFlags, HWND hWnd, NCRYPT_PROTECT_STREAM_INFO* pStreamInfo, NCRYPT_STREAM_HANDLE* phStream);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptStreamOpenToUnprotect(NCRYPT_PROTECT_STREAM_INFO* pStreamInfo, uint32 dwFlags, HWND hWnd, NCRYPT_STREAM_HANDLE* phStream);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptStreamOpenToUnprotectEx(NCRYPT_PROTECT_STREAM_INFO_EX* pStreamInfo, uint32 dwFlags, HWND hWnd, NCRYPT_STREAM_HANDLE* phStream);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptStreamUpdate(NCRYPT_STREAM_HANDLE hStream, uint8* pbData, uint cbData, BOOL fFinal);

	[Import("ncrypt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NCryptStreamClose(NCRYPT_STREAM_HANDLE hStream);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlClose(void* hCryptXml);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlGetTransforms(CRYPT_XML_TRANSFORM_CHAIN_CONFIG** ppConfig);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlOpenToEncode(CRYPT_XML_TRANSFORM_CHAIN_CONFIG* pConfig, CRYPT_XML_FLAGS dwFlags, PWSTR wszId, CRYPT_XML_PROPERTY* rgProperty, uint32 cProperty, CRYPT_XML_BLOB* pEncoded, void** phSignature);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlOpenToDecode(CRYPT_XML_TRANSFORM_CHAIN_CONFIG* pConfig, CRYPT_XML_FLAGS dwFlags, CRYPT_XML_PROPERTY* rgProperty, uint32 cProperty, CRYPT_XML_BLOB* pEncoded, void** phCryptXml);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlAddObject(void* hSignatureOrObject, uint32 dwFlags, CRYPT_XML_PROPERTY* rgProperty, uint32 cProperty, CRYPT_XML_BLOB* pEncoded, CRYPT_XML_OBJECT** ppObject);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlCreateReference(void* hCryptXml, uint32 dwFlags, PWSTR wszId, PWSTR wszURI, PWSTR wszType, CRYPT_XML_ALGORITHM* pDigestMethod, uint32 cTransform, CRYPT_XML_ALGORITHM* rgTransform, void** phReference);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlDigestReference(void* hReference, uint32 dwFlags, CRYPT_XML_DATA_PROVIDER* pDataProviderIn);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlSetHMACSecret(void* hSignature, uint8* pbSecret, uint32 cbSecret);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlSign(void* hSignature, HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hKey, CERT_KEY_SPEC dwKeySpec, CRYPT_XML_FLAGS dwFlags, CRYPT_XML_KEYINFO_SPEC dwKeyInfoSpec, void* pvKeyInfoSpec, CRYPT_XML_ALGORITHM* pSignatureMethod, CRYPT_XML_ALGORITHM* pCanonicalization);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlImportPublicKey(CRYPT_XML_FLAGS dwFlags, CRYPT_XML_KEY_VALUE* pKeyValue, BCRYPT_KEY_HANDLE* phKey);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlVerifySignature(void* hSignature, BCRYPT_KEY_HANDLE hKey, CRYPT_XML_FLAGS dwFlags);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlGetDocContext(void* hCryptXml, CRYPT_XML_DOC_CTXT** ppStruct);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlGetSignature(void* hCryptXml, CRYPT_XML_SIGNATURE** ppStruct);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlGetReference(void* hCryptXml, CRYPT_XML_REFERENCE** ppStruct);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlGetStatus(void* hCryptXml, CRYPT_XML_STATUS* pStatus);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlEncode(void* hCryptXml, CRYPT_XML_CHARSET dwCharset, CRYPT_XML_PROPERTY* rgProperty, uint32 cProperty, void* pvCallbackState, PFN_CRYPT_XML_WRITE_CALLBACK pfnWrite);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlGetAlgorithmInfo(CRYPT_XML_ALGORITHM* pXmlAlgorithm, CRYPT_XML_FLAGS dwFlags, CRYPT_XML_ALGORITHM_INFO** ppAlgInfo);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPT_XML_ALGORITHM_INFO* CryptXmlFindAlgorithmInfo(uint32 dwFindByType, void* pvFindBy, uint32 dwGroupId, uint32 dwFlags);

	[Import("CRYPTXML.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CryptXmlEnumAlgorithmInfo(uint32 dwGroupId, uint32 dwFlags, void* pvArg, PFN_CRYPT_XML_ENUM_ALG_INFO pfnEnumAlgInfo);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetToken(uint32 cPolicyChain, POLICY_ELEMENT* pPolicyChain, GENERIC_XML_TOKEN** securityToken, INFORMATIONCARD_CRYPTO_HANDLE** phProofTokenCrypto);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ManageCardSpace();

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImportInformationCard(PWSTR fileName);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT Encrypt(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, BOOL fOAEP, uint32 cbInData, uint8* pInData, uint32* pcbOutData, uint8** ppOutData);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT Decrypt(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, BOOL fOAEP, uint32 cbInData, uint8* pInData, uint32* pcbOutData, uint8** ppOutData);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SignHash(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, uint32 cbHash, uint8* pHash, PWSTR hashAlgOid, uint32* pcbSig, uint8** ppSig);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VerifyHash(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, uint32 cbHash, uint8* pHash, PWSTR hashAlgOid, uint32 cbSig, uint8* pSig, BOOL* pfVerified);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetCryptoTransform(INFORMATIONCARD_CRYPTO_HANDLE* hSymmetricCrypto, uint32 mode, PaddingMode padding, uint32 feedbackSize, Direction direction, uint32 cbIV, uint8* pIV, INFORMATIONCARD_CRYPTO_HANDLE** pphTransform);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetKeyedHash(INFORMATIONCARD_CRYPTO_HANDLE* hSymmetricCrypto, INFORMATIONCARD_CRYPTO_HANDLE** pphHash);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TransformBlock(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, uint32 cbInData, uint8* pInData, uint32* pcbOutData, uint8** ppOutData);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TransformFinalBlock(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, uint32 cbInData, uint8* pInData, uint32* pcbOutData, uint8** ppOutData);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HashCore(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, uint32 cbInData, uint8* pInData);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HashFinal(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, uint32 cbInData, uint8* pInData, uint32* pcbOutData, uint8** ppOutData);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeToken(GENERIC_XML_TOKEN* pAllocMemory);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CloseCryptoHandle(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GenerateDerivedKey(INFORMATIONCARD_CRYPTO_HANDLE* hCrypto, uint32 cbLabel, uint8* pLabel, uint32 cbNonce, uint8* pNonce, uint32 derivedKeyLength, uint32 offset, PWSTR algId, uint32* pcbKey, uint8** ppKey);

	[Import("infocardapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetBrowserToken(uint32 dwParamType, void* pParam, uint32* pcbToken, uint8** ppToken);

}
#endregion
