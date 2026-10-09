/** Unit tests for NamedCredentialSelector — NamedCredential records are not insertable, so the query is stubbed. */
@IsTest
public class NamedCredentialSelectorTest {

    @IsTest
    static void testNamespacedCredentialReturnsQualifiedCalloutName() {
        NamedCredentialSelector.mockCredentials = new NamedCredential[]{
            buildCredential('TSANet API', 'TSANetAPI', 'tsanetconnect')
        };

        Test.startTest();
            NamedCredentialSelector.NamedCredentialOption[] options = NamedCredentialSelector.getNamedCredentials();
        Test.stopTest();

        System.assertEquals(1, options.size(), 'Expected one option');
        System.assertEquals('TSANet API', options[0].label, 'Label must be the Named Credential master label');
        System.assertEquals('tsanetconnect__TSANetAPI', options[0].value, 'Packaged credentials must include the namespace prefix');
        System.assertEquals(false, options[0].isCustom, 'Packaged credentials are not subscriber-created');
    }

    @IsTest
    static void testUnmanagedCredentialReturnsDeveloperName() {
        NamedCredentialSelector.mockCredentials = new NamedCredential[]{
            buildCredential('Local API', 'LocalAPI', null)
        };

        Test.startTest();
            NamedCredentialSelector.NamedCredentialOption[] options = NamedCredentialSelector.getNamedCredentials();
        Test.stopTest();

        System.assertEquals('LocalAPI', options[0].value, 'Credentials without a namespace use the developer name as-is');
        System.assertEquals(true, options[0].isCustom, 'Subscriber-created credentials are marked custom');
    }

    @IsTest
    static void testEmptyOrgReturnsNoOptions() {
        NamedCredentialSelector.mockCredentials = new NamedCredential[]{};

        Test.startTest();
            NamedCredentialSelector.NamedCredentialOption[] options = NamedCredentialSelector.getNamedCredentials();
        Test.stopTest();

        System.assertEquals(true, options.isEmpty(), 'An org without Named Credentials returns no options');
    }

    /** NamedCredential fields are read-only, so records are built through JSON deserialisation. */
    private static NamedCredential buildCredential(String label, String developerName, String namespacePrefix){
        Map<String, Object> fields = new Map<String, Object>{
            'attributes' => new Map<String, String>{ 'type' => 'NamedCredential' },
            'MasterLabel' => label,
            'DeveloperName' => developerName,
            'NamespacePrefix' => namespacePrefix
        };

        return (NamedCredential) JSON.deserialize(JSON.serialize(fields), NamedCredential.class);
    }
}
