pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Operatable - Base contract which allows primary and secondary operator 
// to be enabled for child contract. 
//
// Copyright (c) 2018 Bitcoin Exchange Pte Ltd.
// http://www.btcex.ch/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

contract OperatableBasic
{
    function setPrimaryOperator (address addr) public;
    function setSecondaryOperator (address addr) public;
    function isPrimaryOperator(address addr) public view returns (bool);
    function isSecondaryOperator(address addr) public view returns (bool);
}