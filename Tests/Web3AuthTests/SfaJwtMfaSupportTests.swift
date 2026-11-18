@testable import Web3Auth
import XCTest

/**
 JWT / SFA MFA helpers — no Torus or network.
 */
final class SfaJwtMfaSupportTests: XCTestCase {
    func testJwtConnectDefaultsToAuthFirstToAvoidTokenIsUsed() {
        XCTAssertTrue(SfaJwtMfaSupport.shouldUseAuthFirstForJwt(idToken: "firebase-jwt", mfaLevel: nil))
        XCTAssertTrue(SfaJwtMfaSupport.shouldUseAuthFirstForJwt(idToken: "firebase-jwt", mfaLevel: .MANDATORY))
        // Silent local SFA only when app opts out of Auth (known non-MFA).
        XCTAssertFalse(SfaJwtMfaSupport.shouldUseAuthFirstForJwt(idToken: "firebase-jwt", mfaLevel: .NONE))
        XCTAssertFalse(SfaJwtMfaSupport.shouldUseAuthFirstForJwt(idToken: nil, mfaLevel: nil))
        XCTAssertFalse(SfaJwtMfaSupport.shouldUseAuthFirstForJwt(idToken: "", mfaLevel: nil))
    }

    func testBuildJwtAuthLoginParamsPutsIdTokenInExtraLoginOptions() {
        let params = SfaJwtMfaSupport.buildJwtAuthLoginParams(
            loginParams: sampleJwtLoginParams(),
            loginHint: "firebase-uid-1",
            clientId: "firebase-client"
        )
        // Default login does not force mandatory; Auth prompts MFA when needed.
        XCTAssertNil(params.mfaLevel)
        XCTAssertEqual(params.extraLoginOptions?.id_token, "firebase-jwt")
        XCTAssertEqual(params.extraLoginOptions?.login_hint, "firebase-uid-1")
        XCTAssertEqual(params.extraLoginOptions?.client_id, "firebase-client")
    }

    func testForceMfaMandatorySetsMfaLevel() {
        let params = SfaJwtMfaSupport.buildJwtAuthLoginParams(
            loginParams: sampleJwtLoginParams(),
            loginHint: "uid",
            forceMfaMandatory: true
        )
        XCTAssertEqual(params.mfaLevel, .MANDATORY)
    }

    func testIsUpgradedFalseOrNullDoesNotRequireAuthMfaFlow() {
        XCTAssertFalse(SfaJwtMfaSupport.requiresAuthMfaFlow(isUpgraded: false))
        XCTAssertFalse(SfaJwtMfaSupport.requiresAuthMfaFlow(isUpgraded: nil))
        XCTAssertTrue(SfaJwtMfaSupport.requiresAuthMfaFlow(isUpgraded: true))
    }

    func testEnableMfaPreservesCustomJwtCredentialsInExtraLoginOptions() {
        let merged = SfaJwtMfaSupport.mergeJwtExtraLoginOptions(
            existing: ExtraLoginOptions(domain: "example.com"),
            idToken: "jwt-from-firebase",
            loginHint: "user-123",
            clientId: "client-abc"
        )
        XCTAssertEqual(merged.id_token, "jwt-from-firebase")
        XCTAssertEqual(merged.login_hint, "user-123")
        XCTAssertEqual(merged.client_id, "client-abc")
        XCTAssertEqual(merged.domain, "example.com")
    }

