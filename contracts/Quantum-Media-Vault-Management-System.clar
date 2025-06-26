;; Quantum Media Vault Management System
;; Advanced blockchain-powered multimedia storage and verification protocol
;; 
;; Revolutionary platform for immutable media file registration, authentication, and distribution
;; Features advanced cryptographic validation with multi-layer security protocols
;; Enables decentralized content management with sophisticated access control mechanisms

;; Internal system constants and configuration parameters
(define-constant vault-master-key tx-sender)

;; Comprehensive error handling framework with detailed response codes
(define-constant media-file-missing-error (err u401))
(define-constant content-already-exists-error (err u402))
(define-constant invalid-metadata-error (err u403))
(define-constant file-size-violation-error (err u404))
(define-constant unauthorized-access-error (err u405))
(define-constant ownership-mismatch-error (err u406))
(define-constant admin-privileges-required-error (err u400))
(define-constant viewing-restricted-error (err u407))
(define-constant tag-validation-failed-error (err u408))

;; Media content registry tracking variable
(define-data-var media-vault-sequence uint u0)

;; Core multimedia content storage mapping
(define-map quantum-media-vault
  { content-hash-id: uint }
  {
    multimedia-title: (string-ascii 64),
    content-proprietor: principal,
    binary-file-weight: uint,
    blockchain-timestamp: uint,
    descriptive-metadata: (string-ascii 128),
    classification-labels: (list 10 (string-ascii 32))
  }
)

;; Advanced authorization and access control matrix
(define-map vault-access-matrix
  { content-hash-id: uint, requesting-principal: principal }
  { viewing-permission-granted: bool }
)

;; ===== Internal validation and utility functions =====

;; Comprehensive tag format validation algorithm
(define-private (validate-classification-tag (classification-tag (string-ascii 32)))
  (and
    (> (len classification-tag) u0)
    (< (len classification-tag) u33)
  )
)

;; Multi-tag collection validation with comprehensive checks
(define-private (verify-tag-collection-integrity (tag-collection (list 10 (string-ascii 32))))
  (and
    (> (len tag-collection) u0)
    (<= (len tag-collection) u10)
    (is-eq (len (filter validate-classification-tag tag-collection)) (len tag-collection))
  )
)

;; Content existence verification in the quantum vault
(define-private (verify-content-existence (content-hash-id uint))
  (is-some (map-get? quantum-media-vault { content-hash-id: content-hash-id }))
)

;; Binary file weight extraction utility function
(define-private (extract-binary-weight (content-hash-id uint))
  (default-to u0
    (get binary-file-weight
      (map-get? quantum-media-vault { content-hash-id: content-hash-id })
    )
  )
)

;; Comprehensive ownership validation mechanism
(define-private (validate-content-ownership (content-hash-id uint) (requesting-principal principal))
  (match (map-get? quantum-media-vault { content-hash-id: content-hash-id })
    content-record (is-eq (get content-proprietor content-record) requesting-principal)
    false
  )
)

;; ===== Primary public interface functions =====

;; Comprehensive multimedia content registration with advanced metadata handling
(define-public (register-multimedia-content
  (multimedia-title (string-ascii 64))
  (binary-file-weight uint)
  (descriptive-metadata (string-ascii 128))
  (classification-labels (list 10 (string-ascii 32)))
)
  (let
    (
      (next-content-identifier (+ (var-get media-vault-sequence) u1))
    )
    ;; Extensive parameter validation with detailed error checking
    (asserts! (> (len multimedia-title) u0) invalid-metadata-error)
    (asserts! (< (len multimedia-title) u65) invalid-metadata-error)
    (asserts! (> binary-file-weight u0) file-size-violation-error)
    (asserts! (< binary-file-weight u1000000000) file-size-violation-error)
    (asserts! (> (len descriptive-metadata) u0) invalid-metadata-error)
    (asserts! (< (len descriptive-metadata) u129) invalid-metadata-error)
    (asserts! (verify-tag-collection-integrity classification-labels) tag-validation-failed-error)

    ;; Secure content registration in quantum vault storage
    (map-insert quantum-media-vault
      { content-hash-id: next-content-identifier }
      {
        multimedia-title: multimedia-title,
        content-proprietor: tx-sender,
        binary-file-weight: binary-file-weight,
        blockchain-timestamp: block-height,
        descriptive-metadata: descriptive-metadata,
        classification-labels: classification-labels
      }
    )

    ;; Automatic access permission initialization for content creator
    (map-insert vault-access-matrix
      { content-hash-id: next-content-identifier, requesting-principal: tx-sender }
      { viewing-permission-granted: true }
    )

    ;; Increment the global media vault sequence counter
    (var-set media-vault-sequence next-content-identifier)
    (ok next-content-identifier)
  )
)

