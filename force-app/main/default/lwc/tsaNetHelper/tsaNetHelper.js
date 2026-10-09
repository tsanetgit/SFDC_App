import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import {
    TSANET_DIRECTION,
    SKIP_FORM_CUSTOM_FIELDS,
    TSANET_CASE_STATUSES,
    TSANET_CASE_STATUS_STYLE,
    TSANET_CASE_PRIORITY_STYLE,
    ACTION_CONFIG,
    getStandardNoteConfig
} from 'c/tsaNetConstants'

import getCaseInformation from '@salesforce/apex/TSANetUtils.getCaseInformation'
import getCompaniesByName from '@salesforce/apex/TSANetService.getCompaniesByName'

import createCollaborationCase from '@salesforce/apex/TSANetService.createCollaborationCase'
import getAccessToken from '@salesforce/apex/AuthManager.updateAccessToken'

import approveIncomingRequest from '@salesforce/apex/TSANetService.approveIncomingRequest'
import rejectTSANetCase from '@salesforce/apex/TSANetService.rejectTSANetCase'
import requestAdditionalInformation from '@salesforce/apex/TSANetService.requestAdditionalInformation'
import sendAdditionalInformation from '@salesforce/apex/TSANetService.sendAdditionalInformation'

import closeTSANetCase from '@salesforce/apex/TSANetService.closeTSANetCase'

import getFormByCompanyId from '@salesforce/apex/TSANetService.getFormByCompanyId'

import getTSANetCases from '@salesforce/apex/TSANetUtils.getTSANetCases'

import createCaseNote from '@salesforce/apex/TSANetService.createTSANetNote'

import logUIError from '@salesforce/apex/ErrorLogger.logUIError'

