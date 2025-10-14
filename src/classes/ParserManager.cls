public class ParserManager {
    
    public static tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
    public static tsanet_connect__TSANetCaseMapping__mdt[] TSANET_MAPPING = MappingManager.getTSANetMapping();
    
    // TSANetCase Fields
    public static Map<String, SObjectField> TSANET_CASE_TEXT_FIELD_MAP = new Map<String, SObjectField>{
    	'summary'     				=> tsanet_connect__TSANetCase__c.tsanet_connect__FullSummary__c,
        'description' 				=> tsanet_connect__TSANetCase__c.tsanet_connect__Description__c,
        'priority'    				=> tsanet_connect__TSANetCase__c.tsanet_connect__Priority__c,
        'status'      				=> tsanet_connect__TSANetCase__c.tsanet_connect__Status__c,
        'token'       				=> tsanet_connect__TSANetCase__c.tsanet_connect__CaseToken__c,
        'priorityNote'				=> tsanet_connect__TSANetCase__c.tsanet_connect__PriorityNote__c,
        'submitCompanyName'  		=> tsanet_connect__TSANetCase__c.tsanet_connect__SubmittedCompanyName__c, 
        'receiveCompanyName' 		=> tsanet_connect__TSANetCase__c.tsanet_connect__receivedCompanyName__c,
        'submitterCaseNumber' 	    => tsanet_connect__TSANetCase__c.tsanet_connect__SubmitterCaseNumber__c,
        'receiverCaseNumber' 		=> tsanet_connect__TSANetCase__c.tsanet_connect__ReceiverCaseNumber__c,
        'direction' 				=> tsanet_connect__TSANetCase__c.tsanet_connect__Direction__c,
        'escalationInstructions' 	=> tsanet_connect__TSANetCase__c.tsanet_connect__EscalationInstructions__c          
    };
        
    public static Map<String, SObjectField> TSANET_CASE_NUMBER_FIELD_MAP = new Map<String, SObjectField>{
        'id' 					=> tsanet_connect__TSANetCase__c.tsanet_connect__tsaNetCaseId__c,
    	'submitCompanyId'       => tsanet_connect__TSANetCase__c.tsanet_connect__SubmittedCompanyId__c,
        'receiveCompanyId'      => tsanet_connect__TSANetCase__c.tsanet_connect__receivedCompanyId__c
    };
        
    public static Map<String, SObjectField> TSANET_CASE_DATETIME_FIELD_MAP = new Map<String, SObjectField>{
        'createdAt' 	=> tsanet_connect__TSANetCase__c.tsanet_connect__RequestDate__c,
    	'respondBy'     => tsanet_connect__TSANetCase__c.tsanet_connect__ResponseDate__c,
        'updatedAt'     => tsanet_connect__TSANetCase__c.tsanet_connect__UpdatedAt__c
    };
        
    public static Map<String, SObjectField> TSANET_CASE_BOOLEAN_FIELD_MAP = new Map<String, SObjectField>{
        'responded' 		=> tsanet_connect__TSANetCase__c.tsanet_connect__Responded__c,
    	'reminderSent'     	=> tsanet_connect__TSANetCase__c.tsanet_connect__ReminderSent__c,
        'feedbackRequested' => tsanet_connect__TSANetCase__c.tsanet_connect__FeedbackRequested__c
    };
        
    public static String[] TSANET_CASE_RELATED_OBJECT_FIELDS = new String[]{'caseNotes', 'caseResponses', 'customFields'};
    public static String[] TSANET_CASE_RELATED_OBJECTS_FIELDS = new String[]{'submitterContactDetails', 'receiverContactDetails', 'submittedBy'};
        
        
    // TSANetCustomNote Fields
    
    public static final Map<String, SObjectField> TSANET_NOTE_TEXT_FIELD_MAP = new Map<String, SObjectField>{
        'summary'        => tsanet_connect__TSANetNote__c.tsanet_connect__FullSummary__c,
        'description'    => tsanet_connect__TSANetNote__c.tsanet_connect__Description__c,
        'priority'       => tsanet_connect__TSANetNote__c.tsanet_connect__Priority__c,
        'status'         => tsanet_connect__TSANetNote__c.tsanet_connect__Status__c,
        'token'          => tsanet_connect__TSANetNote__c.tsanet_connect__Token__c,
        'creatorName'    => tsanet_connect__TSANetNote__c.tsanet_connect__CreatorName__c,
        'creatorUsername'=> tsanet_connect__TSANetNote__c.tsanet_connect__CreatorUsername__c,
        'companyName'    => tsanet_connect__TSANetNote__c.tsanet_connect__CompanyName__c,
        'creatorEmail'   => tsanet_connect__TSANetNote__c.tsanet_connect__CreatorEmail__c
    };
    
    public static final Map<String, SObjectField> TSANET_NOTE_NUMBER_FIELD_MAP = new Map<String, SObjectField>{
        'caseId'  => tsanet_connect__TSANetNote__c.tsanet_connect__CaseId__c
    };
    
    public static final Map<String, SObjectField> TSANET_NOTE_DATETIME_FIELD_MAP = new Map<String, SObjectField>{
        'createdAt' => tsanet_connect__TSANetNote__c.tsanet_connect__CreatedAt__c,
        'updatedAt' => tsanet_connect__TSANetNote__c.tsanet_connect__UpdatedAt__c
    };
        
    // TSANet Response Fields
    public static final Map<String, SObjectField> TSANET_RESPONSE_TEXT_FIELD_MAP = new Map<String, SObjectField>{
        'type'          => tsanet_connect__TSANetResponse__c.tsanet_connect__Type__c,
        'caseNumber'    => tsanet_connect__TSANetResponse__c.tsanet_connect__CaseNumber__c,
        'engineerName'  => tsanet_connect__TSANetResponse__c.tsanet_connect__EngineerName__c,
        'engineerPhone' => tsanet_connect__TSANetResponse__c.tsanet_connect__EngineerPhone__c,
        'engineerEmail' => tsanet_connect__TSANetResponse__c.tsanet_connect__EngineerEmail__c,
        'nextSteps'     => tsanet_connect__TSANetResponse__c.tsanet_connect__Note__c
    };

    public static final Map<String, SObjectField> TSANET_RESPONSE_NUMBER_FIELD_MAP = new Map<String, SObjectField>{
        'id' => tsanet_connect__TSANetResponse__c.tsanet_connect__tsaNetResponseId__c
    };

    public static final Map<String, SObjectField> TSANET_RESPONSE_DATETIME_FIELD_MAP = new Map<String, SObjectField>{
        'createdAt' => tsanet_connect__TSANetResponse__c.tsanet_connect__CreatedAt__c
    };
        
    //submittedBy
    public static final Map<String, SObjectField> TSANET_CASE_SUBMITTED_BY_FIELD_MAP = new Map<String, SObjectField>{
        'firstName'        	=> tsanet_connect__TSANetCase__c.tsanet_connect__FirstName__c,
        'lastName'        	=> tsanet_connect__TSANetCase__c.tsanet_connect__LastName__c,  
        'email'    	 	    => tsanet_connect__TSANetCase__c.tsanet_connect__Email__c,
        'phone'       	 	=> tsanet_connect__TSANetCase__c.tsanet_connect__Phone__c
    };
    
    public static TSANetData parseTSANetCases(String json, String caseId){

        try {
 
            tsanet_connect__TSANetCase__c[] tsaNetCases = new tsanet_connect__TSANetCase__c[]{};
            tsanet_connect__TSANetResponse__c[] tsaNetResponses = new tsanet_connect__TSANetResponse__c[]{};
            tsanet_connect__TSANetNote__c[] tsaNetNotes = new tsanet_connect__TSANetNote__c[]{};
                
            TSANetCaseRecord[] cases = TSANetCaseRecord.parse(json);
            
            Map<String, Map<String, Object>> test = new Map<String, Map<String, Object>>();
    
            for(TSANetCaseRecord caseRecord : cases){
                tsanet_connect__TSANetCase__c sfCase = new tsanet_connect__TSANetCase__c();
                
                Map<String, Object> caseRecordFieldMap = (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(caseRecord));
    
                String tsaNetCaseId = String.valueOf((Integer) caseRecordFieldMap.get('id'));
                
                for (String fieldName : caseRecordFieldMap.keySet()) {
                    
                    if(TSANET_CASE_TEXT_FIELD_MAP.containsKey(fieldName)){
                        SObjectField field = TSANET_CASE_TEXT_FIELD_MAP.get(fieldName);
                        String value = (String) caseRecordFieldMap.get(fieldName);
                        sfCase.put(field, value);
                        
                        if(fieldName == 'token'){
                            sfCase.put(tsanet_connect__TSANetCase__c.tsanet_connect__Token__c, String.valueOf(value));
                        }
                    } 
                    
                    if(TSANET_CASE_NUMBER_FIELD_MAP.containsKey(fieldName)){
                        SObjectField field = TSANET_CASE_NUMBER_FIELD_MAP.get(fieldName);
                        Integer value = (Integer) caseRecordFieldMap.get(fieldName);
                        sfCase.put(field, String.valueOf(value));
                    }
                    
                    if(TSANET_CASE_DATETIME_FIELD_MAP.containsKey(fieldName)){
                        SObjectField field = TSANET_CASE_DATETIME_FIELD_MAP.get(fieldName);
                        DateTime dt = getDateTimeValue((String) caseRecordFieldMap.get(fieldName));
                        sfCase.put(field, dt);
                    }
                    
                    if(TSANET_CASE_BOOLEAN_FIELD_MAP.containsKey(fieldName)){
                        SObjectField field = TSANET_CASE_BOOLEAN_FIELD_MAP.get(fieldName);
                        Boolean value = (Boolean) caseRecordFieldMap.get(fieldName);
                        sfCase.put(field, value);
                    }
                }
                
                // Relations
                tsaNetNotes.addAll(parseTSANetNotes(caseRecordFieldMap));
                tsaNetResponses.addAll(parseTSANetResponses(tsaNetCaseId, caseRecordFieldMap));
    
                // Custom fields
                parseCustomFields(sfCase, caseRecordFieldMap);
    
                // Submitted By
                parseSubmittedBy(sfCase, caseRecordFieldMap);
                
                tsaNetCases.add(sfCase);
            }
    
            TSANetData data = new TSANetData();
            data.cases = tsaNetCases;
            data.responses = tsaNetResponses;
            data.notes = tsaNetNotes;
            
            return data;
            
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_DATA_MAPPING_ERROR');
            return new TSANetData();
        }
            
    }
    
    public static tsanet_connect__TSANetNote__c[] parseTSANetNotes(Map<String, Object> caseRecordFieldMap){
        try {
            List<Object> caseNotes = (List<Object>) caseRecordFieldMap.get('caseNotes');
            tsanet_connect__TSANetNote__c[] sfNotes = new tsanet_connect__TSANetNote__c[]{};
            if(caseNotes.size() > 0){
                
                for(Object note : caseNotes){
                    
                    tsanet_connect__TSANetNote__c sfNote = new tsanet_connect__TSANetNote__c();
                    sfNote.tsanet_connect__isApiNote__c = TRUE;
                    
                    Map<String, Object> noteRecordFieldMap = ( Map<String, Object> ) note;
                    
                    String noteId = (String) noteRecordFieldMap.get('token');
                    
                    for(String noteField : noteRecordFieldMap.keySet()){
                        if(TSANET_NOTE_TEXT_FIELD_MAP.containsKey(noteField)){
                            SObjectField field = TSANET_NOTE_TEXT_FIELD_MAP.get(noteField);
                            String value = (String) noteRecordFieldMap.get(noteField);
                            System.debug('companyNameNoteField : ' + noteField);
                            System.debug('value : ' + value);
                            if(noteField == 'companyName'){
                                System.debug('companyNameValue : ' + value);
                            }
                            sfNote.put(field, value);
                        }
                        
                        if(TSANET_NOTE_NUMBER_FIELD_MAP.containsKey(noteField)){
                            SObjectField field = TSANET_NOTE_NUMBER_FIELD_MAP.get(noteField);
                            Integer value = (Integer) noteRecordFieldMap.get(noteField);
                            sfNote.put(field, String.valueOf(value));
                        }
                        
                        if(TSANET_NOTE_DATETIME_FIELD_MAP.containsKey(noteField)){
                            SObjectField field = TSANET_NOTE_DATETIME_FIELD_MAP.get(noteField);
                            DateTime dt = getDateTimeValue((String) noteRecordFieldMap.get(noteField));
                            sfNote.put(field, dt);
                        }
                    }
                    
                    sfNotes.add(sfNote);
                }
            }
            return sfNotes;
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_NOTE_MAPPING_ERROR');
            return new tsanet_connect__TSANetNote__c[]{};
        }
    }
    
    public static tsanet_connect__TSANetResponse__c[] parseTSANetResponses(String caseId, Map<String, Object> caseRecordFieldMap){
        try {
            List<Object> caseResponses = (List<Object>) caseRecordFieldMap.get('caseResponses');
            
            tsanet_connect__TSANetResponse__c[] sfResponses = new tsanet_connect__TSANetResponse__c[]{};
                
            if(caseResponses.size() > 0){
                
                for(Object caseResponse : caseResponses){
                    
                    tsanet_connect__TSANetResponse__c sfResponse = new tsanet_connect__TSANetResponse__c();
                    sfResponse.tsanet_connect__CaseId__c = caseId;
                        
                    Map<String, Object> responseRecordFieldMap = ( Map<String, Object> ) caseResponse;
                    
                    
                    for(String responseField : responseRecordFieldMap.keySet()){
                        if(TSANET_RESPONSE_TEXT_FIELD_MAP.containsKey(responseField)){
                            SObjectField field = TSANET_RESPONSE_TEXT_FIELD_MAP.get(responseField);
                            String value = (String) responseRecordFieldMap.get(responseField);
                            sfResponse.put(field, value);
                        }
                        
                        if(TSANET_RESPONSE_NUMBER_FIELD_MAP.containsKey(responseField)){
                            SObjectField field = TSANET_RESPONSE_NUMBER_FIELD_MAP.get(responseField);
                            Integer value = (Integer) responseRecordFieldMap.get(responseField);
                            sfResponse.put(field, String.valueOf(value));
                        }
                        
                        if(TSANET_RESPONSE_DATETIME_FIELD_MAP.containsKey(responseField)){
                            SObjectField field = TSANET_RESPONSE_DATETIME_FIELD_MAP.get(responseField);
                            DateTime dt = getDateTimeValue((String) responseRecordFieldMap.get(responseField));
                            sfResponse.put(field, dt);
                        }
                    }
                    
                    sfResponses.add(sfResponse);
                }
            }
            return sfResponses;
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_RESPONSE_MAPPING_ERROR');
            return new tsanet_connect__TSANetResponse__c[]{};
        }
    }
    
    public static void parseCustomFields(tsanet_connect__TSANetCase__c sfCase, Map<String, Object> caseRecordFieldMap){
        try {
            List<Object> customFields = (List<Object>) caseRecordFieldMap.get('customFields');
            
            sfCase.put(tsanet_connect__TSANetCase__c.tsanet_connect__customFields__c, System.JSON.serialize(customFields));
            
            Map<String, tsanet_connect__TSANetCustomField__mdt> mapper = getCustomFieldMapping();
            
            for(Object customField : customFields){
                Map<String, Object> customerFieldToValue = ( Map<String, Object> ) customField;
                
                String customFieldName = (String) customerFieldToValue.get('fieldName');
                String value = (String) customerFieldToValue.get('value');
                
                if(mapper.containsKey(customFieldName)){
                    tsanet_connect__TSANetCustomField__mdt field = mapper.get(customFieldName);
                    sfCase.put(field.tsanet_connect__To__c, value);
                }
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'CUSTOM_FIELDS_MAPPING_ERROR');
        }
    }
    
    public static void parseSubmittedBy(tsanet_connect__TSANetCase__c sfCase, Map<String, Object> caseRecordFieldMap){
         
        try {
            Map<String, Object> submittedBy = (Map<String, Object>) caseRecordFieldMap.get('submittedBy');
            System.debug('submittedBy HERE : ' + submittedBy);
            for(String fieldName : submittedBy.keySet()){
                System.debug('submittedByFieldName : ' + fieldName);
                if(TSANET_CASE_SUBMITTED_BY_FIELD_MAP.containsKey(fieldName)){
                    SObjectField field = TSANET_CASE_SUBMITTED_BY_FIELD_MAP.get(fieldName);
                    
                    String value = (String) submittedBy.get(fieldName);
                    System.debug('submittedByValue : ' + value);
                    sfCase.put(field, value);
                }
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'SUBMITTED_BY_MAPPING_ERROR');
        }
    }
        
    public static Map<String, tsanet_connect__TSANetCustomField__mdt> getCustomFieldMapping(){
        tsanet_connect__TSANetCustomField__mdt[] customFields = [SELECT Id, tsanet_connect__From__c, tsanet_connect__To__c, tsanet_connect__Type__c FROM tsanet_connect__TSANetCustomField__mdt];
        
        Map<String, tsanet_connect__TSANetCustomField__mdt> sortedCustomFields = new Map<String, tsanet_connect__TSANetCustomField__mdt>();
        for(tsanet_connect__TSANetCustomField__mdt customField : customFields){
            sortedCustomFields.put(customField.tsanet_connect__From__c, customField);
        }
        return sortedCustomFields;
    }
    
    public static DateTime getDateTimeValue(String datetimeString){
        try {
            if(datetimeString != null){
                datetimeString = datetimeString.replace('Z', '');
                DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
                return dt;
            } else {
                return null;
            }
        } catch(Exception e){
            System.debug(e.getMessage());
            ErrorLogger.logError(e, 'DATETIME_FIELD_PARSING_ERROR');
            return null;
        }
    }
}