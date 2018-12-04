/********************************************************************************
 * Copyright (c) 2017-2018 TypeFox and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 ********************************************************************************/

import { injectable } from "inversify";
import {
    SModelElementSchema, SModelRootSchema, RequestPopupModelAction, PreRenderedElementSchema, IPopupModelProvider
} from "sprotty/lib";

@injectable()
export class PopupModelProvider implements IPopupModelProvider {

    getPopupModel(request: RequestPopupModelAction, element?: SModelElementSchema): SModelRootSchema | undefined {
        if (element !== undefined && element.type === 'node:class') {
            return {
                type: 'html',
                id: 'popup',
                children: [
                    <PreRenderedElementSchema> {
                        type: 'pre-rendered',
                        id: 'popup-title',
                        code: `<div class="sprotty-popup-title">Popup title</div>`
                    },
                    <PreRenderedElementSchema> {
                        type: 'pre-rendered',
                        id: 'popup-body',
                        code: '<div class="sprotty-popup-body">Popup info.</div>'
                    }
                ]
            };
        }
        return undefined;
    }

}
