# STX Savings Vault

A simple STX vault with a time-lock function on the Stacks blockchain.

## Overview

This smart contract allows users to deposit STX with a configurable time-lock period. The deposited STX can only be withdrawn after the specified number of blocks have passed since the deposit.

## Features

- **Time-locked deposits**: Lock STX for a specified number of blocks
- **Self-custody**: Users retain control of their assets
- **Flexible lock periods**: Choose any lock duration from 1 block to maximum
- **Multi-deposit support**: Users can have multiple deposits with different lock periods

## Contract Functions

### deposit-stx
Deposit STX into the vault with a time-lock.

**Parameters:**
- `amount`: Amount of STX to deposit (in micro-STX)
- `lock-blocks`: Number of blocks to lock the STX

**Returns:** `(ok true)` on success

### withdraw-stx
Withdraw STX from the vault after lock period expires.

**Returns:** `(ok true)` on success

**Requirements:**
- Must have an existing deposit
- Lock period must have expired

### get-deposit
Get deposit information for a user.

### get-total-supply
Get total STX in the vault.

### can-withdraw
Check if a deposit can be withdrawn.

## Error Codes

| Code | Description |
|------|-------------|
| 100 | Not owner |
| 101 | Lock period not met |
| 102 | No deposit found |
| 103 | Zero amount |
| 104 | Insufficient balance |
| 105 | Zero lock period |

## Development

```bash
# Install dependencies
npm install

# Run tests
npm test

# Run with Clarinet
clarinet test
```

## Security Considerations

- Always verify lock periods before withdrawing
- Keep track of your unlock block heights
- Ensure sufficient balance before depositing
