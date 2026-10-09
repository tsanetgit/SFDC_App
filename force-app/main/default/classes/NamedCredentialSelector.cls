/** Centralized SOQL for NamedCredential, used by the credential creation UI. */
public with sharing class NamedCredentialSelector {

    /** Combobox-ready Named Credential entry exposed to the client. */
    public class NamedCredentialOption {
        /** Display label of the Named Credential. */
        @AuraEnabled public String label;
        /** Callout name, including the namespace prefix for packaged credentials. */
        @AuraEnabled public String value;
        /** True when the Named Credential was created in the subscriber org. */
        @AuraEnabled public Boolean isCustom;

        /**
         * Builds an option from a NamedCredential record.
         * @param credential the source NamedCredential
         */
        public NamedCredentialOption(NamedCredential credential){
            isCustom = String.isBlank(credential.NamespacePrefix);
            label = credential.MasterLabel;
            value = isCustom
                ? credential.DeveloperName
                : credential.NamespacePrefix + '__' + credential.DeveloperName;
        }
    }

    @TestVisible
    private static NamedCredential[] mockCredentials;

    /**
     * Returns the Named Credentials available in the org for selection.
     * Requires "View Setup and Configuration" on the running user; callers are
     * expected to offer a manual entry fallback when this throws.
     * @return list of Named Credential options sorted by label
     */
    @AuraEnabled(cacheable=true)
    public static NamedCredentialOption[] getNamedCredentials(){
        try {
            NamedCredentialOption[] options = new NamedCredentialOption[]{};
            for(NamedCredential credential : query()){
                options.add(new NamedCredentialOption(credential));
            }
            return options;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Queries the org Named Credentials in user mode. NamedCredential is a setup
     * object; the credential UI is an admin with View Setup and Configuration.
     * @return list of NamedCredential records
     */
    private static NamedCredential[] query(){
        if(mockCredentials != null){
            return mockCredentials;
        }

        return [
            SELECT Id, MasterLabel, DeveloperName, NamespacePrefix
            FROM NamedCredential
            WITH USER_MODE
            ORDER BY MasterLabel
            LIMIT 200
        ];
    }
}
