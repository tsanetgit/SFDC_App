/* **********************************************************************************************
* VerAccessDecision Class
* Class for detecting field & object level security
*
*********************************************************************************************** */
public class AccessDecisionUtils {

    public class AccessDecisionException extends Exception {}
	    
	public class Decision {
        public Boolean allowDML;
        public sObject[] records;
        public Map<String,Set<String>> removedFields;
        public Integer[] modifiedIndexes;
        
        public Decision(){}
        
        public Decision(Boolean allowDML, 
                        sObject[] records, 
                        Map<String,Set<String>> removedFields, 
                        Integer[] modifiedIndexes){
            this.allowDML = allowDML;
            this.records = records;
            this.removedFields = removedFields;
            this.modifiedIndexes = modifiedIndexes;
        }
    }

    // Method for checking field level security and object level security 
    public static Decision verifyAccessDecision(sObject[] records, AccessType accessType){
        
        Decision decision = checkAccessDecision(records, accessType);
        
        if(decision.allowDML){
            return decision;
        } else {
            // Create error message for AccessDecisionException. 
            // decision.removedFields => Map of sObject types to their corresponding inaccessible fields.
            throw new AccessDecisionException('Permission Denied. Please check your access : ' + getErrorMessage(decision.removedFields));
        }
    }

    public static Decision checkAccessDecision(sObject[] records, AccessType accessType){
        
        Decision access = new Decision();
        
        SObjectAccessDecision decision = Security.stripInaccessible(accessType, records);

        if(decision.getRemovedFields().keySet().size() == 0){ 
            access = new Decision(true, decision.getRecords(), decision.getRemovedFields(), new List<Integer>(decision.getModifiedIndexes()));
        } else {
            access = new Decision(false, decision.getRecords(), decision.getRemovedFields(), new List<Integer>(decision.getModifiedIndexes()));
        }
        return access;
    }
    
    public static String getErrorMessage(Map<String,Set<String>> removedFields){
        String errorMessage = ''; 
        for(String sObjectApiName : removedFields.keySet()){
            errorMessage = errorMessage + sObjectApiName + ' : ' + String.join(new List<String>(removedFields.get(sObjectApiName)), ', ');
        }
        return errorMessage;
    }
}