/* **********************************************************************************************
* VerAccessDecision Class
* Class for detecting field & object level security
*
*********************************************************************************************** */
/** Utility class for field and object level security checks. */
public inherited sharing class AccessDecisionUtils {

    /** Exception thrown when access decision checks fail. */
    public class AccessDecisionException extends Exception {}

    /** Wrapper holding the results of a security access decision. */
	public class Decision {
        /** Whether DML is allowed based on field-level security. */
        public Boolean allowDML;
        /** Records after stripping inaccessible fields. */
        public sObject[] records;
        /** Map of SObject types to their inaccessible field names. */
        public Map<String,Set<String>> removedFields;
        /** Indexes of records that had fields stripped. */
        public Integer[] modifiedIndexes;

        /** Default constructor. */
        public Decision(){
            // Default constructor
        }

        /**
         * Constructs a Decision with all fields populated.
         * @param allowDML whether DML is allowed
         * @param records stripped records
         * @param removedFields map of SObject types to removed field names
         * @param modifiedIndexes indexes of modified records
         */
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

    /**
     * Verifies field and object level security, throwing if access is denied.
     * @param records records to check
     * @param accessType the type of access to verify
     * @return Decision result if access is allowed
     */
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

    /**
     * Checks field-level security without throwing on failure.
     * @param records records to check
     * @param accessType the type of access to verify
     * @return Decision result with access details
     */
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

    /**
     * Builds a human-readable error message from removed fields.
     * @param removedFields map of SObject types to inaccessible field names
     * @return formatted error string
     */
    public static String getErrorMessage(Map<String,Set<String>> removedFields){
        String errorMessage = '';
        for(String sObjectApiName : removedFields.keySet()){
            errorMessage = errorMessage + sObjectApiName + ' : ' + String.join(new List<String>(removedFields.get(sObjectApiName)), ', ');
        }
        return errorMessage;
    }
}