export const getNewAccessToken = () => {
    return new Promise((resolve, reject) => {
        getAccessToken()
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const getRelatedTSANetCases = (caseId) => {
    return new Promise((resolve, reject) => {
        getTSANetCases({ caseId })
            .then(response => resolve(response))
            .catch(error => reject(error))
    })
}

export const getCaseInfo = (caseId) => {
    return new Promise((resolve, reject) => {
        getCaseInformation({ caseId })
        .then(data => resolve(prepareCaseData(data)))
        .catch(error => reject(error))
    })
}

const prepareCaseData = (data) => {
    data.caseRecord['link'] = '/' + data.caseRecord.Id

    const caseSubject = data?.caseRecord?.Subject

    data?.relatedCases?.forEach(relatedCase => {
        relatedCase['link'] = '/' + relatedCase.Id
        relatedCase['caseLink'] = '/' + relatedCase.tsanetconnect__Case__c
        relatedCase['actionCss'] = relatedCase?.tsanetconnect__Status__c == TSANET_CASE_STATUSES.ACCEPTED || relatedCase?.tsanetconnect__Direction__c == TSANET_DIRECTION.OUTBOUND ? 'slds-hide' : ''
        relatedCase['internalCaseNumber'] = '/' + relatedCase.Id

        relatedCase.isNoteable = ( relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.ACCEPTED || relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.INFORMATION )
        relatedCase.isAcceptable = ( relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.OPEN || relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.INFORMATION ) && relatedCase.tsanetconnect__Direction__c == TSANET_DIRECTION.INBOUND
        relatedCase.isRejectable = ( relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.OPEN || relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.INFORMATION ) && relatedCase.tsanetconnect__Direction__c == TSANET_DIRECTION.INBOUND
        relatedCase.isRequestable = ( relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.OPEN && relatedCase.tsanetconnect__Direction__c == TSANET_DIRECTION.INBOUND )
        relatedCase.isCloseable = ( relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.ACCEPTED && relatedCase.tsanetconnect__Direction__c == TSANET_DIRECTION.OUTBOUND )
        relatedCase.isResponseable = ( relatedCase.tsanetconnect__Status__c == TSANET_CASE_STATUSES.INFORMATION && relatedCase.tsanetconnect__Direction__c == TSANET_DIRECTION.OUTBOUND )

        relatedCase.isAttachmentable = relatedCase.tsanetconnect__receivedCompanyName__c.includes('Cisco')

        relatedCase.statusStyle = TSANET_CASE_STATUS_STYLE[relatedCase.tsanetconnect__Status__c]
        relatedCase.priorityStyle = TSANET_CASE_PRIORITY_STYLE[relatedCase.tsanetconnect__Priority__c]

        // Precompute badge class strings so card and table views render identical badges.
        relatedCase.priorityBadgeClass = `card-pill ${relatedCase.priorityStyle}`
        relatedCase.statusBadgeClass = `slds-badge_inverse card-pill ${relatedCase.statusStyle}`

        // Precompute the escalation helptext so card and table views share one source.
        const escalation = relatedCase.tsanetconnect__EscalationInstructions__c?.replace(/<[^>]*>/g, '') || ''
        relatedCase.escalationText = `${relatedCase.tsanetconnect__Direction__c} - ${escalation}`

        // Parse custom fields once into readable groups for the details popover.
        relatedCase.customFieldGroups = parseCustomFields(relatedCase.tsanetconnect__customFields__c)

        // Build the conversation/chat view model for the notes panel.
        relatedCase.notes = mapNotes(relatedCase, caseSubject)
        relatedCase.notesCount = relatedCase.notes.length

        relatedCase.isHideAction = ( relatedCase.isNoteable || relatedCase.isRejectable || relatedCase.isRequestable || relatedCase.isCloseable )

        if(relatedCase?.tsanetconnect__TSANetResponses__r && relatedCase?.tsanetconnect__TSANetResponses__r.length){
            relatedCase['agentEmail'] = relatedCase?.tsanetconnect__TSANetResponses__r[0]?.tsanetconnect__EngineerEmail__c
        }
    })

    return data
}

// Maps a related case's child notes into a chat view model for the notes panel.
// Standard system notes (Case Created/Accepted/Rejected) become compact status rows;
// the rest become conversation bubbles. Summary is hidden when it equals the Case Subject.
const mapNotes = (relatedCase, caseSubject) => {
    const rawNotes = relatedCase?.tsanetconnect__TSANetNotes__r || []

    // Our company is the submitter on outbound cases and the receiver on inbound ones.
    // Our (outbound) notes always render on the left; the partner's render on the right.
    const ownCompany = relatedCase?.tsanetconnect__Direction__c === TSANET_DIRECTION.OUTBOUND
        ? relatedCase?.tsanetconnect__SubmittedCompanyName__c
        : relatedCase?.tsanetconnect__receivedCompanyName__c

    return rawNotes.map(note => {
        const summary = note?.tsanetconnect__Summary__c
        const standardConfig = getStandardNoteConfig(summary)

        // Hide the summary line when it just repeats the Case Subject.
        const showSummary = !!summary && normalize(summary) !== normalize(caseSubject)
        const sender = note?.tsanetconnect__CreatorName__c

        const isOwn = !!ownCompany && note?.tsanetconnect__CompanyName__c === ownCompany

        return {
            key: note.Id,
            createdAt: note?.tsanetconnect__CreatedAt__c,
            sender,
            initials: getInitials(sender),
            companyName: note?.tsanetconnect__CompanyName__c,
            summary,
            showSummary,
            description: note?.tsanetconnect__Description__c,
            isStandard: !!standardConfig,
            standardLabel: standardConfig?.label || summary,
            standardIcon: standardConfig?.icon,
            standardThemeClass: `note-system__pill ${standardConfig?.theme || ''}`,
            alignRight: !isOwn,
            rowClass: isOwn ? 'note-row note-row_inbound' : 'note-row note-row_outbound',
            bubbleClass: isOwn ? 'note-bubble note-bubble_inbound' : 'note-bubble note-bubble_outbound'
        }
    })
}

// Normalizes a string for case-insensitive comparison.
const normalize = (value) => (value || '').trim().toLowerCase()

// Derives up-to-two-letter initials from a name for the chat avatar.
const getInitials = (name) => {
    if(!name){ return '?' }
    const parts = name.trim().split(/\s+/)
    const first = parts[0]?.charAt(0) || ''
    const last = parts.length > 1 ? parts[parts.length - 1].charAt(0) : ''
    return (first + last).toUpperCase()
}

// Parses the stored customFields JSON into readable, ordered groups keyed by section.
const parseCustomFields = (raw) => {
    if(!raw){ return [] }

    let fields = []
    try {
        fields = JSON.parse(raw)
    } catch(e){
        return []
    }

    const withValues = (fields || [])
        .filter(f => f && f.value !== null && f.value !== undefined && String(f.value).trim() !== '')
        .sort((a, b) => (a.displayOrder ?? 0) - (b.displayOrder ?? 0))

    const groups = []
    withValues.forEach(f => {
        const section = f.section || 'Custom Fields'
        let group = groups.find(g => g.section === section)
        if(!group){
            group = { key: section, section, fields: [] }
            groups.push(group)
        }
        group.fields.push({
            key: `${section}:${f.fieldName}:${f.id}`,
            fieldName: f.fieldName,
            value: f.value
        })
    })

    return groups
}

export const getCompanies = (companyName) => {
    return new Promise((resolve, reject) => {
        getCompaniesByName({ companyName })
        .then(json => resolve(prepareCompaniesData(json)))
        .catch(error => reject(error))
    })
}

const prepareCompaniesData = (json) => {
    const companies = json && JSON.parse(json)

    companies.forEach(c => {
        c?.tags && c?.tags.length && c?.tags.forEach(tag => {
            c['companyTags'] += tag + ' ';
        })
    })

    return companies
}

export const createNewCollaborationCase = (caseId, json) => {
    return new Promise((resolve, reject) => {
        createCollaborationCase({ caseId, json })
        .then(response => {
            resolve(response)
        }).catch(error => reject(error))
    })
}

export const approveRequest = (token, json) => {
    return new Promise((resolve, reject) => {
        approveIncomingRequest({ caseToken: token, json })
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const rejectRequest = (tsaNetCaseId, json) => {
    return new Promise((resolve, reject) => {
        rejectTSANetCase({ tsaNetCaseId, json})
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const requestAdditionalInfo = (tsaNetCaseId, json) => {
    return new Promise((resolve, reject) => {
        requestAdditionalInformation({ tsaNetCaseId, json})
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const sendAdditionalInfo = (tsaNetCaseId, json) => {
    return new Promise((resolve, reject) => {
        sendAdditionalInformation({ tsaNetCaseId, json})
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const closeRequest = (tsaNetCaseId) => {
    return new Promise((resolve, reject) => {
        closeTSANetCase({ tsaNetCaseId })
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const getCompanyForm = (companyId, mode) => {
    return new Promise((resolve, reject) => {
        getFormByCompanyId({ companyId, mode })
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const createTSANetCaseNote = (caseId, json) => {
    return new Promise((resolve, reject) => {
        createCaseNote({ caseToken: caseId, json, token: undefined })
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const logError = (ex, context, relations) => {
    return new Promise((resolve, reject) => {
        logUIError({ ex, context, relations })
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const getCompanyId = (company) => {
    return company?.departmentId ? company?.departmentId : company?.companyId
}

export const getMode = (company) => {
    return company?.departmentId ? 'department' : 'company'
}

export const initializeForm = (form) => {
    form.customFields.forEach(field => {
        if(!SKIP_FORM_CUSTOM_FIELDS.includes(field.label)){

            field['isSelect'] = field?.type == 'SELECT'
            field['isTierSelect'] = field?.type == 'TIERSELECT'
            field['isString'] = field?.type == 'STRING'
            field['isEmail'] = field?.type == 'EMAIL'
            field['isPhone'] = field?.type == 'PHONE'

            if(field?.isSelect){
                const raw = field?.options ?? '';

                const normalized = raw
                .replace(/\r\n/g, '\n')
                .replace(/\\n/g, '\n');

                const options = normalized
                .split('\n')
                .map(v => v.trim())
                .filter(Boolean);

                field.values = options.map(o => ({ label: o, value: o }));
            }

            if(field?.isTierSelect){
                const values = field.selections
                const mappedValues = values.map(o => ({ label: o.value, value: o.value, children: o.children }))
                field['values'] = mappedValues
            }
        }
    })
    return form;
}

export const getSelectedCompany = (event, self) => {
    const { department, value } = event?.currentTarget?.dataset || {};

    const key = department ? 'departmentId' : 'companyId';
    const id  = department ?? value;

    const company = self.companies.find(
        c => String(c[key]) === String(id)
    );
    return company;
}

export const getActionHeader = (action) => ACTION_CONFIG[action]?.header ?? '';
export const getActionSubmitVariant = (action) => ACTION_CONFIG[action]?.submitVariant ?? 'brand';
export const getActionCloseVariant = (action) => ACTION_CONFIG[action]?.closeVariant ?? 'destructive-text';
export const getActionSubmitButtonLabel = (action) => ACTION_CONFIG[action]?.submitButtonLabel ?? 'Send';
export const getActionRequestParam = (action) => ACTION_CONFIG[action]?.requestParam ?? '';
export const getActionRequestParamLabel = (action) => ACTION_CONFIG[action]?.requestParamLabel ?? '';
export const getActionResultMessage = (action) => ACTION_CONFIG[action]?.resultMessage ?? '';


// Strips HTML tags/entities so empty rich text (<p></p>, &nbsp;) is treated as blank.
export const stripRichText = (html) => {
    return (html || '')
        .replace(/<[^>]*>/g, '')
        .replace(/&nbsp;/g, ' ')
        .trim()
}

export const isRichTextEmpty = (html) => !stripRichText(html)

export const toast = (self, title, variant, message) => {
    self.dispatchEvent(new ShowToastEvent({ title, variant, message }))
}

export const deepCopy = (value) => {
    return JSON.parse(JSON.stringify(value))
}