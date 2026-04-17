declare module "@salesforce/apex/UserLookupController.searchUsers" {
  export default function searchUsers(param: {searchTerm: any, limitSize: any}): Promise<any>;
}
declare module "@salesforce/apex/UserLookupController.getUserById" {
  export default function getUserById(param: {userId: any}): Promise<any>;
}
