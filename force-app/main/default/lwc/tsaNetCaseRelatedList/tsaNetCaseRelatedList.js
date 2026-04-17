import { LightningElement, api, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation'

import TSANET_LOGO from '@salesforce/resourceUrl/TSANetLogo'

import tsaNetCaseCreator from 'c/tsaNetCaseCreator';

import { getRelatedTSANetCases } from 'c/tsaNetHelper'

export default class TsaNetCaseRelatedList extends NavigationMixin(LightningElement) {

    @api recordId

    tsaNetLogo = TSANET_LOGO

    @track isLoading

    @track _state
    @track records
    @track caseRecord

    @api
    get state(){
        return this._state
    }

    set state(value){

        this._state = value

        this.caseRecord = value?.caseRecord
        this.records = value?.relatedCases ? value.relatedCases : []
    }

    handleRefresh(){
        this.isLoading = true
        getRelatedTSANetCases(this.recordId).then(() => {
            this.dispatchEvent(new CustomEvent('refresh'))
        }).catch(error => {
            console.error(error)
        }).finally(() => {
            this.isLoading = false
        })
    }

    handleOnLoading(event){
        this.isLoading = event?.detail?.isLoading
    }

    async handleCreateNewCase() {
        const result = await tsaNetCaseCreator.open({
            state: this.state,
            size: 'small'
        });

        if(result.success){
            this.handleRefresh()
        }
    }

    handleRelatedListRedirect() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                relationshipApiName: 'tsanetconnect__TSANetCases__r',
                actionName: 'view'
            }
        })
    }

    // Getters

    get hasRecords(){ return this.records && this.records?.length }

    get recordsLength(){ return this.records && this.records?.length ? this.records.length : '0' }

    get title(){
        return ' TSANet Cases (' + this.recordsLength + ')'
    }

    get listHeight() {
        if(this.records?.length == 0){
            return 'min-height:3rem;';
        } else if(this.records?.length > 3){
            return 'max-height:400px;';
        } else {
            return 'min-height:150px;'
        }
    }

    get relatedListClass(){
        let className = 'rl-scroll related-list-box '
        if(this.records?.length == 0){
            className += 'empty-related-list-height';
        } else if(this.records?.length > 3){
            className += 'full-related-list-height';
        } else {
            className += 'default-related-list-height'
        }
        return className;
    }
}