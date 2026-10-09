/** Resolves the Named Credential used for TSANet API callouts by the primary credential. */
public with sharing class AuthModeManager {

    private static final String CALLOUT_PREFIX = 'callout:';
    private static final String PACKAGE_NAMESPACE = 'tsanetconnect';
    private static final String NAMESPACE_SEPARATOR = '__';
    private static final Set<String> PACKAGED_CALLOUT_NAMES = new Set<String>{
        'TSANetAPI', 'TSANetAPIDev', 'TSANetAPIBeta', 'TSANetAPITest'
    };

    @TestVisible
    private static Boolean usesNamedCredentialCache;
    @TestVisible
    private static String calloutBaseCache;

    /**
     * True when the primary credential resolves to a usable Named Credential. False when
     * there is no primary credential or it has no Named Credential selected, in which case
     * callers must surface a configuration error instead of attempting a callout.
     * @return true when callouts can go through the Named Credential
     */
    public static Boolean usesNamedCredential(){
        if(usesNamedCredentialCache == null){
            resolve();
        }
        return usesNamedCredentialCache;
    }

    /**
     * Returns the callout base for the primary credential, e.g. "callout:tsanetconnect__TSANetAPI".
     * @return callout base URL, or null when no Named Credential is configured
     */
    public static String getCalloutBase(){
        if(usesNamedCredentialCache == null){
            resolve();
        }
        return calloutBaseCache;
    }

    /**
     * True when the given credential record has a Named Credential selected.
     * @param credential the credential record to inspect
     * @return true when the record can be used for callouts
     */
    public static Boolean usesNamedCredential(tsanetconnect__TSANet_Credentials__c credential){
        return credential != null
            && String.isNotBlank(credential.tsanetconnect__NamedCredential__c);
    }

    /**
     * Returns the callout base for the given credential record.
     * @param credential the credential record to inspect
     * @return callout base URL, or null when the record has no Named Credential
     */
    public static String getCalloutBase(tsanetconnect__TSANet_Credentials__c credential){
        if(!usesNamedCredential(credential)){
            return null;
        }
        String calloutName = resolveNamedCredentialName(credential.tsanetconnect__NamedCredential__c);
        return String.isBlank(calloutName) ? null : CALLOUT_PREFIX + calloutName;
    }

    /**
     * Maps the stored Named Credential value to the callout name.
     * Packaged Dev/Beta/Prod credentials always use the tsanetconnect__ prefix.
     * Any other name is left unqualified.
     * @param rawName value saved on TSANet_Credentials__c.NamedCredential__c
     * @return callout name, or null when blank
     */
    @TestVisible
    static String resolveNamedCredentialName(String rawName){
        if(String.isBlank(rawName)){
            return null;
        }

        String name = rawName.trim();
        String packagePrefix = PACKAGE_NAMESPACE + NAMESPACE_SEPARATOR;
        String developerName = name.startsWith(packagePrefix)
            ? name.substring(packagePrefix.length())
            : name;

        if(PACKAGED_CALLOUT_NAMES.contains(developerName)){
            return packagePrefix + developerName;
        }
        return developerName;
    }

    /** Clears the cached resolution; used after credential changes and by tests. */
    @TestVisible
    public static void clearCache(){
        usesNamedCredentialCache = null;
        calloutBaseCache = null;
    }

    /**
     * Reads the primary credential in system mode: the routing decision must resolve
     * identically for background jobs that lack field access.
     */
    private static void resolve(){
        try {
            tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
            usesNamedCredentialCache = usesNamedCredential(credential);
            calloutBaseCache = getCalloutBase(credential);
        } catch(Exception e){
            usesNamedCredentialCache = false;
            calloutBaseCache = null;
        }
    }
}
