/** Unit tests for per-request multipart boundary generation. */
@IsTest
public class AttachmentUploadHelperTest {

    /** Two uploads must not share a boundary, and the body must use the returned value. */
    @IsTest
    static void buildBody_usesDistinctRandomBoundary(){
        List<Map<String, Object>> files = new List<Map<String, Object>>{
            new Map<String, Object>{
                'filename' => 'a.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('x'))
            }
        };

        AttachmentUploadHelper.MultipartPayload first = AttachmentUploadHelper.buildBody(files);
        AttachmentUploadHelper.MultipartPayload second = AttachmentUploadHelper.buildBody(files);

        System.assertNotEquals(null, first.boundary);
        System.assertNotEquals(first.boundary, second.boundary, 'Each upload must get a new boundary');
        System.assert(first.body.contains('--' + first.boundary), 'Body must use the generated boundary');
        System.assert(first.body.contains('--' + first.boundary + '--'), 'Closing delimiter must match');
        System.assert(!first.body.contains('EWG3x2i19rjSk310MA4YWxkTrZu0gW'));
    }
}
