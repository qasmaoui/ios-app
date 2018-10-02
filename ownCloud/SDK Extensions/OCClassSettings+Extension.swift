//
//  OCClassSettings+Extension.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 02/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK

extension OCClassSettingsSupport where Self: NSObject & OCClassSettingsSupport {

	 func setting<T>(as type: T.Type, for key: OCClassSettingsKey) -> T? {
		 return self.classSetting(forOCClassSettingsKey: key) as? T
	}
}
