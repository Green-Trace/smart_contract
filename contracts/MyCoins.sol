// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;
contract MyCoin  {
mapping(address => uint) public balanceOf;
mapping(address=>toSend) public balanceToSend;
mapping(address=>toReceive) public balanceToReceive;
struct toSend{
mapping (string => uint) keyAmount;
uint total;
}
struct toReceive{
mapping (string => uint) keyAmount;
uint total;
}

function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function getHash(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
        
    } 
    function getEthSignedHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    function verify(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    function splitSignature(bytes memory sig) internal pure returns ( bytes32, bytes32,uint8)
    {
    require(sig.length == 65);
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
        
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
    }
    return (r, s, v);
    }

function transfert(address receiver,uint amount) public returns(bool){
    balanceOf[msg.sender]-=amount;
    balanceOf[receiver]+=amount;
    return true;
}

function mint(uint amount) public {
    balanceOf[msg.sender]+=amount;
}

function mintAddress(address owner,uint amount) public {
    balanceOf[owner]+=amount;
}

function transfertWithSignature
(address receiver,address sender,bytes memory _signature,uint productId) public returns(bool){
    bytes32 hash = getHash(toString(productId));
    bytes32 ethSignHash = getEthSignedHash(hash);
    address signerAddress = verify(ethSignHash, _signature);
    //ProductData memory product= productsData[productId];
    //address wholeSalerOwner = product.owner;
    // require(signerAddress==wholeSalerOwner, "invalide signature");
    require(signerAddress== sender,"signer are not the sender in input");
    balanceOf[receiver]+=balanceToReceive[receiver].keyAmount[toString(productId)];
    balanceToReceive[receiver].total-=balanceToReceive[receiver].keyAmount[toString(productId)];
    balanceToReceive[receiver].keyAmount[toString(productId)]=0;
    balanceToSend[sender].total-=balanceToSend[sender].keyAmount[toString(productId)];
    balanceToSend[sender].keyAmount[toString(productId)]=0;
    return true;
}

function blockAmount(address receiver,address sender,uint productId ,uint amount) public {
require(balanceOf[sender]>= amount,"you dont have money");
balanceOf[sender]-=amount;
balanceToReceive[receiver].total+=amount;
balanceToReceive[receiver].keyAmount[toString(productId)]=amount;
balanceToSend[sender].keyAmount[toString(productId)]=amount;
balanceToSend[sender].total+=amount;

}

function balance(address retailerAddr) public view returns ( uint ){
        return balanceOf[retailerAddr];
    }
    function balanceToReceiveBlocked(address retailerAddr) public view returns ( uint){
        return balanceToReceive[retailerAddr].total ;
    }
    function balanceToSendBlocked(address retailerAddr) public view returns ( uint){
        return balanceToSend[retailerAddr].total ;
    }

}