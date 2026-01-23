<!-- STX Savings Vault contribution -->n# STX Vault -- Bitcoin-Backed Saving Vault on Stacks

## Overview

STX Vault is a decentralized, non-custodial saving vault built on
**Stacks**, the Bitcoin-secured smart contract layer. Users can deposit
STX into a smart contract vault, lock their balance for savings, and
withdraw later --- with all transactions settled on **Bitcoin finality**
through Stacks' Proof-of-Transfer consensus.

## Why This Is a Stacks + Bitcoin Project

-   Clarity smart contract stored in `/contracts/vault.clar`
-   Bitcoin finality via Proof‑of‑Transfer
-   Hiro Wallet Web integration
-   Deployed and verifiable on Stacks Explorer
-   Uses Stacks.js for deposits, withdrawals, and balance fetching

## Features

-   Deposit STX into vault\
-   Optional lock periods\
-   Withdraw anytime or after lock period\
-   On-chain balances viewable on Stacks Explorer\
-   Bitcoin-secured execution

## Smart Contract (vault.clar)

    (define-data-var vault-balances (map principal uint))
    (define-data-var lock-periods (map principal uint))
    (define-constant COOLDOWN-SECONDS u604800)

    (define-public (deposit)
      (let (
          (amount (stx-get-balance tx-sender))
      )
        (asserts! (> amount u0) "NO_STX")
        (try! (stx-transfer? amount tx-sender contract-principal))
        (map-set vault-balances tx-sender (+ (default-to u0 (map-get? vault-balances tx-sender)) amount))
        (ok amount)
      )
    )

    (define-public (withdraw (amount uint))
      (let (
          (balance (default-to u0 (map-get? vault-balances tx-sender)))
      )
        (asserts! (>= balance amount) "INSUFFICIENT_BALANCE")
        (try! (stx-transfer? amount contract-principal tx-sender))
        (map-set vault-balances tx-sender (- balance amount))
        (ok true)
      )
    )

## Deployment Steps (Mobile-Friendly)

1.  Deploy `vault.clar` using Stacks Explorer Sandbox\
2.  Connect Hiro Wallet Web\
3.  Upload contract file\
4.  Confirm deployment on Testnet/Mainnet\
5.  Add contract address + txid to README\
6.  Deploy frontend on Vercel

## Frontend Integration (Stacks.js)

### Deposit

``` js
await makeContractCall({
  contractAddress,
  contractName: "vault",
  functionName: "deposit",
  network,
});
```

### Withdraw

``` js
await makeContractCall({
  contractAddress,
  contractName: "vault",
  functionName: "withdraw",
  functionArgs: [uintCV(amount)],
  network,
});
```

## Project Structure

    /contracts
      vault.clar
    /src
      connect-wallet.js
      deposit.js
      withdraw.js
      get-balance.js
    package.json
    README.md

## Live Links 

-   Live dApp: `<your-vercel-url>`{=html}
-   Contract Address: ST...vault
-   Explorer TxID: `<txid>`{=html}
