/**
 * TSANet API path constants.
 *
 * Paths are relative: the base URL comes from the Named Credential callout, which
 * TSANetAPIService and TSANetWebhookService prepend. The {token} placeholder is the
 * TSANet-issued collaboration request identifier, not a Salesforce field.
 */
public with sharing class EndpointManager {

    /**
     * Collaboration requests API path. Still V1: only the read endpoints moved to V2,
     * while case creation and the attachment sub-resources remain on this path.
     */
    public static String case_path = '/v1/collaboration-requests';
    /** Collaboration requests list API path (V2), returns a plain JSON array. */
    public static String cases_list_path = '/v2/collaboration-requests/list';
    /** Collaboration requests paginated API path (V2), returns a PagedResponse. */
    public static String cases_paged_path = '/v2/collaboration-requests';
    /** Partners search API path. */
    public static String companies_path = '/v1/partners/';
    /** Company-level form API path. */
    public static String get_form_company_path = '/v1/forms/company/';
    /** Department-level form API path. */
    public static String get_form_department_path = '/v1/forms/department/';
    /** Approval endpoint template. */
    public static String approve = '/v1/collaboration-requests/{token}/approval';
    /** Rejection endpoint template. */
    public static String reject = '/v1/collaboration-requests/{token}/rejection';
    /** Update collaboration request endpoint template. */
    public static String updateCase = '/v1/collaboration-requests/{token}';
    /** Information request endpoint template. */
    public static String informationRequest = '/v1/collaboration-requests/{token}/information-request';
    /** Information response endpoint template. */
    public static String informationResponse = '/v1/collaboration-requests/{token}/information-response';
    /** Closure endpoint template. */
    public static String close = '/v1/collaboration-requests/{token}/closure';
    /** Notes endpoint template. */
    public static String notes = '/v1/collaboration-requests/{token}/notes';
    /** Current user info API path. */
    public static String me_path = '/v1/me';
    /** Webhook subscriptions API path (V2 CloudEvents). */
    public static String webhooks_path = '/v2/webhooks';
    /** Webhook by ID template. */
    public static String webhook_by_id = '/v1/webhooks/{id}';
    /** Webhook delivery log template. */
    public static String webhook_deliveries = '/v1/webhooks/{id}/deliveries';
}
