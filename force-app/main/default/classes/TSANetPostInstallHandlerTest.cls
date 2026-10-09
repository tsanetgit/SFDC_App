/** Unit tests for TSANetPostInstallHandler. */
@IsTest
public class TSANetPostInstallHandlerTest {

    @IsTest
    static void testInstallIsANoOp() {
        Test.startTest();
            Test.testInstall(new TSANetPostInstallHandler(), null);
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM tsanetconnect__TSANetError__c WHERE tsanetconnect__Context__c = 'TSANET_POST_INSTALL'
        ], 'Post-install must not write upgrade DML');
    }
}
