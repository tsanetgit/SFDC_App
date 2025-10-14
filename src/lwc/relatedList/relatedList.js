import { LightningElement, api, track } from 'lwc'
import { NavigationMixin } from 'lightning/navigation'
import LightningConfirm from 'lightning/confirm';

import TSANetLogo from '@salesforce/resourceUrl/TSANetLogo'

import closeTSANetCase from '@salesforce/apex/TSANetService.closeTSANetCase'

import { getRelatedTSANetCases, toast } from 'c/tsaNetHelper'

import './relatedList.css'
 
export default class RelatedList extends NavigationMixin(LightningElement) {

    @api recordId
    @api isLogin

    isLoading

    isNew = false
    isApprove = false

    isNoteMode = false
    isRejectMode = false
    isRequestMode = false
    isResponseMode = false
    isAttachmentMode = false
    externalCaseId 
    caseToken

    logo = TSANetLogo
    @track columns
    @track record
    @track records = []
    unAssignedCases = []
    @track caseRecord
    @track config 
    @track currentUser

    @track _state

    @api
    get state(){
        return this._state
    }

    set state(value){

        this._state = value

        console.log('value current user', value?.currentUser)

        this.config = value?.config
        this.records = value?.relatedCases ? value.relatedCases : []
        this.caseRecord = value?.caseRecord
        this.currentUser = value?.currentUser
        this.columns = value?.columns
        //this.logo = value?.logo
    }

