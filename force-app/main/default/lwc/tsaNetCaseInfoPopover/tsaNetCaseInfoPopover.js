import { LightningElement, api, track } from 'lwc';

const POPOVER_WIDTH = 420;
const VIEWPORT_MARGIN = 8;
const HIDE_DELAY_MS = 400;
const STYLE_ID = 'tsanet-case-info-popover-styles';

// Hover popover for case details not shown on the card. Built imperatively in a body portal
// so LWC reconciliation never re-inserts it inside the zoomed/clipped card container.
export default class TsaNetCaseInfoPopover extends LightningElement {

    @api record

    @track showPopover = false
    _hideTimeout
    _portal
    _popoverEl
    _triggerEl
    _repositionHandler
    _portalMouseEnter
    _portalMouseLeave

    handleShow(){
        if(this._hideTimeout){
            clearTimeout(this._hideTimeout)
            this._hideTimeout = undefined
        }

        if(this.showPopover){
            return
        }

        this.showPopover = true
        this._openPopover()
    }

    // Creates the popover in a body portal and positions it beside the trigger icon.
    _openPopover(){
        const trigger = this.template.querySelector('.info-trigger__btn')
        if(!trigger){
            return
        }

        this._ensurePortal()
        this._ensureGlobalStyles()
        this._clearPortal()

        const popover = this._buildPopoverElement()
        this._portal.appendChild(popover)

        this._popoverEl = popover
        this._triggerEl = trigger

        this._positionAtViewport(popover, trigger)
        this._attachRepositionListeners()

        // Re-measure once content is painted so above/below flip uses real height.
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            if(this.showPopover && this._popoverEl?.isConnected && this._triggerEl?.isConnected){
                this._positionAtViewport(this._popoverEl, this._triggerEl)
            }
        })
    }

    // Builds the popover DOM tree imperatively so it lives only in the portal.
    _buildPopoverElement(){
        const popover = document.createElement('section')
        popover.setAttribute('role', 'dialog')
        popover.setAttribute('aria-label', this.caseNumber || '')
        popover.className = 'slds-popover info-popover'

        const header = document.createElement('header')
        header.className = 'info-popover__header slds-p-horizontal_medium slds-p-vertical_small'

        const caseTitle = document.createElement('span')
        caseTitle.className = 'info-popover__case slds-truncate'
        caseTitle.textContent = this.caseNumber || ''
        header.appendChild(caseTitle)
        popover.appendChild(header)

        const body = document.createElement('div')
        body.className = 'slds-popover__body info-popover__body slds-p-around_none'
        this._appendPopoverSections(body)
        popover.appendChild(body)

        this._portalMouseEnter = () => this.handleShow()
        this._portalMouseLeave = () => this.handleHide()
        popover.addEventListener('mouseenter', this._portalMouseEnter)
        popover.addEventListener('mouseleave', this._portalMouseLeave)

        return popover
    }

    // Appends problem, escalation, custom-field, and empty-state sections to the popover body.
    _appendPopoverSections(body){
        if(this.hasProblem){
            const section = document.createElement('div')
            section.className = 'info-section'
            section.appendChild(this._sectionTitle('Problem'))

            if(this.summary){
                section.appendChild(this._blockLabel('Summary'))
                section.appendChild(this._blockText(this.summary))
            }
            if(this.description){
                section.appendChild(this._blockLabel('Description'))
                section.appendChild(this._blockText(this.description))
            }
            body.appendChild(section)
        }

        if(this.hasEscalation){
            const section = document.createElement('div')
            section.className = 'info-section'
            section.appendChild(this._sectionTitle('Escalation Instructions'))
            section.appendChild(this._blockText(this.escalation))
            body.appendChild(section)
        }

        if(this.hasCustomFields){
            this.customFieldGroups.forEach(group => {
                const section = document.createElement('div')
                section.className = 'info-section'
                section.appendChild(this._sectionTitle(group.section))

                const list = document.createElement('dl')
                list.className = 'info-list'
                group.fields.forEach(field => {
                    const row = document.createElement('div')
                    row.className = 'info-row'

                    const label = document.createElement('dt')
                    label.className = 'info-row__label'
                    label.textContent = field.fieldName

                    const value = document.createElement('dd')
                    value.className = 'info-row__value'
                    value.textContent = field.value

                    row.appendChild(label)
                    row.appendChild(value)
                    list.appendChild(row)
                })
                section.appendChild(list)
                body.appendChild(section)
            })
        }

        if(this.hasNoContent){
            const section = document.createElement('div')
            section.className = 'info-section'
            const text = this._blockText('No additional details available.')
            text.classList.add('slds-text-color_weak')
            section.appendChild(text)
            body.appendChild(section)
        }
    }

    _sectionTitle(text){
        const title = document.createElement('p')
        title.className = 'info-section__title'
        title.textContent = text
        return title
    }

    _blockLabel(text){
        const label = document.createElement('p')
        label.className = 'info-block__label'
        label.textContent = text
        return label
    }

    _blockText(text){
        const block = document.createElement('p')
        block.className = 'info-block__text'
        block.textContent = text || ''
        return block
    }

    // While open, the body-portaled popover is positioned with fixed viewport coordinates.
    // Any scroll (page or the related-list scroll container) or resize moves the trigger,
    // so re-anchor on those events and close once the trigger scrolls out of view.
    _attachRepositionListeners(){
        if(this._repositionHandler){
            return
        }

        this._repositionHandler = () => {
            if(!this.showPopover || !this._popoverEl?.isConnected || !this._triggerEl?.isConnected){
                return
            }

            const rect = this._triggerEl.getBoundingClientRect()
            if(!this._isTriggerVisible(rect)){
                this._closeNow()
                return
            }

            this._positionAtViewport(this._popoverEl, this._triggerEl)
        }

        // Capture phase catches scrolling on inner scroll containers, not just window.
        window.addEventListener('scroll', this._repositionHandler, true)
        window.addEventListener('resize', this._repositionHandler)
    }

    _detachRepositionListeners(){
        if(!this._repositionHandler){
            return
        }
        window.removeEventListener('scroll', this._repositionHandler, true)
        window.removeEventListener('resize', this._repositionHandler)
        this._repositionHandler = undefined
    }

    // True when the trigger is within the visible viewport (with a small margin).
    _isTriggerVisible(rect){
        return rect.bottom > 0
            && rect.right > 0
            && rect.top < window.innerHeight
            && rect.left < window.innerWidth
    }

    _closeNow(){
        if(this._hideTimeout){
            clearTimeout(this._hideTimeout)
            this._hideTimeout = undefined
        }
        this.showPopover = false
        this._detachRepositionListeners()
        this._clearPortal()
    }

    // Places the popover in true viewport coordinates beside the trigger icon.
    _positionAtViewport(popover, trigger){
        const rect = trigger.getBoundingClientRect()

        let left = rect.left
        let top = rect.bottom - 8

        if(left + POPOVER_WIDTH > window.innerWidth - VIEWPORT_MARGIN){
            left = Math.max(VIEWPORT_MARGIN, rect.right - POPOVER_WIDTH)
        }
        if(left < VIEWPORT_MARGIN){
            left = VIEWPORT_MARGIN
        }

        const popoverHeight = popover.offsetHeight || 280
        if(top + popoverHeight > window.innerHeight - VIEWPORT_MARGIN){
            top = Math.max(VIEWPORT_MARGIN, rect.top - popoverHeight + 8)
        }

        popover.style.position = 'fixed'
        popover.style.top = `${top}px`
        popover.style.left = `${left}px`
        popover.style.width = `${POPOVER_WIDTH}px`
        popover.style.zIndex = '9050'
    }

    _ensurePortal(){
        if(this._portal?.isConnected){
            return
        }

        this._portal = document.createElement('div')
        this._portal.className = 'tsanet-info-popover-portal'
        this._portal.setAttribute('data-tsanet-popover-portal', 'true')
        document.body.appendChild(this._portal)
    }

    _ensureGlobalStyles(){
        if(document.getElementById(STYLE_ID)){
            return
        }

        const style = document.createElement('style')
        style.id = STYLE_ID
        style.textContent = `
            .tsanet-info-popover-portal .info-popover {
                max-height: 60vh;
                overflow-y: auto;
                box-shadow: 0 2px 12px rgba(0, 0, 0, 0.2);
                background-color: #fff;
                border: 1px solid #e5e5e5;
                border-radius: 0.25rem;
                pointer-events: auto;
                user-select: text;
                -webkit-user-select: text;
                cursor: text;
            }
            .tsanet-info-popover-portal .info-popover__header {
                border-bottom: 1px solid #e5e5e5;
                position: sticky;
                top: 0;
                background-color: #fff;
                z-index: 1;
                padding: 0.5rem 1rem;
            }
            .tsanet-info-popover-portal .info-popover__case {
                font-weight: 700;
                font-size: 0.9375rem;
            }
            .tsanet-info-popover-portal .info-section {
                padding: 0.625rem 1rem;
            }
            .tsanet-info-popover-portal .info-section + .info-section {
                border-top: 1px solid #f0f0f0;
            }
            .tsanet-info-popover-portal .info-section__title {
                font-size: 0.6875rem;
                font-weight: 700;
                text-transform: uppercase;
                letter-spacing: 0.06em;
                color: #747474;
                margin: 0 0 0.375rem;
            }
            .tsanet-info-popover-portal .info-row {
                display: flex;
                align-items: baseline;
                gap: 0.5rem;
                padding: 0.125rem 0;
            }
            .tsanet-info-popover-portal .info-row__label {
                flex: 0 0 42%;
                max-width: 42%;
                color: #747474;
                font-size: 0.8125rem;
                margin: 0;
            }
            .tsanet-info-popover-portal .info-row__value {
                flex: 1 1 auto;
                min-width: 0;
                font-size: 0.8125rem;
                color: #181818;
                overflow-wrap: anywhere;
                margin: 0;
                user-select: text;
                -webkit-user-select: text;
            }
            .tsanet-info-popover-portal .info-block__label {
                color: #747474;
                font-size: 0.75rem;
                font-weight: 600;
                margin: 0.375rem 0 0;
            }
            .tsanet-info-popover-portal .info-block__text {
                font-size: 0.8125rem;
                color: #181818;
                white-space: pre-wrap;
                overflow-wrap: anywhere;
                margin: 0 0 0.25rem;
                user-select: text;
                -webkit-user-select: text;
            }
            .tsanet-info-popover-portal .info-list {
                margin: 0;
            }
        `
        document.head.appendChild(style)
    }

    _clearPortal(){
        if(this._popoverEl){
            if(this._portalMouseEnter){
                this._popoverEl.removeEventListener('mouseenter', this._portalMouseEnter)
            }
            if(this._portalMouseLeave){
                this._popoverEl.removeEventListener('mouseleave', this._portalMouseLeave)
            }
            this._popoverEl.remove()
            this._popoverEl = undefined
        }

        if(this._portal){
            this._portal.textContent = ''
        }

        this._portalMouseEnter = undefined
        this._portalMouseLeave = undefined
    }

    _destroyPortal(){
        this._clearPortal()
        if(this._portal?.parentNode){
            this._portal.parentNode.removeChild(this._portal)
        }
        this._portal = undefined
    }

    handleHide(){
        this._hideTimeout = setTimeout(() => {
            this._closeNow()
        }, HIDE_DELAY_MS)
    }

    disconnectedCallback(){
        if(this._hideTimeout){
            clearTimeout(this._hideTimeout)
        }
        this._detachRepositionListeners()
        this._destroyPortal()
    }

    get caseNumber(){ return this.record?.Name }
    get summary(){ return this.record?.tsanetconnect__Summary__c }
    get description(){ return this.record?.tsanetconnect__Description__c }

    get escalation(){
        return this.record?.tsanetconnect__EscalationInstructions__c?.replace(/<[^>]*>/g, '').trim()
    }

    get customFieldGroups(){
        return this.record?.customFieldGroups || []
    }

    get hasProblem(){
        return !!(this.summary || this.description)
    }

    get hasEscalation(){
        return !!this.escalation
    }

    get hasCustomFields(){
        return this.customFieldGroups.length > 0
    }

    get hasNoContent(){
        return !(this.hasProblem || this.hasEscalation || this.hasCustomFields)
    }
}
