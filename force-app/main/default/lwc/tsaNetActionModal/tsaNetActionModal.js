import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { ACTIONS } from 'c/tsaNetConstants'

import {
    approveRequest,
    rejectRequest,
    createTSANetCaseNote,
    requestAdditionalInfo,
    sendAdditionalInfo,

    getActionHeader,
    getActionSubmitVariant,
    getActionCloseVariant,
    getActionSubmitButtonLabel,
    getActionResultMessage,

    logError,
    toast,
    isRichTextEmpty
} from 'c/tsaNetHelper'

export default class TsaNetActionModal extends LightningModal {

    isLoading

    @api mode
    @api record
    @api state
    @api user
    @api isQuickAction

    @track form

    @track response

    resultDescription = 'All submitted information has been saved and is currently being processed...'

    onCancel = () => {
        if(this.isQuickAction){
            this.dispatchEvent(new CustomEvent('close'))
        } else {
            this.close({ success: this.isDone })
        }
    }

    onSave = () => {
        this.validateRequestBody()
        this.handleSubmit()
    }

    handleSubmit(){
        this.isLoading = true

        const json = JSON.stringify(this.form)

        let action;
        switch (this.mode) {
            case ACTIONS.ACCEPT:
                action = this.handleAcceptRequest(json)
                break;
            case ACTIONS.REJECT:
                action = this.handleRejectRequest(json)
                break;
            case ACTIONS.CREATE_NOTE:
                action = this.handleCreateNote(json)
                break;
            case ACTIONS.REQUEST_INFO:
                action = this.handleRequestInformation(json)
                break;
            case ACTIONS.SEND_INFO:
                action = this.handleSendInformation(json)
                break;
            default:
                break;
        }

        action.then(response => {
            this.response = response

            this.isQuickAction && setTimeout(() => this.onCancel(), 1000)

        }).catch(error => {
            const errorMessage = error?.body?.message ? error?.body?.message : error
            toast(this, 'Error', 'error', errorMessage)
            logError({ message: errorMessage }, 'REQUEST_ADDITIONAL_INFO', { caseId: this.caseRecord?.Id, tsaNetCaseId: this.record?.Id  } )
        })
        .finally(() => this.isLoading = false)
    }

    handleAcceptRequest(json){
        return new Promise((resolve, reject) => {
            approveRequest(this.token, json)
            .then(response => resolve(response))
            .catch(error => reject(error))
        })
    }

    handleRejectRequest(json){
        return new Promise((resolve, reject) => {
            rejectRequest(this.record?.Id, json)
            .then(response => resolve(response))
            .catch(error => reject(error))
        })
    }

    handleCreateNote(json){
        return new Promise((resolve, reject) => {
            createTSANetCaseNote(this.token, json)
            .then(response => resolve(response))
            .catch(error => reject(error))
        })
    }

    handleRequestInformation(json){
        console.log('requesting info: ', json)
        return new Promise((resolve, reject) => {
            requestAdditionalInfo(this.record.Id, json)
            .then(response => resolve(response))
            .catch(error => reject(error))
        })
    }

    handleSendInformation(json){
        return new Promise((resolve, reject) => {
            sendAdditionalInfo(this.record.Id, json)
            .then(response => resolve(response))
            .catch(error => reject(error))
        })
    }

    validateRequestBody(){
        if(this.isInvalid){
            toast(this, 'Warning', 'warning', 'Please check if all the data has been filled out correctly!')
            return;
        }
    }

    handleChangeForm(event){
        const form = JSON.parse(JSON.stringify(event?.detail?.form))
        console.log('form changed: ', form)
        this.form = form ? form : this.form
    }

    // Getters

    get header(){
        return getActionHeader(this.mode)
    }

    get token(){
        return this.record?.tsanetconnect__Token__c
    }

    get caseRecord(){
        return this.state?.caseRecord
    }

    get isInvalid(){
        switch (this.mode) {
            case ACTIONS.ACCEPT: return isRichTextEmpty(this.form?.nextSteps)
            case ACTIONS.CREATE_NOTE: return !this.form?.summary || isRichTextEmpty(this.form?.description)
            case ACTIONS.REJECT: return !this.form?.engineerName && isRichTextEmpty(this.form?.reason)
            case ACTIONS.REQUEST_INFO:  return !this.form?.engineerName && isRichTextEmpty(this.form?.requestedInformation)
            case ACTIONS.SEND_INFO: return !this.form?.engineerName && isRichTextEmpty(this.form?.requestedInformation)
            default: return true
        }
    }

    // Buttons

    get showSubmitButton(){
        return !this.isLoading && !this.isDone
    }

    get submitButtonVariant(){
        return getActionSubmitVariant(this.mode)
    }

    get closeButtonVariant(){
        const variant = getActionCloseVariant(this.mode)
        return variant ? variant : 'destructive-text'
    }

    get submitButtonLabel(){
        return getActionSubmitButtonLabel(this.mode)
    }

    get isDisabled(){
        return true
    }

    // General

    get isCaseRequired(){
        if(this.mode == ACTIONS.ACCEPT && this.caseRecord == null){
            return false
        } else {
            return true
        }

    }

    get resultMessage(){
        return getActionResultMessage(this.mode)
    }

    get isDone(){
        return this.response
    }
}