import { LightningElement, api, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation'
import { RefreshEvent } from 'lightning/refresh'

import TSANET_LOGO from '@salesforce/resourceUrl/TSANetLogo'

import tsaNetCaseCreator from 'c/tsaNetCaseCreator';

import { getRelatedTSANetCases } from 'c/tsaNetHelper'

// Width thresholds with hysteresis to prevent flicker when a scrollbar appears
// after the view switches.
const TABLE_BREAKPOINT_UP = 860
const TABLE_BREAKPOINT_DOWN = 820

// Single per-user preference (localStorage is already per-browser/per-user) shared
// across all Case pages.
const EXPANDED_STORAGE_KEY = 'tsanet:relatedListExpanded'

export default class TsaNetCaseRelatedList extends NavigationMixin(LightningElement) {

    @api recordId
    @api typingTokens = []

    tsaNetLogo = TSANET_LOGO

    @track isLoading

    @track _state
    @track records
    @track caseRecord

    @track isTableView = false
    @track isExpanded = true

    _resizeObserver
    _rafId

    @api
    get state(){
        return this._state
    }

    set state(value){

        this._state = value

        this.caseRecord = value?.caseRecord
        this.records = value?.relatedCases ? value.relatedCases : []
    }

    connectedCallback(){
        this.isExpanded = this.readExpandedPreference()
    }

    renderedCallback(){
        if(!this._resizeObserver){
            this.initResizeObserver()
        }
    }

    disconnectedCallback(){
        if(this._resizeObserver){
            this._resizeObserver.disconnect()
            this._resizeObserver = undefined
        }
        if(this._rafId){
            cancelAnimationFrame(this._rafId)
        }
    }

    // Observe the card's own width so the layout adapts to the actual region size.
    initResizeObserver(){
        const container = this.template.querySelector('.rl-card')
        if(!container){
            return
        }
        this._resizeObserver = new ResizeObserver(entries => {
            this._rafId = requestAnimationFrame(() => {
                this.updateView(entries[0]?.contentRect?.width)
            })
        })
        this._resizeObserver.observe(container)
    }

    updateView(width){
        if(!width){
            return
        }
        if(!this.isTableView && width >= TABLE_BREAKPOINT_UP){
            this.isTableView = true
        } else if(this.isTableView && width <= TABLE_BREAKPOINT_DOWN){
            this.isTableView = false
        }
    }

    // Persistence

    readExpandedPreference(){
        try {
            const stored = window.localStorage.getItem(EXPANDED_STORAGE_KEY)
            return stored === null ? true : stored === 'true'
        } catch(e){
            return true
        }
    }

    writeExpandedPreference(value){
        try {
            window.localStorage.setItem(EXPANDED_STORAGE_KEY, String(value))
        } catch(e){
            // localStorage may be unavailable (private mode / blocked); ignore.
        }
    }

    handleToggleExpand(){
        this.isExpanded = !this.isExpanded
        this.writeExpandedPreference(this.isExpanded)
    }

    handleRefresh(event){
        // Background refresh (e.g. after sending a message): let the app reload data silently,
        // skipping the header spinner and the redundant API pull.
        if(event?.detail?.background){
            this.dispatchEvent(new CustomEvent('refresh', { detail: { background: true }}))
            return
        }

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

    // Bubble the outbound-send signal up to the application for typing-indicator suppression.
    handleNoteSent(event){
        this.dispatchEvent(new CustomEvent('notesent', { detail: { token: event?.detail?.token }}))
    }

    async handleCreateNewCase() {
        const result = await tsaNetCaseCreator.open({
            state: this.state,
            size: 'small'
        });

        if(result?.success){
            this.handleRefresh()
            // Fired at the page level so the Case record page and any other wired
            // components (related lists, highlights panel, etc.) also re-render.
            this.dispatchEvent(new RefreshEvent())
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

    get chevronIcon(){
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright'
    }

    get toggleAltText(){
        return this.isExpanded ? 'Collapse TSANet Cases' : 'Expand TSANet Cases'
    }

    get ariaExpanded(){
        return this.isExpanded ? 'true' : 'false'
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

    get showFooter(){
        return this.hasRecords && !this.isTableView
    }
}
