//
//  FindRelatedAccountsAsAdmin.swift
//
//
//  Created by Christopher Jr Riley on 2024-10-24.
//

import Foundation

extension ATProtoAdmin {

    /// Gets user accounts that match threat signatures with the root
    /// user account as a moderator.
    ///
    /// - Note: According to the AT Protocol specifications: "Get accounts that share some matching
    /// threat signatures with the root account."
    ///
    /// - SeeAlso: This is based on the [`tools.ozone.signature.findRelatedAccounts`][github] lexicon.
    ///
    /// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/tools/ozone/signature/findRelatedAccounts.json
    ///
    public func findRelatedAccount(
        did: String,
        cursor: String? = nil,
        limit: Int? = 50
    ) async throws -> ToolsOzoneLexicon.Signature.FindRelatedAccountsOutput {
        guard session != nil,
              let accessToken = session?.accessToken else {
            throw ATRequestPrepareError.missingActiveSession
        }

        guard let sessionURL = session?.pdsURL,
              let requestURL = URL(string: "\(sessionURL)/xrpc/tools.ozone.signature.findRelatedAccounts") else {
            throw ATRequestPrepareError.invalidRequestURL
        }

        var queryItems = [(String, String)]()

        queryItems = [("did", did)]

        if let cursor {
            queryItems.append(("cursor", cursor))
        }

        if let limit {
            let finalLimit = max(1, min(limit, 100))
            queryItems.append(("limit", "\(finalLimit)"))
        }

        let queryURL: URL

        do {
            queryURL = try APIClientService.setQueryItems(
                for: requestURL,
                with: queryItems
            )

            let request = APIClientService.createRequest(
                forRequest: queryURL,
                andMethod: .get,
                acceptValue: "application/json",
                contentTypeValue: nil,
                authorizationValue: "Bearer \(accessToken)"
            )
            let response = try await APIClientService.shared.sendRequest(
                request,
                decodeTo: ToolsOzoneLexicon.Signature.FindRelatedAccountsOutput.self
            )

            return response
        } catch {
            throw error
        }
    }
}