    handleGotoRelatedList() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                relationshipApiName: 'tsanet_connect__TSANetCases__r',
                actionName: 'view'
            }
        })
    }

    handleRefresh(){
        this.isLoading = true
        getRelatedTSANetCases(undefined).then(response => {
            this.dispatchEvent(new CustomEvent('refresh'))
        }).finally(() => {
            this.isLoading = false
        })
    }

    handleSwitchNew(event){
        let isRefresh = event.detail.refresh;
        console.log('isRefresh; ', isRefresh)
        this.isNew = !this.isNew
        if(isRefresh){
            this.handleRefresh()
        }
    }

    handleSwitchApprove(event){
        console.log('event handleSwitchApprove', JSON.stringify(event))
        let isRefresh = event.detail.refresh;
        console.log('isRefresh; ', isRefresh)
        this.isApprove = !this.isApprove
        if(isRefresh){
            this.handleRefresh()
        } 
    }

    handleOnNote(event){
        this.isNoteMode = true
    }

    handleOnCloseNote(event){
        this.isNoteMode = false
        this.dispatchEvent(new CustomEvent('refesh'))
    }

    addNewNote(event){
        let externalId = event.currentTarget.dataset.id
        this.externalCaseId = externalId

        this.isNoteMode = true
        this.dispatchEvent(new CustomEvent('opennote'), {
            detail: this.isNoteMode
        })
    }

    handleRejectTSANetCase(event){
        let externalId = event.currentTarget.dataset.id
        let record = this.records.find(r => ( r.tsanet_connect__tsaNetCaseId__c == externalId))
        this.externalCaseId = externalId
        this.record = record

        this.isRejectMode = true
    }

    handleRequestTSANetInfo(event){
        let externalId = event.currentTarget.dataset.id
        let record = this.records.find(r => ( r.tsanet_connect__tsaNetCaseId__c == externalId))
        this.externalCaseId = externalId
        this.record = record

        this.isRequestMode = true
    }

    handleOnSelectAction(event){
        let selectedItemValue = event.detail.value;

        let externalId = event.currentTarget.dataset.id
        let token = event.currentTarget.dataset.token
        let record = this.records.find(r => ( r.tsanet_connect__tsaNetCaseId__c == externalId))
        this.externalCaseId = externalId
        this.caseToken = token
        this.record = record

        if(selectedItemValue == 'note'){
            this.isNoteMode = true
        } else if(selectedItemValue == 'reject'){
            this.isRejectMode = true
        } else if(selectedItemValue == 'request'){
            this.isRequestMode = true
        } else if(selectedItemValue == 'response'){
            this.isResponseMode = true
        } else if(selectedItemValue == 'accept'){
            this.isApprove = true
        } else if(selectedItemValue == 'attachment'){
            this.isAttachmentMode = true
        } else if(selectedItemValue == 'close'){
            this.closeCase()
        }
    }

    async closeCase(){
        const result = await LightningConfirm.open({
            message: 'Do you really want to close this case? This action cannot be undone.',
            variant: 'header',
            theme: 'warning',
            label: 'Close Case Confirmation'
        });

        if(result){
            this.isLoading = true
            closeTSANetCase({ tsaNetCaseId: this.record?.Id }).then(response => {
                this.isLoading = false
                try {
                    let data = JSON.parse(response)
                    if(data?.status == 'CLOSED'){
                        toast(this, 'Success', 'success', 'Case has been closed successfully!')
                    }
                    this.dispatchEvent(new CustomEvent('refesh'))
                } catch(e){
                    toast(this, 'Error', 'error', response)
                    this.dispatchEvent(new CustomEvent('refesh'))
                }
            }).catch(error => {
                console.log(error)
                toast(this, 'Error', 'error', error?.body?.message)
                
                getRelatedTSANetCases(undefined)
            })
        }
    }

    handleCloseNoteMode(event){
        let isRefresh = event.detail.refresh;
        console.log('isRefresh; ', isRefresh)
        this.isNoteMode = false

        if(isRefresh){
            this.handleRefresh()
        }
    }

    handleCloseRejectMode(event){
        let isRefresh = event.detail.refresh;
        console.log('isRefresh; ', isRefresh)
        this.isRejectMode = false
        if(isRefresh){
            this.handleRefresh()
        }  
    }

    handleCloseRequestMode(event){
        let isRefresh = event.detail.refresh;
        console.log('isRefresh; ', isRefresh)
        this.isRequestMode = false
        if(isRefresh){
            this.handleRefresh()
        }       
    }

    handleCloseAttachmentMode(event){
        let isRefresh = event.detail.refresh;
        console.log('isRefresh; ', isRefresh)
        this.isAttachmentMode = !this.isAttachmentMode
        if(isRefresh){
            this.handleRefresh()
        } 
    }

    handleCloseResponseMode(event){
        console.log('event handleCloseResponseMode', JSON.stringify(event))
        let isRefresh = event.detail.refresh;
        console.log('isRefresh; ', isRefresh)
        this.isResponseMode = false
        if(isRefresh){
            this.handleRefresh()
        } 
    }

    get recordsLength(){ return this.records && this.records?.length ? this.records.length : '0' }

    get datatableHeight() {
        if(this.records?.length == 0){
            return 'min-height:3rem;';
        } else if(this.records?.length > 3){
            return 'max-height:300px;';
        } else {
            return 'min-height:150px;'
        }
    }

    get title(){
        return ' TSANet Cases (' + this.recordsLength + ')'
    }


        /*
    selectedRecord 
    show = false
    showTable = false
    activeRecordsCount = 0
    left
    top

    handlePopoverLeave(event){
        console.log('leave')
        this.showTable = false
        this.show = false
        this.selectedRecord = undefined
        
    }

    handlePopover(event){

        console.log('handlePopover')

        if(this.isNoteMode || this.showTable){ 
            return 
        }

        this.showTable = !this.showTable

        console.log(this.showTable)

        if(this.showTable){

            this.show = true
            this.left = event.clientX;
            this.top= event.clientY;

            console.log('record?.weeks : ')

            let selectedRecordId = event.currentTarget.dataset.recordid
            let selectedRecord = this.records.find(record => (record.Id == selectedRecordId))
            this.selectedRecord = selectedRecord
            console.log("JSON> ", JSON.stringify(selectedRecord))
        } else {
            this.show = false;
            this.selectedRecord = undefined
        }

    }

    handleClose() {
        this.show = false;
        this.showTable = !this.showTable
        this.selectedRecord = undefined
    }


    handleOnShowDetail(event){

        this.showTable = !this.showTable

        console.log(this.showTable)

        if(this.showTable){

            this.show = true
            this.left = event.clientX;
            this.top= event.clientY;

            console.log('record?.weeks : ')

            let selectedRecordId = event.currentTarget.dataset.recordid
            this.selectedRecord = this.records.find(record => (record.Id == selectedRecordId))
            this.selectedRecord = selectedRecord
            console.log("JSON> ", JSON.stringify(selectedRecord))
        } else {
            this.show = false;
            this.selectedRecord = undefined
        }
    }

    handleOnHideDetail(event){
        this.showTable = !this.showTable

        console.log(this.showTable)

        if(this.showTable){

            this.show = true
            this.left = event.clientX;
            this.top= event.clientY;

            console.log('record?.weeks : ')

            let selectedRecordId = event.currentTarget.dataset.recordid
            this.selectedRecord = this.records.find(record => (record.Id == selectedRecordId))
            this.selectedRecord = selectedRecord
            console.log("JSON> ", JSON.stringify(selectedRecord))
        } else {
            this.show = false;
            this.selectedRecord = undefined
        }
    }

    handleMouseover(event){
        console.log(1)
        this.dispatchEvent(new CustomEvent('showdetail'), { detail: event })
    }

    handleMouseout(event){
        console.log(2)
        this.dispatchEvent(new CustomEvent('hidedetail'), { detail: event })
    }

    */

}