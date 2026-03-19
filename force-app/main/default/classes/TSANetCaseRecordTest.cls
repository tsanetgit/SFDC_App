@IsTest
public class TSANetCaseRecordTest {

    @IsTest
    static void testParseOne() {
        // Arrange
        String json = JSON.serialize(new Map<String, Object>{
            'id' => 1,
            'submitCompanyName' => 'Test Company',
            'submitCompanyId' => 100,
            'summary' => 'Test summary',
            'description' => 'Test description',
            'status' => 'Open',
            'submittedBy' => new Map<String, Object>{
                'id' => 10,
                'firstName' => 'John',
                'lastName' => 'Doe',
                'email' => 'john.doe@test.com'
            },
            'customFields' => new List<Object>{
                new Map<String, Object>{
                    'id' => 5,
                    'fieldName' => 'Environment',
                    'value' => 'Production'
                }
            }
        });

        // Act
        TSANetCaseRecord record = TSANetCaseRecord.parseOne(json);

        // Assert
        System.assertNotEquals(null, record);
        System.assertEquals(1, record.id);
        System.assertEquals('Test Company', record.submitCompanyName);
        System.assertEquals('Open', record.status);

        System.assertNotEquals(null, record.submittedBy);
        System.assertEquals('John', record.submittedBy.firstName);

        System.assertEquals(1, record.customFields.size());
        System.assertEquals('Environment', record.customFields[0].fieldName);
    }

    @IsTest
    static void testParseList() {
        // Arrange
        String json = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'id' => 1,
                'summary' => 'Case 1',
                'status' => 'Open'
            },
            new Map<String, Object>{
                'id' => 2,
                'summary' => 'Case 2',
                'status' => 'Closed'
            }
        });

        // Act
        TSANetCaseRecord[] records = TSANetCaseRecord.parse(json);

        // Assert
        System.assertEquals(2, records.size());
        System.assertEquals(1, records[0].id);
        System.assertEquals('Closed', records[1].status);
    }
}