//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireLogging

enum JSONValue: Decodable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: DynamicCodingKeys.self) {
            var dict: [String: JSONValue] = [:]
            for key in c.allKeys {
                dict[key.stringValue] = try c.decode(JSONValue.self, forKey: key)
            }
            self = .object(dict)
            return
        }
        if var uc = try? decoder.unkeyedContainer() {
            var arr: [JSONValue] = []
            while !uc.isAtEnd { arr.append(try uc.decode(JSONValue.self)) }
            self = .array(arr)
            return
        }
        let s = try? decoder.singleValueContainer()
        if let v = try? s?.decode(Bool.self) { self = .bool(v); return }
        if let v = try? s?.decode(Double.self) { self = .number(v); return }
        if let v = try? s?.decode(String.self) { self = .string(v); return }
        self = .null
    }

    func toAny() -> Any {
        switch self {
        case .object(let o): return o.mapValues { $0.toAny() }
        case .array(let a):  return a.map { $0.toAny() }
        case .string(let s): return s
        case .number(let n): return n
        case .bool(let b):   return b
        case .null:          return NSNull()
        }
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }
}

extension UpdateEventDecodingProxy {

    init(
        eventType: ConversationEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: ConversationEventCodingKeys.self)

        let json = try JSONValue(from: decoder).toAny()
        if JSONSerialization.isValidJSONObject(json)  {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            if let pretty = String(data: data, encoding: .utf8) {
                WireLogger.notifications.info("Pretty JSON:\n\(pretty)")
            }
        }

        switch eventType {
        case .accessUpdate:
            let event = try ConversationAccessUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.accessUpdate(event))

        case .codeUpdate:
            let event = try ConversationCodeUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.codeUpdate(event))

        case .create:
            let event = try ConversationCreateEventDecoder().decode(from: container)
            updateEvent = .conversation(.create(event))

        case .delete:
            let event = try ConversationDeleteEventDecoder().decode(from: container)
            updateEvent = .conversation(.delete(event))

        case .memberJoin:
            let event = try ConversationMemberJoinEventDecoder().decode(from: container)
            updateEvent = .conversation(.memberJoin(event))

        case .memberLeave:
            let event = try ConversationMemberLeaveEventDecoder().decode(from: container)
            updateEvent = .conversation(.memberLeave(event))

        case .memberUpdate:
            let event = try ConversationMemberUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.memberUpdate(event))

        case .messageTimerUpdate:
            let event = try ConversationMessageTimerUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.messageTimerUpdate(event))

        case .mlsMessageAdd:
            let event = try ConversationMLSMessageAddEventDecoder().decode(from: container)
            updateEvent = .conversation(.mlsMessageAdd(event))

        case .mlsWelcome:
            let event = try ConversationMLSWelcomeEventDecoder().decode(from: container)
            updateEvent = .conversation(.mlsWelcome(event))

        case .otrMessageAdd:
            let event = try ConversationProteusMessageAddEventDecoder().decode(from: container)
            updateEvent = .conversation(.proteusMessageAdd(event))

        case .protocolUpdate:
            let event = try ConversationProtocolUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.protocolUpdate(event))

        case .receiptModeUpdate:
            let event = try ConversationReceiptModeUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.receiptModeUpdate(event))

        case .rename:
            let event = try ConversationRenameEventDecoder().decode(from: container)
            updateEvent = .conversation(.rename(event))

        case .typing:
            let event = try ConversationTypingEventDecoder().decode(from: container)
            updateEvent = .conversation(.typing(event))

        case .addPermissionUpdate:
            let event = try ConversationAddPermissionEventDecoder().decode(from: container)
            updateEvent = .conversation(.permissionUpdate(event))

        case .mlsReset:
            let event = try ConversationMLSResetEventDecoder().decode(from: container)
            updateEvent = .conversation(.mlsReset(event))
        }
    }

}
