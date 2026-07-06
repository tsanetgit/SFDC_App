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

/** Lets users search TSANet members and load the collaboration form for the selected company. */
export default class CompanySelector extends LightningElement {

    tsaNetLogo = TSANetLogo

    @api recordId

    @track isLoading = false
    @track errorMessage

    @api company
    @track companies = []

    @track typingTimer

    @track form

    _searchText

    /** Initial or bound search text; triggers lookup when set. */
    @api
    get searchText() {
        return this._searchText;
    }

    set searchText(value) {
        this._searchText = value ?? '';
        if (this._searchText && this.isConnected) {
            this.runSearch(this._searchText, true);
        }
    }

    connectedCallback() {
        if (this._searchText) {
            this.runSearch(this._searchText, true);
        }
    }

    handleSearchKey(event) {
        clearTimeout(this.typingTimer);
        this._searchText = event.target.value;

        if (this._searchText) {
            this.runSearch(this._searchText, false);
        } else {
            this.companies = [];
        }
    }

    /** Runs a company name search, optionally debounced for typing. */
    runSearch(text, immediate) {
        clearTimeout(this.typingTimer);

        const executeSearch = () => {
            if (!text) {
                this.companies = [];
                return;
            }

            this.companies = [];
            this.isLoading = true;

            getCompanies(text)
                .then(companies => this.setCompanies(companies))
                .catch(error => {
                    logError(error?.body, TSANET_EXCEPTION_TYPES.SEARCH_TSANET_COMPANIES, { caseId: this.recordId });
                    toast(this, 'Error', 'error', error?.body?.message);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        };

        if (immediate) {
            executeSearch();
        } else {
            this.typingTimer = setTimeout(executeSearch, TYPING_INTERVAL);
        }
    }

    setCompanies(companies) {
        this.companies = companies && companies.map(c => ({
            ...c,
            uniqueKey: `${c.companyId}:${c.departmentId ?? 'none'}`
        }));
    }

    selectCompany(event) {
        this.company = getSelectedCompany(event, this);

        if (this.company) {
            this.isLoading = true;

            const companyId = getCompanyId(this.company);
            const mode = getMode(this.company);

            getCompanyForm(companyId, mode).then(response => {
                if (response == YOU_ARE_NOT_ABLE_TO_INTERACT_WITH_THE_REFERENCED_COMPANY) {
                    toast(this, 'Warning', 'warning', response);
                    return;
                }
                const companyForm = response && JSON.parse(response);
                this.form = initializeForm(companyForm);
                this.dispatchSelect();
                this.isLoading = false;

            }).catch(error => {
                console.error(error);
                this.errorMessage = error?.body?.message;
                logError(error?.body, TSANET_EXCEPTION_TYPES.SEARCH_TSANET_COMPANIES, { caseId: this.recordId });
            });
        } else {
            this.handleChangeCompany();
        }
    }

    handleChangeCompany() {
        this.company = undefined;
        this.companies = [];
        this._searchText = '';

        this.dispatchSelect();
    }

    dispatchSelect() {
        this.dispatchEvent(new CustomEvent('select', { detail: {
            form: this.form,
            company: this.company
        }}));
    }
}
