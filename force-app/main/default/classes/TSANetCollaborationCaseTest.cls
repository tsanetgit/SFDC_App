@isTest
public class TSANetCollaborationCaseTest {
	
    @isTest
    public static void TSANetCollaborationCaseTest(){
        String json = '{ "id": 2738, "submitCompanyName": "Demo - Cisco", "submitCompanyId": 1071, "submitterCaseNumber": "00001063", "receiveCompanyName": "Demo - VMware", "receiveCompanyId": 1072, "receiverCaseNumber": "2738", "summary": "New Test for July 24", "description": "", "priority": "MEDIUM", "status": "ACCEPTED", "token": "mkTCWSolZxjkUxeKmy", "createdAt": "2024-07-24T22:24:57Z", "updatedAt": "2024-09-25T16:15:18Z", "deletedAt": null, "responded": true, "respondBy": "2024-07-25T02:24:57Z", "feedbackRequested": true, "reminderSent": false, "priorityNote": "<p>Priority 2 (4 hours)</p>", "escalationInstructions": "<p>test Vmware escalation</p>", "testCase": false, "customFields": [] }';
        TSANetCollaborationCase caseRecord = (TSANetCollaborationCase) System.JSON.deserialize(json, TSANetCollaborationCase.class);
        System.assertEquals(true, 
                            caseRecord.id == 2738 && 
                            caseRecord.submitCompanyName == 'Demo - Cisco' && 
                            caseRecord.submitCompanyId == 1071 && 
                            caseRecord.submitterCaseNumber == '00001063' && 
                            caseRecord.receiveCompanyName == 'Demo - VMware' && 
                            caseRecord.receiveCompanyId == 1072 && 
                            caseRecord.receiverCaseNumber == '2738' && 
                            caseRecord.summary == 'New Test for July 24' && 
                            caseRecord.description == '' && 
                            caseRecord.priority == 'MEDIUM' &&
                            caseRecord.status == 'ACCEPTED' &&
                            caseRecord.token == 'mkTCWSolZxjkUxeKmy' &&
                            caseRecord.createdAt == '2024-07-24T22:24:57Z' &&
                            caseRecord.updatedAt == '2024-09-25T16:15:18Z' &&
                            caseRecord.deletedAt == NULL &&
                            caseRecord.responded == TRUE &&
                            caseRecord.respondBy == '2024-07-25T02:24:57Z' &&
                            caseRecord.feedbackRequested == TRUE &&
                            caseRecord.reminderSent == FALSE &&
                            caseRecord.priorityNote == '<p>Priority 2 (4 hours)</p>' &&
                            caseRecord.escalationInstructions == '<p>test Vmware escalation</p>' &&
                            caseRecord.testCase == FALSE &&
                            caseRecord.customFields.size() == 0 &&
                            caseRecord.caseNotes == NULL &&
                            caseRecord.submittedBy == NULL &&
                            caseRecord.caseResponses == NULL
                           );
    }
}