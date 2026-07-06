/** Reads and writes TSANet access tokens in org-default custom settings. */
public without sharing class TokenManager {

    /** Exception thrown when token storage or retrieval fails. */
    public class TokenManagerException extends Exception {}

    /** In-memory token cache to avoid DML before callouts. */
    private static String pendingToken;
    private static Integer pendingExpiresIn;

    /**
     * Returns a valid stored token or refreshes via login when missing or expired.
     * Does NOT persist to custom settings — call commitTokenIfPending() after callouts.
     * @return concatenated access token string
     */
    public static String getAccessToken() {
        if (String.isNotBlank(pendingToken)) {
            return pendingToken;
        }

        tsanetconnect__TSANet_Tokens__c settings = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
        String token = concatenate(settings);

        if (String.isNotBlank(token) && !isExpired(settings)) {
            return token;
        }

        return refreshToken();
    }

    /**
     * Splits and persists the access token with optional expiry metadata.
     * @param token the access token to store
     * @param expiresIn token lifetime in seconds from login response
     */
    public static void updateToken(String token, Integer expiresIn) {
        tsanetconnect__TSANet_Tokens__c settings = getOrCreateOrgDefaults();
        AccessTokenSplitter.SplitResult splitResult = AccessTokenSplitter.splitBy175(token);

        settings.tsanetconnect__AccessTokenPart1__c = splitResult.firstPart;
        settings.tsanetconnect__AccessTokenPart2__c = splitResult.restPart;
        settings.tsanetconnect__TokenExpiresAt__c = expiresIn != null
            ? DateTime.now().addSeconds(expiresIn)
            : null;

        // System mode: protected token setting is written by guest/background contexts that lack FLS.
        Database.upsert(settings, true, AccessLevel.SYSTEM_MODE);
        pendingToken = null;
        pendingExpiresIn = null;
    }

    /** Clears stored token parts and expiry from org-default custom settings. */
    public static void clearToken() {
        tsanetconnect__TSANet_Tokens__c settings = getOrCreateOrgDefaults();
        settings.tsanetconnect__AccessTokenPart1__c = null;
        settings.tsanetconnect__AccessTokenPart2__c = null;
        settings.tsanetconnect__TokenExpiresAt__c = null;
        // System mode: protected token setting is written by guest/background contexts that lack FLS.
        Database.upsert(settings, true, AccessLevel.SYSTEM_MODE);
        pendingToken = null;
        pendingExpiresIn = null;
    }

    /** Persists any token obtained via auto-refresh. Call after all callouts are done. */
    public static void commitTokenIfPending() {
        if (String.isNotBlank(pendingToken)) {
            updateToken(pendingToken, pendingExpiresIn);
        }
    }

    /**
     * Forces a fresh login without DML. Safe to call between HTTP callouts.
     * Persistence is deferred until commitTokenIfPending().
     * @return new access token from login response
     */
    public static String refreshAccessToken() {
        pendingToken = null;
        return refreshToken();
    }

    @TestVisible
    private static String concatenate(tsanetconnect__TSANet_Tokens__c settings) {
        if (settings == null || String.isBlank(settings.tsanetconnect__AccessTokenPart1__c)) {
            return null;
        }

        String part2 = settings.tsanetconnect__AccessTokenPart2__c;
        return settings.tsanetconnect__AccessTokenPart1__c + (part2 == null ? '' : part2);
    }

    private static Boolean isExpired(tsanetconnect__TSANet_Tokens__c settings) {
        if (settings == null || settings.tsanetconnect__TokenExpiresAt__c == null) {
            return false;
        }

        DateTime refreshAt = settings.tsanetconnect__TokenExpiresAt__c.addSeconds(
            -TSANetConstants.TOKEN_EXPIRY_BUFFER_SECONDS
        );
        return DateTime.now() >= refreshAt;
    }

    /** Logs in and caches token in memory without DML — safe to call before callouts. */
    private static String refreshToken() {
        AuthManager.AccessTokenResponse response = TSANetService.login(CredentialManager.getCredentialsSystemMode());

        if (response == null || String.isBlank(response.accessToken)) {
            throw new TokenManagerException('Unauthorized');
        }

        pendingToken = response.accessToken;
        pendingExpiresIn = response.expiresIn;
        return response.accessToken;
    }

    private static tsanetconnect__TSANet_Tokens__c getOrCreateOrgDefaults() {
        tsanetconnect__TSANet_Tokens__c settings = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
        return settings != null ? settings : new tsanetconnect__TSANet_Tokens__c();
    }
}
