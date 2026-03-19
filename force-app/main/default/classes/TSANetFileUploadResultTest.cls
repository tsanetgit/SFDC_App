@IsTest
public class TSANetFileUploadResultTest {

    @IsTest
    static void testParse() {
        // Arrange
        String json = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'fileName' => 'test1.pdf',
                'receiverStatus' => 'SUCCESS',
                'receiverMessage' => 'Received',
                'submitterStatus' => 'SUCCESS',
                'submitterMessage' => 'Uploaded',
                'completeSuccess' => true,
                'partialSuccess' => false
            },
            new Map<String, Object>{
                'fileName' => 'test2.pdf',
                'receiverStatus' => 'FAILED',
                'receiverMessage' => 'Invalid format',
                'submitterStatus' => 'SUCCESS',
                'submitterMessage' => 'Uploaded',
                'completeSuccess' => false,
                'partialSuccess' => true
            }
        });

        // Act
        List<TSANetFileUploadResult> results = TSANetFileUploadResult.parse(json);

        // Assert
        System.assertEquals(2, results.size());

        System.assertEquals('test1.pdf', results[0].fileName);
        System.assertEquals(true, results[0].completeSuccess);

        System.assertEquals('FAILED', results[1].receiverStatus);
        System.assertEquals(true, results[1].partialSuccess);
    }
}