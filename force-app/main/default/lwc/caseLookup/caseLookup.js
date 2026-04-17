import { LightningElement, api, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

import getCases from '@salesforce/apex/TSANetUtils.getCases'

export default class CaseLookup extends NavigationMixin(LightningElement) {

    isLoading
    @api caseRecord
    searchText

    @track cases = []

    typingTimer

    getSearchedCases(){
        getCases({ searchText: this.searchText })
        .then(cases => {
            this.cases = cases
        })
        .then(() => this.isLoading = false )
        .catch(error => {
            console.error('error : ', error)
        })
        .finally(() => {
            this.isLoading = false
        })
    }

    handleChangeCase(){
        this.caseRecord = undefined

        this.dispatchEvent(new CustomEvent('select', { detail: undefined }))

        this.getSearchedCases()
    }

    handleSearchKey(event){
        clearTimeout(this.typingTimer)

        this.searchText = event.target.value

        if(event?.target?.value){
            this.typingTimer = setTimeout(() => {
                this.case = []
                this.isLoading = true
                this.getSearchedCases()

            }, 300)
        } else {
            this.companies = []
        }
    }

    selectCase(event){
        this.caseRecord = this.cases.find(c => ( c.Id == event?.currentTarget?.dataset?.value ))
        this.dispatchEvent(new CustomEvent('select', { detail: event?.currentTarget?.dataset?.value }))
    }

    createNewCase(){
        window.open('/lightning/o/Case/new', '_blank')
    }

    get boxHeight(){
        return ( this.isLoading || this.cases.length ) ? 'height: 200px;' : ''
    }

}