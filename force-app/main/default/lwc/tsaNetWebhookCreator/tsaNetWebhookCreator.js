import { LightningElement, wire } from 'lwc'
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import registerWebhook from '@salesforce/apex/TSANetWebhookService.registerWebhook'
import getDefaultCallbackUrl from '@salesforce/apex/TSANetWebhookService.getDefaultCallbackUrl'

import WEBHOOK_OBJECT from '@salesforce/schema/TSANetWebhook__c'
import CREDENTIALS_OBJECT from '@salesforce/schema/TSANet_Credentials__c'

const EVENT_TYPE_CREATED = 'collaboration-request.created'
const EVENT_TYPE_NOTE = 'note.created'
const CREDENTIAL_FIELD = 'TSANetCredential__c'

/** Walks the Salesforce inContextOfRef payload to the parent record Id. */
const decodeInContextOfRef = (value) => {
    if (!value || typeof value !== 'string') {
        return null
    }

    try {
        const encoded = value.startsWith('1.') ? value.substring(2) : value
        const context = JSON.parse(atob(encoded))
        if (context?.state?.inContextOfRef) {
            return decodeInContextOfRef(context.state.inContextOfRef)
        }
        return context?.attributes?.recordId || null
    } catch {
        return null
    }
}

/**
 * Reads the parent TSANet Credential Id from a New-action page reference
 * (related-list defaultFieldValues or nested inContextOfRef).
 */
const resolveParentCredentialId = (pageRef) => {
    if (!pageRef?.state) {
        return null
    }

    const defaults = pageRef.state.defaultFieldValues
    if (defaults) {
        const match = decodeURIComponent(defaults).match(new RegExp(`${CREDENTIAL_FIELD}=([^,]+)`))
        if (match) {
            return match[1]
        }
    }

    return decodeInContextOfRef(pageRef.state.inContextOfRef)
}

/**
 * New-action screen for TSANet Webhooks. Collects the Org Domain callback URL, event types,
 * Connected App client Id/secret, and registers via Apex (secrets are not stored).
 */
export default class TsaNetWebhookCreator extends NavigationMixin(LightningElement) {

    objectApiName = WEBHOOK_OBJECT.objectApiName
    credentialsObjectApiName = CREDENTIALS_OBJECT.objectApiName

    callbackUrl = ''
    isCallbackUrlEditable = false
    eventTypes = [EVENT_TYPE_CREATED, EVENT_TYPE_NOTE]
    credentialId
    clientId = ''
    clientSecret = ''
    isSaving = false

    eventTypeOptions = [
        { label: EVENT_TYPE_CREATED, value: EVENT_TYPE_CREATED },
        { label: EVENT_TYPE_NOTE, value: EVENT_TYPE_NOTE }
    ]

    get isCallbackUrlDisabled(){
        return !this.isCallbackUrlEditable
    }

    @wire(getDefaultCallbackUrl)
    wiredDefaultCallbackUrl({ data }){
        if (!data || this.callbackUrl) {
            return
        }
        this.callbackUrl = data
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageRef){
        const parentId = resolveParentCredentialId(pageRef)
        if (parentId) {
            this.credentialId = parentId
        }
    }

    handleCallbackUrlChange(event){
        this.callbackUrl = event.detail.value
    }

    handleEditCallbackUrlChange(event){
        this.isCallbackUrlEditable = event.detail.checked
    }

    handleEventTypesChange(event){
        this.eventTypes = event.detail.value || []
    }

    handleCredentialChange(event){
        this.credentialId = event.detail.recordId
    }

    handleClientIdChange(event){
        this.clientId = event.detail.value
    }

    handleClientSecretChange(event){
        this.clientSecret = event.detail.value
    }

    handleSave(){
        if (!this.validateForm()) {
            return
        }

        this.isSaving = true
        registerWebhook({
            callbackUrl: this.callbackUrl,
            eventTypes: this.eventTypes,
            clientId: this.clientId,
            clientSecret: this.clientSecret,
            credentialId: this.credentialId
        })
            .then((recordId) => {
                if (!recordId) {
                    this.toast('Error', 'error', 'The webhook was registered but could not be saved.')
                    return
                }
                this.toast('Success', 'success', 'The TSANet webhook has been created successfully!')
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { recordId, objectApiName: this.objectApiName, actionName: 'view' }
                })
            })
            .catch((error) => {
                const message = this.reduceError(error)
                console.error('TSANet webhook register failed', message, error)
                this.toast('Error', 'error', message)
            })
            .finally(() => {
                this.isSaving = false
            })
    }

    handleCancel(){
        if (this.credentialId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.credentialId,
                    objectApiName: this.credentialsObjectApiName,
                    actionName: 'view'
                }
            })
            return
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: this.objectApiName, actionName: 'list' }
        })
    }

    /** Reports native input validity and required credential / event-type / OAuth checks. */
    validateForm(){
        const inputs = this.template.querySelectorAll('lightning-input, lightning-checkbox-group, lightning-record-picker')
        let valid = true
        inputs.forEach((input) => {
            if (typeof input.reportValidity === 'function' && !input.reportValidity()) {
                valid = false
            }
        })
        if (!this.callbackUrl) {
            this.toast('Error', 'error', 'Callback URL is required.')
            valid = false
        }
        if (!this.eventTypes.length) {
            this.toast('Error', 'error', 'Select at least one event type.')
            valid = false
        }
        if (!this.credentialId) {
            this.toast('Error', 'error', 'Select a TSANet Credential.')
            valid = false
        }
        if (!this.clientId || !this.clientSecret) {
            this.toast('Error', 'error', 'Client Id and Client Secret are required.')
            valid = false
        }
        return valid
    }

    reduceError(error){
        if (error?.body?.message) {
            return error.body.message
        }
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ')
        }
        return error?.message || 'Unable to register the webhook.'
    }

    toast(title, variant, message){
        this.dispatchEvent(new ShowToastEvent({ title, variant, message }))
    }
}
