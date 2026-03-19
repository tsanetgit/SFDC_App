@isTest
public class TSANetUserTest {

    @isTest
    public static void TSANetUserParseTest(){
        String json = '{ "id": 8705, "username": null, "firstName": "John", "lastName": "Smith", "email": "John.Smith@cisco.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }';
        TSANetUser user = (TSANetUser) System.JSON.deserialize(json, TSANetUser.class);
        System.assertEquals(true, 
                            user.id == 8705 && 
                            user.username == null && 
                            user.firstName == 'John' && 
                            user.lastName == 'Smith' && 
                            user.email == 'John.Smith@cisco.com' && 
                            user.phone == '4155551212' && 
                            user.phoneCountryCode == 'US' && 
                            user.city == 'Baton Rouge' 
                           );
    }
    
}