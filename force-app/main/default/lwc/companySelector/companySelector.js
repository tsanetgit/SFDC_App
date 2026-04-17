import { LightningElement, api, track } from 'lwc';

import TSANetLogo from '@salesforce/resourceUrl/TSANetLogo'

import {
    TSANET_EXCEPTION_TYPES,
    TYPING_INTERVAL,
    YOU_ARE_NOT_ABLE_TO_INTERACT_WITH_THE_REFERENCED_COMPANY
} from 'c/tsaNetConstants'

import { getCompanyId, getMode, initializeForm, getSelectedCompany,
    getCompanies, getCompanyForm, toast, logError
} from 'c/tsaNetHelper'

export default class CompanySelector extends LightningElement {

    tsaNetLogo = TSANetLogo

    @api recordId

    @track isLoading = false
    @track errorMessage

    @api company
    @track companies = []

    @track searchText
    @track typingTimer

    @track form

    handleSearchKey(event){
        clearTimeout(this.typingTimer)

        this.searchText = event.target.value
        if(this.searchText){
            this.typingTimer = setTimeout(() => {
                this.companies = []
                this.isLoading = true

                getCompanies(this.searchText)
                .then(companies => this.setCompanies(companies))
                .then(() => this.isLoading = false )
                .catch(error => {
                    logError(error?.body, TSANET_EXCEPTION_TYPES.SEARCH_TSANET_COMPANIES, { caseId: this.recordId } )
                    toast(this, 'Error', 'error', error?.body?.message)
                })

            }, TYPING_INTERVAL)
        } else {
            this.companies = []
        }
    }

    setCompanies(companies){
        this.companies = companies && companies.map(c => ({
            ...c,
            uniqueKey: `${c.companyId}:${c.departmentId ?? 'none'}`
        }));
    }

    selectCompany(event){

        this.company = getSelectedCompany(event, this)

        if(this.company){
            this.isLoading = true

            const companyId = getCompanyId(this.company);
            const mode = getMode(this.company)

            getCompanyForm(companyId, mode).then(response => {
                if(response == YOU_ARE_NOT_ABLE_TO_INTERACT_WITH_THE_REFERENCED_COMPANY){
                    toast(this, 'Warning', 'warning', response)
                    return
                }
                const companyForm = response && JSON.parse(response)
                this.form = initializeForm(companyForm);
                this.dispatchSelect()
                this.isLoading = false

            }).catch(error => {
                console.error(error)
                this.errorMessage = error?.body?.message
                logError(error?.body, TSANET_EXCEPTION_TYPES.SEARCH_TSANET_COMPANIES, { caseId: this.recordId } )
            })
        } else {
            this.handleChangeCompany()
        }
    }

    handleChangeCompany(){
        this.company = undefined
        this.companies = []
        this.searchText = ''

        this.dispatchSelect()
    }

    dispatchSelect(){
        this.dispatchEvent(new CustomEvent('select', { detail : {
            form: this.form,
            company: this.company
        }}))
    }
}