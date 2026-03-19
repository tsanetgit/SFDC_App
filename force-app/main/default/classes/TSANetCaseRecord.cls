public class TSANetCaseRecord {
    
    public Integer id;
    public String submitCompanyName;
    public Integer submitCompanyId;
    public String submitterCaseNumber;
    public String receiveCompanyName;
    public Integer receiveCompanyId;
    public String receiverCaseNumber;
    public String summary;
    public String description;
    public String direction;
    public String priority;
    public String status;
    public String token;
    public Datetime createdAt;
    public Datetime updatedAt;
    public Datetime deletedAt;
    public Boolean responded;
    public Datetime respondBy;
    public Boolean feedbackRequested;
    public Boolean reminderSent;
    public String priorityNote;
    public String escalationInstructions;
    public Boolean testCase;
    public List<CustomFieldWrapper> customFields;
    public SubmittedByWrapper submittedBy;
    public List<CaseNoteWrapper> caseNotes;
    public List<CaseResponseWrapper> caseResponses;

    public class CustomFieldWrapper {
        public Integer id;
        public String section;
        public String fieldName;
        public String value;
        public Integer displayOrder;
    }

    public class SubmittedByWrapper {
        public Integer id;
        public String username;
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String phoneCountryCode;
        public String city;
    }

    public class CaseNoteWrapper {
        public Integer id;
        public Integer caseId;
        public String creatorUsername;
        public String creatorEmail;
        public String creatorName;
        public String companyName;
        public String summary;
        public String description;
        public String priority;
        public String status;
        public String token;
        public Datetime createdAt;
        public Datetime updatedAt;
    }

    public class CaseResponseWrapper {
        public Integer id;
        public String type;
        public String caseNumber;
        public String engineerName;
        public String engineerPhone;
        public String engineerEmail;
        public String nextSteps;
        public Datetime createdAt;
    }
    
    public static TSANetCaseRecord[] parse(String json){
        return (TSANetCaseRecord[]) System.JSON.deserialize(json, TSANetCaseRecord[].class);
    }
    
    public static TSANetCaseRecord parseOne(String json){
        return (TSANetCaseRecord) System.JSON.deserialize(json, TSANetCaseRecord.class);
    }
}