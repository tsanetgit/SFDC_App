@isTest
public class TSANetCustomerDataTest {

    @isTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "fieldId":5573, "section":"COMMON_CUSTOMER_SECTION", "label":"Customer Company", "value":"Test" }';
        TSANetCustomerData data = (TSANetCustomerData) System.JSON.deserialize(json, TSANetCustomerData.class);
        System.assertEquals(true, 
                            data.fieldId == '5573' && 
                            data.section == 'COMMON_CUSTOMER_SECTION' && 
                            data.label == 'Customer Company' && 
                            data.value == 'Test');
    }
}