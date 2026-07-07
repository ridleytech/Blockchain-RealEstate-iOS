//
//  Blockchain_RealEstate_iOSTests.swift
//  Blockchain-RealEstate-iOSTests
//
//  Created by Randall Ridley on 7/7/26.
//

import XCTest
@testable import Blockchain_RealEstate_iOS

final class Blockchain_RealEstate_iOSTests: XCTestCase {

    func testPropertyImageDecodesFromString() throws {
        let json = "\"/assets/properties/house.jpg\""
        let data = try XCTUnwrap(json.data(using: .utf8))
        let image = try JSONDecoder().decode(PropertyImage.self, from: data)

        XCTAssertEqual(image.url, "/assets/properties/house.jpg")
        XCTAssertNil(image.isMain)
    }

    func testPropertyImageDecodesFromObject() throws {
        let json = """
        {"url":"/assets/properties/main.jpg","isMain":true}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let image = try JSONDecoder().decode(PropertyImage.self, from: data)

        XCTAssertEqual(image.url, "/assets/properties/main.jpg")
        XCTAssertEqual(image.isMain, true)
    }

    func testPropertyDecodesLossyNumberTypes() throws {
        let json = """
        {
          "_id": "p1",
          "title": "Test Property",
          "price": "1250000",
          "sharePrice": 250.5,
          "totalShares": "100",
          "availableShares": 75,
          "bedrooms": "3",
          "bathrooms": 2,
          "yearBuilt": "1999",
          "squareFeet": "1234.5"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let property = try JSONDecoder().decode(Property.self, from: data)

        XCTAssertEqual(property.id, "p1")
        XCTAssertEqual(property.price, 1_250_000)
        XCTAssertEqual(property.sharePrice, 250.5)
        XCTAssertEqual(property.totalShares, 100)
        XCTAssertEqual(property.availableShares, 75)
        XCTAssertEqual(property.bedrooms, 3)
        XCTAssertEqual(property.bathrooms, 2)
        XCTAssertEqual(property.yearBuilt, 1999)
        XCTAssertEqual(property.squareFeet, 1234.5)
    }

    func testPropertyComputedSoldSharesAndProgress() throws {
        let json = """
        {
          "_id": "p1",
          "totalShares": 100,
          "availableShares": 40
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let property = try JSONDecoder().decode(Property.self, from: data)

        XCTAssertEqual(property.soldShares, 60)
        XCTAssertEqual(property.soldProgress, 0.6, accuracy: 0.0001)
    }

    func testPropertyPrimaryImageURLUsesAbsoluteURLIfProvided() throws {
        let json = """
        {
          "_id": "p1",
          "images": [
            {"url":"https://example.com/a.jpg","isMain":true}
          ]
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let property = try JSONDecoder().decode(Property.self, from: data)

        XCTAssertEqual(property.primaryImageURL?.absoluteString, "https://example.com/a.jpg")
    }

    func testPropertyPrimaryImageURLBuildsRelativeURLFromBase() throws {
        let json = """
        {
          "_id": "p1",
          "images": [
            "/assets/properties/a.jpg"
          ]
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let property = try JSONDecoder().decode(Property.self, from: data)

        XCTAssertEqual(property.primaryImageURL?.absoluteString, "http://localhost:4000/images/assets/properties/a.jpg")
    }

    func testAPIErrorDescriptions() {
        XCTAssertEqual(APIError.invalidResponse.errorDescription, "Invalid server response")
        XCTAssertEqual(APIError.httpError(404).errorDescription, "Request failed (HTTP 404)")
        XCTAssertEqual(APIError.decodingError(nil).errorDescription, "Failed to decode server response")
        XCTAssertEqual(
            APIError.decodingError("oops").errorDescription,
            "Failed to decode server response. Body preview: oops"
        )
    }
}
