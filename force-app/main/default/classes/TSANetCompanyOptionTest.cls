@IsTest
public class TSANetCompanyOptionTest {

    @IsTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "label": "Demo - VMware", "companyId": 1072, "departmentId": null }';
        TSANetCompanyOption data = (TSANetCompanyOption) System.JSON.deserialize(json, TSANetCompanyOption.class);
        System.assertEquals(true,
                            data.companyId == 1072 &&
                            data.label == 'Demo - VMware' &&
                            data.departmentId == null);
    }
}