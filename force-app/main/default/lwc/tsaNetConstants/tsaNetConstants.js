import CASE_SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';

import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';
import USER_LAST_NAME_FIELD from '@salesforce/schema/User.LastName';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import USER_PHONE_FIELD from '@salesforce/schema/User.Phone';
import USER_MOBILE_PHONE_FIELD from '@salesforce/schema/User.MobilePhone';

import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_PHONE_FIELD from '@salesforce/schema/Contact.Phone';

export {
  CASE_NUMBER_FIELD,
  CASE_SUBJECT_FIELD,
  USER_NAME_FIELD,
  USER_FIRST_NAME_FIELD,
  USER_LAST_NAME_FIELD,
  USER_EMAIL_FIELD,
  USER_PHONE_FIELD,
  USER_MOBILE_PHONE_FIELD,

  ACCOUNT_NAME_FIELD,

  CONTACT_NAME_FIELD,
  CONTACT_EMAIL_FIELD,
  CONTACT_PHONE_FIELD
}

export const FORM_FIELDS = Object.freeze({
  PROBLEM_SUMMARY: 'problemSummary',
  PROBLEM_DESCRIPTION: 'problemDescription',
  PRIORITY: 'priority',
  INTERNAL_CASE_NUMBER: 'internalCaseNumber',
  RECEIVER_INTERNAL_CASE_NUMBER: 'receiverInternalCaseNumber',
  SUBMITTER_CONTACT_DETAILS: 'submitterContactDetails',
  CUSTOM_FIELDS: 'customFields',
  CUSTOMER_COMPANY: 'Customer Company',
  CUSTOMER_NAME: 'Customer Name',
  CUSTOMER_EMAIL: 'Customer Email',
  CUSTOMER_PHONE_INCLUDING_COUNTRY_CODE: 'Customer Phone Including Country Code',

  ADMIN_NOTE: 'adminNote',
  ESCALATION_INSTRUCTIONS: 'escalationInstructions'

});

export const SKIP_FORM_FIELDS = new Set([FORM_FIELDS.ADMIN_NOTE, FORM_FIELDS.ESCALATION_INSTRUCTIONS]);


export const ACTIONS = Object.freeze({
  ACCEPT: 'ACCEPT',
  CREATE_NOTE: 'CREATE_NOTE',
  REJECT: 'REJECT',
  CLOSE: 'CLOSE',
  REQUEST_INFO: 'REQUEST_INFO',
  SEND_INFO: 'SEND_INFO',
  SEND_ATTACHMENT: 'SEND_ATTACHMENT'
});

export const ACTION_CONFIG = Object.freeze({
  [ACTIONS.ACCEPT]: {
    header: 'Accept Collaboration Request',
    submitVariant: 'success',
    submitButtonLabel: 'Accept',
    requestParam: 'nextSteps',
    requestParamLabel: 'Next Steps',
    resultMessage: 'The collaboration request has been accepted successfully'
  },
  [ACTIONS.CREATE_NOTE]: {
    header: 'Create New Note',
    submitVariant: 'brand',
    submitButtonLabel: 'Create Note',
    resultMessage: 'The note has been created successfully'
  },
  [ACTIONS.REJECT]: {
    header: 'Reject Collaboration Request',
    submitVariant: 'destructive-text',
    closeVariant: 'brand',
    submitButtonLabel: 'Reject',
    requestParam: 'reason',
    requestParamLabel: 'Reason',
    resultMessage: 'The collaboration request has been rejected successfully'
  },
  [ACTIONS.CLOSE]: {
    header: 'Close Collaboration Request',
    submitVariant: 'destructive-text',
    submitButtonLabel: 'Close',
    resultMessage: 'The collaboration request has been closed successfully'
  },
  [ACTIONS.REQUEST_INFO]: {
    header: 'Additional Information Request',
    submitVariant: 'brand',
    submitButtonLabel: 'Request',
    requestParam: 'requestedInformation',
    requestParamLabel: 'Requested Information',
    resultMessage: 'The request for additional information has been sent successfully'
  },
  [ACTIONS.SEND_INFO]: {
    header: 'Send Additional Information',
    submitVariant: 'brand',
    submitButtonLabel: 'Send Information',
    requestParam: 'requestedInformation',
    requestParamLabel: 'Additional Information',
    resultMessage: 'The additional information has been sent successfully'
  },
  [ACTIONS.SEND_ATTACHMENT]: {
    header: 'Send Attachment',
    submitVariant: 'brand',
    submitButtonLabel: 'Send Attachment',
    resultMessage: 'The attachment has been sent successfully'
  }
});

