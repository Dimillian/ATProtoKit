//
//  UpdateCommunicationTemplateAsAdmin.swift
//
//
//  Created by Christopher Jr Riley on 2024-03-03.
//

import Foundation

extension ATProtoKit {
    /// Updates a communication template.
    /// 
    /// - Important: This is a moderator task and as such, regular users won't be able to access this; if they attempt to do so, an error will occur.
    ///
    /// - Note: According to the AT Protocol specifications: "Update the password for a user account as an administrator."
    /// 
    /// - Parameters:
    ///   - id: The ID of the communication template.
    ///   - name: The name of the communication template. Optional.
    ///   - contentMarkdown: The content of the communication template. Optional.
    ///   - subject: The subject line of the message itself. Optional.
    ///   - updatedBy: The decentralized identifier (DID) of the user who updated the communication template. Optional.
    ///   - isDisabled: Indicates whether the communication template is disabled. Optional.
    /// - Returns: A `Result`, containing either an ``OzoneCommunicationTemplateView`` if successful, or an `Error` if not.
    public func updateCommunicationTemplate(_ id: String, name: String?, contentMarkdown: String?, subject: String?, updatedBy: String?,
                                                   isDisabled: Bool?) async throws -> Result<OzoneCommunicationTemplateView, Error> {
        guard let sessionURL = session.pdsURL,
              let requestURL = URL(string: "\(sessionURL)/xrpc/com.atproto.admin.updateCommunicationTemplate") else {
            return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }

        let requestBody = AdminUpdateCommunicationTemplate(
            id: id, name: name, contentMarkdown: contentMarkdown,
            subject: subject, updatedBy: updatedBy, isDisabled: isDisabled
        )

        do {
            let request = APIClientService.createRequest(forRequest: requestURL,
                                                         andMethod: .post,
                                                         acceptValue: "application/json",
                                                         contentTypeValue: "application/json",
                                                         authorizationValue: "Bearer \(session.accessToken)")
            let response = try await APIClientService.sendRequest(request, withEncodingBody: requestBody, decodeTo: OzoneCommunicationTemplateView.self)

            return .success(response)
        } catch {
            return .failure(error)
        }
    }
}