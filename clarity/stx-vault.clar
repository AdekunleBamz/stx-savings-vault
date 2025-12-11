;; stx-vault.clar

;; A simple STX vault with a time-lock fun

(define-fungible-token stx-token u10000000000000000)

;; Store user deposits and unlock block height.
(define-map deposits {
    owner: principal,
    unlock-block: uint
} {
    amount: uint
})

;; Store contract owner, for future upgrades or controls.
(define-data-var contract-owner principal tx-sender)

;; Error codes
(define-constant err-not-owner (err u100))
(define-constant err-lock-period-not-met (err u101))
(define-constant err-no-deposit-found (err u102))

;; Public function to deposit STX into the vault.
(define-public (deposit-stx (amount uint) (lock-blocks uint))
    (begin
        (assert! (> lock-blocks u0) (err u103)) ;; Lock time must be positive
        (ft-transfer? stx-token amount tx-sender (as-contract tx-sender))
        (map-set deposits { owner: tx-sender, unlock-block: (+ block-height lock-blocks) } { amount: amount })
        (ok true)
    )
)

;; Public function for a user to withdraw their STX after the lock period has passed.
(define-public (withdraw-stx)
    (let (
        (user-deposit (map-get? deposits { owner: tx-sender, unlock-block: (get unlock-block (map-get? deposits { owner: tx-sender, unlock-block: (get unlock-block (map-get? deposits { owner: tx-sender, unlock-block: u0 })) })) }))
    )
        (assert! (is-some user-deposit) err-no-deposit-found)
        (assert! (>= block-height (get unlock-block (unwrap-some user-deposit))) err-lock-period-not-met)

        (begin
            (ft-transfer? stx-token (get amount (unwrap-some user-deposit)) (as-contract tx-sender) tx-sender)
            (map-delete deposits { owner: tx-sender, unlock-block: (get unlock-block (unwrap-some user-deposit)) })
            (ok true)
        )
    )
)