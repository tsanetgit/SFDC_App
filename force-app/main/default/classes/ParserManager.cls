public with sharing class ParserManager {
    
    // TSANetCase Fields
    public static Map<String, SObjectField> TSANET_CASE_TEXT_FIELD_MAP = new Map<String, SObjectField>{
    	'summary'     				=> tsanetconnect__TSANetCase__c.tsanetconnect__Summary__c,
        'description' 				=> tsanetconnect__TSANetCase__c.tsanetconnect__Description__c,
        'priority'    				=> tsanetconnect__TSANetCase__c.tsanetconnect__Priority__c,
        'status'      				=> tsanetconnect__TSANetCase__c.tsanetconnect__Status__c,
        'token'       				=> tsanetconnect__TSANetCase__c.tsanetconnect__Token__c,
        'priorityNote'				=> tsanetconnect__TSANetCase__c.tsanetconnect__PriorityNote__c,
        'submitCompanyName'  		=> tsanetconnect__TSANetCase__c.tsanetconnect__SubmittedCompanyName__c, 
        'receiveCompanyName' 		=> tsanetconnect__TSANetCase__c.tsanetconnect__receivedCompanyName__c,
        'submitterCaseNumber' 	    => tsanetconnect__TSANetCase__c.tsanetconnect__SubmitterCaseNumber__c,
        'receiverCaseNumber' 		=> tsanetconnect__TSANetCase__c.tsanetconnect__ReceiverCaseNumber__c,
        'direction' 				=> tsanetconnect__TSANetCase__c.tsanetconnect__Direction__c,
        'escalationInstructions' 	=> tsanetconnect__TSANetCase__c.tsanetconnect__EscalationInstructions__c          
    };
        
    public static Map<String, SObjectField> TSANET_CASE_NUMBER_FIELD_MAP = new Map<String, SObjectField>{
        'id' 					=> tsanetconnect__TSANetCase__c.tsanetconnect__tsaNetCaseId__c,
    	'submitCompanyId'       => tsanetconnect__TSANetCase__c.tsanetconnect__SubmittedCompanyId__c,
        'receiveCompanyId'      => tsanetconnect__TSANetCase__c.tsanetconnect__receivedCompanyId__c
    };
        
    public static Map<String, SObjectField> TSANET_CASE_DATETIME_FIELD_MAP = new Map<String, SObjectField>{
        'createdAt' 	=> tsanetconnect__TSANetCase__c.tsanetconnect__RequestDate__c,
    	'respondBy'     => tsanetconnect__TSANetCase__c.tsanetconnect__ResponseDate__c,
        'updatedAt'     => tsanetconnect__TSANetCase__c.tsanetconnect__UpdatedAt__c
    };
        
    public static Map<String, SObjectField> TSANET_CASE_BOOLEAN_FIELD_MAP = new Map<String, SObjectField>{
        'responded' 		=> tsanetconnect__TSANetCase__c.tsanetconnect__Responded__c,
    	'reminderSent'     	=> tsanetconnect__TSANetCase__c.tsanetconnect__ReminderSent__c,
        'feedbackRequested' => tsanetconnect__TSANetCase__c.tsanetconnect__FeedbackRequested__c
    };
        
    // TSANetCustomNote Fields
    
    public static final Map<String, SObjectField> TSANET_NOTE_TEXT_FIELD_MAP = new Map<String, SObjectField>{
        'summary'        => tsanetconnect__TSANetNote__c.tsanetconnect__Summary__c,
        'description'    => tsanetconnect__TSANetNote__c.tsanetconnect__Description__c,
        'priority'       => tsanetconnect__TSANetNote__c.tsanetconnect__Priority__c,
        'status'         => tsanetconnect__TSANetNote__c.tsanetconnect__Status__c,
        'token'          => tsanetconnect__TSANetNote__c.tsanetconnect__Token__c,
        'creatorName'    => tsanetconnect__TSANetNote__c.tsanetconnect__CreatorName__c,
        'companyName'    => tsanetconnect__TSANetNote__c.tsanetconnect__CompanyName__c,
        'creatorEmail'   => tsanetconnect__TSANetNote__c.tsanetconnect__CreatorEmail__c
    };
    
    public static final Map<String, SObjectField> TSANET_NOTE_NUMBER_FIELD_MAP = new Map<String, SObjectField>{
        'caseId'  => tsanetconnect__TSANetNote__c.tsanetconnect__CaseId__c
    };
    
    public static final Map<String, SObjectField> TSANET_NOTE_DATETIME_FIELD_MAP = new Map<String, SObjectField>{
        'createdAt' => tsanetconnect__TSANetNote__c.tsanetconnect__CreatedAt__c,
        'updatedAt' => tsanetconnect__TSANetNote__c.tsanetconnect__UpdatedAt__c
    };
        
    // TSANet Response Fields
    public static final Map<String, SObjectField> TSANET_RESPONSE_TEXT_FIELD_MAP = new Map<String, SObjectField>{
        'type'          => tsanetconnect__TSANetResponse__c.tsanetconnect__Type__c,
        'caseNumber'    => tsanetconnect__TSANetResponse__c.tsanetconnect__CaseNumber__c,
        'engineerName'  => tsanetconnect__TSANetResponse__c.tsanetconnect__EngineerName__c,
        'engineerPhone' => tsanetconnect__TSANetResponse__c.tsanetconnect__EngineerPhone__c,
        'engineerEmail' => tsanetconnect__TSANetResponse__c.tsanetconnect__EngineerEmail__c,
        'nextSteps'     => tsanetconnect__TSANetResponse__c.tsanetconnect__Note__c
    };

    public static final Map<String, SObjectField> TSANET_RESPONSE_NUMBER_FIELD_MAP = new Map<String, SObjectField>{
        'id' => tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c
    };

    public static final Map<String, SObjectField> TSANET_RESPONSE_DATETIME_FIELD_MAP = new Map<String, SObjectField>{
        'createdAt' => tsanetconnect__TSANetResponse__c.tsanetconnect__CreatedAt__c
    };
        
    //submittedBy
    public static final Map<String, SObjectField> TSANET_CASE_SUBMITTED_BY_FIELD_MAP = new Map<String, SObjectField>{
        'firstName'        	=> tsanetconnect__TSANetCase__c.tsanetconnect__FirstName__c,
        'lastName'        	=> tsanetconnect__TSANetCase__c.tsanetconnect__LastName__c,  
        'email'    	 	    => tsanetconnect__TSANetCase__c.tsanetconnect__Email__c,
        'phone'       	 	=> tsanetconnect__TSANetCase__c.tsanetconnect__Phone__c
    };
        
    public static final Map<String, SObjectField> STANDARD_CUSTOM_FIELD_MAP = new Map<String, SObjectField>{
        'Customer Case #' 		=> tsanetconnect__TSANetCase__c.tsanetconnect__ReceiverCaseNumber__c
    };
    
    public static TSANetData parseTSANetCases(String json, String caseId){

        try {
 
            tsanetconnect__TSANetCase__c[] tsaNetCases = new tsanetconnect__TSANetCase__c[]{};
            tsanetconnect__TSANetResponse__c[] tsaNetResponses = new tsanetconnect__TSANetResponse__c[]{};
            tsanetconnect__TSANetNote__c[] tsaNetNotes = new tsanetconnect__TSANetNote__c[]{};
                
            TSANetCaseRecord[] cases = TSANetCaseRecord.parse(json);
            
            for(TSANetCaseRecord caseRecord : cases){
                tsanetconnect__TSANetCase__c sfCase = new tsanetconnect__TSANetCase__c();
                
                Map<String, Object> caseRecordFieldMap = (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(caseRecord));
    
                String tsaNetCaseId = String.valueOf((Integer) caseRecordFieldMap.get('id'));
                
                for (String fieldName : caseRecordFieldMap.keySet()) {
                    
                    if(TSANET_CASE_TEXT_FIELD_MAP.containsKey(fieldName)){
                        SObjectField field = TSANET_CASE_TEXT_FIELD_MAP.get(fieldName);
                        String value = (String) caseRecordFieldMap.get(fieldName);
                        sfCase.put(field, value);
                        
                        if(fieldName == 'token'){
                            sfCase.put(tsanetconnect__TSANetCase__c.tsanetconnect__Token__c, String.valueOf(value));
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
    
    public static tsanetconnect__TSANetNote__c[] parseTSANetNotes(Map<String, Object> caseRecordFieldMap){
        try {
            List<Object> caseNotes = (List<Object>) caseRecordFieldMap.get('caseNotes');
            tsanetconnect__TSANetNote__c[] sfNotes = new tsanetconnect__TSANetNote__c[]{};
            if(caseNotes.size() > 0){
                
                for(Object note : caseNotes){
                    
                    tsanetconnect__TSANetNote__c sfNote = new tsanetconnect__TSANetNote__c();
                    
                    Map<String, Object> noteRecordFieldMap = ( Map<String, Object> ) note;
                    
                    String noteId = (String) noteRecordFieldMap.get('token');
                    
                    for(String noteField : noteRecordFieldMap.keySet()){
                        if(TSANET_NOTE_TEXT_FIELD_MAP.containsKey(noteField)){
                            SObjectField field = TSANET_NOTE_TEXT_FIELD_MAP.get(noteField);
                            String value = (String) noteRecordFieldMap.get(noteField);
                            if(noteField == 'description'){
                                String plainText = TSANetUtils.stripHtml(value);
                                sfNote.put(tsanetconnect__TSANetNote__c.tsanetconnect__DescriptionPlainText__c, plainText);
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
            return new tsanetconnect__TSANetNote__c[]{};
        }
    }
    
    public static tsanetconnect__TSANetResponse__c[] parseTSANetResponses(String caseId, Map<String, Object> caseRecordFieldMap){
        try {
            List<Object> caseResponses = (List<Object>) caseRecordFieldMap.get('caseResponses');
            
            tsanetconnect__TSANetResponse__c[] sfResponses = new tsanetconnect__TSANetResponse__c[]{};
                
            if(caseResponses.size() > 0){
                
                for(Object caseResponse : caseResponses){
                    
                    tsanetconnect__TSANetResponse__c sfResponse = new tsanetconnect__TSANetResponse__c();
                    sfResponse.tsanetconnect__CaseId__c = caseId;
                        
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
            return new tsanetconnect__TSANetResponse__c[]{};
        }
    }
    
    public static void parseCustomFields(tsanetconnect__TSANetCase__c sfCase, Map<String, Object> caseRecordFieldMap){
        try {
            List<Object> customFields = (List<Object>) caseRecordFieldMap.get('customFields');
            
            sfCase.put(tsanetconnect__TSANetCase__c.tsanetconnect__customFields__c, System.JSON.serialize(customFields));
            
            Map<String, tsanetconnect__TSANetCustomField__mdt> mapper = getCustomFieldMapping();
            
            for(Object customField : customFields){
                Map<String, Object> customerFieldToValue = ( Map<String, Object> ) customField;
                
                String customFieldName = (String) customerFieldToValue.get('fieldName');
                String value = (String) customerFieldToValue.get('value');
                
                if(mapper.containsKey(customFieldName)){
                    tsanetconnect__TSANetCustomField__mdt field = mapper.get(customFieldName);
                    sfCase.put(field.tsanetconnect__To__c, value);
                }
                
                for(String fieldName : STANDARD_CUSTOM_FIELD_MAP.keySet()){
                    if(customFieldName.contains(fieldName)){
                        SObjectField field = STANDARD_CUSTOM_FIELD_MAP.get(fieldName);
                        sfCase.put(field, value);
                    }
                }
                
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'CUSTOM_FIELDS_MAPPING_ERROR');
        }
    }
    
    public static void parseSubmittedBy(tsanetconnect__TSANetCase__c sfCase, Map<String, Object> caseRecordFieldMap){
         
        try {
            Map<String, Object> submittedBy = (Map<String, Object>) caseRecordFieldMap.get('submittedBy');
            for(String fieldName : submittedBy.keySet()){
                if(TSANET_CASE_SUBMITTED_BY_FIELD_MAP.containsKey(fieldName)){
                    SObjectField field = TSANET_CASE_SUBMITTED_BY_FIELD_MAP.get(fieldName);
                    
                    String value = (String) submittedBy.get(fieldName);
                    sfCase.put(field, value);
                }
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'SUBMITTED_BY_MAPPING_ERROR');
        }
    }
        
    public static Map<String, tsanetconnect__TSANetCustomField__mdt> getCustomFieldMapping(){
        tsanetconnect__TSANetCustomField__mdt[] customFields = [SELECT Id, tsanetconnect__From__c, tsanetconnect__To__c, tsanetconnect__Type__c FROM tsanetconnect__TSANetCustomField__mdt WITH SECURITY_ENFORCED ];
        
        Map<String, tsanetconnect__TSANetCustomField__mdt> sortedCustomFields = new Map<String, tsanetconnect__TSANetCustomField__mdt>();
        for(tsanetconnect__TSANetCustomField__mdt customField : customFields){
            sortedCustomFields.put(customField.tsanetconnect__From__c, customField);
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
            ErrorLogger.logError(e, 'DATETIME_FIELD_PARSING_ERROR');
            return null;
        }
    }

    public static tsanetconnect__TSANetNote__c parseTSANetNote(String json){
        try {
            tsanetconnect__TSANetNote__c sfNote = new tsanetconnect__TSANetNote__c();
            
            Map<String, Object> noteFieldMap = (Map<String, Object>) System.JSON.deserializeUntyped(json);
            
            for(String fieldName : noteFieldMap.keySet()){
                
                if(TSANET_NOTE_TEXT_FIELD_MAP.containsKey(fieldName)){
                    SObjectField field = TSANET_NOTE_TEXT_FIELD_MAP.get(fieldName);
                    String value = (String) noteFieldMap.get(fieldName);
                    sfNote.put(field, value);
                    
                    if(fieldName == 'description'){
                        String plainText = TSANetUtils.stripHtml(value);
                        sfNote.put(tsanetconnect__TSANetNote__c.tsanetconnect__DescriptionPlainText__c, plainText);
                    }
                }
                
                if(TSANET_NOTE_NUMBER_FIELD_MAP.containsKey(fieldName)){
                    SObjectField field = TSANET_NOTE_NUMBER_FIELD_MAP.get(fieldName);
                    Integer value = (Integer) noteFieldMap.get(fieldName);
                    sfNote.put(field, String.valueOf(value));
                }
                
                if(TSANET_NOTE_DATETIME_FIELD_MAP.containsKey(fieldName)){
                    SObjectField field = TSANET_NOTE_DATETIME_FIELD_MAP.get(fieldName);
                    DateTime dt = getDateTimeValue((String) noteFieldMap.get(fieldName));
                    sfNote.put(field, dt);
                }
            }
            
            return sfNote;
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_NOTE_JSON_PARSING_ERROR');
            return null;
        }
    }
}