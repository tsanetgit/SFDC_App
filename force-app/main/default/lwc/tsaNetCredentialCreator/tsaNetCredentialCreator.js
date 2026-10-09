import { LightningElement, wire } from 'lwc'
import { NavigationMixin } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import getNamedCredentials from '@salesforce/apex/NamedCredentialSelector.getNamedCredentials'

import CREDENTIALS_OBJECT from '@salesforce/schema/TSANet_Credentials__c'
import NAMED_CREDENTIAL_FIELD from '@salesforce/schema/TSANet_Credentials__c.NamedCredential__c'
import IS_PRIMARY_FIELD from '@salesforce/schema/TSANet_Credentials__c.isPrimary__c'
import INTEGRATION_USER_FIELD from '@salesforce/schema/TSANet_Credentials__c.IntegrationUser__c'

/**
 * Creation screen for TSANet Credentials. The API is always called through a Named Credential,
 * and background FeedItems are authored as the selected Integration User.
 * Rendered through the NewTSANetCredential Aura wrapper as the object's New action.
 */
export default class TsaNetCredentialCreator extends NavigationMixin(LightningElement) {

    objectApiName = CREDENTIALS_OBJECT.objectApiName

    namedCredential
    namedCredentialOptions = []
    isNamedCredentialListUnavailable = false
    integrationUserId
    isSaving = false

    @wire(getNamedCredentials)
    wiredNamedCredentials({ data, error }){
        if(data){
            this.namedCredentialOptions = data.map(({ label, value, isCustom }) => ({
                label: isCustom ? `${label} (${value}) — custom` : `${label} (${value})`,
                value
            }))
            this.isNamedCredentialListUnavailable = this.namedCredentialOptions.length === 0
        } else if(error){
            // Listing Named Credentials needs "View Setup and Configuration"; let the user type the name instead.
            this.namedCredentialOptions = []
            this.isNamedCredentialListUnavailable = true
        }
    }

    get namedCredentialHelp(){
        return 'tsanetconnect__TSANetAPI (prod), tsanetconnect__TSANetAPIDev (dev), tsanetconnect__TSANetAPIBeta (beta), or tsanetconnect__TSANetAPITest (test).'
    }

    handleNamedCredentialChange(event){
        this.namedCredential = event.detail.value
    }

    handleSelectUser(event){
        this.integrationUserId = event.detail.value
    }

    handleClearUser(){
        this.integrationUserId = null
    }

    handleSubmit(event){
        event.preventDefault()

        if(!this.namedCredential){
            this.toast('Error', 'error', 'Select a Named Credential before saving.')
            return
        }

        const userLookup = this.template.querySelector('c-user-lookup')
        if(!this.integrationUserId){
            if(userLookup && typeof userLookup.validate === 'function'){
                userLookup.validate()
            }
            this.toast('Error', 'error', 'Select an Integration User before saving.')
            return
        }

        const fields = { ...event.detail.fields }
        fields[NAMED_CREDENTIAL_FIELD.fieldApiName] = this.namedCredential
        fields[INTEGRATION_USER_FIELD.fieldApiName] = this.integrationUserId
        // New credentials created from this page are always the primary connection.
        fields[IS_PRIMARY_FIELD.fieldApiName] = true

        this.isSaving = true
        this.template.querySelector('lightning-record-edit-form').submit(fields)
    }

    handleSuccess(event){
        this.isSaving = false
        this.toast('Success', 'success', 'The TSANet credentials have been created successfully!')
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.detail.id, objectApiName: this.objectApiName, actionName: 'view' }
        })
    }

    handleError(){
        this.isSaving = false
    }

    handleCancel(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: this.objectApiName, actionName: 'list' }
        })
    }

    toast(title, variant, message){
        this.dispatchEvent(new ShowToastEvent({ title: title, variant: variant, message: message }))
    }
}
