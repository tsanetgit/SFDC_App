import { LightningElement, api, track } from 'lwc';

import {
    CASE_SUBJECT_FIELD,
    CASE_NUMBER_FIELD,
    ACCOUNT_NAME_FIELD,
    CONTACT_NAME_FIELD,
    CONTACT_EMAIL_FIELD,
    CONTACT_PHONE_FIELD,

    FORM_FIELDS,
    SKIP_FORM_FIELDS,

    PRIORITY_OPTIONS,
    TSANET_CASE_PRIORITIES,
    REQUIRED_FIELDS_WARNING,

    ACCOUNT_REQUIRED_WARNING,
    CONTACT_REQUIRED_WARNING,

    TOAST_MODE,
    WARNING_LABEL

} from 'c/tsaNetConstants'

import {
    getCaseInfo,
    toast
} from 'c/tsaNetHelper'

export default class TsaNetForm extends LightningElement {

    @api form
    @api caseRecord

    @track selectedCaseRecord

    @track isDone = false

    @track subject
    @track priority
    @track description
    @track submitterDetails = {}

    @track customFieldMap = new Map()

    priorities = PRIORITY_OPTIONS

    handleChangeSubject(event){
        this.subject = event.target.value
    }

    handleDescription(event){
        this.description = event.target.value
    }

    handleChangePriority(event){
        this.priority = event.target.value
    }

    handleChangeCustomField(event){
        const fieldName = event.target.label
        const value = event.target.value
        this.customFieldMap.set(fieldName, value)
    }

    handleChangeTierPicklist(event){
        const fieldName = event.detail.label
        const value = event.detail.value
        this.customFieldMap.set(fieldName, value)
    }

    handleChangeCase(event){

        const recordId = event.target.value
        getCaseInfo(recordId)
        .then(data => {
            const isValid = this.validateCaseInfo(data)
            this.selectedCaseRecord = isValid ? data?.caseRecord : undefined
        })
        .catch(error => {
            console.error('error', error)
        })
    }

    validateCaseInfo(data){
        let isValid = true;
        if(!data?.caseRecord?.Contact?.Name){
            toast(this, REQUIRED_FIELDS_WARNING, TOAST_MODE.WARNING, CONTACT_REQUIRED_WARNING)
            isValid = false
        } else if(!data?.caseRecord?.Account?.Name){
            toast(this, REQUIRED_FIELDS_WARNING, TOAST_MODE.WARNING, ACCOUNT_REQUIRED_WARNING)
            isValid = false
        }
        return isValid;
    }

    handleSelectUser(e){
        const { user } = e.detail;
        this.submitterDetails = {
            name: user?.name,
            email: user?.email,
            phone: user?.phone
        }
    }

    handleClearUser() {
        this.submitterDetails = {
            name: '',
            email: '',
            phone: '',
        }
    }

    @api
    resolveCustomForm() {
        // Basic required fields
        if (!this.subjectValue || !this.priorityValue || !this.description) {
            toast(this, WARNING_LABEL, TOAST_MODE.WARNING, REQUIRED_FIELDS_WARNING);
            return { hasError: true, object: null };
        }

        const missingRequired = new Set();

        const form = this.form || {};
        const customFieldsMeta = form.customFields || []; // metadata (required flags etc.)

        // Build a quick lookup for required custom field labels
        const requiredLabels = new Set(
            customFieldsMeta.filter(f => f?.required).map(f => f.label)
        );

        const object = {};

        for (const [key, value] of Object.entries(form)) {
            if (SKIP_FORM_FIELDS.has(key)) continue;

            if (key === FORM_FIELDS.PROBLEM_SUMMARY) {
                object[key] = this.subjectValue ?? '';
                continue;
            }

            if (key === FORM_FIELDS.PROBLEM_DESCRIPTION) {
                object[key] = this.description ?? '';
                continue;
            }

            if (key === FORM_FIELDS.PRIORITY) {
                object[key] = this.priorityValue ?? '';
                continue;
            }

            if (key === FORM_FIELDS.INTERNAL_CASE_NUMBER) {
                object[key] = this.caseNumber;
                continue;
            }

            if (key === FORM_FIELDS.RECEIVER_INTERNAL_CASE_NUMBER) {
                object[key] = '';
                continue;
            }

            if (key === FORM_FIELDS.SUBMITTER_CONTACT_DETAILS) {
                object[key] = this.submitterDetails ?? '';
                continue;
            }

            if (key === FORM_FIELDS.CUSTOM_FIELDS) {
                const clonedCustomFields = Array.isArray(value)
                    ? value.map(cf => ({ ...cf }))
                    : [];

                clonedCustomFields.forEach((cf) => {
                    const label = cf?.label;

                    // Resolve value
                    let resolvedValue = '';

                    if (label === FORM_FIELDS.CUSTOMER_COMPANY) {
                        resolvedValue = this.accountName;
                    } else if (label === FORM_FIELDS.CUSTOMER_NAME) {
                        resolvedValue = this.contactName;
                    } else if (label === FORM_FIELDS.CUSTOMER_EMAIL) {
                        resolvedValue = this.contactEmail;
                    } else if (label === FORM_FIELDS.CUSTOMER_PHONE_INCLUDING_COUNTRY_CODE) {
                        resolvedValue = this.contactPhone;
                    } else {
                        resolvedValue = this.customFieldMap?.has(label)
                            ? (this.customFieldMap.get(label) ?? '')
                            : '';
                    }

                    cf.value = resolvedValue;

                    // Required validation
                    const isMissing = resolvedValue == null || String(resolvedValue).trim() === '';
                    if (label && requiredLabels.has(label) && isMissing) {
                        missingRequired.add(label);
                    }
                });

                object[key] = clonedCustomFields;
                continue;
            }

            // Default: copy as-is
            object[key] = value;
        }

        const hasError = missingRequired.size > 0;
        if (hasError) {
            const missingText = Array.from(missingRequired).join(', ');
            toast(
                this,
                WARNING_LABEL,
                TOAST_MODE.WARNING,
                `${REQUIRED_FIELDS_WARNING}${missingText ? ` ${missingText}` : ''}`
            );
        }
        return { hasError, object, caseId: this.salesforceCaseRecord?.Id };
    }

    // Getters

    get salesforceCaseRecord(){
        return this.caseRecord ?? this.selectedCaseRecord
    }

    get caseNumber() {
        return this.salesforceCaseRecord?.[CASE_NUMBER_FIELD.fieldApiName] ?? '';
    }

    get accountName() {
        return this.salesforceCaseRecord?.Account?.[ACCOUNT_NAME_FIELD.fieldApiName] ?? '';
    }

    get contactName() {
        return this.salesforceCaseRecord?.Contact?.[CONTACT_NAME_FIELD.fieldApiName] ?? '';
    }

    get contactEmail() {
        return this.salesforceCaseRecord?.Contact?.[CONTACT_EMAIL_FIELD.fieldApiName] ?? '';
    }

    get contactPhone() {
        return this.salesforceCaseRecord?.Contact?.[CONTACT_PHONE_FIELD.fieldApiName] ?? '';
    }

    get subjectValue(){
        return this.subject ?? this.salesforceCaseRecord?.[CASE_SUBJECT_FIELD.fieldApiName]
    }

    get priorityValue(){
        return this.priority ?? TSANET_CASE_PRIORITIES.LOW
    }

    get customFields(){
        return this.form?.customFields ?? []
    }

}