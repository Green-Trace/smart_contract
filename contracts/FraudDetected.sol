// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FraudDetection {
    event FraudDetected(
        uint indexed fraudId,
        uint transactionId,
        address reported,
        string fraudType,
        uint timestamp,
        string details,
        address reportedBy,
        bool isChecked
    );
                                                                             
    struct Fraud {
        uint fraudId;
        uint transactionId;
        address reported;
        string fraudType;
        uint timestamp;
        string details;
        address reportedBy;
        bool isChecked;
    }

    uint public fraudCount = 0;
                                                                                 
    mapping(uint => Fraud) public frauds;
    mapping(string => string) public productSeasons;
    mapping(string => uint) public maxAllowedPrices;
                                                                                 

constructor() {
    // Associate products with their seasons
    productSeasons["Potatoes"] = "Fall";
    productSeasons["Tomatoes"] = "Summer";
    productSeasons["Strawberries"] = "Spring";
    productSeasons["Plums"] = "Summer";
    productSeasons["Peaches"] = "Summer";
    productSeasons["Eggplant"] = "Summer";
    productSeasons["Cucumber"] = "Summer";
    productSeasons["Figs"] = "Summer";
    productSeasons["Onions"] = "Fall";
    productSeasons["Apples"] = "Fall";
    productSeasons["Cherries"] = "Spring";
    productSeasons["Broccoli"] = "Fall";
    productSeasons["Grapes"] = "Fall";
    productSeasons["Kiwi"] = "Winter";
    productSeasons["Lemons"] = "Winter";
    productSeasons["Oranges"] = "Winter";
    productSeasons["Spinach"] = "Spring";
    productSeasons["Carrots"] = "Fall";
    productSeasons["Lettuce"] = "Spring";
    productSeasons["Apricots"] = "Spring";

    // Set default maximum allowed prices (values in cents)
    maxAllowedPrices["Potatoes"] = 50; 
    maxAllowedPrices["Tomatoes"] = 70; 
    maxAllowedPrices["Strawberries"] = 100;
    maxAllowedPrices["Plums"] = 90; 
    maxAllowedPrices["Peaches"] = 85; 
    maxAllowedPrices["Eggplant"] = 75; 
    maxAllowedPrices["Cucumber"] = 60; 
    maxAllowedPrices["Figs"] = 120; 
    maxAllowedPrices["Onions"] = 40; 
    maxAllowedPrices["Apples"] = 80; 
    maxAllowedPrices["Cherries"] = 110; 
    maxAllowedPrices["Broccoli"] = 65; 
    maxAllowedPrices["Grapes"] = 95; 
    maxAllowedPrices["Kiwi"] = 130; 
    maxAllowedPrices["Lemons"] = 50; 
    maxAllowedPrices["Oranges"] = 55;
    maxAllowedPrices["Spinach"] = 45;
    maxAllowedPrices["Carrots"] = 35; 
    maxAllowedPrices["Lettuce"] = 30; 
    maxAllowedPrices["Apricots"] = 115;
}

    function getSeason() public view returns (string memory) {
        uint month = (block.timestamp / 30 days) % 12 + 1;
        if (month == 12 || month <= 2) {
            return "Winter";
        } else if (month >= 3 && month <= 5) {
            return "Spring";
        } else if (month >= 6 && month <= 8) {
            return "Summer";
        } else {
            return "Fall";
        }
    }

    function isOutOfSeason(string memory productName) public view returns (bool) {
        string memory currentSeason = getSeason();
        return keccak256(abi.encodePacked(currentSeason)) != keccak256(abi.encodePacked(productSeasons[productName]));
    }

    function detectOutOfSeasonSale(
        uint transactionId,
        address reported,
        string memory productName,
        address reportedBy
    ) public {
        if (isOutOfSeason(productName)) {
            string memory details = string(abi.encodePacked("Product ", productName, " is being sold out of season during ", getSeason(), "."));
            logFraud(transactionId, reported, "Out of Season Sale", details, reportedBy);
        }
    }
    
    function logFraud(
        uint transactionId,
        address reported,
        string memory fraudType,
        string memory details,
        address reportedBy
    ) public {
        fraudCount++;
        frauds[fraudCount] = Fraud(fraudCount, transactionId, reported, fraudType, block.timestamp, details, reportedBy, false);
        emit FraudDetected(fraudCount, transactionId, reported, fraudType, block.timestamp, details, reportedBy, false);
    }



    function detectExpiredProduct(
        uint transactionId,
        address reported,
        string memory productName,
        uint expirationDate,
        address reportedBy
    ) public {
        require(block.timestamp > expirationDate, "Product is not expired yet.");
        string memory details = string(abi.encodePacked("Product ", productName, " with transaction ID ", uint2str(transactionId), " is expired."));
        logFraud(transactionId, reported, "Expired Product", details, reportedBy);
    }

 function detectOverpricedProduct(
    uint transactionId,
    address reported,
    string memory productName,
    uint currentPriceInCents, // Price in cents
    address reportedBy
) public {
    uint maxAllowedPrice = maxAllowedPrices[productName];
    require(currentPriceInCents > maxAllowedPrice, "Product price is not above the allowed limit.");
    string memory details = string(abi.encodePacked(
        "Product ", productName, 
        " with transaction ID ", uint2str(transactionId), 
        " is being sold at an overpriced amount of ", 
        uint2str(currentPriceInCents ), ".00", 
        ". Maximum allowed price is ", 
        uint2str(maxAllowedPrice ), ".00", "."
    ));
    logFraud(transactionId, reported, "Overpriced Product", details, reportedBy);
}

    function detectHealthViolation(
        uint transactionId,
        address reported,
        string memory productName,
        string memory healthIssue,
        address reportedBy
    ) public {
        string memory details = string(abi.encodePacked("Product ", productName, " with transaction ID ", uint2str(transactionId), " has a health violation: ", healthIssue, "."));
        logFraud(transactionId, reported, "Health Violation", details, reportedBy);
    }

    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function getFraud(uint fraudId) public view returns (Fraud memory) {
        return frauds[fraudId];
    }

    function getAllFrauds() public view returns (Fraud[] memory) {
        Fraud[] memory allFrauds = new Fraud[](fraudCount);
        for (uint i = 1; i <= fraudCount; i++) {
            allFrauds[i - 1] = frauds[i];
        }
        return allFrauds;
    }

    function updateFraudStatus(uint fraudId, bool isChecked) public {
        Fraud storage fraud = frauds[fraudId];
        fraud.isChecked = isChecked;
    }

    function setMaxAllowedPrice(string memory productName, uint newMaxPriceInCents) public {
    maxAllowedPrices[productName] = newMaxPriceInCents;
}

function getMaxAllowedPrice(string memory productName) public view returns (uint) {
    return maxAllowedPrices[productName];
}

}
