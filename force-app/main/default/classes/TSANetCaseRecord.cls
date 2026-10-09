/** Represents a single TSANet collaboration case record from the API. */
public inherited sharing class TSANetCaseRecord {

    /** TSANet case identifier. */
    public Integer id;
    /** Name of the company that submitted the case. */
    public String submitCompanyName;
    /** Id of the company that submitted the case. */
    public Integer submitCompanyId;
    /** Case number from the submitting company. */
    public String submitterCaseNumber;
    /** Name of the company receiving the case. */
    public String receiveCompanyName;
    /** Id of the company receiving the case. */
    public Integer receiveCompanyId;
    /** Case number from the receiving company. */
    public String receiverCaseNumber;
    /** Brief summary of the case. */
    public String summary;
    /** Detailed description of the case. */
    public String description;
    /** Direction of the collaboration (inbound/outbound). */
    public String direction;
    /** Priority level of the case. */
    public String priority;
    /** Current status of the case. */
    public String status;
    /** Security token for the case. */
    public String token;
    /** Timestamp when the case was created. */
    public Datetime createdAt;
    /** Timestamp when the case was last updated. */
    public Datetime updatedAt;
    /** Timestamp when the case was deleted. */
    public Datetime deletedAt;
    /** Whether the case has been responded to. */
    public Boolean responded;
    /** Deadline for responding to the case. */
    public Datetime respondBy;
    /** Whether feedback has been requested. */
    public Boolean feedbackRequested;
    /** Whether a reminder has been sent. */
    public Boolean reminderSent;
    /** Note explaining the priority level. */
    public String priorityNote;
    /** Instructions for escalation. */
    public String escalationInstructions;
    /** Contact document identifier from TSANet. */
    public Integer contactDocumentId;
    /** Contact document name from TSANet. */
    public String contactDocumentName;
    /** Whether this is a test case. */
    public Boolean testCase;
    /** Custom fields attached to the case. */
    public List<CustomFieldWrapper> customFields;
    /** Information about who submitted the case. */
    public SubmittedByWrapper submittedBy;
    /** Notes attached to the case. */
    public List<CaseNoteWrapper> caseNotes;
    /** Responses attached to the case. */
    public List<CaseResponseWrapper> caseResponses;

    /** Wrapper for a custom field on a TSANet case. */
    public class CustomFieldWrapper {
        /** Custom field identifier. */
        public Integer id;
        /** Section the field belongs to. */
        public String section;
        /** Name of the custom field. */
        public String fieldName;
        /** Value of the custom field. */
        public String value;
        /** Display order of the field. */
        public Integer displayOrder;
    }

    /** Wrapper for the user who submitted the case. */
    public class SubmittedByWrapper {
        /** User identifier. */
        public Integer id;
        /** Username of the submitter. */
        public String username;
        /** First name of the submitter. */
        public String firstName;
        /** Last name of the submitter. */
        public String lastName;
        /** Email address of the submitter. */
        public String email;
        /** Phone number of the submitter. */
        public String phone;
        /** Country code for the phone number. */
        public String phoneCountryCode;
        /** City of the submitter. */
        public String city;
    }

    /** Wrapper for a note attached to a TSANet case. */
    public class CaseNoteWrapper {
        /** Note identifier. */
        public Integer id;
        /** Parent case identifier. */
        public Integer caseId;
        /** Username of the note creator. */
        public String creatorUsername;
        /** Email of the note creator. */
        public String creatorEmail;
        /** Display name of the note creator. */
        public String creatorName;
        /** Id of the company that authored the note. */
        public Integer companyId;
        /** Company name of the note creator. */
        public String companyName;
        /** Brief summary of the note. */
        public String summary;
        /** Detailed description of the note. */
        public String description;
        /** Priority level of the note. */
        public String priority;
        /** Sender intent: USER_PUBLIC, USER_PARTNER or SYSTEM. */
        public String type;
        /** Note direction relative to the reader: INBOUND or OUTBOUND. */
        public String direction;
        /** Status of the note. */
        public String status;
        /** Security token for the note. */
        public String token;
        /** Timestamp when the note was created. */
        public Datetime createdAt;
        /** Timestamp when the note was last updated. */
        public Datetime updatedAt;
    }

    /** Wrapper for a response to a TSANet case. */
    public class CaseResponseWrapper {
        /** Response identifier. */
        public Integer id;
        /** Type of the response. */
        public String type;
        /** Associated case number. */
        public String caseNumber;
        /** Name of the responding engineer. */
        public String engineerName;
        /** Phone of the responding engineer. */
        public String engineerPhone;
        /** Email of the responding engineer. */
        public String engineerEmail;
        /** Next steps described in the response. */
        public String nextSteps;
        /** Timestamp when the response was created. */
        public Datetime createdAt;
    }

    /**
     * Deserializes a JSON array into a list of TSANetCaseRecord instances.
     * @param json the JSON string to parse
     * @return array of deserialized case records
     */
    public static TSANetCaseRecord[] parse(String json){
        return (TSANetCaseRecord[]) System.JSON.deserialize(json, TSANetCaseRecord[].class);
    }

    /**
     * Deserializes a JSON object into a single TSANetCaseRecord instance.
     * @param json the JSON string to parse
     * @return the deserialized case record
     */
    public static TSANetCaseRecord parseOne(String json){
        return (TSANetCaseRecord) System.JSON.deserialize(json, TSANetCaseRecord.class);
    }
}