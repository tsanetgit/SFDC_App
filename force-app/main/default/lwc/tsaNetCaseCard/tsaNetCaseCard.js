import { LightningElement, api, track } from 'lwc';

import LightningConfirm from 'lightning/confirm';

import tsaNetActionModal from 'c/tsaNetActionModal';

import { ACTIONS  } from 'c/tsaNetConstants'


import { 
    closeRequest, toast, logError
} from 'c/tsaNetHelper'
 
export default class TsaNetCaseCard extends LightningElement {

    @track isLoading

    @api record
    @api state
    @api user

    handleOnSelectAction(event){
        let selectedAction = event.detail.value;

        switch (selectedAction) {
            case ACTIONS.CLOSE:
                this.handleCloseCase()
                break;
            case ACTIONS.SEND_ATTACHMENT:
                //this.handleSendAttachment()
                break;
    
            default:
                this.handleOpenActionModal(selectedAction)
                break;
        }
    }

    async handleOpenActionModal(mode) {
        const result = await tsaNetActionModal.open({
            mode: mode,
            record: this.record,
            state: this.state,
            size: 'small'
        });

        if(result.success){
            this.handleRefresh()
        }
    }


    async handleApproveCase() {
        const result = await tsaNetCaseApprover.open({
            record: this.record,
            state: this.state,
            size: 'small'
        });

        if(result.success){
            this.handleRefresh()
        }
    }

    handleRefresh(){
        this.dispatchEvent(new CustomEvent('refresh'))
    }

    handleOnLoading(){
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: this.isLoading }}))
    }

    async handleCloseCase(){
        const result = await LightningConfirm.open({
            message: 'Do you really want to close this case? This action cannot be undone.',
            variant: 'header',
            theme: 'warning',
            label: 'Close Case Confirmation'
        });

        if(result){
            this.isLoading = true
            this.handleOnLoading()
            closeRequest(this.record?.Id).then(response => {
                this.isLoading = false
                try {
                    let data = JSON.parse(response)
                    if(data?.status == 'CLOSED'){
                        toast(this, 'Success', 'success', 'Case has been closed successfully!')
                    }
                    this.handleRefresh()
                } catch(e){
                    toast(this, 'Error', 'error', response)
                }
            }).catch(error => {
                toast(this, 'Error', 'error', error?.body?.message)
            })
        }
    }
 
    get acceptMode(){
        return ACTIONS.ACCEPT
    }

    get createNoteMode(){
        return ACTIONS.CREATE_NOTE
    }

    get closeCaseMode(){
        return ACTIONS.CLOSE
    }

    get rejectMode(){
        return ACTIONS.REJECT
    }

    get requestInfoMode(){
        return ACTIONS.REQUEST_INFO
    }

    get sendInfoMode(){
        return ACTIONS.SEND_INFO
    }

    get sendAttachmentMode(){
        return ACTIONS.SEND_ATTACHMENT
    }

    get caseRecord(){
        return this.state?.caseRecord
    }

    get status(){
        return this.record?.tsanetconnect__Status__c;
    }

    get member(){
        return this.record?.tsanetconnect__Partner__c;
    }

    get contact(){
        return this.record?.tsanetconnect__TSANetContact__c;
    }

    get email(){
        return this.record?.tsanetconnect__TSANetEmail__c;
    }

    get summary(){
        return this.record?.tsanetconnect__Summary__c;
    }

    get description(){
        return this.record?.tsanetconnect__Description__c;
    }

    get requestDate(){
        return this.record?.tsanetconnect__RequestDate__c;
    }

    get priority(){
        return this.record?.tsanetconnect__Priority__c;
    }

    get direction(){
        return this.record?.tsanetconnect__Direction__c;
    }

    get tsaNetCaseId(){
        return this.record?.tsanetconnect__tsaNetCaseId__c;
    }

    get token(){
        return this.record?.tsanetconnect__Token__c;
    }

    get escalationInstructions() {
        return this.direction + ' - ' + this.record?.tsanetconnect__EscalationInstructions__c
            ?.replace(/<[^>]*>/g, '') || '';
    }

    get priorityStyleClass() {
        return `slds-m-right_xx-small card-pill ${this.record?.priorityStyle}`;
    }

    get statusStyleClass() {
        return `slds-badge_inverse slds-m-right_small card-pill ${this.record?.statusStyle}`;
    }
}