@IsTest
public class TSANetSubmittedByTest {

    @IsTest
    static void testTSANetSubmittedBy() {
        // Arrange
        TSANetSubmittedBy submittedBy = new TSANetSubmittedBy();
        submittedBy.firstName = 'John';
        submittedBy.lastName = 'Smith';

        // Assert
        System.assertEquals('John', submittedBy.firstName);
        System.assertEquals('Smith', submittedBy.lastName);
    }
}