@IsTest
public class TSANetAdditionalInfoFormTest {

    @IsTest
    static void testTSANetAdditionalInfoForm() {
        // Arrange
        TSANetAdditionalInfoForm form = new TSANetAdditionalInfoForm();
        form.requestedInformation = 'Please provide additional logs';

        // Act
        String value = form.requestedInformation;

        // Assert
        System.assertEquals(
            'Please provide additional logs',
            value,
            'Requested information should be set and returned correctly'
        );
    }
}