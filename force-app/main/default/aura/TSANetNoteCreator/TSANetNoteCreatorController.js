({
	init : function(cmp, event, helper) {

        const urlParams = new URLSearchParams(window.location.search);
        let recordId = urlParams.get('tsanetconnect__recordId');

        if(!recordId){
            recordId = urlParams.get('force__recordId')
        }

        if(recordId){
            cmp.set('v.recordId', recordId)
        } else {

            const pageRef = cmp.get("v.pageReference");
            const state = (pageRef && pageRef.state) ? pageRef.state : {};
            const inCtx = state.inContextOfRef;

            if (!inCtx) return;

            try {
                let token = decodeURIComponent(inCtx);

                if (token.indexOf('.') > -1) {
                    token = token.substring(token.indexOf('.') + 1);
                }

                token = token.replace(/-/g, '+').replace(/_/g, '/');

                while (token.length % 4 !== 0) {
                    token += '=';
                }
                const decoded = atob(token);
                // decoded виглядає як JSON або як "...{json}"
                const jsonStr = decoded.substring(decoded.indexOf('{'));
                const ctx = JSON.parse(jsonStr);

                const parentId = ctx.attributes.recordId;

                if(parentId){
                    cmp.set("v.recordId", parentId);
                }

            } catch (e) {
                console.error('error: ', e, inCtx);
            }
        }

        cmp.set('v.isLoaded', false)
        helper.fetch(cmp, 'c.getTSANetInfo', { recordId: cmp.get('v.recordId') }).then(data => {
            cmp.set('v.record', data.record)
            cmp.set('v.state', data)
            cmp.set('v.isLoaded', true)
        })
	},

    close : function(){
        history.back()
        $A.get('e.force:refreshView').fire();
    }
})