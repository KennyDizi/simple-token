pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// PeterShareTokenConfig - PTS Token Configuration 
//
// Copyright (c) 2018 Bitcoin Exchange Pte Ltd.
// http://www.btcex.ch/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

contract PeterShareTokenConfig 
{
    string public constant NAME = "PeterShares Chain Token";
    string public constant SYMBOL = "PTS";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 500000000 * DECIMALSFACTOR;
}