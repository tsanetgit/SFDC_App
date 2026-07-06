import { LightningElement, api, track } from 'lwc';

import LightningConfirm from 'lightning/confirm';

import tsaNetActionModal from 'c/tsaNetActionModal';

import { ACTIONS } from 'c/tsaNetConstants'

import { closeRequest, toast } from 'c/tsaNetHelper'

// Shared per-record action menu (Accept/Reject/Note/Close/Attachment/Request/Send).
// Reused by both the card view and the table view so the action logic lives in one place.
export default class TsaNetCaseActions extends LightningElement {

    @track isLoading
    @track showAttachment = false

    @api record
    @api state

    handleOnSelectAction(event){
        const selectedAction = event.detail.value;

        switch (selectedAction) {
            case ACTIONS.CLOSE:
                this.handleCloseCase()
                break;
            case ACTIONS.SEND_ATTACHMENT:
                this.showAttachment = true
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

    handleCloseAttachment(event){
        this.showAttachment = false
        if(event?.detail?.refresh){
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
                    const data = JSON.parse(response)
                    if(data?.status == 'CLOSED'){
                        toast(this, 'Success', 'success', 'Case has been closed successfully!')
                    }
                    this.handleRefresh()
                } catch(e){
                    console.debug(e)
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

    get tsaNetCaseId(){
        return this.record?.tsanetconnect__tsaNetCaseId__c;
    }

    get token(){
        return this.record?.tsanetconnect__Token__c;
    }
}
