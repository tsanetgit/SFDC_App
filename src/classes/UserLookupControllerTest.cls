@IsTest
private class UserLookupControllerTest {
    @TestSetup
    static void setupData(){
        List<User> us = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        // Створимо кількох активних
        for (Integer i=0; i<3; i++) {
            User u = new User(
                Alias = 'tst' + i,
                Email = 'test'+i+'@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Tester' + i,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'unique'+i+'@example.com',
                ProfileId = p.Id
            );
            us.add(u);
        }
        insert us;
    }

    @IsTest
    static void testSearchBasic(){
        Test.startTest();
        List<UserLookupController.UserDTO> res = UserLookupController.searchUsers('test', 10);
        Test.stopTest();

        System.assertNotEquals(0, res.size(), 'Should find test users');
        System.assertNotEquals(null, res[0].id);
        // Обмеження ліміту
        List<UserLookupController.UserDTO> res2 = UserLookupController.searchUsers(null, 1);
        System.assertEquals(1, res2.size(), 'Respects limit');
    }

    @IsTest
    static void testSecurityAccessible(){
        // Просто виклик перевіряє, що метод не падає на FLS
        Test.startTest();
        List<UserLookupController.UserDTO> res = UserLookupController.searchUsers('nonexistent', 10);
        Test.stopTest();
        System.assertEquals(0, res.size());
    }
}