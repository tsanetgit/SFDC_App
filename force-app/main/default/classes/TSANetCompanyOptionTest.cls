@isTest
public class TSANetCompanyOptionTest {

    @isTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "label": "Demo - VMware", "companyId": 1072, "departmentId": null }';
        TSANetCompanyOption data = (TSANetCompanyOption) System.JSON.deserialize(json, TSANetCompanyOption.class);
        TSANetCompanyOption option = new TSANetCompanyOption('test', 1011, 1012);
        System.assertEquals(true, 
                            data.companyId == 1072 && 
                            data.label == 'Demo - VMware' && 
                            data.departmentId == null);
    }
}