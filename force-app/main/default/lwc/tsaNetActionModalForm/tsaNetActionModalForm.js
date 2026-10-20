import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import TSANET_NOTE_OBJECT from '@salesforce/schema/TSANetNote__c';
import TSANET_NOTE_TYPE_FIELD from '@salesforce/schema/TSANetNote__c.Type__c';

import {
    CASE_SUBJECT_FIELD,
    CASE_NUMBER_FIELD,
    USER_NAME_FIELD,
    USER_FIRST_NAME_FIELD,
    USER_LAST_NAME_FIELD,
    USER_EMAIL_FIELD,
    USER_PHONE_FIELD,
    USER_MOBILE_PHONE_FIELD,

    ACTIONS,
    NOTE_STATE,
    NOTE_TYPE_NONE_OPTION,
    NOTE_TYPE_SYSTEM_CODE,
    RICH_TEXT_FORMATS,
    buildNoteTypeReference
} from 'c/tsaNetConstants'

import {
    getActionRequestParam
} from 'c/tsaNetHelper'

export default class TsaNetActionModalForm extends LightningElement {

    @api mode
    @api state
    @api record

    // Note
    @track note = NOTE_STATE
    @track summary
    @track description
    noteType = ''
    // Only "None" until TSANetNote__c.Type__c picklist values are loaded.
    noteTypeOptions = [NOTE_TYPE_NONE_OPTION]
    // Accept, Reject, Request Info, Send Info
    @track form

    @track value

    @wire(getObjectInfo, { objectApiName: TSANET_NOTE_OBJECT })
    noteObjectInfo

    // Loads TSANetNote__c.Type__c picklist values for the default record type.
    @wire(getPicklistValues, {
        recordTypeId: '$noteObjectInfo.data.defaultRecordTypeId',
        fieldApiName: TSANET_NOTE_TYPE_FIELD
    })
    wiredNoteTypes({ data, error }){
        if(error){
            console.error('Failed to load note type picklist values', error)
            return
        }
        if(!data){ return }
        this.noteTypeOptions = this.buildNoteTypeOptions(data.values)
    }

    // Maps active Type__c picklist values to combobox options, hiding the platform-only "system" type, with "None" first.
    buildNoteTypeOptions(values = []){
        const options = values
            .filter(item => item.value !== NOTE_TYPE_SYSTEM_CODE)
            .map(({ label, value }) => ({ label, value }))
        return [NOTE_TYPE_NONE_OPTION, ...options]
    }

    handleChangeSummary(event){
        this.summary = event?.target?.value
        this.generateNote()
        this.dispatchEvent(new CustomEvent('changeform', { detail: { form: this.note }}))
    }

    handleChangeDescription(event){
        this.description = event?.target?.value
        this.generateNote()
        this.dispatchEvent(new CustomEvent('changeform', { detail: { form: this.note }}))
    }

    handleChangeType(event){
        this.noteType = event?.detail?.value ?? ''
        this.generateNote()
        this.dispatchEvent(new CustomEvent('changeform', { detail: { form: this.note }}))
    }

    get richTextFormats() {
        return RICH_TEXT_FORMATS
    }

    generateNote(){
        this.note.summary = this.summaryValue
        this.note.description = this.description
        this.note.submittedBy.firstName = this.userFirstName
        this.note.submittedBy.lastName = this.userLastName
        // API expects type as { code }; "None" sends an explicit null so the note is stored without a type.
        this.note.type = buildNoteTypeReference(this.noteType)
    }

    handleChangeField(event){
        this.value = event?.detail?.value
        this.dispatchFieldChange(event)
    }

    dispatchFieldChange(){
        const param = getActionRequestParam(this.mode)
        const data = {
            ...this.engineerData,
            [param]: this.value
        }
        this.dispatchEvent(new CustomEvent('changeform', { detail: { form: data }}))
    }

    get summaryValue(){
        return this.summary ?? this.caseSubject
    }

    get actionRequestParam(){
        return getActionRequestParam(this.mode)
    }

    get caseRecord(){
        return this.state?.caseRecord
    }

    get caseSubject(){
        return this.state?.caseRecord && this.state?.caseRecord[CASE_SUBJECT_FIELD.fieldApiName]
    }

    // Engineer Data
    get caseNumber() {
        return this.caseRecord?.[CASE_NUMBER_FIELD.fieldApiName] ?? '';
    }

    get engineerData(){
        return {
            caseNumber: this.caseNumber,
            engineerName: this.ownerName || this.userName,
            engineerEmail: this.ownerEmail || this.userEmail,
            engineerPhone: this.ownerPhone || this.userPhone
        }
    }

    // Owner Data
    get ownerFirstName() {
        return this.caseRecord?.Owner[USER_FIRST_NAME_FIELD.fieldApiName] ?? '';
    }

    get ownerLastName() {
        return this.caseRecord?.Owner[USER_LAST_NAME_FIELD.fieldApiName] ?? '';
    }

    get ownerName() {
        return this.caseRecord?.Owner[USER_NAME_FIELD.fieldApiName] ?? '';
    }

    get ownerEmail() {
        return this.caseRecord?.Owner[USER_EMAIL_FIELD.fieldApiName] ?? '';
    }

    get ownerPhone() {
        return this.caseRecord?.Owner[USER_PHONE_FIELD.fieldApiName] ?? '';
    }

    // Current User Data

    get userFirstName() {
        return this.state?.user?.[USER_FIRST_NAME_FIELD.fieldApiName] ?? '';
    }

    get userLastName() {
        return this.state?.user?.[USER_LAST_NAME_FIELD.fieldApiName] ?? '';
    }

    get userName() {
        return this.state?.user[USER_NAME_FIELD.fieldApiName] ?? '';
    }

    get userEmail() {
        return this.state?.user[USER_EMAIL_FIELD.fieldApiName] ?? '';
    }

    get userPhone() {
        return (
            this.state?.user[USER_PHONE_FIELD.fieldApiName] ??
            this.state?.user[USER_MOBILE_PHONE_FIELD.fieldApiName] ??
            ''
        );
    }

    get isNoteMode(){
        return this.mode == ACTIONS.CREATE_NOTE
    }
}