export const NOTE_STATE = {
    summary: '',
    description: '',
    priority: 'MEDIUM',
    submittedBy: {
        firstName: '',
        lastName: ''
    }
}

// Modal END

export const TSANET_EXCEPTION_TYPES = {
    SEARCH_TSANET_COMPANIES: 'SEARCH_TSANET_COMPANIES'
}

export const TSANET_CASE_STATUSES = {
    ACCEPTED: 'ACCEPTED',
    OPEN: 'OPEN',
    INFORMATION: 'INFORMATION',
    CLOSED: 'CLOSED',
    REJECTED: 'REJECTED',
}

export const TSANET_DIRECTION = {
    INBOUND: 'INBOUND',
    OUTBOUND: 'OUTBOUND'
}

export const TSANET_CASE_STATUS_STYLE = {
    'ACCEPTED': 'slds-theme_success',
    'OPEN': 'slds-theme_success',
    'INFORMATION': 'slds-theme_warning',
    'CLOSED': 'slds-theme_error',
    'REJECTED': 'slds-theme_error',
}

export const TSANET_CASE_PRIORITIES = {
    LOW: 'LOW',
    MEDIUM: 'MEDIUM',
    HIGH: 'HIGH'
}

export const TSANET_CASE_PRIORITY_STYLE = {
    'LOW': 'slds-theme_info',
    'MEDIUM': 'slds-theme_warning',
    'HIGH': 'slds-theme_error'
}

// Standard system note types, keyed by their normalized (lowercased, trimmed) Summary.
// Used to render system notes as compact status rows instead of chat bubbles.
export const STANDARD_NOTE_CONFIG = Object.freeze({
  'case created': { label: 'Case Created', icon: 'utility:new', theme: 'slds-theme_success' },
  'case accepted': { label: 'Case Accepted', icon: 'utility:success', theme: 'slds-theme_success' },
  'case rejected': { label: 'Case Rejected', icon: 'utility:error', theme: 'slds-theme_error' }
})

// Returns the standard-note config for a summary, or undefined for a regular note.
export const getStandardNoteConfig = (summary) => {
  if(!summary){ return undefined }
  return STANDARD_NOTE_CONFIG[summary.trim().toLowerCase()]
}

export const TYPING_INTERVAL = 300

// Toolbar formats for note editors: bold, italic, underline, strikethrough, lists, and link.
export const RICH_TEXT_FORMATS = Object.freeze(['bold', 'italic', 'underline', 'strike', 'list', 'link'])

export const PRIORITY_OPTIONS = [
    { label: 'Low', value: TSANET_CASE_PRIORITIES.LOW },
    { label: 'Medium', value: TSANET_CASE_PRIORITIES.MEDIUM },
    { label: 'High', value: TSANET_CASE_PRIORITIES.HIGH },
]

export const TSANET_NOTE_TYPES = Object.freeze({
    USER_PUBLIC: 'USER_PUBLIC',
    USER_PARTNER: 'USER_PARTNER'
})

// Note type options for the Create Note form; empty value means the type is omitted from the request.
export const NOTE_TYPE_OPTIONS = [
    { label: 'None', value: '' },
    { label: 'User Public', value: TSANET_NOTE_TYPES.USER_PUBLIC },
    { label: 'User Partner', value: TSANET_NOTE_TYPES.USER_PARTNER },
]
export const TOAST_MODE = Object.freeze({
  SUCCESS : 'success',
  WARNING : 'warning',
  ERROR : 'error'
})

export const WARNING_LABEL = 'Warning!'
export const REQUIRED_FIELDS_WARNING = 'Please fill out all required fields! '
export const YOU_ARE_NOT_ABLE_TO_INTERACT_WITH_THE_REFERENCED_COMPANY = 'You are not able to interact with the referenced company.';

export const CONTACT_REQUIRED_WARNING = 'The Contact field on the Case is required'
export const ACCOUNT_REQUIRED_WARNING = 'The Account field on the Case is required'

export const SKIP_FORM_CUSTOM_FIELDS = ['Customer Company', 'Customer Name', 'Customer Email', 'Customer Phone Including Country Code']