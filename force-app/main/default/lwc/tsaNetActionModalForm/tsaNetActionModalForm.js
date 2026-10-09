import { LightningElement, api, track } from 'lwc';

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
    NOTE_TYPE_OPTIONS,
    RICH_TEXT_FORMATS
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
    noteTypeOptions = NOTE_TYPE_OPTIONS
    // Accept, Reject, Request Info, Send Info
    @track form

    @track value

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
        // "None" omits the type so TSANet applies its default.
        if(this.noteType){
            this.note.type = this.noteType
        } else {
            delete this.note.type
        }
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