public with sharing class UserLookupController {
    
    public class UserDTO {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String title;
        @AuraEnabled public String smallPhotoUrl;
        public UserDTO(User u){
            id = u.Id;
            name = u.Name;
            email = (Schema.sObjectType.User.fields.Email.isAccessible()) ? u.Email : null;
            phone = (Schema.sObjectType.User.fields.MobilePhone.isAccessible()) ? u.MobilePhone : null;
            title = (Schema.sObjectType.User.fields.Title.isAccessible()) ? u.Title : null;
            smallPhotoUrl = (Schema.sObjectType.User.fields.SmallPhotoUrl.isAccessible()) ? u.SmallPhotoUrl : null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<UserDTO> searchUsers(String searchTerm, Integer limitSize){
        if (limitSize == null || limitSize <= 0 || limitSize > 50) limitSize = 10;
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
    
    @AuraEnabled(cacheable=true)
    public static UserDTO getUserById(Id userId){
        if (userId == null || !Schema.sObjectType.User.isAccessible()) return null;
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