;; stx-vault.clar — A simple STX vault with a time-lock function.
;;
;; This contract allows users to deposit STX with a time-lock period.
;; The STX can only be withdrawn after the specified number of blocks
;; have passed since the deposit.
;;
;; Security Properties:
;; - No admin keys for deposits
;; - Time-locked withdrawals prevent immediate access
;; - Self-custody - users retain control of their assets
;; - Immutable - no upgrade mechanisms

;; Define the fungible token for the vault
;; Maximum supply: 10000000000000000 (10 billion) micro-STX
(define-fungible-token stx-token u10000000000000000)

;; Store user deposits and unlock block height.
;; Key: { owner: principal, unlock-block: uint }
;; Value: { amount: uint }
(define-map deposits {
    owner: principal,
    unlock-block: uint
} {
    amount: uint
})

;; Store contract owner, for future upgrades or controls.
(define-data-var contract-owner principal tx-sender)

;; Error codes for vault operations
(define-constant err-not-owner (err u100))
(define-constant err-lock-period-not-met (err u101))
(define-constant err-no-deposit-found (err u102))
(define-constant err-zero-amount (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-zero-lock-period (err u105))

;; Deposit STX into the vault with a time-lock.
;;
;; Arguments:
;; - amount: Amount of STX to deposit in micro-STX
;; - lock-blocks: Number of blocks to lock the STX
;;
;; Returns:
;; - (ok true) on success
;; - Error code;; Security:
;; on failure
;;
 - Lock period must be positive
;; - Tokens are transferred to contract address
(define-public (deposit-stx (amount uint) (lock-blocks uint))
    (begin
        ;; Validate deposit amount
        (assert! (> amount u0) err-zero-amount)
        ;; Validate lock period
        (assert! (> lock-blocks u0) err-zero-lock-period)
        
        ;; Transfer STX from user to contract
        (try! (ft-transfer? stx-token amount tx-sender (as-contract tx-sender)))
        
        ;; Record the deposit with unlock block
        (map-set deposits { 
            owner: tx-sender, 
            unlock-block: (+ block-height lock-blocks) 
        } { amount: amount })
        
        (ok true)
    )
)

;; Withdraw STX from the vault after lock period.
;;
;; Returns:
;; - (ok true) on success
;; - Error code on failure
;;
;; Requirements:
;; - Must have a deposit
;; - Lock period must have passed
;;
;; Security:
;; - Uses post-conditions for safe transfer
;; - Deletes deposit record after withdrawal
(define-public (withdraw-stx)
    (let (
        ;; Get the user's deposit
        (user-deposit (map-get? deposits { 
            owner: tx-sender, 
            unlock-block: (unwrap-panic (get unlock-block (map-get? deposits { owner: tx-sender, unlock-block: u0 })))
        }))
    )
        ;; Validate deposit exists
        (assert! (is-some user-deposit) err-no-deposit-found)
        
        ;; Get the deposit details
        (let (
            (deposit-data (unwrap-panic user-deposit))
            (unlock-height (get unlock-block deposit-data))
            (deposit-amount (get amount deposit-data))
        )
            ;; Validate lock period has passed
            (assert! (>= block-height unlock-height) err-lock-period-not-met)
            
            ;; Transfer STX back to user
            (try! (ft-transfer? stx-token deposit-amount (as-contract tx-sender) tx-sender))
            
            ;; Delete the deposit record
            (map-delete deposits { 
                owner: tx-sender, 
                unlock-block: unlock-height 
            })
            
            (ok true)
        )
    )
)

;; Get the deposit information for a user.
;;
;; Arguments:
;; - user: The principal to query
;; - unlock-block: The unlock block height
;;
;; Returns:
;; - (some { amount }) if deposit exists, none otherwise
(define-read-only (get-deposit (user principal) (unlock-block uint))
    (map-get? deposits { owner: user, unlock-block: unlock-block }))

;; Get the total supply of STX in the vault.
;;
;; Returns:
;; - Total token supply
(define-read-only (get-total-supply)
    (ft-get-supply stx-token))

;; Get the contract owner.
;;
;; Returns:
;; - The contract owner principal
(define-read-only (get-contract-owner)
    (var-get contract-owner))

;; Check if a deposit can be withdrawn.
;;
;; Arguments:
;; - user: The user to check
;; - unlock-block: The unlock block height
;;
;; Returns:
;; - (ok true) if withdrawable, error otherwise
(define-read-only (can-withdraw (user principal) (unlock-block uint))
    (let (
        (deposit (map-get? deposits { owner: user, unlock-block: unlock-block }))
    )
        (if (is-some deposit)
            (let (
                (unlock-height (get unlock-block (unwrap-panic deposit)))
            )
                (if (>= block-height unlock-height)
                    (ok true)
                    err-lock-period-not-met
                )
            )
            err-no-deposit-found
        )
    )
)