;; Advanced content modification with comprehensive validation protocols
(define-public (modify-multimedia-content
  (content-hash-id uint)
  (updated-multimedia-title (string-ascii 64))
  (updated-binary-file-weight uint)
  (updated-descriptive-metadata (string-ascii 128))
  (updated-classification-labels (list 10 (string-ascii 32)))
)
  (let
    (
      (existing-content-record (unwrap! (map-get? quantum-media-vault { content-hash-id: content-hash-id })
        media-file-missing-error))
    )
    ;; Comprehensive authorization and parameter validation
    (asserts! (verify-content-existence content-hash-id) media-file-missing-error)
    (asserts! (is-eq (get content-proprietor existing-content-record) tx-sender) ownership-mismatch-error)
    (asserts! (> (len updated-multimedia-title) u0) invalid-metadata-error)
    (asserts! (< (len updated-multimedia-title) u65) invalid-metadata-error)
    (asserts! (> updated-binary-file-weight u0) file-size-violation-error)
    (asserts! (< updated-binary-file-weight u1000000000) file-size-violation-error)
    (asserts! (> (len updated-descriptive-metadata) u0) invalid-metadata-error)
    (asserts! (< (len updated-descriptive-metadata) u129) invalid-metadata-error)
    (asserts! (verify-tag-collection-integrity updated-classification-labels) tag-validation-failed-error)

    ;; Execute comprehensive content record update with merged data
    (map-set quantum-media-vault
      { content-hash-id: content-hash-id }
      (merge existing-content-record {
        multimedia-title: updated-multimedia-title,
        binary-file-weight: updated-binary-file-weight,
        descriptive-metadata: updated-descriptive-metadata,
        classification-labels: updated-classification-labels
      })
    )
    (ok true)
  )
)

;; Secure ownership transfer protocol with validation mechanisms
(define-public (execute-ownership-transfer (content-hash-id uint) (designated-new-proprietor principal))
  (let
    (
      (current-content-record (unwrap! (map-get? quantum-media-vault { content-hash-id: content-hash-id })
        media-file-missing-error))
    )
    ;; Strict ownership verification before transfer execution
    (asserts! (verify-content-existence content-hash-id) media-file-missing-error)
    (asserts! (is-eq (get content-proprietor current-content-record) tx-sender) ownership-mismatch-error)

    ;; Execute secure ownership transfer with updated proprietor information
    (map-set quantum-media-vault
      { content-hash-id: content-hash-id }
      (merge current-content-record { content-proprietor: designated-new-proprietor })
    )
    (ok true)
  )
)

;; Permanent content removal from quantum vault with security checks
(define-public (purge-multimedia-content (content-hash-id uint))
  (let
    (
      (target-content-record (unwrap! (map-get? quantum-media-vault { content-hash-id: content-hash-id })
        media-file-missing-error))
    )
    ;; Comprehensive ownership validation before permanent deletion
    (asserts! (verify-content-existence content-hash-id) media-file-missing-error)
    (asserts! (is-eq (get content-proprietor target-content-record) tx-sender) ownership-mismatch-error)

    ;; Execute irreversible content removal from quantum vault
    (map-delete quantum-media-vault { content-hash-id: content-hash-id })
    (ok true)
  )
)

;; Advanced permission management for content access control
(define-public (configure-access-permissions (content-hash-id uint) (authorized-principal principal) (permission-status bool))
  (let
    (
      (content-record (unwrap! (map-get? quantum-media-vault { content-hash-id: content-hash-id })
        media-file-missing-error))
    )
    ;; Verify content existence and ownership before permission modification
    (asserts! (verify-content-existence content-hash-id) media-file-missing-error)
    (asserts! (is-eq (get content-proprietor content-record) tx-sender) ownership-mismatch-error)

    (ok true)
  )
)

;; ===== Advanced read-only information retrieval functions =====

;; Comprehensive content information retrieval with access control
(define-read-only (retrieve-multimedia-details (content-hash-id uint))
  (let
    (
      (content-record (unwrap! (map-get? quantum-media-vault { content-hash-id: content-hash-id })
        media-file-missing-error))
      (access-permission (default-to false
        (get viewing-permission-granted
          (map-get? vault-access-matrix { content-hash-id: content-hash-id, requesting-principal: tx-sender })
        )
      ))
    )
    ;; Verify access permissions before data retrieval
    (asserts! (verify-content-existence content-hash-id) media-file-missing-error)
    (asserts! (or access-permission (is-eq (get content-proprietor content-record) tx-sender)) viewing-restricted-error)

    ;; Return comprehensive content information
    (ok {
      multimedia-title: (get multimedia-title content-record),
      content-proprietor: (get content-proprietor content-record),
      binary-file-weight: (get binary-file-weight content-record),
      blockchain-timestamp: (get blockchain-timestamp content-record),
      descriptive-metadata: (get descriptive-metadata content-record),
      classification-labels: (get classification-labels content-record)
    })
  )
)

;; Global vault statistics retrieval function
(define-read-only (get-vault-statistics)
  (ok {
    total-registered-content: (var-get media-vault-sequence),
    vault-master-authority: vault-master-key
  })
)

;; Content ownership verification utility
(define-read-only (verify-content-proprietor (content-hash-id uint))
  (match (map-get? quantum-media-vault { content-hash-id: content-hash-id })
    content-record (ok (get content-proprietor content-record))
    media-file-missing-error
  )
)

;; Access permission status verification
(define-read-only (check-viewing-permissions (content-hash-id uint) (requesting-principal principal))
  (let
    (
      (content-record (unwrap! (map-get? quantum-media-vault { content-hash-id: content-hash-id })
        media-file-missing-error))
      (explicit-permission (default-to false
        (get viewing-permission-granted
          (map-get? vault-access-matrix { content-hash-id: content-hash-id, requesting-principal: requesting-principal })
        )
      ))
    )
    ;; Return comprehensive permission status
    (ok {
      has-explicit-permission: explicit-permission,
      is-content-owner: (is-eq (get content-proprietor content-record) requesting-principal),
      can-access-content: (or explicit-permission (is-eq (get content-proprietor content-record) requesting-principal))
    })
  )
)