    func testResolveJwtForMfaPrefersParamsThenStoredThenOAuthOverSessionIdToken() {
        let user = Web3AuthUserInfo(
            email: "",
            name: nil,
            profileImage: nil,
            groupedAuthConnectionId: nil,
            authConnectionId: nil,
            userId: nil,
            dappShare: nil,
            idToken: "session-id-token",
            oAuthIdToken: "firebase-oauth-jwt",
            oAuthAccessToken: nil,
            isMfaEnabled: false,
            authConnection: "custom",
            appState: nil
        )
        XCTAssertEqual(
            SfaJwtMfaSupport.resolveJwtForMfa(
                paramsIdToken: "from-params",
                paramsExtraIdToken: nil,
                storedLoginIdToken: nil,
                userInfo: user
            ),
            "from-params"
        )
        XCTAssertEqual(
            SfaJwtMfaSupport.resolveJwtForMfa(
                paramsIdToken: nil,
                paramsExtraIdToken: "from-extra",
                storedLoginIdToken: nil,
                userInfo: user
            ),
            "from-extra"
        )
        XCTAssertEqual(
            SfaJwtMfaSupport.resolveJwtForMfa(
                paramsIdToken: nil,
                paramsExtraIdToken: nil,
                storedLoginIdToken: "from-stored",
                userInfo: user
            ),
            "from-stored"
        )
        XCTAssertEqual(
            SfaJwtMfaSupport.resolveJwtForMfa(
                paramsIdToken: nil,
                paramsExtraIdToken: nil,
                storedLoginIdToken: nil,
                userInfo: user,
                storedLoginExtraIdToken: "from-stored-extra"
            ),
            "from-stored-extra"
        )
        // After Auth-first + process death: prefer oAuthIdToken, not session idToken.
        XCTAssertEqual(
            SfaJwtMfaSupport.resolveJwtForMfa(
                paramsIdToken: nil,
                paramsExtraIdToken: nil,
                storedLoginIdToken: nil,
                userInfo: user
            ),
            "firebase-oauth-jwt"
        )
        let sessionOnly = Web3AuthUserInfo(
            email: "",
            name: nil,
            profileImage: nil,
            groupedAuthConnectionId: nil,
            authConnectionId: nil,
            userId: nil,
            dappShare: nil,
            idToken: "session-id-token-only",
            oAuthIdToken: nil,
            oAuthAccessToken: nil,
            isMfaEnabled: false,
            authConnection: "custom",
            appState: nil
        )
        XCTAssertEqual(
            SfaJwtMfaSupport.resolveJwtForMfa(
                paramsIdToken: nil,
                paramsExtraIdToken: nil,
                storedLoginIdToken: nil,
                userInfo: sessionOnly
            ),
            "session-id-token-only"
        )
        XCTAssertNil(
            SfaJwtMfaSupport.resolveJwtForMfa(
                paramsIdToken: nil,
                paramsExtraIdToken: nil,
                storedLoginIdToken: nil,
                userInfo: nil
            )
        )
    }

    func testHasLocalSessionForMfaFallbackUsesPreRefreshSnapshot() {
        XCTAssertTrue(
            SfaJwtMfaSupport.hasLocalSessionForMfaFallback(
                storageSessionId: "",
                privateKey: "0xabc",
                factorKey: nil
            )
        )
        XCTAssertTrue(
            SfaJwtMfaSupport.hasLocalSessionForMfaFallback(
                storageSessionId: "sess",
                privateKey: nil,
                factorKey: nil
            )
        )
        XCTAssertFalse(
            SfaJwtMfaSupport.hasLocalSessionForMfaFallback(
                storageSessionId: "",
                privateKey: nil,
                factorKey: nil
            )
        )
        XCTAssertTrue(
            SfaJwtMfaSupport.canLaunchMfaWithoutCitadel(
                jwt: "firebase-jwt",
                hasActiveLocalSession: SfaJwtMfaSupport.hasLocalSessionForMfaFallback(
                    storageSessionId: "",
                    privateKey: "0xabc",
                    factorKey: nil
                )
            )
        )
        XCTAssertFalse(
            SfaJwtMfaSupport.canLaunchMfaWithoutCitadel(
                jwt: "firebase-jwt",
                hasActiveLocalSession: SfaJwtMfaSupport.hasLocalSessionForMfaFallback(
                    storageSessionId: "",
                    privateKey: nil,
                    factorKey: nil
                )
            )
        )
    }

    func testCanLaunchMfaWithoutCitadelOnlyWithJwtAndLocalSession() {
        XCTAssertTrue(SfaJwtMfaSupport.canLaunchMfaWithoutCitadel(jwt: "jwt", hasActiveLocalSession: true))
        XCTAssertFalse(SfaJwtMfaSupport.canLaunchMfaWithoutCitadel(jwt: "jwt", hasActiveLocalSession: false))
        XCTAssertFalse(SfaJwtMfaSupport.canLaunchMfaWithoutCitadel(jwt: nil, hasActiveLocalSession: true))
        XCTAssertFalse(SfaJwtMfaSupport.canLaunchMfaWithoutCitadel(jwt: "", hasActiveLocalSession: true))
    }

    private func sampleJwtLoginParams() -> LoginParams {
        LoginParams(
            authConnection: .CUSTOM,
            authConnectionId: "w3a-firebase-demo",
            idToken: "firebase-jwt"
        )
    }
}
