({
    NO_CASE_MESSAGE : 'A TSANet Note can only be created from a TSANet Case. Open the TSANet Case and use New on its TSANet Notes list.',

    /**
     * Resolves the parent TSANet Case Id from, in order: explicit URL params (web link / quick action),
     * the page reference state, and the encoded inContextOfRef of the page the "New" action was launched from.
     * Returns null when no record context is available (e.g. the object list view).
     */
    resolveRecordId : function(cmp) {
        const urlParams = new URLSearchParams(window.location.search)
        const fromUrl = urlParams.get('tsanetconnect__recordId') || urlParams.get('force__recordId')
        if(fromUrl){ return fromUrl }

        const pageRef = cmp.get('v.pageReference')
        const state = (pageRef && pageRef.state) ? pageRef.state : {}

        return this.readRecordIdFromState(state) || this.readRecordIdFromContextRef(state.inContextOfRef)
    },

    /**
     * Decodes a base64url "1.<payload>" inContextOfRef token and returns the record Id of the launching page.
     * Record / related-list pages carry it in attributes.recordId; component pages such as the dynamic
     * related list "View All" (force__dynamicRelatedListViewAll) carry it in state.force__recordId.
     */
    readRecordIdFromContextRef : function(inCtx) {
        if(!inCtx){ return null }
        try {
            let token = decodeURIComponent(inCtx)
            if(token.indexOf('.') > -1){
                token = token.substring(token.indexOf('.') + 1)
            }
            token = token.replace(/-/g, '+').replace(/_/g, '/')
            while(token.length % 4 !== 0){ token += '=' }

            const decoded = atob(token)
            const ctx = JSON.parse(decoded.substring(decoded.indexOf('{'))) || {}
            return (ctx.attributes && ctx.attributes.recordId) || this.readRecordIdFromState(ctx.state)
        } catch(e){
            console.error('Unable to read inContextOfRef: ', e, inCtx)
            return null
        }
    },

    /** Returns the first page-state value whose key is "recordId" or ends with "__recordId" (namespaced), or null. */
    readRecordIdFromState : function(state) {
        if(!state){ return null }
        const key = Object.keys(state).find(k => k === 'recordId' || /__recordId$/.test(k))
        return key ? state[key] : null
    },

    /** Shows an error toast and returns the user to the previous page instead of rendering a broken modal. */
    closeWithError : function(cmp, message) {
        this.toast('Error', 'error', message)
        history.back()
    },

	fetch : function(cmp, method, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            const action = cmp.get(method)
            params && action.setParams(params)
            action.setCallback(this, response => {
                const state = response.getState()
                switch (state) {
                case 'SUCCESS': resolve(response.getReturnValue())
                break
                case 'INCOMPLETE': console.log('INCOMPLETE')
                break
                case 'ERROR': {
                    const errors = response.getError()
                    errors
                    ? reject(errors[0].message)
                    : console.log('Unknown error')
                    break
                }
                default: console.log(state)
            }
                               })
            $A.enqueueAction(action)
        }))
    },
    toast : function(title, type, message) {
        $A.get("e.force:showToast").setParams({ title: title, type: type, message: message }).fire()
    }
})
