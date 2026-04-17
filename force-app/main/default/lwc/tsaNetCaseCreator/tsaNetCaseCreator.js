import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { NavigationMixin } from 'lightning/navigation';

import {
    createNewCollaborationCase, toast, logError
} from 'c/tsaNetHelper'

export default class TsaNetCaseCreator extends NavigationMixin(LightningModal) {

    header = 'Create New Collaboration Request';

    @track caseId // Salesforce Case ID
    @track isLoading

    @api isQuickAction
    @api state

    @track step = 1

    @track company
    @track form

    @track submitResponse

    resultMessage = 'Your case has been successfully submitted'
    resultDescription = 'The request was sent to TSANet and is now being processed'

    onCancel = () => {
        if(this.isSearchMode || this.isDone){
            this.isQuickAction ? this.handleCancelQuickAction() : this.close({ success: this.isDone })
        } else {
            this.step--
        }
    };

    handleCancelQuickAction() {
        this.dispatchEvent(new CustomEvent('close'));
        this.caseId && this.navigateToRecord(this.caseId)
    }

    onSave = () => {
        if(this.isSearchMode){
            this.step++
        } else {
            this.handleSubmit()
        }
    };

    handleSelectCompany(event){
        this.form = event?.detail?.form
        this.company = event?.detail?.company
    }

    handleSubmit(){

        const tsaNetForm = this.template.querySelector('c-tsa-net-form');
        if (!tsaNetForm) return;

        const data = tsaNetForm.resolveCustomForm();
        if(data?.hasError || !data?.caseId){ return }

        this.caseId = data?.caseId

        const object = data?.object

        this.isLoading = true

        createNewCollaborationCase(data?.caseId, JSON.stringify(object))
        .then(response => {

            const res = JSON.parse(response)

            if(res?.message){
                toast(this, 'Error', 'error', res?.message)
                logError({ message: res?.message }, 'CREATE_TSANET_COLLABORATION_REQUEST', { caseId: this.caseId } )
            } else {
                this.submitResponse = res
            }
        }).catch(error => {
            toast(this, 'Error', 'error', error?.body?.message)
            logError(error?.body, 'CREATE_TSANET_COLLABORATION_REQUEST', { caseId: this.recordId } )
        }).finally(() => {
            this.isLoading = false
        })
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view' // view | edit
            }
        });
    }

    // Getters

    get caseRecord(){
        return this.state?.caseRecord
    }

    get isNextDisabled(){
        return !this.form
    }

    get isSearchMode(){
        return this.step == 1
    }

    get cancelButtonLabel(){
        return this.isSearchMode || this.isDone ? 'Close': 'Back'
    }

    get submitButtonLabel(){
        return this.isSearchMode ? 'Next': 'Submit'
    }

    get cancelButtonVariant(){
        return this.isSearchMode || this.isDone ? 'destructive-text' : 'neutral'
    }

    get isDone(){
        return !!this.submitResponse?.id
    }

    get showSubmitButton(){
        return !this.isLoading && !this.isDone
    }

    get showCancelButton(){
        return !this.isLoading
    }
}