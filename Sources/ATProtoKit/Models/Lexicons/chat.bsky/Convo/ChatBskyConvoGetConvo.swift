//
//  ChatBskyConvoGetConvo.swift
//
//
//  Created by Christopher Jr Riley on 2024-05-19.
//

import Foundation

extension ChatBskyLexicon.Conversation {

    /// The data model definition for the output of a message reference.
    ///
    /// - SeeAlso: This is based on the [`chat.bsky.convo.getConvo`][github] lexicon.
    ///
    /// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/chat/bsky/convo/getConvo.json
    public struct GetConversationOutput: Codable {

        /// The conversation itself.
        public let conversation: ConversationView

        enum CodingKeys: String, CodingKey {
            case conversation = "convo"
        }
    }
}
