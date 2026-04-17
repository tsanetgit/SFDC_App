/** Controller for the user-lookup LWC component. */
public with sharing class UserLookupController {

    /** Lightweight DTO exposing safe User fields to the client. */
    public class UserDTO {
        /** Salesforce User Id. */
        @AuraEnabled public Id     id;
        /** Full display name. */
        @AuraEnabled public String name;
        /** User email address. */
        @AuraEnabled public String email;
        /** User mobile phone number. */
        @AuraEnabled public String phone;
        /** User job title. */
        @AuraEnabled public String title;
        /** URL of the user's small profile photo. */
        @AuraEnabled public String smallPhotoUrl;
        /**
         * Constructs a UserDTO from a User record with FLS checks.
         * @param u the source User record
         */
        public UserDTO(User u){
            id = u.Id;
            name = u.Name;
            email = (Schema.sObjectType.User.fields.Email.isAccessible()) ? u.Email : null;
            phone = (Schema.sObjectType.User.fields.MobilePhone.isAccessible()) ? u.MobilePhone : null;
            title = (Schema.sObjectType.User.fields.Title.isAccessible()) ? u.Title : null;
            smallPhotoUrl = (Schema.sObjectType.User.fields.SmallPhotoUrl.isAccessible()) ? u.SmallPhotoUrl : null;
        }
    }

    /**
     * Searches active users by name or email with FLS enforcement.
     * @param searchTerm text to match against Name or Email
     * @param limitSize maximum number of results (capped at 50)
     * @return list of matching UserDTO records
     */
    @AuraEnabled(cacheable=true)
    public static List<UserDTO> searchUsers(String searchTerm, Integer limitSize){
        if (limitSize == null || limitSize <= 0 || limitSize > 50) {
            limitSize = 10;
        }
        String term = (searchTerm == null) ? '' : searchTerm.trim();

        if (!Schema.sObjectType.User.isAccessible()) {
            return new List<UserDTO>();
        }

        String searchText = String.isBlank(term) ? '%' : ('%' + term.replace('%','\\%').replace('_','\\_') + '%');

        List<User> raw = [
            SELECT Id, Name, Email, Title, SmallPhotoUrl, MobilePhone
            FROM User
            WHERE IsActive = true AND (Name LIKE :searchText OR Email LIKE :searchText)
            WITH SECURITY_ENFORCED
            ORDER BY LastName NULLS LAST, FirstName NULLS LAST
            LIMIT :limitSize
        ];

        SObjectAccessDecision sec = Security.stripInaccessible(
            AccessType.READABLE,
            raw
        );

        List<UserDTO> outp = new List<UserDTO>();
        for (User u : (List<User>)sec.getRecords()) {
            outp.add(new UserDTO(u));
        }
        return outp;
    }

    /**
     * Returns a single UserDTO by Salesforce User Id.
     * @param userId the User Id to look up
     * @return UserDTO or null if not accessible
     */
    @AuraEnabled(cacheable=true)
    public static UserDTO getUserById(Id userId){
        if (userId == null || !Schema.sObjectType.User.isAccessible()) {
            return null;
        }
        User u = [
            SELECT Id, Name, Email, Title, SmallPhotoUrl, MobilePhone
            FROM User
            WHERE Id = :userId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        SObjectAccessDecision sec = Security.stripInaccessible(AccessType.READABLE, new List<User>{ u });
        List<User> safe = (List<User>)sec.getRecords();
        return safe.isEmpty() ? null : new UserDTO(safe[0]);
    }
}