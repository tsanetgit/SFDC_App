/** Shared multipart body building and file linking for TSANet attachment uploads. */
public with sharing class AttachmentUploadHelper {

    private static final String LINE_BREAK = '\r\n';

    /** Multipart body plus the per-request boundary used to build it. */
    public class MultipartPayload {
        /** RFC 2046 boundary unique to this request. */
        public String boundary;
        /** Full multipart/form-data body. */
        public String body;
    }

    /** True when the running user can create the records needed to store uploaded files. */
    public static Boolean canUpload(){
        return Schema.sObjectType.ContentVersion.isCreateable()
            && Schema.sObjectType.ContentDocumentLink.isCreateable();
    }

    /**
     * Resolves the base64 content of files that were passed by ContentVersion Id.
     * @param files raw file-data maps from the client (base64 or fileId)
     * @return file-data maps that all carry a filename and base64 content
     */
    public static List<Map<String, Object>> prepareFiles(List<Map<String, Object>> files){
        Id[] contentVersionIds = new Id[]{};
        for(Map<String, Object> fileData : files){
            if(fileData.get('base64') == NULL){
                contentVersionIds.add((String) fileData.get('fileId'));
            }
        }

        ContentVersion[] selectedContentVersions = [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE Id IN:contentVersionIds WITH USER_MODE ];

        List<Map<String, Object>> newFiles = new List<Map<String, Object>>();
        for(Map<String, Object> fileData : files){
            String base64String = (String) fileData.get('base64');
            if(base64String == NULL){
                String fileId = (String) fileData.get('fileId');
                for(ContentVersion cv : selectedContentVersions){
                    if(cv.Id == fileId){
                        Map<String, Object> newFileData = new Map<String, Object>();
                        newFileData.put('fileId', fileId);
                        newFileData.put('filename', cv.Title);
                        newFileData.put('base64', EncodingUtil.base64Encode(cv.VersionData));
                        newFileData.put('isCV', true);
                        newFiles.add(newFileData);
                    }
                }
            } else {
                newFiles.add(fileData);
            }
        }

        return newFiles;
    }

    /**
     * Builds a multipart/form-data body with a cryptographically random boundary.
     * @param newFiles prepared file-data maps
     * @return body and the boundary that must be set on Content-Type
     */
    public static MultipartPayload buildBody(List<Map<String, Object>> newFiles){
        MultipartPayload payload = new MultipartPayload();
        payload.boundary = newBoundary();

        String body = '';
        body += '--' + payload.boundary + LINE_BREAK;
        body += 'Content-Disposition: form-data; name="description"' + LINE_BREAK + LINE_BREAK;
        body += '' + LINE_BREAK;

        for(Map<String, Object> fileData : newFiles){
            String base64String = (String) fileData.get('base64');
            String fileName = (String) fileData.get('filename');

            body += '--' + payload.boundary + LINE_BREAK;
            body += 'Content-Disposition: form-data; name="files"; filename="' + fileName + '"' + LINE_BREAK;
            body += 'Content-Type: multipart/form-data' + LINE_BREAK + LINE_BREAK;
            body += EncodingUtil.base64Decode(base64String) + LINE_BREAK;
        }

        body += '--' + payload.boundary + '--' + LINE_BREAK;
        payload.body = body;
        return payload;
    }

    /** 32-char hex boundary from a 128-bit AES key; unique per call. */
    private static String newBoundary(){
        return EncodingUtil.convertToHex(Crypto.generateAesKey(128));
    }

    /**
     * Stores successfully uploaded files as ContentVersions and links them to the TSANet case.
     * Files that already existed as ContentVersions are skipped.
     * @param responseBody the upload API response body
     * @param newFiles prepared file-data maps that were uploaded
     * @param tsaNetCaseId the TSANetCase__c record to link the files to
     */
    public static void linkFiles(String responseBody, List<Map<String, Object>> newFiles, Id tsaNetCaseId){
        TSANetFileUploadResult[] results = TSANetFileUploadResult.parse(responseBody);

        ContentVersion[] versions = new ContentVersion[]{};
        for(Map<String, Object> fileData : newFiles){
            String fileName = (String) fileData.get('filename');
            String base64String = (String) fileData.get('base64');
            Boolean isCV = (Boolean) fileData.get('isCV');
            if(isCV == NULL || !isCV){
                for(TSANetFileUploadResult result : results){
                    if(result.receiverStatus == TSANetConstants.UPLOAD_STATUS_SUCCESS && result.fileName == fileName){
                        ContentVersion cv = new ContentVersion();
                        cv.Title = fileName;
                        cv.PathOnClient = fileName;
                        cv.VersionData = EncodingUtil.base64Decode(base64String);
                        versions.add(cv);
                    }
                }
            }
        }
        Database.insert(versions, AccessLevel.USER_MODE);

        Id[] versionIds = new Id[]{};
        for(ContentVersion version : versions){
            versionIds.add(version.Id);
        }

        ContentVersion[] contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:versionIds WITH USER_MODE ];

        ContentDocumentLink[] links = new ContentDocumentLink[]{};
        for(ContentVersion cv : contentVersions){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = tsaNetCaseId;
            cdl.ShareType = TSANetConstants.SHARE_TYPE_VIEWER;
            cdl.Visibility = TSANetConstants.VISIBILITY_ALL;
            links.add(cdl);
        }

        if (Schema.sObjectType.ContentDocumentLink.isCreateable()
            && Schema.sObjectType.ContentDocumentLink.fields.LinkedEntityId.isCreateable()
            && Schema.sObjectType.tsanetconnect__TSANetCase__c.isAccessible()
            && Schema.sObjectType.tsanetconnect__TSANetCase__c.isCreateable()) {
            tsanetconnect__TSANetCase__c[] parentCases = [
                SELECT Id
                FROM tsanetconnect__TSANetCase__c
                WHERE Id = :tsaNetCaseId
                WITH USER_MODE
                LIMIT 1
            ];
            if (!parentCases.isEmpty()) {
                Database.insert(links, AccessLevel.USER_MODE);
            }
        }
    }
}
