@IsTest
public class TSANetRejectFormTest {

    @IsTest
    static void testTSANetRejectFormProperties() {
        // Arrange
        TSANetRejectForm form = new TSANetRejectForm();
        form.engineerName  = 'John Doe';
        form.engineerEmail = 'john.doe@test.com';
        form.engineerPhone = '+123456789';
        form.reason        = 'Not enough information provided';

        // Assert
        System.assertEquals('John Doe', form.engineerName);
        System.assertEquals('john.doe@test.com', form.engineerEmail);
        System.assertEquals('+123456789', form.engineerPhone);
        System.assertEquals('Not enough information provided', form.reason);
    }
}