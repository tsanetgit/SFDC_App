@isTest
public class TSANetCompanyFormTest {

    @isTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customFields": [ { "fieldId": 5558, "section": "COMMON_CUSTOMER_SECTION", "label": "Customer Company", "value": null }, { "fieldId": 5559, "section": "COMMON_CUSTOMER_SECTION", "label": "Customer Name", "value": null }, { "fieldId": 5560, "section": "COMMON_CUSTOMER_SECTION", "label": "Customer Email", "value": null }, { "fieldId": 5561, "section": "COMMON_CUSTOMER_SECTION", "label": "Customer Phone Including Country Code", "value": null }, { "fieldId": 5562, "section": "COMMON_CUSTOMER_SECTION", "label": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
        TSANetCompanyForm form = (TSANetCompanyForm) System.JSON.deserialize(json, TSANetCompanyForm.class);
        System.assertEquals(true, 
                            form.documentId == '2115' && 
                            form.internalCaseNumber == '' && 
                            form.optionalRecieverInternalCaseNumber == '' && 
                            form.problemSummary == '' && 
                            form.problemDescription == '' && 
                            form.casePriority == '' && 
                            form.readonlyAdminNote == '<p>test admin note (description)</p>' && 
                            form.readonlyEscalationInstructions == '<p>test escalation instructions</p>' && 
                            form.testSubmission == false && 
                            form.customFields.size() > 0
                           );
    }
}