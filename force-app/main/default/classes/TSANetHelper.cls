/** Utility class providing HTML sanitization and case feed item creation for TSANet. */
public with sharing class TSANetHelper {

    /**
     * Removes HTML tags from the given string.
     * @param input the string potentially containing HTML tags
     * @return the input string with all HTML tags removed
     */
    public static String stripHtmlTags(String input) {
        if (String.isEmpty(input)) { return ''; }
        Pattern htmlPattern = Pattern.compile('<[^>]+>');
        Matcher htmlMatcher = htmlPattern.matcher(input);
        String sanitizedString = htmlMatcher.replaceAll('');
        return sanitizedString;
    }

    /**
     * Unescapes HTML entities and strips all HTML tags from the given string.
     * @param input the string potentially containing HTML entities and tags
     * @return the fully sanitized plain-text string
     */
    public static String stripAllHtml(String input) {
        if (String.isEmpty(input)) {
            return '';
        }
        String finalBody = input.unescapeHtml4();
        finalBody = stripHtmlTags(finalBody);
        return finalBody;
    }


    /**
     * Creates a Chatter FeedItem on the specified Case with collaboration request details.
     * CRUD guards sit next to the SOQL/DML so Checkmarx Apex_CRUD_Violation can see them.
     * @param caseId the Id of the Case to attach the feed item to
     * @param response map of collaboration request fields returned from TSANet
     */
    public static void createCaseFeedItem(ID caseId, Map<String, Object> response){
        if (caseId == null) {
            return;
        }

        Case[] accessibleCases = new Case[]{};
        
        if (Schema.sObjectType.Case.isAccessible()) {
            accessibleCases = [
                SELECT Id
                FROM Case
                WHERE Id = :caseId
                WITH USER_MODE
                LIMIT 1
            ];
        }
        if (accessibleCases.isEmpty()) {
            return;
        }

        Map<String, Object> submittedByMap = (Map<String, Object>) response.get('submittedBy');
        String submitCompanyName = (String) response.get('submitCompanyName');
        String receiveCompanyName = (String) response.get('receiveCompanyName');
        String submitterCaseNumber = (String) response.get('submitterCaseNumber');
        String summary = (String) response.get('summary');
        String description = (String) response.get('description');
        String priority = (String) response.get('priority');
        String status = (String) response.get('status');
        DateTime createdAt = (DateTime) Json.deserialize('"'+response.get('createdAt')+'"', DateTime.class);
        String firstName = (String) submittedByMap.get('firstName');
        String lastName = (String) submittedByMap.get('lastName');
        String email = (String) submittedByMap.get('email');
        String phone = (String) submittedByMap.get('phone');
        String phoneCountryCode = (String) submittedByMap.get('phoneCountryCode');
        String priorityNote = (String) response.get('priorityNote');
        String city = (String) submittedByMap.get('city');

        priorityNote = TSANetHelper.stripHtmlTags(priorityNote);

        String message = 'Your collaboration request to ' + receiveCompanyName + ' for ' + submitCompanyName + ' Case# ' + submitterCaseNumber + ' has been sent. ' + priorityNote + '. \n' +
            '\n' +
            'Request Details: \n' +
            'Summary: ' + summary + ' \n' +
            'Description: ' + description + ' \n' +
            'Priority: ' + priority + ' \n' +
            'Status: ' + status + ' \n' +
            'Created At: ' + createdAt + ' \n' +
            'First Name: ' + firstName + ' \n' +
            'Last Name: ' + lastName + ' \n' +
            'Email: ' + email + ' \n' +
            'Phone: ' + phone + ' \n' +
            'Phone Country Code: ' + phoneCountryCode + ' \n' +
            'City: ' + city + ' \n';

        if (caseId.getSobjectType().getDescribe().isAccessible()) {
            FeedItem caseFeedItem = new FeedItem(
                ParentId = caseId,
                Title = 'TSANet FeedItem',
                Body = message
            );
            if (Schema.sObjectType.FeedItem.isCreateable()
                && Schema.sObjectType.FeedItem.fields.ParentId.isCreateable()
                && Schema.sObjectType.FeedItem.fields.Title.isCreateable()
                && Schema.sObjectType.FeedItem.fields.Body.isCreateable()
                && Schema.sObjectType.Case.isAccessible()
                && Schema.sObjectType.Case.isCreateable()) {
                Case[] parentCase = [
                    SELECT Id
                    FROM Case
                    WHERE Id = :caseFeedItem.ParentId
                    WITH USER_MODE
                    LIMIT 1
                ];
                if (!parentCase.isEmpty()) {
                    Database.insert(caseFeedItem, AccessLevel.USER_MODE);
                }
            }
        }
    }
}