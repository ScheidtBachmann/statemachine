function getDiagramModel() {
    const state0 = {
        id: 'state0',
        type: 'node:state',
        position: {
            x: 10,
            y: 10
        },
        layout: 'stack',
        layoutOptions: {
            resizeContainer: true,
            paddingLeft: 10,
            paddingRight: 10,
            paddingTop: 8,
            paddingBottom: 8
        },
        children: [
            {
                id: 'state0_name',
                type: 'label:stateLabel',
                text: 'Hello World'
            }/* ,
            {
                id: 'state0_expand',
                type: 'button:expand'
            } */
        ]
    }
    
    return {
        id: 'graph',
        type: 'graph',
        children: [ state0 ],
        layoutOptions: {
            hGap: 5,
            hAlign: 'left',
            paddingLeft: 7,
            paddingRight: 7,
            paddingTop: 7,
            paddingBottom: 7
        }
    };
}