declare module "@salesforce/apex/ErrorLogger.logUIError" {
  export default function logUIError(param: {ex: any, context: any, relations: any}): Promise<any>;
}
