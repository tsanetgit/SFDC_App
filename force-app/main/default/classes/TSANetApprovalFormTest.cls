@IsTest
public class TSANetApprovalFormTest {

    @IsTest
    static void testTSANetApprovalForm() {
        // Arrange
        TSANetApprovalForm form = new TSANetApprovalForm();
        form.caseNumber = 'CASE-12345';
        form.engineerName = 'John Doe';
        form.engineerEmail = 'john.doe@test.com';
        form.engineerPhone = '+123456789';
        form.nextSteps = 'Proceed with approval';

        // Assert
        System.assertEquals('CASE-12345', form.caseNumber);
        System.assertEquals('John Doe', form.engineerName);
        System.assertEquals('john.doe@test.com', form.engineerEmail);
        System.assertEquals('+123456789', form.engineerPhone);
        System.assertEquals('Proceed with approval', form.nextSteps);
    }
}