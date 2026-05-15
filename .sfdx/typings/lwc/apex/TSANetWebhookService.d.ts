declare module "@salesforce/apex/TSANetWebhookService.registerWebhook" {
  export default function registerWebhook(param: {callbackUrl: any, eventTypes: any, token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetWebhookService.getWebhooks" {
  export default function getWebhooks(param: {token: any}): Promise<any>;
}
declare module "@salesforce/apex/TSANetWebhookService.getDeliveryLog" {
  export default function getDeliveryLog(param: {webhookId: any, token: any}): Promise<any>;
}
