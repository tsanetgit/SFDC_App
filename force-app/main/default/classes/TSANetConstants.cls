/** Centralized field maps and integration constants for the TSANet Connect package. */
public with sharing class TSANetConstants {

    // ── TSANetCase__c ──────────────────────────────────────────────────

    public static final Map<String, SObjectField> TSANET_CASE_FIELDS = new Map<String, SObjectField>{
        'Id'                    => tsanetconnect__TSANetCase__c.Id,
        'Name'                  => tsanetconnect__TSANetCase__c.Name,
        'OwnerId'               => tsanetconnect__TSANetCase__c.OwnerId,
        'Case'                  => tsanetconnect__TSANetCase__c.tsanetconnect__Case__c,
        'Token'                 => tsanetconnect__TSANetCase__c.tsanetconnect__Token__c,
        'tsaNetCaseId'          => tsanetconnect__TSANetCase__c.tsanetconnect__tsaNetCaseId__c,
        'CaseName'              => tsanetconnect__TSANetCase__c.tsanetconnect__Name__c,
        'CustomFields'          => tsanetconnect__TSANetCase__c.tsanetconnect__customFields__c,
        'EscalationInstructions'=> tsanetconnect__TSANetCase__c.tsanetconnect__EscalationInstructions__c,
        'TSANetContact'         => tsanetconnect__TSANetCase__c.tsanetconnect__TSANetContact__c,
        'FirstName'             => tsanetconnect__TSANetCase__c.tsanetconnect__FirstName__c,
        'LastName'              => tsanetconnect__TSANetCase__c.tsanetconnect__LastName__c,
        'Phone'                 => tsanetconnect__TSANetCase__c.tsanetconnect__Phone__c,
        'EngineerName'          => tsanetconnect__TSANetCase__c.tsanetconnect__EngineerName__c,
        'EngineerEmail'         => tsanetconnect__TSANetCase__c.tsanetconnect__EngineerEmail__c,
        'EngineerPhone'         => tsanetconnect__TSANetCase__c.tsanetconnect__EngineerPhone__c,
        'TSANetEmail'           => tsanetconnect__TSANetCase__c.tsanetconnect__TSANetEmail__c,
        'Email'                 => tsanetconnect__TSANetCase__c.tsanetconnect__Email__c,
        'Partner'               => tsanetconnect__TSANetCase__c.tsanetconnect__Partner__c,
        'SubmittedCompanyName'  => tsanetconnect__TSANetCase__c.tsanetconnect__SubmittedCompanyName__c,
        'SubmittedCompanyId'    => tsanetconnect__TSANetCase__c.tsanetconnect__SubmittedCompanyId__c,
        'ReceivedCompanyName'   => tsanetconnect__TSANetCase__c.tsanetconnect__receivedCompanyName__c,
        'ReceivedCompanyId'     => tsanetconnect__TSANetCase__c.tsanetconnect__receivedCompanyId__c,
        'Summary'               => tsanetconnect__TSANetCase__c.tsanetconnect__Summary__c,
        'Description'           => tsanetconnect__TSANetCase__c.tsanetconnect__Description__c,
        'Status'                => tsanetconnect__TSANetCase__c.tsanetconnect__Status__c,
        'Responded'             => tsanetconnect__TSANetCase__c.tsanetconnect__Responded__c,
        'FeedbackRequested'     => tsanetconnect__TSANetCase__c.tsanetconnect__FeedbackRequested__c,
        'ReminderSent'          => tsanetconnect__TSANetCase__c.tsanetconnect__ReminderSent__c,
        'Priority'              => tsanetconnect__TSANetCase__c.tsanetconnect__Priority__c,
        'RequestDate'           => tsanetconnect__TSANetCase__c.tsanetconnect__RequestDate__c,
        'ResponseDate'          => tsanetconnect__TSANetCase__c.tsanetconnect__ResponseDate__c,
        'PriorityNote'          => tsanetconnect__TSANetCase__c.tsanetconnect__PriorityNote__c,
        'Direction'             => tsanetconnect__TSANetCase__c.tsanetconnect__Direction__c,
        'DocumentId'            => tsanetconnect__TSANetCase__c.tsanetconnect__DocumentId__c,
        'DocumentName'          => tsanetconnect__TSANetCase__c.tsanetconnect__DocumentName__c
    };

    public static final List<String> TSANET_CASE_RELATIONSHIP_FIELDS = new List<String>{
        'tsanetconnect__Case__r.CaseNumber',
        'tsanetconnect__Case__r.Id'
    };

    // ── TSANetResponse__c ──────────────────────────────────────────────

    public static final Map<String, SObjectField> TSANET_RESPONSE_FIELDS = new Map<String, SObjectField>{
        'Id'               => tsanetconnect__TSANetResponse__c.Id,
        'Name'             => tsanetconnect__TSANetResponse__c.Name,
        'TSANetCase'       => tsanetconnect__TSANetResponse__c.tsanetconnect__TSANetCase__c,
        'Type'             => tsanetconnect__TSANetResponse__c.tsanetconnect__Type__c,
        'EngineerName'     => tsanetconnect__TSANetResponse__c.tsanetconnect__EngineerName__c,
        'EngineerPhone'    => tsanetconnect__TSANetResponse__c.tsanetconnect__EngineerPhone__c,
        'EngineerEmail'    => tsanetconnect__TSANetResponse__c.tsanetconnect__EngineerEmail__c,
        'Note'             => tsanetconnect__TSANetResponse__c.tsanetconnect__Note__c,
        'tsaNetCaseId'     => tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetCaseId__c,
        'tsaNetResponseId' => tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c
    };

    // ── TSANetNote__c ──────────────────────────────────────────────────

    public static final Map<String, SObjectField> TSANET_NOTE_FIELDS = new Map<String, SObjectField>{
        'Id'    => tsanetconnect__TSANetNote__c.Id,
        'Name'  => tsanetconnect__TSANetNote__c.Name,
        'Token' => tsanetconnect__TSANetNote__c.tsanetconnect__Token__c,
        'Summary' => tsanetconnect__TSANetNote__c.tsanetconnect__Summary__c,
        'Description' => tsanetconnect__TSANetNote__c.tsanetconnect__Description__c,
        'CompanyName' => tsanetconnect__TSANetNote__c.tsanetconnect__CompanyName__c
    };

    // ── Case ───────────────────────────────────────────────────────────

    public static final Map<String, SObjectField> CASE_FIELDS = new Map<String, SObjectField>{
        'Id'          => Case.Id,
        'Subject'     => Case.Subject,
        'CaseNumber'  => Case.CaseNumber,
        'Description' => Case.Description,
        'OwnerId'     => Case.OwnerId,
        'AccountId'   => Case.AccountId,
        'ContactId'   => Case.ContactId
    };

    public static final List<String> CASE_OWNER_FIELDS = new List<String>{
        'Owner.Name', 'Owner.FirstName', 'Owner.LastName', 'Owner.Phone', 'Owner.Email'
    };
    public static final List<String> CASE_ACCOUNT_FIELDS = new List<String>{
        'Account.Name'
    };
    public static final List<String> CASE_CONTACT_FIELDS = new List<String>{
        'Contact.Name', 'Contact.FirstName', 'Contact.LastName', 'Contact.Email', 'Contact.Phone'
    };

    // ── Integration constants ──────────────────────────────────────────

    public static final Integer DEFAULT_TIMEOUT = 120000;
    public static final Integer SHORT_TIMEOUT = 10000;
    public static final Integer PAGE_SIZE = 50;
    public static final Integer SUCCESS_CODE = 200;
    public static final String SHARE_TYPE_VIEWER = 'V';
    public static final String VISIBILITY_ALL = 'AllUsers';
    public static final String UPLOAD_STATUS_SUCCESS = 'SUCCESS';

    /** Shown whenever the primary credential has no Named Credential to call out with. */
    public static final String NOT_CONFIGURED_ERROR =
        'TSANet Connect is not configured. Open the primary TSANet Credentials record, select a '
        + 'Named Credential, and make sure its External Credential principal has the client ID and secret.';

    // ── API payload keys ───────────────────────────────────────────────

    public static final String KEY_NAME = 'name';
    public static final String KEY_EMAIL = 'email';
    public static final String KEY_PHONE = 'phone';
    public static final String KEY_INTERNAL_CASE_NUMBER = 'internalCaseNumber';
    public static final String KEY_SUBMITTER_CONTACT_DETAILS = 'submitterContactDetails';
    public static final String KEY_CASE_NUMBER = 'caseNumber';
    public static final String KEY_ENGINEER_NAME = 'engineerName';
    public static final String KEY_ENGINEER_PHONE = 'engineerPhone';
    public static final String KEY_ENGINEER_EMAIL = 'engineerEmail';
    public static final String KEY_NEXT_STEPS = 'nextSteps';
}
