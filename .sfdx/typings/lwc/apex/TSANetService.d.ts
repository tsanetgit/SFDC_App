declare module "@salesforce/apex/TSANetService.createTSANetNote" {
  export default function createTSANetNote(param: {caseToken: any, json: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.getTSANetAccessToken" {
  export default function getTSANetAccessToken(): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.getRelatedCollaborationCases" {
  export default function getRelatedCollaborationCases(param: {caseId: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.getFormByCompanyId" {
  export default function getFormByCompanyId(param: {companyId: any, mode: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.getCompaniesByName" {
  export default function getCompaniesByName(param: {companyName: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.createCollaborationCase" {
  export default function createCollaborationCase(param: {caseId: any, json: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.approveIncomingRequest" {
  export default function approveIncomingRequest(param: {caseToken: any, json: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.rejectTSANetCase" {
  export default function rejectTSANetCase(param: {tsaNetCaseId: any, json: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.closeTSANetCase" {
  export default function closeTSANetCase(param: {tsaNetCaseId: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.requestAdditionalInformation" {
  export default function requestAdditionalInformation(param: {tsaNetCaseId: any, json: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.sendAdditionalInformation" {
  export default function sendAdditionalInformation(param: {tsaNetCaseId: any, json: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.getAttachmentConfig" {
  export default function getAttachmentConfig(param: {token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetService.sendAttachment" {
  export default function sendAttachment(param: {token: any, files: any}): Promise<any>;
}
