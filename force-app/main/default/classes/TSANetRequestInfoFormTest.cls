@IsTest
public class TSANetRequestInfoFormTest {

    @IsTest
    static void testTSANetRequestInfoFormProperties() {
        // Arrange
        TSANetRequestInfoForm form = new TSANetRequestInfoForm();
        form.engineerName = 'Jane Smith';
        form.engineerEmail = 'jane.smith@test.com';
        form.engineerPhone = '+380991234567';
        form.requestedInformation = 'Please provide additional logs and screenshots.';

        // Assert
        System.assertEquals('Jane Smith', form.engineerName);
        System.assertEquals('jane.smith@test.com', form.engineerEmail);
        System.assertEquals('+380991234567', form.engineerPhone);
        System.assertEquals(
            'Please provide additional logs and screenshots.',
            form.requestedInformation
        );
    }
}