// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;

import "./MyCoins.sol";

contract SupplyChain {
    event ProductLocation(uint indexed productId, string location);
    event ProductAdded(address indexed owner, uint productId);
    event ProductBuyed(address indexed owner, address indexed receiver, uint productId);

    uint public finalID = 1000; 
    string[] public productTypes = [
        "Potatoes", "Tomatoes", "Strawberries", "Plums", "Peaches", "Eggplant", 
        "Cucumber", "Figs", "Onions", "Apples", "Cherries", "Broccoli", 
        "Grapes", "Kiwi", "Lemons", "Oranges", "Spinach", "Carrots", 
        "Lettuce", "Apricots"
    ];



    

    mapping(uint => productListData) farmersProductByType;
    mapping(uint => productListData) wholesalersProductByType;
    mapping(uint => productListData) retailersProductByType;
    mapping(uint => ProductData) public productsData;
    mapping(address => farmersData) farmers;
    mapping(address => wholeSalerRetailerData) wholesalers;
    mapping(address => wholeSalerRetailerData) retailers;
    mapping(address => customerData) customers;
    mapping(address => string) public usersJobType;

    struct customerData {
        uint[] history;
        uint[] toReceive;
    }

    struct farmersData {
        uint[] productForSale;
        uint[] history;
        uint[] toSend;
    }

    struct wholeSalerRetailerData {
        uint[] productForSale;
        uint[] history;
        uint[] stock;
        uint[] toReceive;
        uint[] toSend;
    }

    struct productListData {
        uint[] productList;
    }

    struct ProductData {
        address owner;
        uint parent;
        uint productType;
        uint amount;
        uint amountRemaining;
        bool isForSale;
        uint price;
        uint minQuantity;
        uint date;
        uint expiredDate; // New field added
    }

    function getHa(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    function indexInListProduct(string memory productType) public view returns (uint) {
        bool bol;
        uint ind;
        (bol, ind) = retreiveIndexString(productTypes, productType);
        return ind;
    }

    function farmerConfirmSending(uint productId, bytes memory signature, address coinAddress) public {
        ProductData memory product = productsData[productId];
        address wholeSalerOwner = product.owner;
        ProductData memory parentProduct = productsData[product.parent];
        address farmerBuyer = parentProduct.owner;
        MyCoin(coinAddress).transfertWithSignature(farmerBuyer, wholeSalerOwner, signature, productId);

        bool bol;
        uint ind;
        bool bool2;
        uint ind2;
        (bol, ind) = retreiveIndex(farmers[farmerBuyer].toSend, productId);
        (bool2, ind2) = retreiveIndex(wholesalers[wholeSalerOwner].toReceive, productId);
        if (bol && bol) {
            farmers[farmerBuyer].toSend[ind] = farmers[farmerBuyer].toSend[farmers[farmerBuyer].toSend.length - 1];
            farmers[farmerBuyer].toSend.pop(); 
            wholesalers[wholeSalerOwner].toReceive[ind] = wholesalers[wholeSalerOwner].toReceive[wholesalers[wholeSalerOwner].toReceive.length - 1];
            wholesalers[wholeSalerOwner].toReceive.pop();
            wholesalers[wholeSalerOwner].stock.push(productId);
            emit ProductBuyed(msg.sender, product.owner, productId);  
        }
    }

    function wholeSalerConfirmSending(uint productId, bytes memory signature, address coinAddress) public { 
        ProductData memory product = productsData[productId];
        address RetailerOwner = product.owner;
        ProductData memory parentProduct = productsData[product.parent];
        address wholeSalerBuyer = parentProduct.owner;
        MyCoin(coinAddress).transfertWithSignature(wholeSalerBuyer, RetailerOwner, signature, productId);

        bool bol;
        uint ind;
        bool bool2;
        uint ind2;
        (bol, ind) = retreiveIndex(wholesalers[wholeSalerBuyer].toSend, productId);
        (bool2, ind2) = retreiveIndex(retailers[RetailerOwner].toReceive, productId);
        if (bol && bol) {
            wholesalers[wholeSalerBuyer].toSend[ind] = wholesalers[wholeSalerBuyer].toSend[wholesalers[wholeSalerBuyer].toSend.length - 1];
            wholesalers[wholeSalerBuyer].toSend.pop(); 
            retailers[RetailerOwner].toReceive[ind] = retailers[RetailerOwner].toReceive[retailers[RetailerOwner].toReceive.length - 1];
            retailers[RetailerOwner].toReceive.pop();
            retailers[RetailerOwner].stock.push(productId); 
            emit ProductBuyed(msg.sender, product.owner, productId);
        }
    }

    function retailerConfirmSending(uint productId, bytes memory signature, address coinAddress) public { 
        ProductData memory product = productsData[productId];
        address customerOwner = product.owner;
        ProductData memory parentProduct = productsData[product.parent];
        address retailerBuyer = parentProduct.owner;
        MyCoin(coinAddress).transfertWithSignature(retailerBuyer, customerOwner, signature, productId);

        bool bol;
        uint ind;
        bool bool2;
        uint ind2;
        (bol, ind) = retreiveIndex(retailers[retailerBuyer].toSend, productId);
        (bool2, ind2) = retreiveIndex(customers[customerOwner].toReceive, productId);
        if (bol && bol) {
            retailers[retailerBuyer].toSend[ind] = retailers[retailerBuyer].toSend[retailers[retailerBuyer].toSend.length - 1];
            retailers[retailerBuyer].toSend.pop(); 
            customers[customerOwner].toReceive[ind] = customers[customerOwner].toReceive[customers[customerOwner].toReceive.length - 1];
            customers[customerOwner].toReceive.pop();
            emit ProductBuyed(msg.sender, product.owner, productId); 
        }
    }

    function buyProductWholesaler(uint productId, uint amount, address coinAddress) public {
        finalID++;
        ProductData memory parentProduct = productsData[productId];
        MyCoin(coinAddress).blockAmount(parentProduct.owner, msg.sender, finalID, amount * parentProduct.price);
        productsData[productId].amountRemaining -= amount;
        uint parent = productId;
        productsData[finalID] = ProductData({
            owner: msg.sender,
            parent: parent,
            productType: parentProduct.productType,
            amount: amount,
            amountRemaining: amount,
            isForSale: false,
            price: 0,
            minQuantity: 0,
            date: block.timestamp,
            expiredDate: parentProduct.expiredDate // Copy the expiredDate from the parent product
        });
        wholesalers[msg.sender].toReceive.push(finalID);
        farmers[parentProduct.owner].toSend.push(finalID);
        if (productsData[productId].minQuantity > productsData[productId].amountRemaining) {
            productsData[productId].minQuantity = productsData[productId].amountRemaining;
        }
        if (productsData[productId].amountRemaining == 0) {
            bool bol;
            uint ind;
            bool bool2;
            uint ind2;
            (bol, ind) = retreiveIndex(farmers[productsData[productId].owner].productForSale, productId);
            (bool2, ind2) = retreiveIndex(farmersProductByType[productsData[productId].productType].productList, productId);
            if (bol) {
                farmers[productsData[productId].owner].productForSale[ind] = farmers[productsData[productId].owner].productForSale[farmers[productsData[productId].owner].productForSale.length - 1];
                farmers[productsData[productId].owner].productForSale.pop();
            }
            if (bool2) {
                farmersProductByType[productsData[productId].productType].productList[ind2] = farmersProductByType[productsData[productId].productType].productList[farmersProductByType[productsData[productId].productType].productList.length - 1];
                farmersProductByType[productsData[productId].productType].productList.pop();  
            }
        }    
    }

    function buyProductRetailer(uint productId, uint amount, address coinAddress) public {
        finalID++;
        ProductData memory parentProduct = productsData[productId];
        MyCoin(coinAddress).blockAmount(parentProduct.owner, msg.sender, finalID, amount * parentProduct.price);
        productsData[productId].amountRemaining -= amount;
        uint parent = productId;
        productsData[finalID] = ProductData({
            owner: msg.sender,
            parent: parent,
            productType: parentProduct.productType,
            amount: amount,
            amountRemaining: amount,
            isForSale: false,
            price: 0,
            minQuantity: 0,
            date: block.timestamp,
            expiredDate: parentProduct.expiredDate // Copy the expiredDate from the parent product
        });
        retailers[msg.sender].stock.push(finalID);
        retailers[msg.sender].toReceive.push(finalID);
        wholesalers[parentProduct.owner].toSend.push(finalID);
        if (productsData[productId].minQuantity > productsData[productId].amountRemaining) {
            productsData[productId].minQuantity = productsData[productId].amountRemaining;
        }
        if (productsData[productId].amountRemaining == 0) {
            bool bol;
            uint ind;
            bool bool2;
            uint ind2;
            (bol, ind) = retreiveIndex(wholesalers[productsData[productId].owner].productForSale, productId);
            (bool2, ind2) = retreiveIndex(wholesalersProductByType[productsData[productId].productType].productList, productId);
            if (bol) {
                wholesalers[productsData[productId].owner].productForSale[ind] = wholesalers[productsData[productId].owner].productForSale[wholesalers[productsData[productId].owner].productForSale.length - 1];
                wholesalers[productsData[productId].owner].productForSale.pop();
            }
            if (bool2) {
                wholesalersProductByType[productsData[productId].productType].productList[ind2] = wholesalersProductByType[productsData[productId].productType].productList[wholesalersProductByType[productsData[productId].productType].productList.length - 1];
                wholesalersProductByType[productsData[productId].productType].productList.pop();  
            }
        }  
    }

    function buyProductCustomers(uint productId, uint amount, address coinAddress) public {
        finalID++;
        ProductData memory parentProduct = productsData[productId];
        MyCoin(coinAddress).blockAmount(parentProduct.owner, msg.sender, finalID, amount * parentProduct.price);
        productsData[productId].amountRemaining -= amount;
        uint parent = productId;
        productsData[finalID] = ProductData({
            owner: msg.sender,
            parent: parent,
            productType: parentProduct.productType,
            amount: amount,
            amountRemaining: amount,
            isForSale: false,
            price: 0,
            minQuantity: 0,
            date: block.timestamp,
            expiredDate: parentProduct.expiredDate // Copy the expiredDate from the parent product
        });
        customers[msg.sender].toReceive.push(finalID);
        retailers[parentProduct.owner].toSend.push(finalID);
        if (productsData[productId].minQuantity > productsData[productId].amountRemaining) {
            productsData[productId].minQuantity = productsData[productId].amountRemaining;
        }
        if (productsData[productId].amountRemaining == 0) {
            bool bol;
            uint ind;
            bool bool2;
            uint ind2;
            (bol, ind) = retreiveIndex(retailers[productsData[productId].owner].productForSale, productId);
            (bool2, ind2) = retreiveIndex(retailersProductByType[productsData[productId].productType].productList, productId);
            if (bol) {
                retailers[productsData[productId].owner].productForSale[ind] = retailers[productsData[productId].owner].productForSale[retailers[productsData[productId].owner].productForSale.length - 1];
                retailers[productsData[productId].owner].productForSale.pop();
            }
            if (bool2) {
                retailersProductByType[productsData[productId].productType].productList[ind2] = retailersProductByType[productsData[productId].productType].productList[retailersProductByType[productsData[productId].productType].productList.length - 1];
                retailersProductByType[productsData[productId].productType].productList.pop();  
            }
        }   
    }

    function farmersProductsListe(string memory pproductType) public view returns (uint[] memory) {
        uint ind = indexInListProduct(pproductType);
        return farmersProductByType[ind].productList;
    }

    function wholesalersProductsListe(string memory pproductType) public view returns (uint[] memory) {
        uint ind = indexInListProduct(pproductType);
        return wholesalersProductByType[ind].productList;
    }

    function retailersProductsListe(string memory pproductType) public view returns (uint[] memory) {
        uint ind = indexInListProduct(pproductType);
        return retailersProductByType[ind].productList;
    }

    function farmersProductsPersonal(address theFarmer, uint listType) public view returns (uint[] memory) {
        if (listType == 1) {
            return farmers[theFarmer].productForSale;
        } else if (listType == 3) {
            return farmers[theFarmer].toSend;
        }
        return new uint[](0) ;
    }

    function wholeSalerProductsPersonal(address wholeSaerAddr, uint listType) public view returns (uint[] memory) {
        if (listType == 1) {
            return wholesalers[wholeSaerAddr].productForSale;
        } else if (listType == 2) {
            return wholesalers[wholeSaerAddr].stock;
        } else if (listType == 3) {
            return wholesalers[wholeSaerAddr].toSend;
        } else if (listType == 4) {
            return wholesalers[wholeSaerAddr].toReceive;
        }
        return new uint[](0) ;
    }

    function retailerProductsPersonal(address retailerAddr, uint listType) public view returns (uint[] memory) {
        if (listType == 1) {
            return retailers[retailerAddr].productForSale;
        } else if (listType == 2) {
            return retailers[retailerAddr].stock;
        } else if (listType == 3) {
            return retailers[retailerAddr].toSend;
        } else if (listType == 4) {
            return retailers[retailerAddr].toReceive;
        }
        return new uint[](0) ;
    }

    function customerProductsPersonal(address theCustomer, uint listType) public view returns (uint[] memory) {
        if (listType == 4) {
            return customers[theCustomer].toReceive;
        }
        return new uint[](0) ;
    }

    function modifyProduct(uint productId, uint amount, uint price, uint minQuantity, uint expiredDate) public {
        // require(msg.sender == productsData[productId].owner, "You are not the owner");
        productsData[productId].price = price;
        productsData[productId].amountRemaining = amount;
        productsData[productId].minQuantity = minQuantity;
        productsData[productId].expiredDate = expiredDate;
    }

    function farmerAddProduct(string memory pproductType, uint amount, uint price, uint minQuantity, string memory location, uint expiredDate) public {
        finalID++;
        uint ind = indexInListProduct(pproductType);
        farmersProductByType[ind].productList.push(finalID);

        productsData[finalID] = ProductData({
            owner: msg.sender,
            parent: 0,
            productType: ind,
            amount: amount,
            amountRemaining: amount,
            isForSale: true,
            price: price,
            minQuantity: minQuantity,
            date: block.timestamp,
            expiredDate: expiredDate
        });
        farmers[msg.sender].productForSale.push(finalID);
        emit ProductAdded(msg.sender, finalID);
        emit ProductLocation(finalID, location);
    }
    
    function wholeSalerFromStockToSale(uint productId, uint price, uint minQuantity, string memory _location, uint expiredDate) public {
        bool bol;
        uint ind;
        productsData[productId].price = price;
        productsData[productId].expiredDate = expiredDate;
        emit ProductLocation(productId, _location);

        productsData[productId].isForSale = true;
        productsData[productId].minQuantity = minQuantity;
        (bol, ind) = retreiveIndex(wholesalers[msg.sender].stock, productId);
        if (bol) {
            wholesalers[msg.sender].stock[ind] = wholesalers[msg.sender].stock[wholesalers[msg.sender].stock.length - 1];
            wholesalers[msg.sender].stock.pop();
            wholesalers[msg.sender].productForSale.push(productId);
            wholesalersProductByType[productsData[productId].productType].productList.push(productId);
        }
        emit ProductAdded(msg.sender, productId);
    }
 function retailerFromStockToSale(uint productId,uint price,uint minQuantity,string memory _location, uint expiredDate)public {
        bool bol;
        uint ind;
        productsData[productId].price = price;
          productsData[productId].expiredDate = expiredDate;
        emit  ProductLocation(productId, _location);
        
        productsData[productId].isForSale= true;
        productsData[productId].minQuantity = minQuantity;
        (bol,ind)=retreiveIndex(retailers[msg.sender].stock,productId);
        if (bol){
            retailers[msg.sender].stock[ind]=retailers[msg.sender].stock[retailers[msg.sender].stock.length-1];
            retailers[msg.sender].stock.pop();
            retailers[msg.sender].productForSale.push(productId);
            retailersProductByType[productsData[productId].productType].productList.push(productId);
        }

        emit ProductAdded(msg.sender,productId);
    }


  function wholeSalerStock(address wholeSaerAddr) public view returns ( uint[] memory){
        return wholesalers[wholeSaerAddr].stock ;
    }

    function wholeSalerToSend(address wholeSaerAddr) public view returns ( uint[] memory){
        return wholesalers[wholeSaerAddr].toSend ;
    }
    function wholeSalerToReceive(address wholeSaerAddr) public view returns ( uint[] memory){
        return wholesalers[wholeSaerAddr].toReceive ;
    }
    
    function retailerToSend(address retailerAddr) public view returns ( uint[] memory){
        return retailers[retailerAddr].toSend ;
    }
    function retailerToReceive(address retailerAddr) public view returns ( uint[] memory){
        return retailers[retailerAddr].toReceive ;
    }
     function customersToReceive(address theCustomer) public view returns ( uint[] memory){
        return customers[theCustomer].toReceive;
    }
   
    function wholeSalerproductsForSale(address wholeSaerAddr) public view returns ( uint[] memory){
        return wholesalers[wholeSaerAddr].productForSale ;
    }
     function wholeSalerHistory(address wholeSaerAddr) public view returns ( uint[] memory){
        return wholesalers[wholeSaerAddr].history ;
    }
    function retailerStock(address retailerAddr) public view returns ( uint[] memory){
        return retailers[retailerAddr].stock ;
    }
    function retailersproductsForSale(address retailerAddr) public view returns ( uint[] memory){
        return retailers[retailerAddr].productForSale ;
    }
    function retailerHistory(address retailerAddr) public view returns ( uint[] memory){
        return retailers[retailerAddr].history ;
    }
    function farmersProductsForSale(address theFarmer) public view returns ( uint[] memory){
        return farmers[theFarmer].productForSale;
    }
    function farmersHistory(address theFarmer) public view returns ( uint[] memory){
        return farmers[theFarmer].history;
    }
     function farmersToSend(address theFarmer) public view returns ( uint[] memory){
        return farmers[theFarmer].toSend;
    }
    function customersHistory(address theCustomer) public view returns ( uint[] memory){
        return customers[theCustomer].history;
    }
   


    function retreiveIndex(uint[] memory list, uint value) public pure returns (bool b, uint u) {
        uint j = 0;
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == value) {
                b = true;
                u = i;
                break;
            }  
            j++;
        }
        if (j == list.length) {
            b = false;
            u = j;
        }
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function retreiveIndexString(string[] memory list, string memory value) public pure returns (bool b, uint u) {
        uint j = 0;
        for (uint i = 0; i < list.length; i++) {
            if (compareStrings(list[i], value)) {
                b = true;
                u = i;
                break;
            }  
            j++;
        }
        if (j == list.length) {
            b = false;
            u = j;
        }
    }

    function productDatafromList(uint[] memory _productsId) public view returns (ProductData[] memory) {
        ProductData[] memory productssData = new ProductData[](_productsId.length);
        for (uint i = 0; i < _productsId.length; i++) {
            ProductData storage productProgress = productsData[_productsId[i]];
            productssData[i] = productProgress;
        }
        return productssData;
    }
}
