import AWSDynamoDB
import SmithyIdentity
import Testing

/// Minimal reproduction for intermittent fatal crash during DynamoDBClient
/// initialization on Linux GitHub Actions runners (Ubuntu 22.04 / 24.04)
/// with Swift 6.2.4 installed from swift.org tarballs.
///
/// The crash manifests as one of:
/// - `Fatal error: Tls Context failed to create` (SIGILL) on Ubuntu 24.04
/// - `double free or corruption` (SIGABRT) on Ubuntu 22.04
/// - `CRTError(code: 15364, message: "Ruleset parsing failed")` on either
///
/// Passes consistently on macOS. Fails approximately 30–50% of the time
/// on Linux GHA runners.
@Suite("DynamoDB Client Initialization")
struct DynamoDBClientInitTests {
    @Test("Client initializes without crashing")
    func clientInit() throws {
        let credentials = AWSCredentialIdentity(accessKey: "test", secret: "test")
        let config = try DynamoDBClient.DynamoDBClientConfig(
            awsCredentialIdentityResolver: StaticAWSCredentialIdentityResolver(credentials),
            region: "us-east-1",
            endpoint: "https://localhost:4566"
        )
        let client = DynamoDBClient(config: config)

        // Verify the client was created successfully.
        _ = client
    }

    @Test("Multiple clients can be created concurrently")
    func concurrentClientInit() async throws {
        // The crash may be race-condition related; creating multiple clients
        // concurrently increases the chance of triggering it.
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    let credentials = AWSCredentialIdentity(
                        accessKey: "test", secret: "test"
                    )
                    let config = try DynamoDBClient.DynamoDBClientConfig(
                        awsCredentialIdentityResolver:
                            StaticAWSCredentialIdentityResolver(credentials),
                        region: "us-east-1",
                        endpoint: "https://localhost:4566"
                    )
                    let client = DynamoDBClient(config: config)
                    _ = client
                }
            }
            try await group.waitForAll()
        }
    }
}
