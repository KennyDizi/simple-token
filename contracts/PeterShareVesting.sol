pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// SencTokenVesting - PTS Token Vesting Contract
//
// Copyright (c) 2018 Bitcoin Exchange Pte Ltd.
// http://www.btcex.ch/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

import "./zeppelin-solidity/contracts/math/Math.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./PeterShareToken.sol";
import "./Salvageable.sol";

// ----------------------------------------------------------------------------
// Total tokens 500m
// * Founding Team 10% - 5 tranches of 20% of 50,000,000 in **arrears** every 24 weeks from the activation date.
// * Early Support 20% - 4 tranches of 25% of 100,000,000 in **advance** every 4 weeks from activation date.
// * Pre-sale 20% - 4 tranches of 25% of 100,000,000 in **advance** every 4 weeks from activation date.
//   * To be separated into ~ 28 presale addresses
// ----------------------------------------------------------------------------

contract PeterShareVesting is Salvageable {
    using SafeMath for uint;

    PeterShareToken public token;

    bool public started = false;
    uint public startTimestamp;
    uint public totalTokens;

    struct Entry {
        uint tokens;
        bool advance;
        uint periods;
        uint periodLength;
        uint withdrawn;
    }
    mapping (address => Entry) public entries;

    event NewEntry(address indexed beneficiary, uint tokens, bool advance, uint periods, uint periodLength);
    event Withdrawn(address indexed beneficiary, uint withdrawn);

    constructor(PeterShareToken _token) public {
        require(_token != address(0));
        token = _token;
    }

    function addEntryIn4WeekPeriods(address beneficiary, uint tokens, bool advance, uint periods) public onlyOwner {
        addEntry(beneficiary, tokens, advance, periods, 4 * 7 days);
    }
    function addEntryIn24WeekPeriods(address beneficiary, uint tokens, bool advance, uint periods) public onlyOwner {
        addEntry(beneficiary, tokens, advance, periods, 24 * 7 days);
    }
    function addEntryInSecondsPeriods(address beneficiary, uint tokens, bool advance, uint periods, uint secondsPeriod) public onlyOwner {
        addEntry(beneficiary, tokens, advance, periods, secondsPeriod);
    }

    function addEntry(address beneficiary, uint tokens, bool advance, uint periods, uint periodLength) internal {
        require(!started);
        require(beneficiary != address(0));
        require(tokens > 0);
        require(periods > 0);
        require(entries[beneficiary].tokens == 0);
        entries[beneficiary] = Entry({
            tokens: tokens,
            advance: advance,
            periods: periods,
            periodLength: periodLength,
            withdrawn: 0
        });
        totalTokens = totalTokens.add(tokens);
        emit NewEntry(beneficiary, tokens, advance, periods, periodLength);
    }

    function start() public onlyOwner {
        require(!started);
        require(totalTokens > 0);
        require(totalTokens == token.balanceOf(this));
        started = true;
        startTimestamp = now;
    }

    function vested(address beneficiary, uint time) public view returns (uint) {
        uint result = 0;
        if (startTimestamp > 0 && time >= startTimestamp) {
            Entry memory entry = entries[beneficiary];
            if (entry.tokens > 0) {
                uint periods = time.sub(startTimestamp).div(entry.periodLength);
                if (entry.advance) {
                    periods++;
                }
                if (periods >= entry.periods) {
                    result = entry.tokens;
                } else {
                    result = entry.tokens.mul(periods).div(entry.periods);
                }
            }
        }
        return result;
    }

    function withdrawable(address beneficiary) public view returns (uint) {
        uint result = 0;
        Entry memory entry = entries[beneficiary];
        if (entry.tokens > 0) {
            uint _vested = vested(beneficiary, now);
            result = _vested.sub(entry.withdrawn);
        }
        return result;
    }

    function withdraw() public {
        withdrawInternal(msg.sender);
    }

    function withdrawOnBehalfOf(address beneficiary) public onlyOwner {
        withdrawInternal(beneficiary);
    }

    function withdrawInternal(address beneficiary) internal {
        Entry storage entry = entries[beneficiary];
        require(entry.tokens > 0);
        uint _vested = vested(beneficiary, now);
        uint _withdrawn = entry.withdrawn;
        require(_vested > _withdrawn);
        uint _withdrawable = _vested.sub(_withdrawn);
        entry.withdrawn = _vested;
        require(token.transfer(beneficiary, _withdrawable));
        emit Withdrawn(beneficiary, _withdrawable);
    }

    function tokens(address beneficiary) public view returns (uint) {
        return entries[beneficiary].tokens;
    }

    function withdrawn(address beneficiary) public view returns (uint) {
        return entries[beneficiary].withdrawn;
    }

    function emergencyERC20Drain(ERC20 oddToken, uint amount) public canOperate {
        // Cannot withdraw PeterShareToken if vesting started
        require(!started || address(oddToken) != address(token));
        super.emergencyERC20Drain(oddToken,amount);
    }
}