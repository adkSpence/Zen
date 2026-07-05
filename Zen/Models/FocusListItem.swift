import Foundation
import SwiftData

@Model final class FocusListItem {
    var text: String
    var isDone: Bool
    var createdAt: Date
    var order: Int
    var sessionScopeID: UUID?

    init(text: String,
         isDone: Bool = false,
         createdAt: Date = .now,
         order: Int = 0,
         sessionScopeID: UUID? = nil) {
        self.text = text
        self.isDone = isDone
        self.createdAt = createdAt
        self.order = order
        self.sessionScopeID = sessionScopeID
    }
}
