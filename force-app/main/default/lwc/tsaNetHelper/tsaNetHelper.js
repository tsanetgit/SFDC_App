import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import { 
    TSANET_DIRECTION,
    SKIP_FORM_CUSTOM_FIELDS,
    TSANET_CASE_STATUSES,
    TSANET_CASE_STATUS_STYLE,
    TSANET_CASE_PRIORITY_STYLE,
    ACTION_CONFIG
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

        relatedCase.isHideAction = ( relatedCase.isNoteable || relatedCase.isRejectable || relatedCase.isRequestable || relatedCase.isCloseable )

        if(relatedCase?.tsanetconnect__TSANetResponses__r && relatedCase?.tsanetconnect__TSANetResponses__r.length){
            relatedCase['agentEmail'] = relatedCase?.tsanetconnect__TSANetResponses__r[0]?.tsanetconnect__EngineerEmail__c
        }
    })

    return data
}

export const getCompanies = (companyName) => {
    return new Promise((resolve, reject) => {
        getCompaniesByName({ companyName })
        .then(json => resolve(prepareCompaniesData(json)))
        .catch(error => reject(error))
    })
}

const prepareCompaniesData = (json) => {
    let companies = json && JSON.parse(json)

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
                let values = field.selections
                let mappedValues = values.map(o => ({ label: o.value, value: o.value, children: o.children }))
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


export const toast = (self, title, variant, message) => {
    self.dispatchEvent(new ShowToastEvent({ title, variant, message }))
}

export const deepCopy = (value) => {
    return JSON.parse(JSON.stringify(value))
}