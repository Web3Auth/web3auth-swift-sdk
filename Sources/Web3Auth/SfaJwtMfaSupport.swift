import Foundation

/**
 Pure helpers for SFA / custom-JWT MFA. Extracted for unit tests without Torus or UI.
 */
enum SfaJwtMfaSupport {
    /**
     Torus `metadata.upgraded == true` means the user already has MFA factors.
     Prefer Auth `/start` with a fresh JWT — never reuse a JWT already passed to
     retrieveShares (backend returns "token is used").
     */
    static func requiresAuthMfaFlow(isUpgraded: Bool?) -> Bool {
        isUpgraded == true
    }

    /**
     Custom JWT login goes Auth-first by default.
     Local Torus retrieval first consumes the JWT so Auth MFA then fails with
     "token is used". Opt into silent local SFA with `MFALevel.NONE` only when
     the user is known not to have MFA.
     */
    static func shouldUseAuthFirstForJwt(idToken: String?, mfaLevel: MFALevel? = nil) -> Bool {
        guard let idToken, !idToken.isEmpty else { return false }
        if mfaLevel == .NONE { return false }
        return true
    }

    /**
     Build Auth `/start` login params for custom JWT.
     Puts credentials in `ExtraLoginOptions`; does not force MFA level unless set.
     */
    static func buildJwtAuthLoginParams(
        loginParams: LoginParams,
        loginHint: String?,
        clientId: String? = nil,
        forceMfaMandatory: Bool = false
    ) -> LoginParams {
        let hint = nonBlank(loginHint)
            ?? nonBlank(loginParams.loginHint)
            ?? nonBlank(loginParams.extraLoginOptions?.login_hint)

        return LoginParams(
            authConnection: AuthConnection(rawValue: loginParams.authConnection) ?? .CUSTOM,
            authConnectionId: loginParams.authConnectionId,
            groupedAuthConnectionId: loginParams.groupedAuthConnectionId,
            appState: loginParams.appState,
            mfaLevel: forceMfaMandatory ? .MANDATORY : loginParams.mfaLevel,
            extraLoginOptions: mergeJwtExtraLoginOptions(
                existing: loginParams.extraLoginOptions,
                idToken: loginParams.idToken,
                loginHint: hint,
                clientId: clientId
            ),
            dappShare: loginParams.dappShare,
            curve: loginParams.curve,
            dappUrl: loginParams.dappUrl,
            loginHint: hint,
            idToken: loginParams.idToken,
            recordId: loginParams.recordId,
            loginSource: loginParams.loginSource
        )
    }

    /**
     Merge JWT credentials into extraLoginOptions
     (`id_token`, `login_hint`, optional `client_id`).
     */
    static func mergeJwtExtraLoginOptions(
        existing: ExtraLoginOptions?,
        idToken: String?,
        loginHint: String?,
        clientId: String? = nil
    ) -> ExtraLoginOptions {
        let base = existing ?? ExtraLoginOptions()
        return ExtraLoginOptions(
            display: base.display,
            prompt: base.prompt,
            max_age: base.max_age,
            ui_locales: base.ui_locales,
            id_token_hint: base.id_token_hint,
            id_token: nonBlank(idToken) ?? base.id_token,
            login_hint: nonBlank(loginHint) ?? base.login_hint,
            acr_values: base.acr_values,
            scope: base.scope,
            audience: base.audience,
            connection: base.connection,
            domain: base.domain,
            client_id: nonBlank(clientId) ?? base.client_id,
            redirect_uri: base.redirect_uri,
            leeway: base.leeway,
            userIdField: base.userIdField,
            isUserIdCaseSensitive: base.isUserIdCaseSensitive,
            additionalParams: base.additionalParams,
            access_token: base.access_token,
            flow_type: base.flow_type ?? .code
        )
    }

    /**
     Resolve a JWT for MFA Auth from enable/manage params or the current user.

     Prefer `oAuthIdToken` over `idToken`: after Auth-first login, `idToken` is
     often the Web3Auth session JWT, while `oAuthIdToken` holds the provider /
     Firebase JWT needed in `extraLoginOptions.id_token`.
     */
    static func resolveJwtForMfa(
        paramsIdToken: String?,
        paramsExtraIdToken: String?,
        storedLoginIdToken: String?,
        userInfo: Web3AuthUserInfo?,
        storedLoginExtraIdToken: String? = nil
    ) -> String? {
        let candidates: [String?] = [
            paramsIdToken,
            paramsExtraIdToken,
            storedLoginIdToken,
            storedLoginExtraIdToken,
            userInfo?.oAuthIdToken,
            // Last resort only — may be a session JWT after Auth rehydrate.
            userInfo?.idToken,
        ]
        return candidates.first { nonBlank($0) != nil }.flatMap { $0 }
    }

    /**
     Whether in-memory / storage state still counts as a local session for MFA
     fallback after citadel refresh fails. Use a **pre-refresh** snapshot —
     `refreshSession` wipes `web3AuthResponse` on failure.
     */
    static func hasLocalSessionForMfaFallback(
        storageSessionId: String?,
        privateKey: String?,
        factorKey: String?
    ) -> Bool {
        nonBlank(storageSessionId) != nil
            || nonBlank(privateKey) != nil
            || nonBlank(factorKey) != nil
    }

    /**
     When citadel refresh fails, JWT users may still open Auth MFA
     (unlike a true no-session case).
     */
    static func canLaunchMfaWithoutCitadel(jwt: String?, hasActiveLocalSession: Bool) -> Bool {
        nonBlank(jwt) != nil && hasActiveLocalSession
    }

    private static func nonBlank(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
