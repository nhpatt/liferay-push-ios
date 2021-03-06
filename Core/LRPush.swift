/**
* Copyright (c) 2000-present Liferay, Inc. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/

/**
* @author Bruno Farache
*/
open class LRPush {

	open static let PAYLOAD = "payload"

	var failure: LRFailureBlock?
	var pushNotification: (([String: AnyObject]) -> ())?
	let session: LRSession
	var success: (([String: AnyObject]?) -> ())?

	open class func withSession(_ session: LRSession) -> LRPush {
		return LRPush(session: session)
	}

	init(session: LRSession) {
		self.session = LRSession(session: session)

		self.session.onSuccess({ result in
			self.success?(result as? [String: AnyObject])
		},
		onFailure: { error in
			self.failure?(error)
		})
	}

	open func didReceiveRemoteNotification(
		_ pushNotification: [String: AnyObject]) {

		var mutablePushNotification = pushNotification

		do {
			let payload = try parse(pushNotification[LRPush.PAYLOAD] as! String)
			mutablePushNotification[LRPush.PAYLOAD] = payload as AnyObject?
			self.pushNotification?(mutablePushNotification)
		}
		catch let error as NSError {
			failure?(error)
		}
	}

	open func onFailure(_ failure: @escaping LRFailureBlock) -> Self {
		self.failure = failure

		return self
	}

	open func onPushNotification(
		_ pushNotification: @escaping (([String: AnyObject]) -> ()))-> Self {

		self.pushNotification = pushNotification

		return self
	}

	open func onSuccess(_ success: @escaping (([String: AnyObject]?)
		-> ())) -> Self {
		
		self.success = success

		return self
	}

	open func registerDevice() {
		let application = UIApplication.shared

		let types: UIUserNotificationType = [.badge, .sound, .alert]
		let settings = UIUserNotificationSettings.init(
			types: types, categories: nil)

		application.registerUserNotificationSettings(settings);
		application.registerForRemoteNotifications()
	}

	open func registerDeviceTokenData(_ deviceTokenData: Data) {
		var deviceToken = ""
		let bytes = UnsafeMutablePointer<CUnsignedChar>.allocate(
			capacity: deviceTokenData.count)

		bytes.initialize(from: deviceTokenData)

		for i in 0 ..< deviceTokenData.count {
			deviceToken += String(format: "%02X", bytes[i])
		}

		registerDeviceToken(deviceToken)
	}

	open func registerDeviceToken(_ deviceToken: String) {
		do {
			try getService().addPushNotificationsDevice(
				withToken: deviceToken, platform: _APPLE)
		}
		catch {
		}
	}

	open func sendToUserId(_ userId: Int, notification: [String: AnyObject]) {
		sendToUserId([userId], notification: notification)
	}

	open func sendToUserId(
		_ userIds: [Int], notification: [String: AnyObject]) {

		do {
			let data = try JSONSerialization.data(
				withJSONObject: notification,
				options: JSONSerialization.WritingOptions())

			let payload = String(
				data: data, encoding: String.Encoding.utf8)

			var error: NSError?

			getService().sendPushNotificationWith(
				toUserIds: userIds, payload: payload, error: &error)
		}
		catch let error as NSError {
			failure?(error)
		}
	}

	open func unregisterDeviceToken(_ deviceToken: String) {
		do {
			try getService().deletePushNotificationsDevice(
				withToken: deviceToken)
		}
		catch {
		}
	}

	fileprivate func getService() -> LRPushNotificationsDeviceService_v62 {
		return LRPushNotificationsDeviceService_v62(session: session)
	}

	fileprivate func parse(_ payload: String) throws
		-> [String: AnyObject] {

		let data = payload.data(using: String.Encoding.utf8)!

			return try JSONSerialization.jsonObject(
				with: data,
				options: JSONSerialization.ReadingOptions.mutableContainers)
			as! [String: AnyObject]
	}

	fileprivate let _APPLE = "apple"

}