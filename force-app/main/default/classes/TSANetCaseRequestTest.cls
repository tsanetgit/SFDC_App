@isTest
public class TSANetCaseRequestTest {

    @isTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "caseNumber": "1072", "engineerName": "Engineer Name", "engineerEmail": "test@gmail.com", "engineerPhone": "+128572571275", "nextSteps": "Next Steps" }';
        TSANetCaseRequest data = (TSANetCaseRequest) System.JSON.deserialize(json, TSANetCaseRequest.class);
        System.assertEquals(true, 
                            data.caseNumber == '1072' && 
                            data.engineerName == 'Engineer Name' && 
                            data.engineerEmail == 'test@gmail.com' &&
                            data.engineerPhone == '+128572571275' &&
                            data.nextSteps == 'Next Steps');
    }
}